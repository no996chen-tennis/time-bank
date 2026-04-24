// TimeBank/Features/Onboarding/Step2RelationshipsView.swift

import SwiftUI

struct Step2RelationshipsView: View {
    @Binding var draft: OnboardingDraft

    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TBSpace.s6) {
            Spacer(minLength: TBSpace.s5)

            header
            relationshipGrid

            Spacer(minLength: TBSpace.s5)

            HStack(spacing: TBSpace.s5) {
                Button("上一步", action: onBack)
                    .buttonStyle(OnboardingSecondaryButtonStyle())

                Button("下一步", action: onNext)
                    .buttonStyle(OnboardingNavigationButtonStyle())
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: TBSpace.s5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            Text("告诉我一些家人的信息。")
                .font(.tbHeadM)
                .foregroundStyle(Color.tbInk)

            Text("不用太准，估个数就好。")
                .font(.tbBody)
                .foregroundStyle(Color.tbInk2)
        }
    }

    private var relationshipGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: TBSpace.s3),
                GridItem(.flexible(), spacing: TBSpace.s3)
            ],
            spacing: TBSpace.s3
        ) {
            relationshipChip(.parents, title: "父母", icon: "person.2.fill")
            relationshipChip(.partner, title: "伴侣", icon: "heart.circle.fill")
            relationshipChip(.children, title: "孩子", icon: "figure.2.and.child.holdinghands")
            relationshipChip(.solo, title: "独处也是一种时间", icon: "moon.stars.fill")
        }
    }

    private func relationshipChip(
        _ relationship: OnboardingRelationship,
        title: String,
        icon: String
    ) -> some View {
        SelectableChip(
            title: title,
            iconSystemName: icon,
            isSelected: draft.selectedRelationships.contains(relationship)
        ) {
            toggle(relationship)
        }
    }

    private func toggle(_ relationship: OnboardingRelationship) {
        if draft.selectedRelationships.contains(relationship) {
            draft.selectedRelationships.remove(relationship)
        } else {
            draft.selectedRelationships.insert(relationship)
        }
    }
}
