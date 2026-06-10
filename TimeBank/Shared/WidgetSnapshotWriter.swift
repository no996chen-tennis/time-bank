import Foundation
import ImageIO
import SwiftData
import UniformTypeIdentifiers
import WidgetKit

enum WidgetSnapshotWriter {
    @discardableResult
    static func writeSnapshot(
        profile: UserProfile,
        dimensions: [Dimension],
        moments: [Moment],
        settings: Settings? = nil,
        now: Date = .now,
        reloadTimelines: Bool = true
    ) throws -> TimeBankWidgetSnapshot {
        let snapshot = makeSnapshot(
            profile: profile,
            dimensions: dimensions,
            moments: moments,
            settings: settings,
            now: now
        )
        try TimeBankWidgetSnapshotStore.write(snapshot)

        if reloadTimelines {
            WidgetCenter.shared.reloadAllTimelines()
        }

        return snapshot
    }

    @discardableResult
    static func writeSnapshot(
        modelContext: ModelContext,
        now: Date = .now,
        reloadTimelines: Bool = true
    ) throws -> TimeBankWidgetSnapshot? {
        guard let profile = try UserProfile.fetchSingleton(in: modelContext) else {
            return nil
        }

        let dimensions = try modelContext.fetch(FetchDescriptor<Dimension>())
        let moments = try modelContext.fetch(FetchDescriptor<Moment>())
        let settings = try Settings.fetchOrCreateDefault(in: modelContext)
        return try writeSnapshot(
            profile: profile,
            dimensions: dimensions,
            moments: moments,
            settings: settings,
            now: now,
            reloadTimelines: reloadTimelines
        )
    }

    static func makeSnapshot(
        profile: UserProfile,
        dimensions: [Dimension],
        moments: [Moment],
        settings: Settings? = nil,
        now: Date = .now
    ) -> TimeBankWidgetSnapshot {
        let visibleDimensions = visibleAccountDimensions(from: dimensions)
        let normalMoments = moments.filter { $0.status == .normal }
        let dimensionsByID = Dictionary(uniqueKeysWithValues: dimensions.map { ($0.id, $0) })
        let preferredIDs = settings?.widgetPreferredDimensions ?? []
        let orderedDimensions = preferredWidgetDimensions(
            from: visibleDimensions,
            preferredIDs: preferredIDs
        )

        let projection = DimensionCompute.projection(profile: profile, scope: .year, now: now)
        let dimensionSnapshots = orderedDimensions.map { dimension in
            makeDimensionSnapshot(
                dimension: dimension,
                profile: profile,
                dimensionsByID: dimensionsByID,
                moments: normalMoments,
                now: now
            )
        }

        return TimeBankWidgetSnapshot(
            generatedAt: now,
            yearBalanceWeeks: Int(max(0, projection.remainingWeeks).rounded()),
            storedMomentCountTotal: totalStoredMomentCount(
                dimensions: visibleDimensions,
                moments: normalMoments
            ),
            topText: topText(for: settings?.widgetTone ?? .warm),
            dimensions: dimensionSnapshots,
            todayDeposited: normalMoments.contains { Calendar.current.isDateInToday($0.createdAt) },
            memories: widgetMemories(
                moments: normalMoments,
                dimensionsByID: dimensionsByID,
                now: now
            ),
            themeKind: TimeBankThemeKind.persisted.rawValue
        )
    }

    /// 为 widget 轮换面挑选记忆池：周年（那年今日）优先 → 刚冲洗优先 → 最近优先，取前 6。
    private static func widgetMemories(
        moments: [Moment],
        dimensionsByID: [String: Dimension],
        now: Date
    ) -> [TimeBankWidgetMemory] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let todayComponents = calendar.dateComponents([.month, .day], from: now)

