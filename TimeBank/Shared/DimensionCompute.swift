// TimeBank/Shared/DimensionCompute.swift

import Foundation
import SwiftData

enum DimensionCompute {
    static let weeksPerYear = 52.1429
    static let daysPerYear = 365.25

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
        let currentYear = Calendar(identifier: .gregorian).component(.year, from: now)
        return max(0, Double(currentYear - birthYear))
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

    static func projection(profile: UserProfile, now: Date = .now) -> LifespanProjection {
        LifespanProjection(
            remainingWeeks: Lifespan.remainingWeeks(profile: profile, now: now),
            remainingYears: Lifespan.remainingYears(profile: profile, now: now),
            remainingHoursK: Lifespan.remainingHoursK(profile: profile, now: now)
        )
    }

    static func consumeHours(
        for dimension: Dimension,
        profile: UserProfile,
        dimensionsByID: [String: Dimension] = [:],
        now: Date = .now
    ) -> Double {
        guard dimension.mode == .normal else { return 0 }

        switch dimension.id {
        case DimensionReservedID.lifespan.rawValue:
            return 0

        case DimensionReservedID.parents.rawValue:
            return parentsHours(profile: profile, now: now)

        case DimensionReservedID.kids.rawValue:
            return kidsHours(dimension: dimension, profile: profile, now: now)

        case DimensionReservedID.partner.rawValue:
            return partnerHours(profile: profile, now: now)

        case DimensionReservedID.sport.rawValue:
            return sportHours(dimension: dimension, profile: profile, now: now)

        case DimensionReservedID.create.rawValue:
            return createHours(dimension: dimension, profile: profile, now: now)

        case DimensionReservedID.free.rawValue:
            let awakeHoursPerDay = dimension.decodeParams(FreeDimensionParams.self, default: FreeDimensionParams()).awakeHoursPerDay
            let totalAwakeHours = Lifespan.remainingYears(profile: profile, now: now) * daysPerYear * awakeHoursPerDay

            let parentsDimension = dimensionsByID[DimensionReservedID.parents.rawValue] ?? defaultDimension(id: .parents)
            let kidsDimension = dimensionsByID[DimensionReservedID.kids.rawValue] ?? defaultDimension(id: .kids)
            let partnerDimension = dimensionsByID[DimensionReservedID.partner.rawValue] ?? defaultDimension(id: .partner)
            let sportDimension = dimensionsByID[DimensionReservedID.sport.rawValue] ?? defaultDimension(id: .sport)
            let createDimension = dimensionsByID[DimensionReservedID.create.rawValue] ?? defaultDimension(id: .create)

            let consumed = consumeHours(for: parentsDimension, profile: profile, dimensionsByID: dimensionsByID, now: now)
                + consumeHours(for: kidsDimension, profile: profile, dimensionsByID: dimensionsByID, now: now)
                + consumeHours(for: partnerDimension, profile: profile, dimensionsByID: dimensionsByID, now: now)
                + consumeHours(for: sportDimension, profile: profile, dimensionsByID: dimensionsByID, now: now)
                + consumeHours(for: createDimension, profile: profile, dimensionsByID: dimensionsByID, now: now)

            return max(0, totalAwakeHours - consumed)

        default:
            return 0
        }
    }

    /// 时间账户卡片副文案（PRD §22.3.1 6 内置时间账户的消耗层显示文案）。
    /// memorial mode 或系统隐藏账户返回 `.none`，View 层不显示副文案。
    static func subtitleData(
        for dimension: Dimension,
        profile: UserProfile,
        dimensionsByID: [String: Dimension] = [:],
        now: Date = .now
    ) -> DimensionSubtitle {
        guard dimension.mode == .normal else { return .none }

        switch dimension.id {
        case DimensionReservedID.lifespan.rawValue:
            return .lifespan(
                years: Lifespan.remainingYears(profile: profile, now: now),
                hoursK: Lifespan.remainingHoursK(profile: profile, now: now)
            )

        case DimensionReservedID.parents.rawValue:
            return .occurrence(count: parentsTotalMeetings(profile: profile, now: now), noun: "见面")

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
                now: now
            ))

        default:
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

