// TimeBank/Features/Moment/MomentEditor/MomentEditorDraft.swift

import Foundation

enum MomentEditorMode: Equatable {
    case create
    case edit(UUID)
}

struct MomentEditorRoute: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let initialDimensionID: String?
    let mode: MomentEditorMode

    static let newMoment = MomentEditorRoute(
        title: "存入一个时刻",
        initialDimensionID: nil,
        mode: .create
    )

    static func dimension(_ dimension: Dimension) -> MomentEditorRoute {
        MomentEditorRoute(
            title: "存入到 \(dimension.name)",
            initialDimensionID: dimension.id,
            mode: .create
        )
    }

    static func edit(_ moment: Moment) -> MomentEditorRoute {
        MomentEditorRoute(
            title: "编辑这个时刻",
            initialDimensionID: moment.dimensionId,
            mode: .edit(moment.id)
        )
    }
}

struct MomentEditorDraft {
    var selectedDimensionID: String?
    var title: String
    var note: String
    var happenedAt: Date
    var durationMinutesText: String
    var mediaItems: [MomentEditorMediaItem]
    var baseline: MomentEditorDraftSnapshot?

    init(
        selectedDimensionID: String? = nil,
        title: String = "",
        note: String = "",
        happenedAt: Date = .now,
        durationMinutesText: String = "",
        mediaItems: [MomentEditorMediaItem] = [],
        baseline: MomentEditorDraftSnapshot? = nil
    ) {
        self.selectedDimensionID = selectedDimensionID
        self.title = title
        self.note = note
        self.happenedAt = happenedAt
        self.durationMinutesText = durationMinutesText
        self.mediaItems = mediaItems
        self.baseline = baseline
    }

    var saveableMediaItems: [MomentEditorMediaItem] {
        mediaItems.filter(\.isSaveable)
    }

    var hasContent: Bool {
        trimmed(title).isEmpty == false
            || trimmed(note).isEmpty == false
            || saveableMediaItems.isEmpty == false
    }

    var hasDiscardableChanges: Bool {
        if let baseline {
            return snapshot != baseline
        }

        return trimmed(title).isEmpty == false
            || trimmed(note).isEmpty == false
            || sanitizedDurationMinutesText.isEmpty == false
            || mediaItems.isEmpty == false
    }

    var canSave: Bool {
        guard let selectedDimensionID, selectedDimensionID.isEmpty == false else {
            return false
        }
        return hasContent
    }

    var disabledSaveAccessibilityLabel: String? {
        hasContent ? nil : "请先添加照片、标题或笔记"
    }

    var sanitizedDurationMinutesText: String {
        durationMinutesText.filter(\.isNumber)
    }

    var durationSeconds: Int? {
        guard let minutes = Int(sanitizedDurationMinutesText), minutes > 0 else {
            return nil
        }
        return minutes * 60
    }

    func makeSaveRequest(id: UUID = UUID()) -> MomentStore.SaveRequest? {
        guard canSave, let selectedDimensionID else { return nil }

        let requestTitle = trimmed(title)
        return MomentStore.SaveRequest(
            id: id,
            dimensionId: selectedDimensionID,
            title: requestTitle.isEmpty ? nil : requestTitle,
            note: trimmed(note),
            happenedAt: happenedAt,
            durationSeconds: durationSeconds,
            media: saveableMediaItems.compactMap(\.pendingMedia)
        )
    }

    func makeUpdateRequest(momentID: UUID) -> MomentStore.UpdateRequest? {
        guard canSave, let selectedDimensionID else { return nil }

        let requestTitle = trimmed(title)
        return MomentStore.UpdateRequest(
            id: momentID,
            dimensionId: selectedDimensionID,
            title: requestTitle.isEmpty ? nil : requestTitle,
            note: trimmed(note),
            happenedAt: happenedAt,
            durationSeconds: durationSeconds,
            media: saveableMediaItems.compactMap(\.updateMedia)
        )
    }

    var snapshot: MomentEditorDraftSnapshot {
        MomentEditorDraftSnapshot(
            selectedDimensionID: selectedDimensionID,
            title: trimmed(title),
            note: trimmed(note),
            happenedAt: happenedAt,
            durationMinutesText: sanitizedDurationMinutesText,
            media: mediaItems.map(\.snapshot)
        )
    }