        let candidates: [(memory: TimeBankWidgetMemory, moment: Moment)] = moments.compactMap { moment in
            guard let title = moment.title?.trimmingCharacters(in: .whitespacesAndNewlines),
                  title.isEmpty == false
            else {
                return nil
            }

            let happenedDay = calendar.startOfDay(for: moment.happenedAt)
            let daysAgo = max(0, calendar.dateComponents([.day], from: happenedDay, to: today).day ?? 0)
            let happenedComponents = calendar.dateComponents([.month, .day], from: moment.happenedAt)
            let isAnniversary = daysAgo > 0
                && happenedComponents.month == todayComponents.month
                && happenedComponents.day == todayComponents.day

            let createdDay = calendar.startOfDay(for: moment.createdAt)
            let createdDaysAgo = calendar.dateComponents([.day], from: createdDay, to: today).day ?? 0
            let developed = (2...4).contains(createdDaysAgo)

            let memory = TimeBankWidgetMemory(
                title: title,
                daysAgo: daysAgo,
                colorKey: dimensionsByID[moment.dimensionId]?.colorKey ?? "rose",
                isAnniversary: isAnniversary,
                developed: developed
            )
            return (memory, moment)
        }

        let sorted = candidates.sorted { lhs, rhs in
            if lhs.memory.isAnniversary != rhs.memory.isAnniversary { return lhs.memory.isAnniversary }
            if lhs.memory.developed != rhs.memory.developed { return lhs.memory.developed }
            return lhs.memory.daysAgo < rhs.memory.daysAgo
        }

