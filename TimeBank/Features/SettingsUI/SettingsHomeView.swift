// TimeBank/Features/SettingsUI/SettingsHomeView.swift

import SwiftUI

struct SettingsHomeView: View {
    let profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("我")
                .font(.tbHeadL)
                .foregroundStyle(Color.tbInk)
                .padding(.horizontal, TBSpace.s5)
                .padding(.top, TBSpace.s5)
                .padding(.bottom, TBSpace.s4)

            ScrollView(showsIndicators: false) {
                VStack(spacing: TBSpace.s3) {
                    NavigationLink {
                        ProfileEditorView(profile: profile)
                    } label: {
                        SettingsRow(
                            icon: "person.text.rectangle",
                            title: "个人信息",
                            subtitle: "生日 · 家人 · 预期寿命",
                            showsChevron: true
                        )
                    }
                    .buttonStyle(.plain)

                    SettingsRow(
                        icon: "lock.doc",
                        title: "你的数据去哪了",
                        subtitle: nil,
                        showsChevron: true
                    )

                    SettingsRow(
                        icon: "info.circle",
                        title: "关于时间银行",
                        subtitle: nil,
                        showsChevron: true
                    )
                }
                .padding(.horizontal, TBSpace.s5)
                .padding(.bottom, TBSpace.s7)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tbBg)
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let showsChevron: Bool

    var body: some View {
        HStack(spacing: TBSpace.s3) {
            Image(systemName: icon)
                .font(.tbHeadS)
                .foregroundStyle(Color.tbPrimary)
                .frame(width: TBSpace.s8, height: TBSpace.s8)
                .background(Color.tbPrimary.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: TBSpace.s1) {
                Text(title)
                    .font(.tbBody)
                    .foregroundStyle(Color.tbInk)

                if let subtitle {
                    Text(subtitle)
                        .font(.tbBodySm)
                        .foregroundStyle(Color.tbInk2)
                }
            }

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk3.opacity(0.55))
            }
        }
        .padding(TBSpace.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tbSurface)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg))
    }
}
