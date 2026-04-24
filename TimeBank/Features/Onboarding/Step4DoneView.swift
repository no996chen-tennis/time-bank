// TimeBank/Features/Onboarding/Step4DoneView.swift

import SwiftData
import SwiftUI
import UserNotifications

struct Step4DoneView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var draft: OnboardingDraft
    @State private var isFinishing = false

    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TBSpace.s6) {
            Spacer()

            completionCopy
            notificationCopy

            Spacer()

            VStack(spacing: TBSpace.s3) {
                Button("好，开启提醒") {
                    Task {
                        await finish(requestNotifications: true)
                    }
                }
                .buttonStyle(OnboardingNavigationButtonStyle())
                .disabled(isFinishing)
                .opacity(isFinishing ? 0.5 : 1)

                Button("以后再说") {
                    Task {
                        await finish(requestNotifications: false)
                    }
                }
                .buttonStyle(OnboardingSecondaryButtonStyle())
                .disabled(isFinishing)
                .opacity(isFinishing ? 0.5 : 1)
            }
            .frame(maxWidth: .infinity)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var completionCopy: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            Text("做好了。")
                .font(.tbHeadM)
                .foregroundStyle(Color.tbInk)

            Text("一切就绪。开始吧。")
                .font(.tbBody)
                .foregroundStyle(Color.tbInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var notificationCopy: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            Text("每天早上轻轻提醒你一次 —— 不催，不推销。")
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)

            Text("只是帮你记得：今天也有一些片段，值得被留下。")
                .font(.tbBody)
                .foregroundStyle(Color.tbInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(TBSpace.s5)
        .background(Color.tbBg2)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg))
    }

    @MainActor
    private func finish(requestNotifications: Bool) async {
        guard isFinishing == false else { return }
        isFinishing = true
        defer { isFinishing = false }

        if requestNotifications {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        }

        guard (try? draft.finalize(in: modelContext)) != nil else {
            return
        }

        onNext()
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
