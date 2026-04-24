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

    init(
        hoursPerWeekBefore50: Double = 5,
        hoursPerWeek50To80: Double = 3,
        hoursPerWeekAfter80: Double = 1
    ) {
        self.hoursPerWeekBefore50 = hoursPerWeekBefore50
        self.hoursPerWeek50To80 = hoursPerWeek50To80
        self.hoursPerWeekAfter80 = hoursPerWeekAfter80
    }
}

nonisolated extension SportDimensionParams: Codable {}

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
