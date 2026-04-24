// TimeBank/Features/Onboarding/Step3DetailsView.swift

import SwiftUI

struct Step3DetailsView: View {
    @Binding var draft: OnboardingDraft

    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: TBSpace.s6) {
            Spacer()

            Text("TODO §3.2B.4 条件化细节")
                .font(.tbBody)
                .foregroundStyle(Color.tbInk)

            HStack(spacing: TBSpace.s5) {
                Button("上一步", action: onBack)
                    .buttonStyle(OnboardingSecondaryButtonStyle())

                Button("下一步", action: onNext)
                    .buttonStyle(OnboardingNavigationButtonStyle())
            }

            Spacer()
        }
    }
}