        return attachThumbs(to: Array(sorted.prefix(6)))
    }

    /// 把入选记忆的缩略图导出到 App Group 共享目录（widget 进程读不到 App 沙盒里的媒体）。
    /// 任何一步失败都静默降级为无图——缩略图绝不能阻塞快照写入。
    private static func attachThumbs(
        to entries: [(memory: TimeBankWidgetMemory, moment: Moment)]
    ) -> [TimeBankWidgetMemory] {
        guard let dir = TimeBankWidgetSnapshotStore.thumbsDirectoryURL() else {
            return entries.map(\.memory)
        }

        let fileStore = FileStore()
        var keptNames = Set<String>()
        let result = entries.map { entry -> TimeBankWidgetMemory in
            var memory = entry.memory
            if let name = exportThumb(for: entry.moment, fileStore: fileStore, into: dir) {
                memory.thumbFile = name
                keptNames.insert(name)
            }
            return memory
        }

        // 清掉不再被任何记忆引用的旧图，目录体积恒定在 ≤6 张小图
        if let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) {
            for file in files where keptNames.contains(file) == false {
                try? FileManager.default.removeItem(at: dir.appendingPathComponent(file))
            }
        }

        return result
    }

    private static func exportThumb(for moment: Moment, fileStore: FileStore, into dir: URL) -> String? {
        let sortedMedia = moment.mediaItems.sorted { $0.sortIndex < $1.sortIndex }
        guard let item = sortedMedia.first(where: { $0.thumbnailPath != nil || $0.mediaKind == .image }) else {
            return nil
        }

        let name = moment.id.uuidString + ".jpg"
        let destination = dir.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: destination.path) {
            return name
        }

        let relativePath = item.thumbnailPath ?? item.relativePath
        let sourceURL = fileStore.url(forRelativePath: relativePath)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 360
        ]
        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              let destinationRef = CGImageDestinationCreateWithURL(
                  destination as CFURL,
                  UTType.jpeg.identifier as CFString,
                  1,
                  nil
              )
        else {
            return nil
        }

        CGImageDestinationAddImage(
            destinationRef,
            thumbnail,
            [kCGImageDestinationLossyCompressionQuality: 0.72] as CFDictionary
        )
        guard CGImageDestinationFinalize(destinationRef) else { return nil }
        return name
    }

    private static func makeDimensionSnapshot(
        dimension: Dimension,
        profile: UserProfile,
        dimensionsByID: [String: Dimension],
        moments: [Moment],
        now: Date
    ) -> TimeBankWidgetDimensionSnapshot {
        let dimensionMoments = moments
            .filter { $0.dimensionId == dimension.id }
            .sorted { $0.happenedAt > $1.happenedAt }
        let lastMoment = dimensionMoments.first.flatMap { moment -> TimeBankWidgetLastMoment? in
            guard let title = moment.title?.trimmingCharacters(in: .whitespacesAndNewlines),
                  title.isEmpty == false
            else {
                return nil
            }
            return TimeBankWidgetLastMoment(title: title, happenedAt: moment.happenedAt)
        }

        let subtitleData = DimensionCompute.subtitleData(
            for: dimension,
            profile: profile,
            dimensionsByID: dimensionsByID,
            scope: .year,
            now: now
        )

        return TimeBankWidgetDimensionSnapshot(
            id: dimension.id,
            name: widgetDisplayName(for: dimension),
            iconKey: TimeBankIconography.dimensionIconSystemName(for: dimension),
            colorKey: dimension.colorKey,
            lifetimeConsumeHours: DimensionCompute.consumeHours(
                for: dimension,
                profile: profile,
                dimensionsByID: dimensionsByID,
                scope: .lifetime,
                now: now
            ),
            yearConsumeHours: DimensionCompute.consumeHours(
                for: dimension,
                profile: profile,
                dimensionsByID: dimensionsByID,
                scope: .year,
                now: now
            ),
            storedHours: DimensionCompute.storedHours(for: dimension.id, moments: moments),
            momentCount: DimensionCompute.storedMomentCount(for: dimension.id, moments: moments),
            subtitle: widgetSubtitle(from: subtitleData),
            lastMoment: lastMoment
        )
    }

    private static func visibleAccountDimensions(from dimensions: [Dimension]) -> [Dimension] {
        dimensions
            .filter { dimension in
                dimension.status == .visible
                    && (dimension.kind == .builtin || dimension.kind == .custom)
                    && dimension.mode == .normal
                    && dimension.name.hasPrefix("__") == false
            }
            .sorted { lhs, rhs in
                if lhs.sortIndex == rhs.sortIndex {
                    return lhs.name < rhs.name
                }
                return lhs.sortIndex < rhs.sortIndex
            }
    }

    private static func preferredWidgetDimensions(
        from dimensions: [Dimension],
        preferredIDs: [String]
    ) -> [Dimension] {
        let lookup = Dictionary(uniqueKeysWithValues: dimensions.map { ($0.id, $0) })
        let preferred = preferredIDs.compactMap { lookup[$0] }

        if preferred.isEmpty == false {
            let selectedIDs = Set(preferred.map(\.id))
            return preferred + dimensions.filter { selectedIDs.contains($0.id) == false }
        }

        let defaultPriority = [
            DimensionReservedID.parents.rawValue,
            DimensionReservedID.kids.rawValue,
            DimensionReservedID.partner.rawValue,
            DimensionReservedID.sport.rawValue,
            DimensionReservedID.create.rawValue,
            DimensionReservedID.free.rawValue
        ]

        let priority = Dictionary(uniqueKeysWithValues: defaultPriority.enumerated().map { ($0.element, $0.offset) })
        return dimensions.sorted { lhs, rhs in
            let lhsRank = priority[lhs.id] ?? Int.max
            let rhsRank = priority[rhs.id] ?? Int.max
            if lhsRank == rhsRank {
                return lhs.sortIndex < rhs.sortIndex
            }
            return lhsRank < rhsRank
        }
    }

    private static func totalStoredMomentCount(
        dimensions: [Dimension],
        moments: [Moment]
    ) -> Int {
        let includedIDs = Set(dimensions.map(\.id))
        return moments.filter { includedIDs.contains($0.dimensionId) }.count
    }

    private static func widgetDisplayName(for dimension: Dimension) -> String {
        switch dimension.id {
        case DimensionReservedID.parents.rawValue:
            return "父母"
        case DimensionReservedID.kids.rawValue:
            return "孩子"
        case DimensionReservedID.partner.rawValue:
            return "伴侣"
        default:
            return dimension.name
        }
    }

    private static func widgetSubtitle(from subtitle: DimensionCompute.DimensionSubtitle) -> String {
        switch subtitle {
        case .occurrence(let count, let noun):
            return "约 \(max(0, count)) 次\(noun)"
        case .weeklyHours(let hours):
            return "每周 \(shortNumber(hours))h"
        case .dailyHoursWith(let hours, _):
            return "每天 \(shortNumber(hours))h"
        case .percentOfAwake(let percent):
            return "清醒约 \(max(0, min(100, Int(percent.rounded()))))%"
        case .lifespan, .none:
            return ""
        }
    }

    private static func shortNumber(_ value: Double) -> String {
        let rounded = (max(0, value) * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return "\(Int(rounded))"
        }
        return String(format: "%.1f", rounded)
    }

    private static func topText(for tone: WidgetTone) -> String {
        switch tone {
        case .warm:
            return "把重要的时间放在眼前。"
        case .minimal:
            return "今年余额，慢慢使用。"
        case .poetic:
            return "这几周，也可以被好好存下。"
        }
    }
}
