// TimeBank/Models/UserProfile.swift

import Foundation
import SwiftData

enum Gender: String, Codable, CaseIterable, Sendable {
    case male
    case female
    case other
    case undisclosed
}

struct FamilyMember: Codable, Sendable, Equatable {
    var birthYear: Int
    var deceased: Bool
    var deceasedAt: Date?

    init(
        birthYear: Int = Calendar.current.component(.year, from: .now) - 60,
        deceased: Bool = false,
        deceasedAt: Date? = nil
    ) {
        self.birthYear = birthYear
        self.deceased = deceased
        self.deceasedAt = deceasedAt
    }
}

struct ParentsInfo: Codable, Sendable, Equatable {
    var father: FamilyMember?
    var mother: FamilyMember?
    var visitsPerYear: Int
    var hoursPerVisit: Double
    var expectedLifespan: Int

    init(
        father: FamilyMember? = nil,
        mother: FamilyMember? = nil,
        visitsPerYear: Int = 4,
        hoursPerVisit: Double = 6.0,
        expectedLifespan: Int = 82
    ) {
        self.father = father
        self.mother = mother
        self.visitsPerYear = visitsPerYear
        self.hoursPerVisit = hoursPerVisit
        self.expectedLifespan = expectedLifespan
    }
}

struct ChildInfo: Codable, Sendable, Equatable {
    var id: UUID
    var birthYear: Int
    var gender: Gender?
    var deceased: Bool
    var deceasedAt: Date?

    init(
        id: UUID = UUID(),
        birthYear: Int = Calendar.current.component(.year, from: .now),
        gender: Gender? = nil,
        deceased: Bool = false,
        deceasedAt: Date? = nil
    ) {
        self.id = id
        self.birthYear = birthYear
        self.gender = gender
        self.deceased = deceased
        self.deceasedAt = deceasedAt
    }
}

struct PartnerInfo: Codable, Sendable, Equatable {
    var birthYear: Int
    var hoursPerDay: Double
    var deceased: Bool
    var deceasedAt: Date?

    init(
        birthYear: Int = Calendar.current.component(.year, from: .now) - 30,
        hoursPerDay: Double = 4.0,
        deceased: Bool = false,
        deceasedAt: Date? = nil
    ) {
        self.birthYear = birthYear
        self.hoursPerDay = hoursPerDay
        self.deceased = deceased
        self.deceasedAt = deceasedAt
    }
}

struct ExtraRelation: Codable, Sendable, Equatable {
    var id: UUID
    var kind: String
    var name: String
    var birthYear: Int?

    init(
        id: UUID = UUID(),
        kind: String = "custom",
        name: String = "",
        birthYear: Int? = nil
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.birthYear = birthYear
    }
}

@Model
final class UserProfile {
    static let singletonID = UUID(uuidString: "8F6F3D90-4C50-4B5F-8F9B-CC4D4A0A0101")!

    @Attribute(.unique) var id: UUID
    var birthday: Date
    var gender: Gender
    var expectedLifespanYears: Int
    var parents: ParentsInfo?
    var children: [ChildInfo]
    var partner: PartnerInfo?
    var soloEmphasis: Bool
    var extras: [ExtraRelation]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UserProfile.singletonID,
        birthday: Date = .now,
        gender: Gender = .undisclosed,
        expectedLifespanYears: Int = 85,
        parents: ParentsInfo? = nil,
        children: [ChildInfo] = [],
        partner: PartnerInfo? = nil,
        soloEmphasis: Bool = false,
        extras: [ExtraRelation] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.birthday = birthday
        self.gender = gender
        self.expectedLifespanYears = expectedLifespanYears
        self.parents = parents
        self.children = children
        self.partner = partner
        self.soloEmphasis = soloEmphasis
        self.extras = extras
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func fetchSingleton(in modelContext: ModelContext) throws -> UserProfile? {
        let id = UserProfile.singletonID
        let descriptor = FetchDescriptor<UserProfile>(predicate: #Predicate { $0.id == id })
        return try modelContext.fetch(descriptor).first
    }

    @discardableResult
    static func fetchOrCreateSingleton(
        in modelContext: ModelContext,
        birthday: Date
    ) throws -> UserProfile {
        if let existing = try fetchSingleton(in: modelContext) {
            return existing
        }

        let profile = UserProfile(birthday: birthday)
        modelContext.insert(profile)
        try modelContext.save()
        return profile
    }
}