    @MainActor
    static func editing(moment: Moment) -> MomentEditorDraft {
        let sortedMedia = moment.mediaItems.sorted { lhs, rhs in
            if lhs.sortIndex == rhs.sortIndex {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.sortIndex < rhs.sortIndex
        }
        let title = moment.title ?? ""
        let durationText = moment.durationSeconds.map { "\($0 / 60)" } ?? ""
        var draft = MomentEditorDraft(
            selectedDimensionID: moment.dimensionId,
            title: title,
            note: moment.note,
            happenedAt: moment.happenedAt,
            durationMinutesText: durationText,
            mediaItems: sortedMedia.map(MomentEditorMediaItem.existing(media:))
        )
        draft.baseline = draft.snapshot
        return draft
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct MomentEditorDraftSnapshot: Equatable {
    var selectedDimensionID: String?
    var title: String
    var note: String
    var happenedAt: Date
    var durationMinutesText: String
    var media: [MomentEditorMediaSnapshot]
}

struct MomentEditorMediaSnapshot: Equatable {
    var id: UUID
    var existingMediaID: UUID?
    var kind: MediaKind
    var isFailed: Bool
}

struct MomentEditorMediaItem: Identifiable, Equatable {
    let id: UUID
    var existingMediaID: UUID?
    var kind: MediaKind
    var data: Data?
    var preferredFileExtension: String
    var originalFilename: String?
    var isFailed: Bool
    var relativePath: String?
    var thumbnailPath: String?

    init(
        id: UUID = UUID(),
        existingMediaID: UUID? = nil,
        kind: MediaKind,
        data: Data?,
        preferredFileExtension: String,
        originalFilename: String? = nil,
        isFailed: Bool = false,
        relativePath: String? = nil,
        thumbnailPath: String? = nil
    ) {
        self.id = id
        self.existingMediaID = existingMediaID
        self.kind = kind
        self.data = data
        self.preferredFileExtension = preferredFileExtension
        self.originalFilename = originalFilename
        self.isFailed = isFailed
        self.relativePath = relativePath
        self.thumbnailPath = thumbnailPath
    }

    var isSaveable: Bool {
        isFailed == false && (existingMediaID != nil || data != nil)
    }

    var pendingMedia: FileStore.PendingMedia? {
        guard let data, isFailed == false else { return nil }

        switch kind {
        case .image:
            return .image(
                data: data,
                fileExtension: preferredFileExtension,
                originalFilename: originalFilename
            )
        case .video:
            return .video(
                data: data,
                fileExtension: preferredFileExtension,
                durationSeconds: nil,
                originalFilename: originalFilename
            )
        }
    }

    var updateMedia: MomentStore.UpdateMedia? {
        guard isFailed == false else { return nil }
        if let existingMediaID {
            return .existing(id: existingMediaID)
        }
        guard let pendingMedia else { return nil }
        return .new(pendingMedia)
    }

    var snapshot: MomentEditorMediaSnapshot {
        MomentEditorMediaSnapshot(
            id: id,
            existingMediaID: existingMediaID,
            kind: kind,
            isFailed: isFailed
        )
    }

    static func existing(media: MediaItem) -> MomentEditorMediaItem {
        MomentEditorMediaItem(
            id: media.id,
            existingMediaID: media.id,
            kind: media.mediaKind,
            data: nil,
            preferredFileExtension: URL(fileURLWithPath: media.relativePath).pathExtension,
            originalFilename: nil,
            isFailed: false,
            relativePath: media.relativePath,
            thumbnailPath: media.thumbnailPath
        )
    }

    static func image(
        data: Data,
        fileExtension: String = "heic",
        originalFilename: String? = nil
    ) -> MomentEditorMediaItem {
        MomentEditorMediaItem(
            kind: .image,
            data: data,
            preferredFileExtension: fileExtension,
            originalFilename: originalFilename
        )
    }

    static func video(
        data: Data,
        fileExtension: String = "mov",
        originalFilename: String? = nil
    ) -> MomentEditorMediaItem {
        MomentEditorMediaItem(
            kind: .video,
            data: data,
            preferredFileExtension: fileExtension,
            originalFilename: originalFilename
        )
    }

    static func failed(kind: MediaKind = .image) -> MomentEditorMediaItem {
        MomentEditorMediaItem(
            kind: kind,
            data: nil,
            preferredFileExtension: kind == .image ? "heic" : "mov",
            isFailed: true
        )
    }
}
