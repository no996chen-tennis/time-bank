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

    init(
        selectedTab: HomeTab = .home,
        onSelect: @escaping (HomeTab) -> Void = { _ in }
    ) {
        self.selectedTab = selectedTab
        self.onSelect = onSelect
    }

    var body: some View {
        HStack(alignment: .center, spacing: TBSpace.s2) {
            tabItem(title: "主页", tab: .home)

            tabItem(title: "账户", tab: .account)

            tabItem(title: "我", tab: .me)
        }
        .padding(.horizontal, TBSpace.s5)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .frame(height: 62)
        .frame(maxWidth: .infinity)
        .background(tabBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.tbHair)
                .frame(height: TimeBankTheme.current.style.cardBorderWidth)
        }
    }

    private func tabItem(
        title: String,
        tab: HomeTab
    ) -> some View {
        let isSelected = selectedTab == tab
        let icon = TimeBankIconography.tabIconSystemName(for: tab, isSelected: isSelected)

        return Button {
            onSelect(tab)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .frame(height: 19)

                Text(title)
                    .font(.system(size: 11.5, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? Color.tbPrimary : Color.tbInk3)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var tabBackground: some View {
        Color.tbSurface
            .ignoresSafeArea(edges: .bottom)
    }
}
