// TimeBank/Models/DimensionParams.swift

import Foundation

struct EmptyDimensionParams: Sendable, Equatable {
    init() {}
}

nonisolated extension EmptyDimensionParams: Codable {}

struct SportDimensionParams: Sendable, Equatable {
    var hoursPerWeekBefore50: Double
    var hoursPerWeek50To80: Double
    var hoursPerWeekAfter80: Double
    var sessionsPerWeek: Int
    var hoursPerSession: Double

    nonisolated init(
        hoursPerWeekBefore50: Double = 5,
        hoursPerWeek50To80: Double = 3,
        hoursPerWeekAfter80: Double = 1,
        sessionsPerWeek: Int = 5,
        hoursPerSession: Double = 1
    ) {
        self.hoursPerWeekBefore50 = hoursPerWeekBefore50
        self.hoursPerWeek50To80 = hoursPerWeek50To80
        self.hoursPerWeekAfter80 = hoursPerWeekAfter80
        self.sessionsPerWeek = sessionsPerWeek
        self.hoursPerSession = hoursPerSession
    }
}

nonisolated extension SportDimensionParams: Codable {
    private enum CodingKeys: String, CodingKey {
        case hoursPerWeekBefore50
        case hoursPerWeek50To80
        case hoursPerWeekAfter80
        case sessionsPerWeek
        case hoursPerSession
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            hoursPerWeekBefore50: try container.decodeIfPresent(Double.self, forKey: .hoursPerWeekBefore50) ?? 5,
            hoursPerWeek50To80: try container.decodeIfPresent(Double.self, forKey: .hoursPerWeek50To80) ?? 3,
            hoursPerWeekAfter80: try container.decodeIfPresent(Double.self, forKey: .hoursPerWeekAfter80) ?? 1,
            sessionsPerWeek: try container.decodeIfPresent(Int.self, forKey: .sessionsPerWeek) ?? 5,
            hoursPerSession: try container.decodeIfPresent(Double.self, forKey: .hoursPerSession) ?? 1
        )
    }
}

struct KidsDimensionParams: Sendable, Equatable {
    var weeklyHoursOverride: Double?

    nonisolated init(weeklyHoursOverride: Double? = nil) {
        self.weeklyHoursOverride = weeklyHoursOverride
    }
}

nonisolated extension KidsDimensionParams: Codable {}

struct CreateDimensionParams: Sendable, Equatable {
    var focusedPhaseEndAge: Int
    var focusedPhaseHoursPerWeek: Double
    var freePhaseHoursPerWeek: Double

    init(
        focusedPhaseEndAge: Int = 65,
        focusedPhaseHoursPerWeek: Double = 40,
        freePhaseHoursPerWeek: Double = 20
    ) {
        self.focusedPhaseEndAge = focusedPhaseEndAge
        self.focusedPhaseHoursPerWeek = focusedPhaseHoursPerWeek
        self.freePhaseHoursPerWeek = freePhaseHoursPerWeek
    }
}

nonisolated extension CreateDimensionParams: Codable {}

struct FreeDimensionParams: Sendable, Equatable {
    var awakeHoursPerDay: Double

    init(awakeHoursPerDay: Double = 14) {
        self.awakeHoursPerDay = awakeHoursPerDay
    }
}

nonisolated extension FreeDimensionParams: Codable {}
