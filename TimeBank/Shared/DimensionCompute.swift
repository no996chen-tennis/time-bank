// TimeBank/Shared/DimensionCompute.swift

import Foundation
import SwiftData

enum DimensionCompute {
    static let weeksPerYear = 52.1429
    static let daysPerYear = 365.25

    enum TimeBalanceScope: String, CaseIterable, Identifiable, Sendable {
        case lifetime
        case year

        var id: String { rawValue }

        var title: String {
            switch self {
            case .lifetime: return "今生"
            case .year: return "今年"
            }
        }
    }

    struct LifespanProjection: Sendable, Equatable {
        let remainingWeeks: Double
        let remainingYears: Double
        let remainingHoursK: Double
    }

    struct TotalAccount: Sendable, Equatable {
        let hours: Double
        let moments: Int
        let dimensionCount: Int
    }

    struct AccountTabAggregate: Sendable, Equatable {
        let totalHours: Double
        let totalMoments: Int
        let dimensionCount: Int
        let slices: [AccountTabSlice]
        let yearGroups: [AccountYearGroup]
    }

    struct AccountTabSlice: Identifiable, Sendable, Equatable {
        let dimensionID: String
        let name: String
        let colorKey: String
        let hours: Double
        let moments: Int
        let percent: Int
        let isOther: Bool
        let isMemorial: Bool

        var id: String { dimensionID }
    }

    struct AccountYearGroup: Identifiable, Sendable, Equatable {
        let year: Int
        let months: [AccountMonthGroup]

        var id: Int { year }
    }

    struct AccountMonthGroup: Identifiable, Sendable, Equatable {
        let year: Int
        let month: Int
        let hours: Double
        let moments: Int

        var id: String { "\(year)-\(month)" }
    }

    /// 时间账户卡片副文案的结构化结果（参考 PRD §22.3.1）。
    /// View 层根据 case 调对应 Formatter 接口（参考 PRD §21）。
    enum DimensionSubtitle: Sendable, Equatable {
        case occurrence(count: Int, noun: String)        // parents → Formatter.occurrenceCount
        case weeklyHours(Double)                          // kids / sport / create → Formatter.weeklyHours
        case dailyHoursWith(Double, action: String)       // partner → Formatter.dailyHoursWith
        case percentOfAwake(Double)                       // free → Formatter.percentOfAwake
        case lifespan(years: Double, hoursK: Double)      // lifespan → Formatter.lifespanSubtitle
        case none                                         // 系统隐藏账户 / memorial mode 等不展示
    }

    static func ageYears(birthday: Date, now: Date = .now) -> Double {
        let seconds = max(0, now.timeIntervalSince(birthday))
        return seconds / (daysPerYear * 24 * 60 * 60)
    }

