// TimeBank/Features/SettingsUI/SettingsHomeView.swift

import SwiftUI

struct SettingsHomeView: View {
    let profile: UserProfile
    @AppStorage(TimeBankThemeKind.storageKey) private var selectedThemeRawValue = TimeBankThemeKind.magazineApartamento.rawValue
    @AppStorage(TimeBankIconSetKind.storageKey) private var selectedIconSetRawValue = TimeBankIconSetKind.nativeFilled.rawValue

    private var selectedTheme: TimeBankThemeKind {
        TimeBankThemeKind(rawValue: selectedThemeRawValue) ?? .magazineApartamento
    }

    private var selectedIconSet: TimeBankIconSetKind {
        TimeBankIconSetKind(rawValue: selectedIconSetRawValue) ?? .nativeFilled
    }

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

                    NavigationLink {
                        DimensionManagerView()
                    } label: {
                        SettingsRow(
                            icon: "rectangle.grid.2x2",
                            title: "时间账户管理",
                            subtitle: "新增 / 编辑 / 删除自定义账户",
                            showsChevron: true
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ThemeSelectionView(selectedThemeRawValue: $selectedThemeRawValue)
                    } label: {
                        SettingsRow(
                            icon: "paintpalette",
                            title: "界面主题",
                            subtitle: selectedTheme.displayName,
                            showsChevron: true
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        IconStyleSelectionView(selectedIconSetRawValue: $selectedIconSetRawValue)
                    } label: {
                        SettingsRow(
                            icon: "sparkles",
                            title: "图标风格",
                            subtitle: selectedIconSet.displayName,
                            showsChevron: true
                        )
                    }
                    .buttonStyle(.plain)

                    SettingsRow(
                        icon: TimeBankIconography.privacyIconSystemName,
                        title: "你的数据去哪了",
                        subtitle: nil,
                        showsChevron: false
                    )

                    SettingsRow(
                        icon: TimeBankIconography.aboutIconSystemName,
                        title: "关于时间银行",
                        subtitle: nil,
                        showsChevron: false
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

private struct IconStyleSelectionView: View {
    @Binding var selectedIconSetRawValue: String

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: TBSpace.s3) {
                ForEach(TimeBankIconSetKind.allCases) { kind in
                    Button {
                        selectedIconSetRawValue = kind.rawValue
                    } label: {
                        IconOptionRow(
                            kind: kind,
                            isSelected: selectedIconSetRawValue == kind.rawValue
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, TBSpace.s5)
            .padding(.top, TBSpace.s4)
            .padding(.bottom, TBSpace.s8)
        }
        .background(Color.tbBg)
        .navigationTitle("图标风格")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct IconOptionRow: View {
    let kind: TimeBankIconSetKind
    let isSelected: Bool

    var body: some View {
        HStack(spacing: TBSpace.s3) {
            IconMiniPreviewCard(kind: kind)
                .frame(width: 84, height: 54)

            VStack(alignment: .leading, spacing: TBSpace.s1) {
                Text(kind.displayName)
                    .font(.tbBody)
                    .foregroundStyle(Color.tbInk)

                Text(kind.subtitle)
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk2)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.tbHeadS)
                    .foregroundStyle(Color.tbPrimary)
                    .accessibilityLabel("当前图标风格")
            }
        }
        .padding(TBSpace.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tbThemedSurface(.row)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(kind.displayName)，\(kind.subtitle)")
    }
}

private struct IconMiniPreviewCard: View {
    let kind: TimeBankIconSetKind

    private var previewIcons: [String] {
        return [
            TimeBankIconography.dimensionIconSystemName(for: DimensionReservedID.parents.rawValue, set: kind),
            TimeBankIconography.dimensionIconSystemName(for: DimensionReservedID.sport.rawValue, set: kind),
            TimeBankIconography.depositIconSystemName(for: kind)
        ]
    }

    var body: some View {
        HStack(spacing: 7) {
            ForEach(previewIcons, id: \.self) { icon in
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.tbPrimary)
                    .frame(width: 20, height: 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tbSurface)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.sm, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: TBRadius.sm, style: .continuous)
                .stroke(Color.tbHair, lineWidth: 1)
        }
    }
}

private struct ThemeSelectionView: View {
    @Binding var selectedThemeRawValue: String

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: TBSpace.s3) {
                ForEach(TimeBankThemeKind.allCases) { kind in
                    Button {
                        selectedThemeRawValue = kind.rawValue
                    } label: {
                        ThemeOptionRow(
                            kind: kind,
                            isSelected: selectedThemeRawValue == kind.rawValue
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, TBSpace.s5)
            .padding(.top, TBSpace.s4)
            .padding(.bottom, TBSpace.s8)
        }
        .background(Color.tbBg)
        .navigationTitle("界面主题")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ThemeOptionRow: View {
    let kind: TimeBankThemeKind
    let isSelected: Bool

    private var theme: TimeBankTheme {
        TimeBankTheme.theme(for: kind)
    }

    var body: some View {
        HStack(spacing: TBSpace.s3) {
            ThemeMiniPreviewCard(theme: theme)
                .frame(width: 84, height: 54)

            VStack(alignment: .leading, spacing: TBSpace.s1) {
                Text(kind.displayName)
                    .font(.tbBody)
                    .foregroundStyle(Color.tbInk)

                Text(kind.subtitle)
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk2)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.tbHeadS)
                    .foregroundStyle(Color.tbPrimary)
                    .accessibilityLabel("当前主题")
            }
        }
        .padding(TBSpace.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tbThemedSurface(.row)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(kind.displayName)，\(kind.subtitle)")
    }
}

private struct ThemeMiniPreviewCard: View {
    let theme: TimeBankTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(theme.palette.primary)
                    .frame(width: 8, height: 8)

                Rectangle()
                    .fill(theme.palette.hairline)
                    .frame(height: 1)
            }

            Text("3084 周")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(theme.palette.ink)
                .lineLimit(1)

            HStack(spacing: 4) {
                Rectangle()
                    .fill(theme.palette.dimensionColor(for: "rose"))
                Rectangle()
                    .fill(theme.palette.dimensionColor(for: "sage"))
                Rectangle()
                    .fill(theme.palette.dimensionColor(for: "sky"))
            }
            .frame(height: 8)
        }
        .padding(7)
        .background(theme.palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.radiusSM, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: theme.metrics.radiusSM, style: .continuous)
                .stroke(theme.style.cardBorderColor, lineWidth: max(1, theme.style.cardBorderWidth))
        }
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
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.tbPrimary)
                .frame(width: TBSpace.s8, height: TBSpace.s8)
                .background(Color.tbPrimary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: iconRadius, style: .continuous))

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
        .tbThemedSurface(.row)
    }

    private var iconRadius: CGFloat {
        switch TimeBankTheme.current.kind {
        case .gallery, .localRemoteEditorial:
            return 0
        default:
            return TBRadius.pill
        }
    }
}
