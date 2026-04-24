// TimeBank/Features/Onboarding/OnboardingDraft.swift

import Foundation
import SwiftData

struct OnboardingDraft: Equatable, Sendable {
    var birthday: Date
    var gender: Gender
    var expectedLifespanYears: Int
    var selectedRelationships: Set<OnboardingRelationship>
    var parents: ParentsInfo?
    var children: [ChildInfo]
    var partner: PartnerInfo?
    var soloEmphasis: Bool
    var extras: [ExtraRelation]

    init(
        birthday: Date = .now,
        gender: Gender = .undisclosed,
        expectedLifespanYears: Int = 85,
        selectedRelationships: Set<OnboardingRelationship> = [],
        parents: ParentsInfo? = nil,
        children: [ChildInfo] = [],
        partner: PartnerInfo? = nil,
        soloEmphasis: Bool = false,
        extras: [ExtraRelation] = []
    ) {
        self.birthday = birthday
        self.gender = gender
        self.expectedLifespanYears = expectedLifespanYears
        self.selectedRelationships = selectedRelationships
        self.parents = parents
        self.children = children
        self.partner = partner
        self.soloEmphasis = soloEmphasis
        self.extras = extras
    }

    func toUserProfile() -> UserProfile {
        UserProfile(
            birthday: birthday,
            gender: gender,
            expectedLifespanYears: expectedLifespanYears,
            parents: selectedRelationships.contains(.parents) ? parents : nil,
            children: selectedRelationships.contains(.children) ? children : [],
            partner: selectedRelationships.contains(.partner) ? partner : nil,
            soloEmphasis: soloEmphasis || selectedRelationships.contains(.solo),
            extras: extras
        )
    }

    @MainActor
    @discardableResult
    func finalize(in modelContext: ModelContext) throws -> UserProfile {
        let profile: UserProfile
        if let existing = try UserProfile.fetchSingleton(in: modelContext) {
            profile = existing
        } else {
            profile = UserProfile(birthday: birthday)
            modelContext.insert(profile)
        }

        profile.birthday = birthday
        profile.gender = gender
        profile.expectedLifespanYears = expectedLifespanYears
        profile.parents = selectedRelationships.contains(.parents) ? parents : nil
        profile.children = selectedRelationships.contains(.children) ? children : []
        profile.partner = selectedRelationships.contains(.partner) ? partner : nil
        profile.soloEmphasis = soloEmphasis || selectedRelationships.contains(.solo)
        profile.extras = extras
        profile.updatedAt = .now

        try revealSelectedRelationshipDimensions(in: modelContext)
        try modelContext.save()

        return profile
    }

    @MainActor
    private func revealSelectedRelationshipDimensions(in modelContext: ModelContext) throws {
        if selectedRelationships.contains(.parents) {
            try revealDimension(.parents, in: modelContext)
        }

        if selectedRelationships.contains(.children) {
            try revealDimension(.kids, in: modelContext)
        }

        if selectedRelationships.contains(.partner) {
            try revealDimension(.partner, in: modelContext)
        }
    }

    @MainActor
    private func revealDimension(
        _ reservedID: DimensionReservedID,
        in modelContext: ModelContext
    ) throws {
        guard let dimension = try Dimension.fetch(by: reservedID.rawValue, in: modelContext) else {
            return
        }

        dimension.status = .visible
        dimension.updatedAt = .now
    }
}

enum OnboardingRelationship: String, CaseIterable, Hashable, Sendable {
    case parents
    case partner
    case children
    case solo
}