    static func ageYears(fromBirthYear birthYear: Int, now: Date = .now) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        guard let birthdayApproximation = calendar.date(from: DateComponents(year: birthYear, month: 1, day: 1)) else {
            let currentYear = calendar.component(.year, from: now)
            return max(0, Double(currentYear - birthYear))
        }
        return ageYears(birthday: birthdayApproximation, now: now)
    }

    enum Lifespan {
        static func remainingWeeks(profile: UserProfile, now: Date = .now) -> Double {
            let age = DimensionCompute.ageYears(birthday: profile.birthday, now: now)
            return max(0, (Double(profile.expectedLifespanYears) - age) * DimensionCompute.weeksPerYear)
        }

        static func remainingYears(profile: UserProfile, now: Date = .now) -> Double {
            let age = DimensionCompute.ageYears(birthday: profile.birthday, now: now)
            return max(0, Double(profile.expectedLifespanYears) - age)
        }

        static func remainingHoursK(profile: UserProfile, now: Date = .now) -> Double {
            remainingYears(profile: profile, now: now) * DimensionCompute.daysPerYear * 24 / 1_000
        }
    }

    static func projection(
        profile: UserProfile,
        scope: TimeBalanceScope = .lifetime,
        now: Date = .now
    ) -> LifespanProjection {
        if scope == .year {
            let remainingYears = remainingCalendarYearsThisYear(now: now)
            return LifespanProjection(
                remainingWeeks: remainingYears * weeksPerYear,
                remainingYears: remainingYears,
                remainingHoursK: remainingYears * daysPerYear * 24 / 1_000
            )
        }

        return LifespanProjection(
            remainingWeeks: Lifespan.remainingWeeks(profile: profile, now: now),
            remainingYears: Lifespan.remainingYears(profile: profile, now: now),
            remainingHoursK: Lifespan.remainingHoursK(profile: profile, now: now)
        )
    }

    static func consumeHours(
        for dimension: Dimension,
        profile: UserProfile,
        dimensionsByID: [String: Dimension] = [:],
        scope: TimeBalanceScope = .lifetime,
        now: Date = .now
    ) -> Double {
        guard dimension.mode == .normal else { return 0 }

        switch dimension.id {
        case DimensionReservedID.lifespan.rawValue:
            return 0

        case DimensionReservedID.parents.rawValue:
            return parentsHours(profile: profile, scope: scope, now: now)

        case DimensionReservedID.kids.rawValue:
            return kidsHours(dimension: dimension, profile: profile, scope: scope, now: now)

        case DimensionReservedID.partner.rawValue:
            return partnerHours(profile: profile, scope: scope, now: now)

        case DimensionReservedID.sport.rawValue:
            return sportHours(dimension: dimension, profile: profile, scope: scope, now: now)

        case DimensionReservedID.create.rawValue:
            return createHours(dimension: dimension, profile: profile, scope: scope, now: now)

        case DimensionReservedID.free.rawValue:
            let awakeHoursPerDay = dimension.decodeParams(FreeDimensionParams.self, default: FreeDimensionParams()).awakeHoursPerDay
            let totalAwakeHours = remainingSelfYears(profile: profile, scope: scope, now: now) * daysPerYear * awakeHoursPerDay

            let parentsDimension = dimensionsByID[DimensionReservedID.parents.rawValue] ?? defaultDimension(id: .parents)
            let kidsDimension = dimensionsByID[DimensionReservedID.kids.rawValue] ?? defaultDimension(id: .kids)
            let partnerDimension = dimensionsByID[DimensionReservedID.partner.rawValue] ?? defaultDimension(id: .partner)
            let sportDimension = dimensionsByID[DimensionReservedID.sport.rawValue] ?? defaultDimension(id: .sport)
            let createDimension = dimensionsByID[DimensionReservedID.create.rawValue] ?? defaultDimension(id: .create)

            let consumed = consumeHours(for: parentsDimension, profile: profile, dimensionsByID: dimensionsByID, scope: scope, now: now)
                + consumeHours(for: kidsDimension, profile: profile, dimensionsByID: dimensionsByID, scope: scope, now: now)
                + consumeHours(for: partnerDimension, profile: profile, dimensionsByID: dimensionsByID, scope: scope, now: now)
                + consumeHours(for: sportDimension, profile: profile, dimensionsByID: dimensionsByID, scope: scope, now: now)
                + consumeHours(for: createDimension, profile: profile, dimensionsByID: dimensionsByID, scope: scope, now: now)

            return max(0, totalAwakeHours - consumed)

        default:
            if dimension.kind == .custom {
                return customHours(dimension: dimension, profile: profile, scope: scope, now: now)
            }
            return 0
        }
    }

    /// 时间账户卡片副文案（PRD §22.3.1 6 内置时间账户的消耗层显示文案）。
    /// memorial mode 或系统隐藏账户返回 `.none`，View 层不显示副文案。
    static func subtitleData(
        for dimension: Dimension,
        profile: UserProfile,
        dimensionsByID: [String: Dimension] = [:],
        scope: TimeBalanceScope = .lifetime,
        now: Date = .now
    ) -> DimensionSubtitle {
        guard dimension.mode == .normal else { return .none }

        switch dimension.id {
        case DimensionReservedID.lifespan.rawValue:
            let projection = projection(profile: profile, scope: scope, now: now)
            return .lifespan(
                years: projection.remainingYears,
                hoursK: projection.remainingHoursK
            )

        case DimensionReservedID.parents.rawValue:
            return .occurrence(count: parentsTotalMeetings(profile: profile, scope: scope, now: now), noun: "见面")

        case DimensionReservedID.kids.rawValue:
            return .weeklyHours(kidsCurrentHoursPerWeek(dimension: dimension, profile: profile, now: now))

        case DimensionReservedID.partner.rawValue:
            guard let partner = profile.partner, partner.deceased == false else { return .none }
            return .dailyHoursWith(max(0, partner.hoursPerDay), action: "共处")

        case DimensionReservedID.sport.rawValue:
            return .weeklyHours(sportCurrentHoursPerWeek(dimension: dimension, profile: profile, now: now))

        case DimensionReservedID.create.rawValue:
            return .weeklyHours(createCurrentHoursPerWeek(dimension: dimension, profile: profile, now: now))

        case DimensionReservedID.free.rawValue:
            return .percentOfAwake(freePercentOfAwake(
                profile: profile,
                dimensionsByID: dimensionsByID,
                scope: scope,
                now: now
            ))

        default:
            if dimension.kind == .custom {
                return customSubtitle(dimension: dimension)
            }
            return .none
        }
    }

    static func storedHours(for dimensionId: String, moments: [Moment]) -> Double {
        let totalSeconds = moments
            .filter { $0.dimensionId == dimensionId && $0.status == .normal }
            .reduce(0) { partial, moment in
                partial + (moment.durationSeconds ?? 0)
            }

        return Double(totalSeconds) / 3600.0
    }

    static func storedMomentCount(for dimensionId: String, moments: [Moment]) -> Int {
        moments.filter { $0.dimensionId == dimensionId && $0.status == .normal }.count
    }

    static func storedHours(for dimensionId: String, modelContext: ModelContext) throws -> Double {
        let moments = try modelContext.fetch(FetchDescriptor<Moment>())
        return storedHours(for: dimensionId, moments: moments)
    }

    static func storedMomentCount(for dimensionId: String, modelContext: ModelContext) throws -> Int {
        let moments = try modelContext.fetch(FetchDescriptor<Moment>())
        return storedMomentCount(for: dimensionId, moments: moments)
    }

    static func totalAccount(dimensions: [Dimension], moments: [Moment]) -> TotalAccount {
        let includedDimensions = dimensions.filter {
            $0.status != .deleted && ($0.kind == .builtin || $0.kind == .custom)
        }

        let totalHours = includedDimensions.reduce(0.0) { partial, dimension in
            partial + storedHours(for: dimension.id, moments: moments)
        }

        let totalMoments = includedDimensions.reduce(0) { partial, dimension in
            partial + storedMomentCount(for: dimension.id, moments: moments)
        }

        let dimensionCount = includedDimensions.reduce(0) { partial, dimension in
            let count = storedMomentCount(for: dimension.id, moments: moments)
            return partial + (count > 0 ? 1 : 0)
        }

        return TotalAccount(hours: totalHours, moments: totalMoments, dimensionCount: dimensionCount)
    }

    static func totalAccount(modelContext: ModelContext) throws -> TotalAccount {
        let dimensions = try modelContext.fetch(FetchDescriptor<Dimension>())
        let moments = try modelContext.fetch(FetchDescriptor<Moment>())
        return totalAccount(dimensions: dimensions, moments: moments)
    }

    static func accountTabAggregate(
        dimensions: [Dimension],
        moments: [Moment],
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> AccountTabAggregate {
        let includedDimensions = accountTabDimensions(from: dimensions)
        let includedDimensionIDs = Set(includedDimensions.map(\.id))
        let normalMoments = moments.filter {
            $0.status == .normal && includedDimensionIDs.contains($0.dimensionId)
        }

        let totalSeconds = normalMoments.reduce(0) { partial, moment in
            partial + (moment.durationSeconds ?? 0)
        }
        let totalHours = Double(totalSeconds) / 3600.0
        let totalMoments = normalMoments.count
        let activeDimensionIDs = Set(normalMoments.map(\.dimensionId))
        let usesHourWeight = totalSeconds > 0
        let totalWeight = usesHourWeight ? Double(totalSeconds) : Double(max(1, totalMoments))

        let slices = includedDimensions.compactMap { dimension -> AccountTabSlice? in
            let dimensionMoments = normalMoments.filter { $0.dimensionId == dimension.id }
            guard dimensionMoments.isEmpty == false else { return nil }

            let dimensionSeconds = dimensionMoments.reduce(0) { partial, moment in
                partial + (moment.durationSeconds ?? 0)
            }
            let weight = usesHourWeight ? Double(dimensionSeconds) : Double(dimensionMoments.count)
            let percent = Int((weight / totalWeight * 100).rounded())

            return AccountTabSlice(
                dimensionID: dimension.id,
                name: accountTabDisplayName(for: dimension),
                colorKey: dimension.colorKey,
                hours: Double(dimensionSeconds) / 3600.0,
                moments: dimensionMoments.count,
                percent: max(0, percent),
                isOther: dimension.id == DimensionReservedID.other.rawValue,
                isMemorial: dimension.mode == .memorial
            )
        }

        let monthBuckets = Dictionary(grouping: normalMoments) { moment -> String in
            let components = calendar.dateComponents([.year, .month], from: moment.happenedAt)
            return "\(components.year ?? 0)-\(components.month ?? 0)"
        }

        let monthGroups = monthBuckets.compactMap { _, bucket -> AccountMonthGroup? in
            guard let first = bucket.first else { return nil }
            let components = calendar.dateComponents([.year, .month], from: first.happenedAt)
            guard let year = components.year, let month = components.month else { return nil }
            let seconds = bucket.reduce(0) { partial, moment in
                partial + (moment.durationSeconds ?? 0)
            }
            return AccountMonthGroup(
                year: year,
                month: month,
                hours: Double(seconds) / 3600.0,
                moments: bucket.count
            )
        }

        let yearGroups = Dictionary(grouping: monthGroups, by: \.year)
            .map { year, months in
                AccountYearGroup(
                    year: year,
                    months: months.sorted { lhs, rhs in lhs.month > rhs.month }
                )
            }
            .sorted { lhs, rhs in lhs.year > rhs.year }

        return AccountTabAggregate(
            totalHours: totalHours,
            totalMoments: totalMoments,
            dimensionCount: activeDimensionIDs.count,
            slices: slices,
            yearGroups: yearGroups
        )
    }

    static func accountTabAggregate(modelContext: ModelContext) throws -> AccountTabAggregate {
        let dimensions = try modelContext.fetch(FetchDescriptor<Dimension>())
        let moments = try modelContext.fetch(FetchDescriptor<Moment>())
        return accountTabAggregate(dimensions: dimensions, moments: moments)
    }

    static func remainingCalendarYearsThisYear(now: Date = .now) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let nextYear = calendar.component(.year, from: now) + 1
        guard let nextYearStart = calendar.date(from: DateComponents(year: nextYear, month: 1, day: 1)) else {
            return 0
        }

        let seconds = max(0, nextYearStart.timeIntervalSince(now))
        return seconds / (daysPerYear * 24 * 60 * 60)
    }

    private static func remainingSelfYears(
        profile: UserProfile,
        scope: TimeBalanceScope,
        now: Date
    ) -> Double {
        let lifetimeYears = Lifespan.remainingYears(profile: profile, now: now)
        switch scope {
        case .lifetime:
            return lifetimeYears
        case .year:
            return min(lifetimeYears, remainingCalendarYearsThisYear(now: now))
        }
    }

    private static func scopedYears(
        _ years: Double,
        scope: TimeBalanceScope,
        now: Date
    ) -> Double {
        switch scope {
        case .lifetime:
            return max(0, years)
        case .year:
            return min(max(0, years), remainingCalendarYearsThisYear(now: now))
        }
    }

    private static func parentsHours(profile: UserProfile, scope: TimeBalanceScope, now: Date) -> Double {
        guard let parents = profile.parents else { return 0 }

        let livingParentAges = [parents.father, parents.mother]
            .compactMap { member -> Double? in
                guard let member, member.deceased == false else { return nil }
                return ageYears(fromBirthYear: member.birthYear, now: now)
            }

        guard livingParentAges.isEmpty == false else { return 0 }

        let representativeAge = livingParentAges.reduce(0, +) / Double(livingParentAges.count)
        let remainingYears = scopedYears(
            Double(parents.expectedLifespan) - representativeAge,
            scope: scope,
            now: now
        )
        return remainingYears * Double(max(0, parents.visitsPerYear)) * max(0, parents.hoursPerVisit)
    }

    private static func kidsHours(dimension: Dimension, profile: UserProfile, scope: TimeBalanceScope, now: Date) -> Double {
        let livingChildren = profile.children.filter { $0.deceased == false }
        guard livingChildren.isEmpty == false else { return 0 }

        let youngestAge = livingChildren
            .map { ageYears(fromBirthYear: $0.birthYear, now: now) }
            .min() ?? 0

        let params = dimension.decodeParams(KidsDimensionParams.self, default: KidsDimensionParams())
        return childQualityHours(
            fromCurrentAge: youngestAge,
            remainingYears: remainingSelfYears(profile: profile, scope: scope, now: now),
            weeklyHoursOverride: params.weeklyHoursOverride
        )
    }

    private static func partnerHours(profile: UserProfile, scope: TimeBalanceScope, now: Date) -> Double {
        guard let partner = profile.partner, partner.deceased == false else { return 0 }

        let selfRemainingYears = remainingSelfYears(profile: profile, scope: scope, now: now)
        let partnerAge = ageYears(fromBirthYear: partner.birthYear, now: now)
        let partnerRemainingYears = max(0, Double(profile.expectedLifespanYears) - partnerAge)
        let sharedYears = min(selfRemainingYears, partnerRemainingYears)

        return sharedYears * daysPerYear * max(0, partner.hoursPerDay)
    }

    private static func sportHours(dimension: Dimension, profile: UserProfile, scope: TimeBalanceScope, now: Date) -> Double {
        let params = dimension.decodeParams(SportDimensionParams.self, default: SportDimensionParams())
        let currentAge = ageYears(birthday: profile.birthday, now: now)
        let lifeEndAge = min(
            Double(profile.expectedLifespanYears),
            currentAge + remainingSelfYears(profile: profile, scope: scope, now: now)
        )

        return hoursAcrossAgeBands(
            startAge: currentAge,
            endAge: lifeEndAge,
            bands: [
                (lower: 0.0, upper: 50.0, hoursPerWeek: params.hoursPerWeekBefore50),
                (lower: 50.0, upper: 80.0, hoursPerWeek: params.hoursPerWeek50To80),
                (lower: 80.0, upper: Double.greatestFiniteMagnitude, hoursPerWeek: params.hoursPerWeekAfter80)
            ]
        )
    }

    private static func createHours(dimension: Dimension, profile: UserProfile, scope: TimeBalanceScope, now: Date) -> Double {
        let params = dimension.decodeParams(CreateDimensionParams.self, default: CreateDimensionParams())
        let currentAge = ageYears(birthday: profile.birthday, now: now)
        let endAge = min(
            Double(profile.expectedLifespanYears),
            currentAge + remainingSelfYears(profile: profile, scope: scope, now: now)
        )
        let focusedEndAge = Double(params.focusedPhaseEndAge)

        return hoursAcrossAgeBands(
            startAge: currentAge,
            endAge: endAge,
            bands: [
                (lower: 0.0, upper: focusedEndAge, hoursPerWeek: params.focusedPhaseHoursPerWeek),
                (lower: focusedEndAge, upper: Double.greatestFiniteMagnitude, hoursPerWeek: params.freePhaseHoursPerWeek)
            ]
        )
    }

    static func customHours(
        params: CustomDimensionParams,
        profile: UserProfile,
        scope: TimeBalanceScope = .lifetime,
        now: Date = .now
    ) -> Double {
        let remainingYears = remainingSelfYears(profile: profile, scope: scope, now: now)
        switch params.formula {
        case .weeklyHours:
            return remainingYears * weeksPerYear * max(0, params.weeklyHours)
        case .dailyHours:
            return remainingYears * daysPerYear * max(0, params.dailyHours)
        case .occurrenceBased:
            return remainingYears
                * Double(max(0, params.annualOccurrences))
                * max(0, params.hoursPerOccurrence)
        }
    }

    private static func customHours(dimension: Dimension, profile: UserProfile, scope: TimeBalanceScope, now: Date) -> Double {
        customHours(
            params: dimension.decodeParams(CustomDimensionParams.self, default: CustomDimensionParams()),
            profile: profile,
            scope: scope,
            now: now
        )
    }

    private static func customSubtitle(dimension: Dimension) -> DimensionSubtitle {
        let params = dimension.decodeParams(CustomDimensionParams.self, default: CustomDimensionParams())
        switch params.formula {
        case .weeklyHours:
            return .weeklyHours(max(0, params.weeklyHours))
        case .dailyHours:
            return .dailyHoursWith(max(0, params.dailyHours), action: "")
        case .occurrenceBased:
            return .occurrence(count: max(0, params.annualOccurrences), noun: "")
        }
    }

    private static func childQualityHours(
        fromCurrentAge age: Double,
        remainingYears: Double,
        weeklyHoursOverride: Double? = nil
    ) -> Double {
        let positiveAge = max(0, age)
        let cap = max(0, remainingYears)
        if let weeklyHoursOverride {
            return cap * weeksPerYear * max(0, weeklyHoursOverride)
        }

        if positiveAge >= 18 {
            return cap * weeksPerYear * 2
        }

        // 0-18 岁段：分年龄段累加，但不超过 self 剩余年数
        let yearsTo18 = min(cap, 18 - positiveAge)
        let beforeAdult = hoursAcrossAgeBands(
            startAge: positiveAge,
            endAge: positiveAge + yearsTo18,
            bands: [
                (lower: 0.0, upper: 6.0, hoursPerWeek: 30.0),
                (lower: 6.0, upper: 13.0, hoursPerWeek: 20.0),
                (lower: 13.0, upper: 18.0, hoursPerWeek: 10.0)
            ]
        )

        // 18+ 尾段：孩子成年后，剩余年按 2h/周
        let yearsAfterAdult = max(0, cap - yearsTo18)
        let afterAdult = yearsAfterAdult * weeksPerYear * 2

        return beforeAdult + afterAdult
    }

    private static func hoursAcrossAgeBands(
        startAge: Double,
        endAge: Double,
        bands: [(lower: Double, upper: Double, hoursPerWeek: Double)]
    ) -> Double {
        guard endAge > startAge else { return 0 }

        return bands.reduce(0.0) { partial, band in
            let overlapStart = max(startAge, band.lower)
            let overlapEnd = min(endAge, band.upper)
            guard overlapEnd > overlapStart else { return partial }

            let years = overlapEnd - overlapStart
            return partial + years * weeksPerYear * max(0, band.hoursPerWeek)
        }
    }

    // MARK: - 副文案数字 helpers（PRD §22.3.1）

    private static func parentsTotalMeetings(profile: UserProfile, scope: TimeBalanceScope, now: Date) -> Int {
        guard let parents = profile.parents else { return 0 }
        let livingParentAges = [parents.father, parents.mother]
            .compactMap { member -> Double? in
                guard let member, member.deceased == false else { return nil }
                return ageYears(fromBirthYear: member.birthYear, now: now)
            }
        guard livingParentAges.isEmpty == false else { return 0 }

        let representativeAge = livingParentAges.reduce(0, +) / Double(livingParentAges.count)
        let remainingYears = scopedYears(
            Double(parents.expectedLifespan) - representativeAge,
            scope: scope,
            now: now
        )
        return Int((remainingYears * Double(max(0, parents.visitsPerYear))).rounded())
    }

    private static func kidsCurrentHoursPerWeek(dimension: Dimension, profile: UserProfile, now: Date) -> Double {
        let livingChildren = profile.children.filter { $0.deceased == false }
        guard livingChildren.isEmpty == false else { return 0 }
        let params = dimension.decodeParams(KidsDimensionParams.self, default: KidsDimensionParams())
        if let override = params.weeklyHoursOverride {
            return max(0, override)
        }

        let youngestAge = livingChildren
            .map { ageYears(fromBirthYear: $0.birthYear, now: now) }
            .min() ?? 0

        switch youngestAge {
        case ..<6:    return 30
        case 6..<13:  return 20
        case 13..<18: return 10
        default:      return 2
        }
    }

    private static func sportCurrentHoursPerWeek(dimension: Dimension, profile: UserProfile, now: Date) -> Double {
        let params = dimension.decodeParams(SportDimensionParams.self, default: SportDimensionParams())
        let age = ageYears(birthday: profile.birthday, now: now)
        switch age {
        case ..<50:   return max(0, params.hoursPerWeekBefore50)
        case 50..<80: return max(0, params.hoursPerWeek50To80)
        default:      return max(0, params.hoursPerWeekAfter80)
        }
    }

    private static func createCurrentHoursPerWeek(dimension: Dimension, profile: UserProfile, now: Date) -> Double {
        let params = dimension.decodeParams(CreateDimensionParams.self, default: CreateDimensionParams())
        let age = ageYears(birthday: profile.birthday, now: now)
        return age < Double(params.focusedPhaseEndAge)
            ? max(0, params.focusedPhaseHoursPerWeek)
            : max(0, params.freePhaseHoursPerWeek)
    }

    /// free 占清醒时间百分比 = free.consumeHours / 剩余清醒时间总和 × 100
    /// 数学上 = 100 - 其他 5 账户占清醒时间的百分比之和
    private static func freePercentOfAwake(
        profile: UserProfile,
        dimensionsByID: [String: Dimension],
        scope: TimeBalanceScope,
        now: Date
    ) -> Double {
        let freeDimension = dimensionsByID[DimensionReservedID.free.rawValue] ?? defaultDimension(id: .free)
        let awakeHoursPerDay = freeDimension.decodeParams(FreeDimensionParams.self, default: FreeDimensionParams()).awakeHoursPerDay
        let totalAwakeHours = remainingSelfYears(profile: profile, scope: scope, now: now) * daysPerYear * max(0, awakeHoursPerDay)

        guard totalAwakeHours > 0 else { return 0 }

        let freeHours = consumeHours(
            for: freeDimension,
            profile: profile,
            dimensionsByID: dimensionsByID,
            scope: scope,
            now: now
        )
        return (freeHours / totalAwakeHours) * 100
    }

    private static func defaultDimension(id: DimensionReservedID) -> Dimension {
        switch id {
        case .sport:
            return Dimension(
                id: id.rawValue,
                name: "运动",
                kind: .builtin,
                status: .visible,
                mode: .normal,
                iconKey: "figure.run",
                colorKey: "sage",
                sortIndex: 4,
                params: Dimension.encodedParams(SportDimensionParams())
            )
        case .create:
            return Dimension(
                id: id.rawValue,
                name: "创造",
                kind: .builtin,
                status: .visible,
                mode: .normal,
                iconKey: "paintbrush",
                colorKey: "sky",
                sortIndex: 5,
                params: Dimension.encodedParams(CreateDimensionParams())
            )
        case .free:
            return Dimension(
                id: id.rawValue,
                name: "自由",
                kind: .builtin,
                status: .visible,
                mode: .normal,
                iconKey: "sun.max",
                colorKey: "peach",
                sortIndex: 6,
                params: Dimension.encodedParams(FreeDimensionParams())
            )
        case .parents:
            return Dimension(
                id: id.rawValue,
                name: "陪父母",
                kind: .builtin,
                status: .hidden,
                mode: .normal,
                iconKey: "heart",
                colorKey: "rose",
                sortIndex: 1,
                params: Dimension.encodedParams(EmptyDimensionParams())
            )
        case .kids:
            return Dimension(
                id: id.rawValue,
                name: "陪孩子",
                kind: .builtin,
                status: .hidden,
                mode: .normal,
                iconKey: "figure.2.and.child.holdinghands",
                colorKey: "warm",
                sortIndex: 2,
                params: Dimension.encodedParams(EmptyDimensionParams())
            )
        case .partner:
            return Dimension(
                id: id.rawValue,
                name: "陪伴侣",
                kind: .builtin,
                status: .hidden,
                mode: .normal,
                iconKey: "sparkles.heart",
                colorKey: "lavender",
                sortIndex: 3,
                params: Dimension.encodedParams(EmptyDimensionParams())
            )
        default:
            return Dimension(
                id: id.rawValue,
                name: id.rawValue,
                kind: .systemHidden,
                status: .hidden,
                mode: .normal,
                iconKey: "circle",
                colorKey: "rose",
                sortIndex: 99,
                params: Dimension.encodedParams(EmptyDimensionParams())
            )
        }
    }

    private static func accountTabDimensions(from dimensions: [Dimension]) -> [Dimension] {
        dimensions
            .filter { dimension in
                guard dimension.status != .deleted else { return false }
                if dimension.id == DimensionReservedID.other.rawValue {
                    return true
                }
                guard dimension.id != DimensionReservedID.lifespan.rawValue,
                      dimension.id != DimensionReservedID.daily.rawValue,
                      dimension.name.hasPrefix("__") == false else {
                    return false
                }
                return dimension.status == .visible
                    && (dimension.kind == .builtin || dimension.kind == .custom)
            }
            .sorted { lhs, rhs in
                if lhs.sortIndex == rhs.sortIndex {
                    return lhs.name < rhs.name
                }
                return lhs.sortIndex < rhs.sortIndex
            }
    }

    private static func accountTabDisplayName(for dimension: Dimension) -> String {
        if dimension.id == DimensionReservedID.other.rawValue {
            return "其他"
        }
        return dimension.name
    }
}
