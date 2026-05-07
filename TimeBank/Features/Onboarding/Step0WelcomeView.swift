// TimeBank/Features/Onboarding/Step0WelcomeView.swift

import SwiftUI

struct Step0WelcomeView: View {
    let onNext: () -> Void

    @State private var pageIndex = 0

    private let pages: [(title: String, body: String)] = [
        (
            "我们习惯看银行里的数字",
            "却很少留意自己的时间余额。"
        ),
        (
            "和重要的人在一起",
            "和父母的时间，和孩子的时间，和身边那个人的时间。那才是最该看的余额。"
        ),
        (
            "但也不必焦虑",
            "当你专注地过一段时光，把它记下来，时间就不会把它带走。"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: TBSpace.s9)

            TabView(selection: $pageIndex) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(spacing: TBSpace.s5) {
                        Text(pages[index].title)
                            .font(.tbHeadL)
                            .lineSpacing(TBSpace.s1)

                        Text(pages[index].body)
                            .font(.tbBody)
                            .lineSpacing(TBSpace.s1)
                            .foregroundStyle(Color.tbInk2)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, TBSpace.s6)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 260)

            HStack(spacing: TBSpace.s2) {
                ForEach(pages.indices, id: \.self) { index in
                    Circle()
                        .fill(index == pageIndex ? Color.tbPrimary : Color.tbHair)
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.top, TBSpace.s4)

            Spacer()

            Button(action: continueOrFinish) {
                Text(pageIndex == pages.indices.last ? "开始" : "继续")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(OnboardingNavigationButtonStyle())
            .padding(.horizontal, TBSpace.s6)
            .padding(.bottom, TBSpace.s7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tbBg)
    }

    private func continueOrFinish() {
        if pageIndex < pages.count - 1 {
            withAnimation(TBAnimation.transition) {
                pageIndex += 1
            }
        } else {
            onNext()
        }
    }
}
