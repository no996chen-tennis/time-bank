// TimeBank/Features/Onboarding/OnboardingDraft.swift

import Foundation

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
}

enum OnboardingRelationship: String, CaseIterable, Hashable, Sendable {
    case parents
    case partner
    case children
    case solo
}
