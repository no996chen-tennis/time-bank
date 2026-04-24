// TimeBank/Features/Home/BottomTabBar.swift

import SwiftUI

struct BottomTabBar: View {
    var body: some View {
        ZStack {
            HStack(alignment: .center) {
                tabItem(icon: "house.fill", title: "主页", isSelected: true)

                tabItem(icon: "chart.pie", title: "账户", isSelected: false)

                Spacer()
                    .frame(width: 104)

                tabItem(icon: "person.circle", title: "我", isSelected: false)
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

            Button(action: {}) {
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
        isSelected: Bool
    ) -> some View {
        Button(action: {}) {
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
