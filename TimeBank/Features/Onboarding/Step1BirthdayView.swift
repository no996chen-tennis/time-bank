// TimeBank/Features/Onboarding/Step1BirthdayView.swift

import SwiftUI

struct Step1BirthdayView: View {
    @Binding var draft: OnboardingDraft

    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: TBSpace.s6) {
            Spacer()

            Text("TODO §3.2B.2 生日 + 性别 + 寿命")
                .font(.tbBody)
                .foregroundStyle(Color.tbInk)

            Button("下一步", action: onNext)
                .buttonStyle(OnboardingNavigationButtonStyle())

            Spacer()
        }
    }
}
