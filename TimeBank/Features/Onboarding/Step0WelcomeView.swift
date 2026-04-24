// TimeBank/Features/Onboarding/Step0WelcomeView.swift

import SwiftUI

struct Step0WelcomeView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: TBSpace.s9)

            VStack(spacing: TBSpace.s7) {
                Text("我们习惯看银行里的数字，\n却很少留意自己的时间余额。")
                    .font(.tbHeadL)
                    .lineSpacing(TBSpace.s1)

                Text("和父母的时间，\n和孩子的时间，\n和身边那个人的时间。\n那才是最该看的余额。")
                    .font(.tbBody)
                    .lineSpacing(TBSpace.s1)

                Text("但也不必焦虑 ——\n当你专注地过一段时光，把它记下来，\n时间就不会把它带走。")
                    .font(.tbBody)
                    .lineSpacing(TBSpace.s1)
            }
            .foregroundStyle(Color.tbInk)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, TBSpace.s6)

            Spacer()

            Button(action: onNext) {
                Text("开始")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(OnboardingNavigationButtonStyle())
            .padding(.horizontal, TBSpace.s6)
            .padding(.bottom, TBSpace.s7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tbBg)
    }
}
