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
            return kidsHours(profile: profile, now: now)

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

    private static func kidsHours(profile: UserProfile, now: Date) -> Double {
        let livingChildren = profile.children.filter { $0.deceased == false }
        guard livingChildren.isEmpty == false else { return 0 }

        let youngestAge = livingChildren
            .map { ageYears(fromBirthYear: $0.birthYear, now: now) }
            .min() ?? 0

        return childQualityHours(fromCurrentAge: youngestAge, remainingYears: Lifespan.remainingYears(profile: profile, now: now))
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

    private static func childQualityHours(fromCurrentAge age: Double, remainingYears: Double) -> Double {
        if age >= 18 {
            return max(0, remainingYears) * weeksPerYear * 2
        }

        return hoursAcrossAgeBands(
            startAge: max(0, age),
            endAge: 18,
            bands: [
                (lower: 0.0, upper: 6.0, hoursPerWeek: 30.0),
                (lower: 6.0, upper: 13.0, hoursPerWeek: 20.0),
                (lower: 13.0, upper: 18.0, hoursPerWeek: 10.0)
            ]
        )
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
