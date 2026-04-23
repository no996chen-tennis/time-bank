// TimeBank/Models/Dimension.swift

import Foundation
import SwiftData

enum DimensionKind: String, Codable, CaseIterable, Sendable {
    case builtin
    case systemTop
    case custom
    case systemHidden
    case systemVirtual
}

enum DimensionStatus: String, Codable, CaseIterable, Sendable {
    case visible
    case hidden
    case deleted
}

enum DimensionMode: String, Codable, CaseIterable, Sendable {
    case normal
    case memorial
}

struct EmptyDimensionParams: Codable, Sendable, Equatable {
    init() {}
}

struct SportDimensionParams: Codable, Sendable, Equatable {
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

struct CreateDimensionParams: Codable, Sendable, Equatable {
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

struct FreeDimensionParams: Codable, Sendable, Equatable {
    var awakeHoursPerDay: Double

    init(awakeHoursPerDay: Double = 14) {
        self.awakeHoursPerDay = awakeHoursPerDay
    }
}

enum DimensionReservedID: String, CaseIterable, Sendable {
    case lifespan
    case parents
    case kids
    case partner
    case sport
    case create
    case free
    case daily
    case other
}

@Model
final class Dimension {
    @Attribute(.unique) var id: String
    var name: String
    var kind: DimensionKind
    var status: DimensionStatus
    var mode: DimensionMode
    var iconKey: String
    var colorKey: String
    var sortIndex: Int
    var params: Data
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        name: String = "",
        kind: DimensionKind = .custom,
        status: DimensionStatus = .visible,
        mode: DimensionMode = .normal,
        iconKey: String = "circle",
        colorKey: String = "rose",
        sortIndex: Int = 0,
        params: Data = Dimension.encodedParams(EmptyDimensionParams()),
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.status = status
        self.mode = mode
        self.iconKey = iconKey
        self.colorKey = colorKey
        self.sortIndex = sortIndex
        self.params = params
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func decodeParams<T: Decodable>(_ type: T.Type, default defaultValue: @autoclosure () -> T) -> T {
        do {
            return try JSONDecoder().decode(type, from: params)
        } catch {
            return defaultValue()
        }
    }

    func setParams<T: Encodable>(_ value: T) {
        params = Dimension.encodedParams(value)
        updatedAt = .now
    }

    static func encodedParams<T: Encodable>(_ value: T) -> Data {
        do {
            return try JSONEncoder().encode(value)
        } catch {
            return Data("{}".utf8)
        }
    }

    static func fetchAll(in modelContext: ModelContext) throws -> [Dimension] {
        try modelContext.fetch(FetchDescriptor<Dimension>())
    }

    static func fetch(by id: String, in modelContext: ModelContext) throws -> Dimension? {
        try fetchAll(in: modelContext).first(where: { $0.id == id })
    }

    @discardableResult
    static func seedReservedDimensionsIfNeeded(in modelContext: ModelContext) throws -> [Dimension] {
        let existing = try fetchAll(in: modelContext)
        let existingIDs = Set(existing.map(\.id))
        var inserted: [Dimension] = []

        for seed in reservedSeeds where existingIDs.contains(seed.id) == false {
            modelContext.insert(seed)
            inserted.append(seed)
        }

        if inserted.isEmpty == false {
            try modelContext.save()
        }

        return inserted
    }

    private static var reservedSeeds: [Dimension] {
        [
            Dimension(
                id: DimensionReservedID.lifespan.rawValue,
                name: "时间余额",
                kind: .systemTop,
                status: .visible,
                mode: .normal,
                iconKey: "hourglass",
                colorKey: "rose",
                sortIndex: 0,
                params: encodedParams(EmptyDimensionParams())
            ),
            Dimension(
                id: DimensionReservedID.parents.rawValue,
                name: "陪父母",
                kind: .builtin,
                status: .hidden,
                mode: .normal,
                iconKey: "heart",
                colorKey: "rose",
                sortIndex: 1,
                params: encodedParams(EmptyDimensionParams())
            ),
            Dimension(
                id: DimensionReservedID.kids.rawValue,
                name: "陪孩子",
                kind: .builtin,
                status: .hidden,
                mode: .normal,
                iconKey: "figure.2.and.child.holdinghands",
                colorKey: "warm",
                sortIndex: 2,
                params: encodedParams(EmptyDimensionParams())
            ),
            Dimension(
                id: DimensionReservedID.partner.rawValue,
                name: "陪伴侣",
                kind: .builtin,
                status: .hidden,
                mode: .normal,
                iconKey: "sparkles.heart",
                colorKey: "lavender",
                sortIndex: 3,
                params: encodedParams(EmptyDimensionParams())
            ),
            Dimension(
                id: DimensionReservedID.sport.rawValue,
                name: "运动",
                kind: .builtin,
                status: .visible,
                mode: .normal,
                iconKey: "figure.run",
                colorKey: "sage",
                sortIndex: 4,
                params: encodedParams(SportDimensionParams())
            ),
            Dimension(
                id: DimensionReservedID.create.rawValue,
                name: "创造",
                kind: .builtin,
                status: .visible,
                mode: .normal,
                iconKey: "paintbrush",
                colorKey: "sky",
                sortIndex: 5,
                params: encodedParams(CreateDimensionParams())
            ),
            Dimension(
                id: DimensionReservedID.free.rawValue,
                name: "自由",
                kind: .builtin,
                status: .visible,
                mode: .normal,
                iconKey: "sun.max",
                colorKey: "peach",
                sortIndex: 6,
                params: encodedParams(FreeDimensionParams())
            ),
            Dimension(
                id: DimensionReservedID.daily.rawValue,
                name: "__daily",
                kind: .systemHidden,
                status: .hidden,
                mode: .normal,
                iconKey: "clock",
                colorKey: "warm",
                sortIndex: 90,
                params: encodedParams(EmptyDimensionParams())
            ),
            Dimension(
                id: DimensionReservedID.other.rawValue,
                name: "其他",
                kind: .systemHidden,
                status: .hidden,
                mode: .normal,
                iconKey: "tray",
                colorKey: "rose",
                sortIndex: 91,
                params: encodedParams(EmptyDimensionParams())
            )
        ]
    }
}
