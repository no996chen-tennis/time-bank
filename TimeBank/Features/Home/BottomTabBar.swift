// TimeBank/Features/Home/BottomTabBar.swift

import SwiftUI

enum HomeTab: Hashable {
    case home
    case account
    case me
}

struct BottomTabBar: View {
    let selectedTab: HomeTab
    let onSelect: (HomeTab) -> Void
    let onCreateMoment: () -> Void

    init(
        selectedTab: HomeTab = .home,
        onSelect: @escaping (HomeTab) -> Void = { _ in },
        onCreateMoment: @escaping () -> Void = {}
    ) {
        self.selectedTab = selectedTab
        self.onSelect = onSelect
        self.onCreateMoment = onCreateMoment
    }

    var body: some View {
        ZStack {
            HStack(alignment: .center) {
                tabItem(icon: "house.fill", title: "主页", tab: .home)

                tabItem(icon: "chart.pie", title: "账户", tab: .account)

                Spacer()
                    .frame(width: 104)

                tabItem(icon: "person.circle", title: "我", tab: .me)
            }
            .padding(.horizontal, TBSpace.s5)
            .frame(height: 84)
            .frame(maxWidth: .infinity)
            .background(Color.tbSurface)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.tbHair)
                    .frame(height: 1)
            }

            Button(action: onCreateMoment) {
                Image(systemName: "plus")
                    .font(.tbHeadM)
                    .foregroundStyle(Color.white)
                    .frame(width: 52, height: 52)
                    .background(Color.tbPrimary)
                    .clipShape(Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .offset(y: -22)
            .accessibilityLabel("存入时刻")
        }
        .frame(height: 84)
    }

    private func tabItem(
        icon: String,
        title: String,
        tab: HomeTab
    ) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            onSelect(tab)
        } label: {
            VStack(spacing: TBSpace.s1) {
                Image(systemName: icon)
                    .font(.tbHeadS)

                Text(title)
                    .font(.tbLabel)
            }
            .foregroundStyle(isSelected ? Color.tbPrimary : Color.tbInk3)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