    private static func parentsHours(profile: UserProfile, now: Date) -> Double {
        guard let parents = profile.parents else { return 0 }

        let livingParentAges = [parents.father, parents.mother]
            .compactMap { member -> Double? in
                guard let member, member.deceased == false else { return nil }
                return ageYears(fromBirthYear: member.birthYear, now: now)
            }

        guard livingParentAges.isEmpty == false else { return 0 }

        let representativeAge = livingParentAges.reduce(0, +) / Double(livingParentAges.count)
        let remainingYears = max(0, Double(parents.expectedLifespan) - representativeAge)
        return remainingYears * Double(max(0, parents.visitsPerYear)) * max(0, parents.hoursPerVisit)
    }

    private static func kidsHours(dimension: Dimension, profile: UserProfile, now: Date) -> Double {
        let livingChildren = profile.children.filter { $0.deceased == false }
        guard livingChildren.isEmpty == false else { return 0 }

        let youngestAge = livingChildren
            .map { ageYears(fromBirthYear: $0.birthYear, now: now) }
            .min() ?? 0

        let params = dimension.decodeParams(KidsDimensionParams.self, default: KidsDimensionParams())
        return childQualityHours(
            fromCurrentAge: youngestAge,
            remainingYears: Lifespan.remainingYears(profile: profile, now: now),
            weeklyHoursOverride: params.weeklyHoursOverride
        )
    }

    private static func partnerHours(profile: UserProfile, now: Date) -> Double {
        guard let partner = profile.partner, partner.deceased == false else { return 0 }

        let selfRemainingYears = Lifespan.remainingYears(profile: profile, now: now)
        let partnerAge = ageYears(fromBirthYear: partner.birthYear, now: now)
        let partnerRemainingYears = max(0, Double(profile.expectedLifespanYears) - partnerAge)
        let sharedYears = min(selfRemainingYears, partnerRemainingYears)

        return sharedYears * daysPerYear * max(0, partner.hoursPerDay)
    }

    private static func sportHours(dimension: Dimension, profile: UserProfile, now: Date) -> Double {
        let params = dimension.decodeParams(SportDimensionParams.self, default: SportDimensionParams())
        let currentAge = ageYears(birthday: profile.birthday, now: now)
        let lifeEndAge = Double(profile.expectedLifespanYears)

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

    private static func createHours(dimension: Dimension, profile: UserProfile, now: Date) -> Double {
        let params = dimension.decodeParams(CreateDimensionParams.self, default: CreateDimensionParams())
        let currentAge = ageYears(birthday: profile.birthday, now: now)
        let focusedEndAge = Double(params.focusedPhaseEndAge)

        if currentAge < focusedEndAge {
            return max(0, focusedEndAge - currentAge) * weeksPerYear * max(0, params.focusedPhaseHoursPerWeek)
        }

        return Lifespan.remainingYears(profile: profile, now: now) * weeksPerYear * max(0, params.freePhaseHoursPerWeek)
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

    private static func parentsTotalMeetings(profile: UserProfile, now: Date) -> Int {
        guard let parents = profile.parents else { return 0 }
        let livingParentAges = [parents.father, parents.mother]
            .compactMap { member -> Double? in
                guard let member, member.deceased == false else { return nil }
                return ageYears(fromBirthYear: member.birthYear, now: now)
            }
        guard livingParentAges.isEmpty == false else { return 0 }

        let representativeAge = livingParentAges.reduce(0, +) / Double(livingParentAges.count)
        let remainingYears = max(0, Double(parents.expectedLifespan) - representativeAge)
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
        now: Date
    ) -> Double {
        let freeDimension = dimensionsByID[DimensionReservedID.free.rawValue] ?? defaultDimension(id: .free)
        let awakeHoursPerDay = freeDimension.decodeParams(FreeDimensionParams.self, default: FreeDimensionParams()).awakeHoursPerDay
        let totalAwakeHours = Lifespan.remainingYears(profile: profile, now: now) * daysPerYear * max(0, awakeHoursPerDay)

        guard totalAwakeHours > 0 else { return 0 }

        let freeHours = consumeHours(
            for: freeDimension,
            profile: profile,
            dimensionsByID: dimensionsByID,
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
}
