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

        // 缩略图导出：先算记忆与 top 分类各自要导出的图，收集"要保留的文件名"，
        // 最后统一清理一次共享目录（记忆图 cat 图互不误删）。
        let thumbsDir = TimeBankWidgetSnapshotStore.thumbsDirectoryURL()
        let fileStore = FileStore()
        var keptThumbNames = Set<String>()

        let memories = widgetMemories(
            moments: normalMoments,
            dimensionsByID: dimensionsByID,
            now: now,
            thumbsDir: thumbsDir,
            fileStore: fileStore,
            keptThumbNames: &keptThumbNames
        )

        let topCategories = widgetTopCategories(
            visibleDimensions: visibleDimensions,
            profile: profile,
            dimensionsByID: dimensionsByID,
            moments: normalMoments,
            now: now,
            thumbsDir: thumbsDir,
            fileStore: fileStore,
            keptThumbNames: &keptThumbNames
        )

        pruneThumbs(in: thumbsDir, keeping: keptThumbNames)

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
            memories: memories,
            themeKind: TimeBankThemeKind.persisted.rawValue,
            dailyRoutine: .default,
            topCategories: topCategories
        )
    }

    /// 用户存入最多的 top 分类：按【normal 状态 Moment 数量】降序，取前 3；无带图瞬间的分类也保留（thumbFiles 为空）。
    /// 与首页维度卡同源：仅"可见账户维度"参与，"今年余额"文案复用 DimensionCompute .year scope + Formatter.hoursCompact。
    private static func widgetTopCategories(
        visibleDimensions: [Dimension],
        profile: UserProfile,
        dimensionsByID: [String: Dimension],
        moments: [Moment],
        now: Date,
        thumbsDir: URL?,
        fileStore: FileStore,
        keptThumbNames: inout Set<String>
    ) -> [TimeBankWidgetTopCategory] {
        // 排名 = "存得最多优先"：按每个维度的 storedMomentCount（存入的 normal 瞬间数）降序，取前 3；
        // 同数按 sortIndex 升序，稳定可预期（不随机、不会每次刷新换一批维度）。
        let ranked = visibleDimensions
            .map { dimension -> (dimension: Dimension, count: Int) in
                (dimension, DimensionCompute.storedMomentCount(for: dimension.id, moments: moments))
            }
            .filter { $0.count > 0 }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count { return lhs.dimension.sortIndex < rhs.dimension.sortIndex }
                return lhs.count > rhs.count
            }
            .prefix(6) // 取存入量前 6 的维度进"跨维度轮换池"，让各维度的瞬间都能轮流在 widget 露脸

        return ranked.map { entry -> TimeBankWidgetTopCategory in
            let dimension = entry.dimension
            let exported = exportCategoryThumbs(
                for: dimension,
                moments: moments,
                fileStore: fileStore,
                into: thumbsDir,
                keptThumbNames: &keptThumbNames
            )
            return TimeBankWidgetTopCategory(
                name: widgetDisplayName(for: dimension),
                colorKey: dimension.colorKey,
                yearRemainingText: yearRemainingText(
                    for: dimension,
                    profile: profile,
                    dimensionsByID: dimensionsByID,
                    now: now
                ),
                thumbFiles: exported.files,
                thumbTitles: exported.titles
            )
        }
    }

    /// "今年余额"文案，与首页维度卡 DimensionCardView.consumeSummary 的消耗层主文案完全一致：
    /// "<还能共度/未来> <Formatter.hoursCompact(今年 consumeHours)>"，如"还能共度 1,180 小时"。
    private static func yearRemainingText(
        for dimension: Dimension,
        profile: UserProfile,
        dimensionsByID: [String: Dimension],
        now: Date
    ) -> String {
        let hours = DimensionCompute.consumeHours(
            for: dimension,
            profile: profile,
            dimensionsByID: dimensionsByID,
            scope: .year,
            now: now
        )
        return "\(consumeLabel(for: dimension)) \(Formatter.hoursCompact(hours))"
    }

    /// 消耗层前缀标签，复用 DimensionCardView.consumeLabel 的分类归属。
    private static func consumeLabel(for dimension: Dimension) -> String {
        switch dimension.id {
        case DimensionReservedID.parents.rawValue,
             DimensionReservedID.kids.rawValue,
             DimensionReservedID.partner.rawValue:
            return "还能共度"
        case DimensionReservedID.sport.rawValue,
             DimensionReservedID.create.rawValue,
             DimensionReservedID.free.rawValue:
            return "未来"
        default:
            return "还能共度"
        }
    }

    /// 每个分类最多导出的缩略图张数。给 widget 轮换更多素材、减少"总看到重复那几张"。
    /// 上限从 4→10：一分钟换一张时，10 张可让循环周期拉到 10 分钟才回到第一张。
    private static let maxCategoryThumbs = 4

    /// 导出某分类最近【最多 maxCategoryThumbs 张】带图瞬间的首图缩略图到共享目录（最近优先）。
    /// 文件名 "cat-<dimId>-<i>.jpg"，与记忆缩略图（<momentUUID>.jpg）前缀隔离、绝不冲突。
    /// 返回 files 与 titles 两个【一一对应】的平行数组：每成功导出一张图，就同时收集该瞬间的标题
    ///（去空白；为空则用兜底 categoryThumbFallbackTitle），保证 files.count == titles.count，
    /// 供中号 widget 用同一下标取"文件名 + 对应标题"叠加标题遮罩。跳过（无图/导出失败）的瞬间两边都不追加。
    private static func exportCategoryThumbs(
        for dimension: Dimension,
        moments: [Moment],
        fileStore: FileStore,
        into dir: URL?,
        keptThumbNames: inout Set<String>
    ) -> (files: [String], titles: [String]) {
        guard let dir else { return ([], []) }

        let dimensionMoments = moments
            .filter { $0.dimensionId == dimension.id }
            .sorted { $0.happenedAt > $1.happenedAt }

        var files: [String] = []
        var titles: [String] = []
        for moment in dimensionMoments {
            guard files.count < maxCategoryThumbs else { break }
            let name = "cat-\(dimension.id)-\(files.count).jpg"
            guard exportCategoryThumb(for: moment, fileStore: fileStore, into: dir, named: name) != nil else {
                continue
            }
            files.append(name)
            titles.append(categoryThumbFallbackTitle(for: moment, dimension: dimension))
            keptThumbNames.insert(name)
        }
        return (files, titles)
    }

    /// 该缩略图叠加用的标题：优先瞬间自己的标题（去首尾空白）；瞬间没写标题时，
    /// 用该分类的展示名兜底（如"父母""运动"），既不留空遮罩也不暴露隐私细节。
    private static func categoryThumbFallbackTitle(for moment: Moment, dimension: Dimension) -> String {
        let trimmed = moment.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty == false { return trimmed }
        return widgetDisplayName(for: dimension)
    }

    /// 为 widget 轮换面挑选记忆池：周年（那年今日）优先 → 刚冲洗优先 → 最近优先，取前 6。
    private static func widgetMemories(
        moments: [Moment],
        dimensionsByID: [String: Dimension],
        now: Date,
        thumbsDir: URL?,
        fileStore: FileStore,
        keptThumbNames: inout Set<String>
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

        return attachThumbs(
            to: Array(sorted.prefix(6)),
            thumbsDir: thumbsDir,
            fileStore: fileStore,
            keptThumbNames: &keptThumbNames
        )
    }

    /// 把入选记忆的缩略图导出到 App Group 共享目录（widget 进程读不到 App 沙盒里的媒体）。
    /// 任何一步失败都静默降级为无图——缩略图绝不能阻塞快照写入。
    /// 只导出并登记要保留的文件名；清理由调用方统一 pruneThumbs（避免和 top 分类图互相误删）。
    private static func attachThumbs(
        to entries: [(memory: TimeBankWidgetMemory, moment: Moment)],
        thumbsDir: URL?,
        fileStore: FileStore,
        keptThumbNames: inout Set<String>
    ) -> [TimeBankWidgetMemory] {
        guard let dir = thumbsDir else {
            return entries.map(\.memory)
        }

        return entries.map { entry -> TimeBankWidgetMemory in
            var memory = entry.memory
            if let name = exportThumb(for: entry.moment, fileStore: fileStore, into: dir) {
                memory.thumbFile = name
                keptThumbNames.insert(name)
            }
            return memory
        }
    }

    /// 统一清理共享缩略图目录：删掉本次快照不再引用的旧图（记忆图 <momentUUID>.jpg + top 分类图 cat-*.jpg）。
    /// keptNames 里已登记本次实际引用到的全部文件（含每类最多 maxCategoryThumbs 张），
    /// 故只删"没引用到的"——既不会误删本次要用的图，也不会无限增长：
    /// 目录总量恒定在 ≤6 记忆图 + ≤3×maxCategoryThumbs 分类图。
    /// 分类图变少（如某维度删了瞬间）时，多出来的旧 cat-*-<i>.jpg 因不在 keptNames 里被顺带清掉。
    private static func pruneThumbs(in dir: URL?, keeping keptNames: Set<String>) {
        guard let dir else { return }
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return }
        for file in files where keptNames.contains(file) == false {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(file))
        }
    }

    /// 导出某分类首图缩略图到指定文件名（覆盖式：分类图按位次固定名 cat-<dimId>-<i>.jpg，
    /// 内容随最近瞬间变化，须强制重写；沿用与记忆图一致的 CGImageSource 480px 方案）。
    private static func exportCategoryThumb(
        for moment: Moment,
        fileStore: FileStore,
        into dir: URL,
        named name: String
    ) -> String? {
        let sortedMedia = moment.mediaItems.sorted { $0.sortIndex < $1.sortIndex }
        guard let item = sortedMedia.first(where: { $0.thumbnailPath != nil || $0.mediaKind == .image }) else {
            return nil
        }

        let destination = dir.appendingPathComponent(name)
        // 位次坑：内容会随最近瞬间变，先清旧内容再写。
        try? FileManager.default.removeItem(at: destination)
        // 高清：图片直接从原图降采样（不用 200px 小缩略图，否则放大发糊）；视频只能用已生成的帧缩略图。
        let sourcePath = item.mediaKind == .image ? item.relativePath : (item.thumbnailPath ?? item.relativePath)
        let sourceURL = fileStore.url(forRelativePath: sourcePath)
        guard writeThumbnail(from: sourceURL, to: destination) else { return nil }
        return name
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

        // 高清：图片直接从原图降采样（不用 200px 小缩略图，否则放大发糊）；视频只能用已生成的帧缩略图。
        let sourcePath = item.mediaKind == .image ? item.relativePath : (item.thumbnailPath ?? item.relativePath)
        let sourceURL = fileStore.url(forRelativePath: sourcePath)
        guard writeThumbnail(from: sourceURL, to: destination) else { return nil }
        return name
    }

    /// 共享缩略图渲染：CGImageSource 生成 480px 缩略图写成 JPEG。记忆图与分类图共用，保证 480px 方案一致。
    private static func writeThumbnail(from sourceURL: URL, to destination: URL) -> Bool {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 800
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
            return false
        }

        CGImageDestinationAddImage(
            destinationRef,
            thumbnail,
            [kCGImageDestinationLossyCompressionQuality: 0.72] as CFDictionary
        )
        return CGImageDestinationFinalize(destinationRef)
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
