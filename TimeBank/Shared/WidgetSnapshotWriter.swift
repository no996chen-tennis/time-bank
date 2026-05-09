import Foundation
import SwiftData
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
            dimensions: dimensionSnapshots
        )
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
