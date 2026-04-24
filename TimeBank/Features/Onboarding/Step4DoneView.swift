// TimeBank/Features/Onboarding/Step4DoneView.swift

import SwiftUI

struct Step4DoneView: View {
    @Binding var draft: OnboardingDraft

    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: TBSpace.s6) {
            Spacer()

            Text("TODO §3.2B.5 完成 + pre-permission")
                .font(.tbBody)
                .foregroundStyle(Color.tbInk)

            HStack(spacing: TBSpace.s5) {
                Button("上一步", action: onBack)
                    .buttonStyle(OnboardingSecondaryButtonStyle())

                Button("完成", action: onNext)
                    .buttonStyle(OnboardingNavigationButtonStyle())
            }

            Spacer()
        }
    }
}

struct OnboardingNavigationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.tbBody)
            .foregroundStyle(Color.tbSurface)
            .padding(.horizontal, TBSpace.s6)
            .padding(.vertical, TBSpace.s3)
            .background(Color.tbPrimary.opacity(configuration.isPressed ? 0.78 : 1))
            .clipShape(Capsule())
    }
}

struct OnboardingSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.tbBody)
            .foregroundStyle(Color.tbInk2)
            .padding(.horizontal, TBSpace.s6)
            .padding(.vertical, TBSpace.s3)
            .background(Color.tbBg2.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(Capsule())
    }
}
