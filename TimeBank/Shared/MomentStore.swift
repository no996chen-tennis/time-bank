// TimeBank/Shared/MomentStore.swift

import Foundation
import SwiftData

@MainActor
final class MomentStore {
    enum MomentStoreError: Error, LocalizedError {
        /// 用户主动新建的 Moment 不允许绑到无存储层的系统账户（lifespan / daily / other）。
        /// 详见 PRD §7.6 「systemTop / systemHidden 无存储层」。
        case invalidDimensionForMoment(String)

        var errorDescription: String? {
            switch self {
            case .invalidDimensionForMoment(let id):
                return "不能把瞬间存入系统账户「\(id)」（无存储层）。"
            }
        }
    }

    /// 系统账户的保留 ID，禁止用户主动 save Moment 到这些账户。
    /// `lifespan`：顶部时间余额卡，无存储层。
    /// `daily`：V1.1 今日此刻系统隐藏账户。
    /// `other`：孤儿 Moment 承接账户，仅供内部迁移使用，不允许用户直接选。
    private static let reservedSystemDimensionIds: Set<String> = [
        DimensionReservedID.lifespan.rawValue,
        DimensionReservedID.daily.rawValue,
        DimensionReservedID.other.rawValue
    ]

    struct SaveRequest: Sendable {
        var id: UUID
        var dimensionId: String
        var originDimensionId: String?
        var title: String?
        var note: String
        var happenedAt: Date
        var durationSeconds: Int?
        var media: [FileStore.PendingMedia]

        init(
            id: UUID = UUID(),
            dimensionId: String,
            originDimensionId: String? = nil,
            title: String? = nil,
            note: String = "",
            happenedAt: Date = .now,
            durationSeconds: Int? = nil,
            media: [FileStore.PendingMedia] = []
        ) {
            self.id = id
            self.dimensionId = dimensionId
            self.originDimensionId = originDimensionId
            self.title = title
            self.note = note
            self.happenedAt = happenedAt
            self.durationSeconds = durationSeconds
            self.media = media
        }
    }

    let modelContext: ModelContext
    let fileStore: FileStore
    private let deleteDelaySeconds: TimeInterval
    private var pendingDeleteTasks: [UUID: Task<Void, Never>] = [:]

    init(
        modelContext: ModelContext,
        fileStore: FileStore = FileStore(),
        deleteDelaySeconds: TimeInterval = 5.0
    ) {
        self.modelContext = modelContext
        self.fileStore = fileStore
        self.deleteDelaySeconds = deleteDelaySeconds
    }

    deinit {
        for task in pendingDeleteTasks.values {
            task.cancel()
        }
    }

    @discardableResult
    func bootstrapReservedData() throws -> [Dimension] {
        let inserted = try Dimension.seedReservedDimensionsIfNeeded(in: modelContext)
        _ = try Settings.fetchOrCreateDefault(in: modelContext)
        return inserted
    }

    @discardableResult
    func save(moment request: SaveRequest) async throws -> Moment {
        if MomentStore.reservedSystemDimensionIds.contains(request.dimensionId) {
            throw MomentStoreError.invalidDimensionForMoment(request.dimensionId)
        }

        let moment = Moment(
            id: request.id,
            dimensionId: request.dimensionId,
            originDimensionId: request.originDimensionId,
            title: request.title,
            note: request.note,
            happenedAt: request.happenedAt,
            durationSeconds: request.durationSeconds,
            status: .normal,
            pendingDeleteAt: nil,
            createdAt: .now,
            updatedAt: .now
        )

        var insertedMoment = false

        do {
            let writtenMedia = try fileStore.writeMedia(request.media, to: request.id)
            for media in writtenMedia {
                let item = MediaItem(
                    momentId: request.id,
                    type: media.kind.rawValue,
                    relativePath: media.relativePath,
                    thumbnailPath: media.thumbnailPath,
                    fileSize: media.fileSize,
                    durationSeconds: media.durationSeconds,
                    sortIndex: media.sortIndex,
                    createdAt: .now,
                    moment: moment
                )
                moment.mediaItems.append(item)
            }

            modelContext.insert(moment)
            insertedMoment = true
            try modelContext.save()

            return moment
        } catch {
            if insertedMoment {
                modelContext.rollback()
            }
            try? fileStore.removeMomentDirectoryIfExists(for: request.id)
            throw error
        }
    }

    func delete(moment: Moment) throws {
        guard moment.status != .pendingDelete else { return }

        pendingDeleteTasks[moment.id]?.cancel()

        moment.status = .pendingDelete
        moment.pendingDeleteAt = .now
        moment.updatedAt = .now
        try modelContext.save()

        let momentID = moment.id
        pendingDeleteTasks[momentID] = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let nanoseconds = UInt64(max(0, self.deleteDelaySeconds) * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanoseconds)
                try self.commitPendingDeleteIfNeeded(momentID: momentID)
            } catch is CancellationError {
                return
            } catch {
                return
            }
        }
    }

    func undoDelete(moment: Moment) throws {
        pendingDeleteTasks[moment.id]?.cancel()
        pendingDeleteTasks[moment.id] = nil

        moment.status = .normal
        moment.pendingDeleteAt = nil
        moment.updatedAt = .now
        try modelContext.save()
    }

    @discardableResult
    func commitPendingDeletes() async throws -> Int {
        let pendingMoments = try fetchAllMoments().filter { $0.status == .pendingDelete }
        for moment in pendingMoments {
            try commitPendingDeleteIfNeeded(momentID: moment.id)
        }
        _ = try cleanupOrphanFiles()
        return pendingMoments.count
    }

    @discardableResult
    func cleanupOrphanFiles() throws -> [URL] {
        let referencedMomentIDs = Set(try fetchAllMoments().map(\.id))
        return try fileStore.removeOrphanMomentDirectories(referencedMomentIDs: referencedMomentIDs)
    }

    func fetchAllMoments() throws -> [Moment] {
        try modelContext.fetch(FetchDescriptor<Moment>())
    }

    func fetchMoment(id: UUID) throws -> Moment? {
        try fetchAllMoments().first(where: { $0.id == id })
    }

    private func commitPendingDeleteIfNeeded(momentID: UUID) throws {
        guard let moment = try fetchMoment(id: momentID) else {
            pendingDeleteTasks[momentID] = nil
            return
        }

        guard moment.status == .pendingDelete else {
            pendingDeleteTasks[momentID] = nil
            return
        }

        try fileStore.removeMomentDirectoryIfExists(for: momentID)
        modelContext.delete(moment)
        try modelContext.save()
        pendingDeleteTasks[momentID] = nil
    }
}
