// TimeBank/Features/Onboarding/Components/FrequencyUnit.swift

import Foundation

enum FrequencyUnit: CaseIterable, Hashable {
    case perWeek
    case perMonth
    case perYear

    var title: String {
        switch self {
        case .perWeek:
            return "每周"
        case .perMonth:
            return "每月"
        case .perYear:
            return "每年"
        }
    }

    private var annualMultiplier: Int {
        switch self {
        case .perWeek:
            return 52
        case .perMonth:
            return 12
        case .perYear:
            return 1
        }
    }

    func visitsPerYear(from value: Int) -> Int {
        max(1, value) * annualMultiplier
    }

    func value(fromVisitsPerYear visitsPerYear: Int) -> Int {
        max(1, Int((Double(max(1, visitsPerYear)) / Double(annualMultiplier)).rounded()))
    }
}
