// TimeBank/Features/SettingsUI/DimensionManager/DimensionEditorDraft.swift

import Foundation
import SwiftData
import SwiftUI

enum DimensionEditorRoute: Identifiable, Equatable {
    case create
    case edit(String)

    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let dimensionID):
            return "edit-\(dimensionID)"
        }
    }
}

struct DimensionColorPreset: Identifiable, Equatable {
    let key: String
    let name: String
    let color: Color

    var id: String { key }
}

enum CustomDimensionAccount {
    static let maxCustomCount = 10
    static let maxNameCount = 12

    static let iconOptions = [
        "book.fill", "pencil.tip", "graduationcap.fill",
        "paintbrush.pointed.fill", "music.note", "camera.fill",
        "cup.and.saucer.fill", "fork.knife", "bed.double.fill",
        "airplane", "figure.walk", "bicycle",
        "person.2.fill", "dog.fill", "star.fill", "heart.fill"
    ]

    static let colorOptions: [DimensionColorPreset] = [
        DimensionColorPreset(key: "rose", name: "珊瑚橘", color: .tbDimParents),
        DimensionColorPreset(key: "warm", name: "金黄", color: .tbDimKids),
        DimensionColorPreset(key: "lavender", name: "薰衣草", color: .tbDimPartner),
        DimensionColorPreset(key: "sky", name: "晨雾蓝", color: .tbDimCreate),
        DimensionColorPreset(key: "sage", name: "薄荷绿", color: .tbDimSport),
        DimensionColorPreset(key: "peach", name: "蜜桃", color: .tbDimFree),
        DimensionColorPreset(key: "coral", name: "珊瑚", color: .tbDimCoral),
        DimensionColorPreset(key: "mint", name: "薄荷", color: .tbDimMint),
        DimensionColorPreset(key: "denim", name: "丹宁", color: .tbDimDenim),
        DimensionColorPreset(key: "mauve", name: "灰紫", color: .tbDimMauve)
    ]

    static func customCount(in dimensions: [Dimension]) -> Int {
        dimensions.filter { $0.kind == .custom && $0.status == .visible }.count
    }

    static func canCreateCustomDimension(in dimensions: [Dimension]) -> Bool {
        customCount(in: dimensions) < maxCustomCount
    }

    static func nextSortIndex(in dimensions: [Dimension]) -> Int {
        let maxSortIndex = dimensions
            .filter { $0.kind == .builtin || $0.kind == .custom }
            .map(\.sortIndex)
            .max() ?? 0
        return maxSortIndex + 1
    }

    static func persistSortOrder(
        orderedIDs: [String],
        dimensions: [Dimension],
        modelContext: ModelContext
    ) throws {
        let lookup = Dictionary(uniqueKeysWithValues: dimensions.map { ($0.id, $0) })
        for (index, id) in orderedIDs.enumerated() {
            guard let dimension = lookup[id] else { continue }
            dimension.sortIndex = index + 1
            dimension.updatedAt = .now
        }
        try modelContext.save()
    }

    static func visibleAccountDimensions(from dimensions: [Dimension]) -> [Dimension] {
        dimensions
            .filter { dimension in
                dimension.status == .visible
                    && (dimension.kind == .builtin || dimension.kind == .custom)
                    && dimension.name.hasPrefix("__") == false
            }
            .sorted { lhs, rhs in
                if lhs.sortIndex == rhs.sortIndex {
                    return lhs.name < rhs.name
                }
                return lhs.sortIndex < rhs.sortIndex
            }
    }

    static func managerDimensions(from dimensions: [Dimension]) -> [Dimension] {
        dimensions
            .filter { dimension in
                guard dimension.name.hasPrefix("__") == false else { return false }
                switch dimension.kind {
                case .builtin:
                    return dimension.status != .deleted
                case .custom:
                    return dimension.status == .visible
                case .systemTop, .systemHidden, .systemVirtual:
                    return false
                }
            }
            .sorted { lhs, rhs in
                if lhs.sortIndex == rhs.sortIndex {
                    return lhs.name < rhs.name
                }
                return lhs.sortIndex < rhs.sortIndex
            }
    }

    static func formulaSummary(_ params: CustomDimensionParams) -> String {
        DimensionDetailCopy.customFormulaSummary(params)
    }

    static func previewHours(params: CustomDimensionParams, profile: UserProfile) -> Double {
        DimensionCompute.customHours(params: params, profile: profile)
    }

    static func limitedName(_ rawName: String) -> String {
        String(rawName.prefix(maxNameCount))
    }
}

struct DimensionEditorDraft: Equatable {
    var name: String
    var iconKey: String
    var colorKey: String
    var formula: CustomFormula
    var weeklyHours: Double
    var dailyHours: Double
    var annualOccurrences: Int
    var hoursPerOccurrence: Double

    init(
        name: String = "",
        iconKey: String = "book.fill",
        colorKey: String = "mint",
        formula: CustomFormula = .weeklyHours,
        weeklyHours: Double = 5,
        dailyHours: Double = 1,
        annualOccurrences: Int = 12,
        hoursPerOccurrence: Double = 2
    ) {
        self.name = name
        self.iconKey = iconKey
        self.colorKey = colorKey
        self.formula = formula
        self.weeklyHours = weeklyHours
        self.dailyHours = dailyHours
        self.annualOccurrences = annualOccurrences
        self.hoursPerOccurrence = hoursPerOccurrence
    }

    init(dimension: Dimension) {
        let params = dimension.decodeParams(CustomDimensionParams.self, default: CustomDimensionParams())
        self.init(
            name: dimension.name,
            iconKey: dimension.iconKey,
            colorKey: dimension.colorKey,
            formula: params.formula,
            weeklyHours: params.weeklyHours,
            dailyHours: params.dailyHours,
            annualOccurrences: params.annualOccurrences,
            hoursPerOccurrence: params.hoursPerOccurrence
        )
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var params: CustomDimensionParams {
        CustomDimensionParams(
            formula: formula,
            weeklyHours: weeklyHours,
            dailyHours: dailyHours,
            annualOccurrences: annualOccurrences,
            hoursPerOccurrence: hoursPerOccurrence
        )
    }

    var canSave: Bool {
        trimmedName.isEmpty == false
            && trimmedName.count <= CustomDimensionAccount.maxNameCount
            && CustomDimensionAccount.iconOptions.contains(iconKey)
            && DimensionPalette.supportedColorKeys.contains(colorKey)
    }

    mutating func clampNameLength() {
        name = CustomDimensionAccount.limitedName(name)
    }
}
