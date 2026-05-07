// TimeBank/Utility/DesignTokens.swift
//  DesignTokens.swift
//  TimeBank
//
//  从 Claude Design UI 定稿 (2026-04-22) 提取的 Design Tokens。
//  这是 SwiftUI 实现的**唯一颜色/字号/间距源**，View 层不得硬编码 hex 或 size。
//  Source of truth: `designs/DesignTokens.swift`。若本文件与 `designs/` 目录内容不一致，以 `designs/` 为准。
//  对应文档：PRD §22 主页 Layout / 设计规范 §9.5 / 文案系统 §6 Formatter Matrix
//
//  版本：V1.3.2 (Warm Illustration · Light Only · Headspace 浅色 · 奶咖底)
//  术语：Dimension（工程类名保留）· UI 上展示为「时间账户」

import SwiftUI

// MARK: - Theme System

enum TimeBankThemeKind: String, CaseIterable, Identifiable {
    static let storageKey = "timeBank.selectedTheme"

    case magazineApartamento
    case artBook
    case gallery
    case zenSongciTea
    case localRemoteEditorial

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .magazineApartamento:
            return "Magazine Apartamento"
        case .artBook:
            return "Art Book"
        case .gallery:
            return "Gallery"
        case .zenSongciTea:
            return "禅意宋瓷茶道"
        case .localRemoteEditorial:
            return "Local Remote Editorial"
        }
    }

    var subtitle: String {
        switch self {
        case .magazineApartamento:
            return "杂志纸张 · 复古出版物"
        case .artBook:
            return "装帧书页 · 红金藏书票"
        case .gallery:
            return "当代艺廊 · 黑白强网格"
        case .zenSongciTea:
            return "宋瓷茶席 · 留白与印章"
        case .localRemoteEditorial:
            return "双栏排版 · 系统标签"
        }
    }

    static var persisted: TimeBankThemeKind {
        let rawValue = UserDefaults.standard.string(forKey: storageKey)
        return rawValue.flatMap(TimeBankThemeKind.init(rawValue:)) ?? .magazineApartamento
    }
}

enum TimeBankIconSetKind: String, CaseIterable, Identifiable {
    static let storageKey = "timeBank.selectedIconSet"

    case nativeFilled
    case softLine
    case editorialGlyph

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nativeFilled:
            return "iOS 原生填充"
        case .softLine:
            return "细线温柔"
        case .editorialGlyph:
            return "极简线性"
        }
    }

    var subtitle: String {
        switch self {
        case .nativeFilled:
            return "SF Symbols · 稳定清晰"
        case .softLine:
            return "Lucide / Iconoir 感 · 轻量克制"
        case .editorialGlyph:
            return "更少细节 · 更轻识别"
        }
    }

    static var persisted: TimeBankIconSetKind {
        let rawValue = UserDefaults.standard.string(forKey: storageKey)
        return rawValue.flatMap(TimeBankIconSetKind.init(rawValue:)) ?? .nativeFilled
    }
}

enum TimeBankIconography {
    static var currentSet: TimeBankIconSetKind {
        TimeBankIconSetKind.persisted
    }

    static func dimensionIconSystemName(for dimension: Dimension) -> String {
        dimensionIconSystemName(
            for: dimension.id,
            fallback: dimension.iconKey
        )
    }

    static func dimensionIconSystemName(
        for id: String,
        fallback: String = "circle",
        set: TimeBankIconSetKind = TimeBankIconography.currentSet
    ) -> String {
        switch set {
        case .nativeFilled:
            switch id {
            case DimensionReservedID.lifespan.rawValue:
                return "hourglass"
            case DimensionReservedID.parents.rawValue:
                return "heart.fill"
            case DimensionReservedID.kids.rawValue:
                return "person.2"
            case DimensionReservedID.partner.rawValue:
                return "heart.circle.fill"
            case DimensionReservedID.sport.rawValue:
                return "figure.run"
            case DimensionReservedID.create.rawValue:
                return "paintpalette.fill"
            case DimensionReservedID.free.rawValue:
                return "sun.max.fill"
            case DimensionReservedID.daily.rawValue:
                return "clock.fill"
            case DimensionReservedID.other.rawValue:
                return "tray.fill"
            default:
                return fallback
            }

        case .softLine:
            switch id {
            case DimensionReservedID.lifespan.rawValue:
                return "hourglass"
            case DimensionReservedID.parents.rawValue:
                return "heart"
            case DimensionReservedID.kids.rawValue:
                return "figure.2.and.child.holdinghands"
            case DimensionReservedID.partner.rawValue:
                return "heart.circle"
            case DimensionReservedID.sport.rawValue:
                return "figure.run"
            case DimensionReservedID.create.rawValue:
                return "paintbrush"
            case DimensionReservedID.free.rawValue:
                return "sun.max"
            case DimensionReservedID.daily.rawValue:
                return "calendar"
            case DimensionReservedID.other.rawValue:
                return "tray"
            default:
                return fallback
            }

        case .editorialGlyph:
            switch id {
            case DimensionReservedID.lifespan.rawValue:
                return "hourglass"
            case DimensionReservedID.parents.rawValue:
                return "heart"
            case DimensionReservedID.kids.rawValue:
                return "figure.2.and.child.holdinghands"
            case DimensionReservedID.partner.rawValue:
                return "heart.circle"
            case DimensionReservedID.sport.rawValue:
                return "figure.run"
            case DimensionReservedID.create.rawValue:
                return "pencil"
            case DimensionReservedID.free.rawValue:
                return "sun.min"
            case DimensionReservedID.daily.rawValue:
                return "clock"
            case DimensionReservedID.other.rawValue:
                return "tray"
            default:
                return fallback
            }
        }
    }

    static func tabIconSystemName(for tab: HomeTab, isSelected: Bool) -> String {
        switch currentSet {
        case .nativeFilled:
            switch tab {
            case .home:
                return isSelected ? "house.fill" : "house"
            case .account:
                return isSelected ? "chart.pie.fill" : "chart.pie"
            case .me:
                return isSelected ? "person.circle.fill" : "person.circle"
            }

        case .softLine:
            switch tab {
            case .home:
                return "house"
            case .account:
                return "chart.pie"
            case .me:
                return "person"
            }

        case .editorialGlyph:
            switch tab {
            case .home:
                return isSelected ? "square.grid.2x2.fill" : "square.grid.2x2"
            case .account:
                return isSelected ? "chart.bar.fill" : "chart.bar"
            case .me:
                return isSelected ? "person.crop.circle.fill" : "person.crop.circle"
            }
        }
    }

    static var lifespanIconSystemName: String {
        dimensionIconSystemName(for: DimensionReservedID.lifespan.rawValue, fallback: "hourglass")
    }

    static var depositIconSystemName: String {
        depositIconSystemName(for: currentSet)
    }

    static func depositIconSystemName(for set: TimeBankIconSetKind) -> String {
        switch set {
        case .nativeFilled:
            return "tray.and.arrow.down"
        case .softLine:
            return "tray.and.arrow.down"
        case .editorialGlyph:
            return "tray"
        }
    }

    static var privacyIconSystemName: String {
        currentSet == .editorialGlyph ? "lock" : "lock.doc"
    }

    static var aboutIconSystemName: String {
        "info.circle"
    }
}

struct ThemePalette {
    let background: Color
    let background2: Color
    let background3: Color
    let surface: Color
    let surfaceElevated: Color
    let ink: Color
    let ink2: Color
    let ink3: Color
    let hairline: Color
    let borderStrong: Color
    let primary: Color
    let danger: Color
    let success: Color
    let dimensionColors: [String: Color]
    let shadowTint: Color

    func dimensionColor(for key: String) -> Color {
        dimensionColors[key] ?? ink3
    }

    func dimensionSoft(for key: String) -> Color {
        dimensionColor(for: key).opacity(TimeBankTheme.current.style.dimensionSoftOpacity)
    }
}

struct ThemeTypography {
    let displayFontName: String
    let textFontName: String
    let labelFontName: String
    let displayWeight: Font.Weight
    let headingWeight: Font.Weight
    let bodyWeight: Font.Weight
    let labelWeight: Font.Weight

    func display(size: CGFloat) -> Font {
        Font.custom(displayFontName, size: size, relativeTo: .largeTitle).weight(displayWeight)
    }

    func heading(size: CGFloat) -> Font {
        Font.custom(textFontName, size: size, relativeTo: size >= 24 ? .title2 : .headline).weight(headingWeight)
    }

    func body(size: CGFloat) -> Font {
        Font.custom(textFontName, size: size, relativeTo: .body).weight(bodyWeight)
    }

    func label(size: CGFloat) -> Font {
        Font.custom(labelFontName, size: size, relativeTo: .caption).weight(labelWeight)
    }
}

struct ThemeMetrics {
    let s1: CGFloat
    let s2: CGFloat
    let s3: CGFloat
    let s4: CGFloat
    let s5: CGFloat
    let s6: CGFloat
    let s7: CGFloat
    let s8: CGFloat
    let s9: CGFloat
    let radiusSM: CGFloat
    let radiusMD: CGFloat
    let radiusLG: CGFloat
    let radiusXL: CGFloat
    let radiusPill: CGFloat

    static let comfortable = ThemeMetrics(
        s1: 4,
        s2: 8,
        s3: 12,
        s4: 16,
        s5: 20,
        s6: 24,
        s7: 32,
        s8: 40,
        s9: 56,
        radiusSM: 8,
        radiusMD: 10,
        radiusLG: 12,
        radiusXL: 16,
        radiusPill: 100
    )
}

enum ThemeHeroStyle {
    case magazine
    case artBook
    case gallery
    case zen
    case localRemote
}

struct ThemeStyle {
    let heroStyle: ThemeHeroStyle
    let heroGradient: [Color]
    let heroTextColor: Color
    let heroSeparatorColor: Color
    let cardBorderColor: Color
    let cardBorderWidth: CGFloat
    let strongBorderWidth: CGFloat
    let usesShadow: Bool
    let shadowOpacity: Double
    let shadowRadius: CGFloat
    let shadowYOffset: CGFloat
    let dimensionSoftOpacity: Double
}

struct TimeBankTheme {
    let kind: TimeBankThemeKind
    let palette: ThemePalette
    let typography: ThemeTypography
    let metrics: ThemeMetrics
    let style: ThemeStyle

    static var current: TimeBankTheme {
        theme(for: TimeBankThemeKind.persisted)
    }

    static func theme(for kind: TimeBankThemeKind) -> TimeBankTheme {
        switch kind {
        case .magazineApartamento:
            return magazineApartamento
        case .artBook:
            return artBook
        case .gallery:
            return gallery
        case .zenSongciTea:
            return zenSongciTea
        case .localRemoteEditorial:
            return localRemoteEditorial
        }
    }

    static let magazineApartamento = TimeBankTheme(
        kind: .magazineApartamento,
        palette: ThemePalette(
            background: Color(hex: "#D7C7B6"),
            background2: Color(hex: "#EDE3D5"),
            background3: Color(hex: "#E2D3C2"),
            surface: Color(hex: "#FAF6ED"),
            surfaceElevated: Color(hex: "#FFF7EA"),
            ink: Color(hex: "#25231F"),
            ink2: Color(hex: "#716A60"),
            ink3: Color(hex: "#6F665B"),
            hairline: Color(hex: "#D8C6B2"),
            borderStrong: Color(hex: "#25231F"),
            primary: Color(hex: "#9D3F2F"),
            danger: Color(hex: "#9D3F2F"),
            success: Color(hex: "#243D32"),
            dimensionColors: [
                "rose": Color(hex: "#9D3F2F"),
                "warm": Color(hex: "#B78242"),
                "lavender": Color(hex: "#6B5774"),
                "sky": Color(hex: "#172B48"),
                "sage": Color(hex: "#243D32"),
                "peach": Color(hex: "#C8917E"),
                "coral": Color(hex: "#B45A4A"),
                "mint": Color(hex: "#4E7765"),
                "denim": Color(hex: "#315174"),
                "mauve": Color(hex: "#8E6178")
            ],
            shadowTint: Color(hex: "#36281B")
        ),
        typography: ThemeTypography(
            displayFontName: "Georgia",
            textFontName: "Avenir Next",
            labelFontName: "Avenir Next",
            displayWeight: .semibold,
            headingWeight: .medium,
            bodyWeight: .medium,
            labelWeight: .semibold
        ),
        metrics: .comfortable,
        style: ThemeStyle(
            heroStyle: .magazine,
            heroGradient: [Color(hex: "#243D32"), Color(hex: "#9D3F2F"), Color(hex: "#B78242")],
            heroTextColor: Color(hex: "#FFF7EA"),
            heroSeparatorColor: Color(hex: "#FFF7EA").opacity(0.22),
            cardBorderColor: Color(hex: "#25231F").opacity(0.16),
            cardBorderWidth: 1,
            strongBorderWidth: 1.5,
            usesShadow: true,
            shadowOpacity: 0.16,
            shadowRadius: 18,
            shadowYOffset: 8,
            dimensionSoftOpacity: 0.16
        )
    )

    static let artBook = TimeBankTheme(
        kind: .artBook,
        palette: ThemePalette(
            background: Color(hex: "#F2EADB"),
            background2: Color(hex: "#EEE2CB"),
            background3: Color(hex: "#E3D4B8"),
            surface: Color(hex: "#FBF6E9"),
            surfaceElevated: Color(hex: "#F2EADB"),
            ink: Color(hex: "#17130F"),
            ink2: Color(hex: "#4D4135"),
            ink3: Color(hex: "#8A7B68"),
            hairline: Color(hex: "#D0BFA1"),
            borderStrong: Color(hex: "#17130F"),
            primary: Color(hex: "#7F1718"),
            danger: Color(hex: "#7F1718"),
            success: Color(hex: "#1D3446"),
            dimensionColors: [
                "rose": Color(hex: "#7F1718"),
                "warm": Color(hex: "#A9792B"),
                "lavender": Color(hex: "#5E4B66"),
                "sky": Color(hex: "#1D3446"),
                "sage": Color(hex: "#2F4D42"),
                "peach": Color(hex: "#A66F4D"),
                "coral": Color(hex: "#9A3F35"),
                "mint": Color(hex: "#3E6E58"),
                "denim": Color(hex: "#2C5367"),
                "mauve": Color(hex: "#77505C")
            ],
            shadowTint: Color(hex: "#0F0B08")
        ),
        typography: ThemeTypography(
            displayFontName: "Iowan Old Style",
            textFontName: "Avenir Next",
            labelFontName: "Avenir Next",
            displayWeight: .medium,
            headingWeight: .semibold,
            bodyWeight: .medium,
            labelWeight: .bold
        ),
        metrics: ThemeMetrics(
            s1: 4,
            s2: 8,
            s3: 12,
            s4: 16,
            s5: 20,
            s6: 24,
            s7: 32,
            s8: 40,
            s9: 56,
            radiusSM: 4,
            radiusMD: 6,
            radiusLG: 8,
            radiusXL: 10,
            radiusPill: 100
        ),
        style: ThemeStyle(
            heroStyle: .artBook,
            heroGradient: [Color(hex: "#17130F"), Color(hex: "#2B241D"), Color(hex: "#7F1718")],
            heroTextColor: Color(hex: "#FBF6E9"),
            heroSeparatorColor: Color(hex: "#FBF6E9").opacity(0.24),
            cardBorderColor: Color(hex: "#17130F").opacity(0.26),
            cardBorderWidth: 1,
            strongBorderWidth: 1.5,
            usesShadow: true,
            shadowOpacity: 0.20,
            shadowRadius: 14,
            shadowYOffset: 7,
            dimensionSoftOpacity: 0.14
        )
    )

    static let gallery = TimeBankTheme(
        kind: .gallery,
        palette: ThemePalette(
            background: Color(hex: "#EFEFEB"),
            background2: Color(hex: "#ECECE7"),
            background3: Color(hex: "#D8D8D2"),
            surface: Color(hex: "#FFFFFF"),
            surfaceElevated: Color(hex: "#F7F7F4"),
            ink: Color(hex: "#050505"),
            ink2: Color(hex: "#454545"),
            ink3: Color(hex: "#747474"),
            hairline: Color(hex: "#B7B7B3"),
            borderStrong: Color(hex: "#050505"),
            primary: Color(hex: "#D93600"),
            danger: Color(hex: "#C23200"),
            success: Color(hex: "#171717"),
            dimensionColors: [
                "rose": Color(hex: "#D93600"),
                "warm": Color(hex: "#B45F00"),
                "lavender": Color(hex: "#6B52B8"),
                "sky": Color(hex: "#0064D2"),
                "sage": Color(hex: "#147A49"),
                "peach": Color(hex: "#B84A35"),
                "coral": Color(hex: "#D93600"),
                "mint": Color(hex: "#008C72"),
                "denim": Color(hex: "#163F9F"),
                "mauve": Color(hex: "#9F3F75")
            ],
            shadowTint: Color(hex: "#050505")
        ),
        typography: ThemeTypography(
            displayFontName: "Helvetica Neue",
            textFontName: "Helvetica Neue",
            labelFontName: "Menlo",
            displayWeight: .bold,
            headingWeight: .bold,
            bodyWeight: .medium,
            labelWeight: .semibold
        ),
        metrics: ThemeMetrics(
            s1: 4,
            s2: 8,
            s3: 12,
            s4: 16,
            s5: 20,
            s6: 24,
            s7: 30,
            s8: 38,
            s9: 52,
            radiusSM: 0,
            radiusMD: 0,
            radiusLG: 0,
            radiusXL: 0,
            radiusPill: 100
        ),
        style: ThemeStyle(
            heroStyle: .gallery,
            heroGradient: [Color(hex: "#FFFFFF"), Color(hex: "#FFFFFF")],
            heroTextColor: Color(hex: "#050505"),
            heroSeparatorColor: Color(hex: "#050505"),
            cardBorderColor: Color(hex: "#050505"),
            cardBorderWidth: 1,
            strongBorderWidth: 1.5,
            usesShadow: false,
            shadowOpacity: 0,
            shadowRadius: 0,
            shadowYOffset: 0,
            dimensionSoftOpacity: 0.11
        )
    )

    static let zenSongciTea = TimeBankTheme(
        kind: .zenSongciTea,
        palette: ThemePalette(
            background: Color(hex: "#EEE9DF"),
            background2: Color(hex: "#F1EADC"),
            background3: Color(hex: "#E7DFCF"),
            surface: Color(hex: "#F8F4EA"),
            surfaceElevated: Color(hex: "#FBF8EF"),
            ink: Color(hex: "#27302C"),
            ink2: Color(hex: "#5E6961"),
            ink3: Color(hex: "#687268"),
            hairline: Color(hex: "#D4CDBE"),
            borderStrong: Color(hex: "#27302C"),
            primary: Color(hex: "#9F3529"),
            danger: Color(hex: "#9F3529"),
            success: Color(hex: "#6F866D"),
            dimensionColors: [
                "rose": Color(hex: "#A5685E"),
                "warm": Color(hex: "#B99A5F"),
                "lavender": Color(hex: "#817189"),
                "sky": Color(hex: "#5B7D88"),
                "sage": Color(hex: "#6F866D"),
                "peach": Color(hex: "#916B45"),
                "coral": Color(hex: "#C66D59"),
                "mint": Color(hex: "#A8BBB1"),
                "denim": Color(hex: "#4F6F86"),
                "mauve": Color(hex: "#9A6876")
            ],
            shadowTint: Color(hex: "#26221B")
        ),
        typography: ThemeTypography(
            displayFontName: "Songti SC",
            textFontName: "Songti SC",
            labelFontName: "PingFang SC",
            displayWeight: .medium,
            headingWeight: .medium,
            bodyWeight: .regular,
            labelWeight: .medium
        ),
        metrics: ThemeMetrics(
            s1: 4,
            s2: 8,
            s3: 12,
            s4: 16,
            s5: 20,
            s6: 24,
            s7: 32,
            s8: 40,
            s9: 56,
            radiusSM: 10,
            radiusMD: 14,
            radiusLG: 18,
            radiusXL: 24,
            radiusPill: 100
        ),
        style: ThemeStyle(
            heroStyle: .zen,
            heroGradient: [Color(hex: "#F8F4EA"), Color(hex: "#A8BBB1"), Color(hex: "#27302C")],
            heroTextColor: Color(hex: "#27302C"),
            heroSeparatorColor: Color(hex: "#27302C").opacity(0.14),
            cardBorderColor: Color(hex: "#27302C").opacity(0.13),
            cardBorderWidth: 1,
            strongBorderWidth: 1,
            usesShadow: true,
            shadowOpacity: 0.13,
            shadowRadius: 22,
            shadowYOffset: 7,
            dimensionSoftOpacity: 0.18
        )
    )

    static let localRemoteEditorial = TimeBankTheme(
        kind: .localRemoteEditorial,
        palette: ThemePalette(
            background: Color(hex: "#FBFAF6"),
            background2: Color(hex: "#F8F4EB"),
            background3: Color(hex: "#E8E0D2"),
            surface: Color(hex: "#FBFAF6"),
            surfaceElevated: Color(hex: "#F8F4EB"),
            ink: Color(hex: "#141414"),
            ink2: Color(hex: "#4F4A43"),
            ink3: Color(hex: "#6E6A62"),
            hairline: Color(hex: "#D8D2C7"),
            borderStrong: Color(hex: "#141414"),
            primary: Color(hex: "#141414"),
            danger: Color(hex: "#A8342B"),
            success: Color(hex: "#2E6B55"),
            dimensionColors: [
                "rose": Color(hex: "#A8342B"),
                "warm": Color(hex: "#A06B2C"),
                "lavender": Color(hex: "#675B82"),
                "sky": Color(hex: "#234B70"),
                "sage": Color(hex: "#2E6B55"),
                "peach": Color(hex: "#A96E57"),
                "coral": Color(hex: "#B6463D"),
                "mint": Color(hex: "#2B8066"),
                "denim": Color(hex: "#243F78"),
                "mauve": Color(hex: "#884F6B")
            ],
            shadowTint: Color(hex: "#141414")
        ),
        typography: ThemeTypography(
            displayFontName: "Avenir Next Condensed",
            textFontName: "Avenir Next Condensed",
            labelFontName: "Menlo",
            displayWeight: .heavy,
            headingWeight: .heavy,
            bodyWeight: .medium,
            labelWeight: .heavy
        ),
        metrics: ThemeMetrics(
            s1: 4,
            s2: 8,
            s3: 12,
            s4: 16,
            s5: 18,
            s6: 22,
            s7: 30,
            s8: 38,
            s9: 52,
            radiusSM: 0,
            radiusMD: 0,
            radiusLG: 0,
            radiusXL: 0,
            radiusPill: 100
        ),
        style: ThemeStyle(
            heroStyle: .localRemote,
            heroGradient: [Color(hex: "#FBFAF6"), Color(hex: "#F8F4EB")],
            heroTextColor: Color(hex: "#141414"),
            heroSeparatorColor: Color(hex: "#141414"),
            cardBorderColor: Color(hex: "#141414"),
            cardBorderWidth: 1,
            strongBorderWidth: 1.25,
            usesShadow: false,
            shadowOpacity: 0,
            shadowRadius: 0,
            shadowYOffset: 0,
            dimensionSoftOpacity: 0.10
        )
    )
}

// MARK: - Colors

extension Color {
    // ─── Backgrounds ──────────────────────────────────────────
    /// 主背景 · 奶咖色
    static var tbBg: Color { TimeBankTheme.current.palette.background }
    /// 卡片背景 · 稍深一档的米黄
    static var tbBg2: Color { TimeBankTheme.current.palette.background2 }
    /// Hover / active 态
    static var tbBg3: Color { TimeBankTheme.current.palette.background3 }
    /// 白色悬浮卡片（最亮层）
    static var tbSurface: Color { TimeBankTheme.current.palette.surface }

    // ─── Text ─────────────────────────────────────────────────
    /// 深巧克力主文字
    static var tbInk: Color { TimeBankTheme.current.palette.ink }
    /// 次文字
    static var tbInk2: Color { TimeBankTheme.current.palette.ink2 }
    /// 占位 / 更次文字
    static var tbInk3: Color { TimeBankTheme.current.palette.ink3 }
    /// 细线 · 分隔
    static var tbHair: Color { TimeBankTheme.current.palette.hairline }

    // ─── Time Account Colors (6 内置时间账户) ─────────────────
    // 工程类名 Dimension，UI 文案「时间账户」
    /// 陪父母 · 珊瑚橘
    static var tbDimParents: Color { TimeBankTheme.current.palette.dimensionColor(for: "rose") }
    /// 陪孩子 · 金黄
    static var tbDimKids: Color { TimeBankTheme.current.palette.dimensionColor(for: "warm") }
    /// 陪伴侣 · 薰衣草紫
    static var tbDimPartner: Color { TimeBankTheme.current.palette.dimensionColor(for: "lavender") }
    /// 创造 · 晨雾蓝
    static var tbDimCreate: Color { TimeBankTheme.current.palette.dimensionColor(for: "sky") }
    /// 运动 · 薄荷绿
    static var tbDimSport: Color { TimeBankTheme.current.palette.dimensionColor(for: "sage") }
    /// 自由 · 蜜桃
    static var tbDimFree: Color { TimeBankTheme.current.palette.dimensionColor(for: "peach") }
    /// 自定义 · 珊瑚
    static var tbDimCoral: Color { TimeBankTheme.current.palette.dimensionColor(for: "coral") }
    /// 自定义 · 薄荷
    static var tbDimMint: Color { TimeBankTheme.current.palette.dimensionColor(for: "mint") }
    /// 自定义 · 丹宁蓝
    static var tbDimDenim: Color { TimeBankTheme.current.palette.dimensionColor(for: "denim") }
    /// 自定义 · 灰紫
    static var tbDimMauve: Color { TimeBankTheme.current.palette.dimensionColor(for: "mauve") }

    // ─── Semantic ─────────────────────────────────────────────
    /// 主 CTA / 强调色 = dimParents（产品核心色）
    static var tbPrimary: Color { TimeBankTheme.current.palette.primary }
    /// 警告/删除
    static var tbDanger: Color { TimeBankTheme.current.palette.danger }
    /// 成功
    static var tbSuccess: Color { TimeBankTheme.current.palette.success }

    // Helper for hex init（ChatGPT 写代码时如果项目还没有，请在 Utility 里加这个扩展）
}

// MARK: - Typography

/// 时间银行专用字阶。显示层必须通过这些 Font extension 使用，不得 `.font(.system(size:))` 裸写。
extension Font {
    /// Display XL · 96pt · 维度详情 hero 大数字（视觉锚）
    static var tbDisplayXL: Font { TimeBankTheme.current.typography.display(size: 96) }
    /// Display L · 72pt
    static var tbDisplayL: Font { TimeBankTheme.current.typography.display(size: 72) }
    /// Display M · 48pt · 主页总账户 128 小时
    static var tbDisplayM: Font { TimeBankTheme.current.typography.display(size: 48) }
    /// Display S · 32pt
    static var tbDisplayS: Font { TimeBankTheme.current.typography.display(size: 32) }

    /// 大标题 · 26pt Medium
    static var tbHeadL: Font { TimeBankTheme.current.typography.heading(size: 26) }
    /// 中标题 · 20pt Medium
    static var tbHeadM: Font { TimeBankTheme.current.typography.heading(size: 20) }
    /// 小标题 · 16pt Medium · 维度名 / section label
    static var tbHeadS: Font { TimeBankTheme.current.typography.heading(size: 16) }

    /// 正文 · 15pt Medium
    static var tbBody: Font { TimeBankTheme.current.typography.body(size: 15) }
    /// 次级正文 · 13pt Medium · 时刻笔记摘要
    static var tbBodySm: Font { TimeBankTheme.current.typography.body(size: 13) }

    /// 小字标签 · 12pt Medium · 元信息
    static var tbLabel: Font { TimeBankTheme.current.typography.label(size: 12) }
    /// 英文 label · 11pt uppercase spacing
    static var tbLabelEn: Font { TimeBankTheme.current.typography.label(size: 11) }
}

// MARK: - Spacing

/// 8pt grid
enum TBSpace {
    static var s1: CGFloat { TimeBankTheme.current.metrics.s1 }    // 最小间距
    static var s2: CGFloat { TimeBankTheme.current.metrics.s2 }
    static var s3: CGFloat { TimeBankTheme.current.metrics.s3 }   // 卡片间 gap
    static var s4: CGFloat { TimeBankTheme.current.metrics.s4 }
    static var s5: CGFloat { TimeBankTheme.current.metrics.s5 }   // 卡片内 padding（小）
    static var s6: CGFloat { TimeBankTheme.current.metrics.s6 }   // 卡片内 padding（大）
    static var s7: CGFloat { TimeBankTheme.current.metrics.s7 }
    static var s8: CGFloat { TimeBankTheme.current.metrics.s8 }
    static var s9: CGFloat { TimeBankTheme.current.metrics.s9 }
}

// MARK: - Radius

/// 圆润系统 · 小 12 · 卡片 20-24 · 胶囊 100
enum TBRadius {
    static var sm: CGFloat { TimeBankTheme.current.metrics.radiusSM }   // 输入框 / chip 小
    static var md: CGFloat { TimeBankTheme.current.metrics.radiusMD }   // 按钮 / FormRow
    static var lg: CGFloat { TimeBankTheme.current.metrics.radiusLG }   // 卡片（标准）
    static var xl: CGFloat { TimeBankTheme.current.metrics.radiusXL }   // 大卡片 / 媒体容器
    static var pill: CGFloat { TimeBankTheme.current.metrics.radiusPill } // 胶囊按钮
}

// MARK: - Shadow

/// 温暖柔和阴影（浅色模式专用）
enum TBShadow {
    /// 卡片 resting · 0/4/12 rgba(232,154,124,0.12) + 0/2/4 rgba(58,46,36,0.04)
    static func soft<V: View>(for view: V) -> some View {
        chrome(for: view, multiplier: 1)
    }

    /// 卡片 elevated
    static func medium<V: View>(for view: V) -> some View {
        chrome(for: view, multiplier: 1.28)
    }

    /// Modal / Sheet lift
    static func lift<V: View>(for view: V) -> some View {
        chrome(for: view, multiplier: 1.72)
    }

    private static func chrome<V: View>(for view: V, multiplier: CGFloat) -> some View {
        let theme = TimeBankTheme.current
        let shadowOpacity = theme.style.usesShadow ? theme.style.shadowOpacity * Double(multiplier) : 0

        return view
            .overlay {
                RoundedRectangle(cornerRadius: TBRadius.lg, style: .continuous)
                    .stroke(theme.style.cardBorderColor, lineWidth: theme.style.cardBorderWidth)
            }
            .shadow(
                color: theme.palette.shadowTint.opacity(shadowOpacity),
                radius: theme.style.shadowRadius * multiplier,
                x: 0,
                y: theme.style.shadowYOffset * multiplier
            )
            .shadow(
                color: theme.palette.ink.opacity(shadowOpacity * 0.28),
                radius: max(2, theme.style.shadowRadius * 0.32),
                x: 0,
                y: max(1, theme.style.shadowYOffset * 0.28)
            )
    }
}

// MARK: - Theme Chrome

enum TBThemedSurfaceRole {
    case card
    case row
    case inset
    case media
}

struct TBThemedSurfaceModifier: ViewModifier {
    let role: TBThemedSurfaceRole

    func body(content: Content) -> some View {
        let theme = TimeBankTheme.current
        let radius = cornerRadius(for: theme)
        let shadowOpacity = theme.style.usesShadow && role != .inset ? theme.style.shadowOpacity : 0

        content
            .background(backgroundColor(for: theme))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(borderColor(for: theme), lineWidth: borderWidth(for: theme))
            }
            .overlay(alignment: .topLeading) {
                themeAccent(for: theme, radius: radius)
            }
            .shadow(
                color: theme.palette.shadowTint.opacity(shadowOpacity),
                radius: theme.style.shadowRadius,
                x: 0,
                y: theme.style.shadowYOffset
            )
    }

    private func backgroundColor(for theme: TimeBankTheme) -> Color {
        switch role {
        case .card, .row:
            return theme.palette.surface
        case .inset:
            return theme.palette.background2
        case .media:
            return theme.palette.surfaceElevated
        }
    }

    private func borderColor(for theme: TimeBankTheme) -> Color {
        switch role {
        case .inset:
            return theme.palette.hairline.opacity(theme.kind == .gallery || theme.kind == .localRemoteEditorial ? 1 : 0.55)
        case .media:
            return theme.style.cardBorderColor.opacity(theme.kind == .gallery || theme.kind == .localRemoteEditorial ? 1 : 0.72)
        case .card, .row:
            return theme.style.cardBorderColor
        }
    }

    private func borderWidth(for theme: TimeBankTheme) -> CGFloat {
        switch role {
        case .row:
            return max(theme.style.cardBorderWidth, theme.kind == .gallery || theme.kind == .localRemoteEditorial ? 1 : 0.75)
        case .media:
            return max(theme.style.cardBorderWidth, 1)
        case .card, .inset:
            return theme.style.cardBorderWidth
        }
    }

    private func cornerRadius(for theme: TimeBankTheme) -> CGFloat {
        switch role {
        case .row:
            return theme.kind == .zenSongciTea ? TBRadius.xl : TBRadius.md
        case .inset:
            return TBRadius.md
        case .media:
            return TBRadius.lg
        case .card:
            return TBRadius.lg
        }
    }

    @ViewBuilder
    private func themeAccent(for theme: TimeBankTheme, radius: CGFloat) -> some View {
        switch theme.kind {
        case .artBook:
            Rectangle()
                .fill(theme.palette.primary)
                .frame(width: role == .row ? 3 : 4)
                .padding(.vertical, role == .row ? TBSpace.s3 : TBSpace.s4)
                .clipShape(RoundedRectangle(cornerRadius: 1.5, style: .continuous))

        case .gallery:
            Rectangle()
                .fill(theme.palette.borderStrong)
                .frame(height: role == .inset ? 0 : 2)

        case .localRemoteEditorial:
            VStack(spacing: 0) {
                Rectangle()
                    .fill(theme.palette.borderStrong)
                    .frame(height: role == .inset ? 0 : 1)
                Rectangle()
                    .fill(theme.palette.hairline.opacity(0.48))
                    .frame(height: role == .inset ? 0 : 1)
            }

        case .zenSongciTea:
            EmptyView()

        case .magazineApartamento:
            EmptyView()
        }
    }
}

extension View {
    func tbThemedSurface(_ role: TBThemedSurfaceRole = .card) -> some View {
        modifier(TBThemedSurfaceModifier(role: role))
    }
}

struct TBPrimaryActionButtonStyle: ButtonStyle {
    var fillsWidth = false

    func makeBody(configuration: Configuration) -> some View {
        let theme = TimeBankTheme.current
        configuration.label
            .font(.tbBody)
            .foregroundStyle(theme.palette.surface)
            .labelStyle(.titleAndIcon)
            .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: 44)
            .padding(.horizontal, TBSpace.s5)
            .background(theme.palette.primary.opacity(configuration.isPressed ? 0.78 : 1))
            .clipShape(RoundedRectangle(cornerRadius: actionRadius(for: theme), style: .continuous))
            .opacity(configuration.isPressed ? 0.9 : 1)
    }

    private func actionRadius(for theme: TimeBankTheme) -> CGFloat {
        switch theme.kind {
        case .gallery, .localRemoteEditorial:
            return 0
        default:
            return TBRadius.pill
        }
    }
}

struct TBSecondaryActionButtonStyle: ButtonStyle {
    var isDestructive = false
    var fillsWidth = false

    func makeBody(configuration: Configuration) -> some View {
        let theme = TimeBankTheme.current
        let foreground = isDestructive ? theme.palette.danger : theme.palette.ink

        configuration.label
            .font(.tbBodySm)
            .foregroundStyle(foreground)
            .labelStyle(.titleAndIcon)
            .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: 44)
            .padding(.horizontal, TBSpace.s4)
            .background(theme.palette.surface.opacity(configuration.isPressed ? 0.68 : 1))
            .clipShape(RoundedRectangle(cornerRadius: actionRadius(for: theme), style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: actionRadius(for: theme), style: .continuous)
                    .stroke(isDestructive ? theme.palette.danger.opacity(0.35) : theme.style.cardBorderColor, lineWidth: theme.style.cardBorderWidth)
            }
    }

    private func actionRadius(for theme: TimeBankTheme) -> CGFloat {
        switch theme.kind {
        case .gallery, .localRemoteEditorial:
            return 0
        default:
            return TBRadius.pill
        }
    }
}

// MARK: - Motion

/// 动效 timing + curve
enum TBAnimation {
    /// 按钮按下 · 150ms ease-out
    static let microPress: Animation = .easeOut(duration: 0.15)
    /// 页面切换 / 列表刷新 · spring 0.5/0.85
    static let transition: Animation = .spring(response: 0.5, dampingFraction: 0.85)
    /// 签名动效：存入成功光点飞行 · spring 更弹一点
    static let heroMoment: Animation = .spring(response: 0.5, dampingFraction: 0.7)
}

// MARK: - Dimension Color Mapping

/// 根据 `Dimension.colorKey` 获取对应的维度色（UI 文案层叫"时间账户色"）。
enum DimensionPalette {
    static let supportedColorKeys = [
        "rose", "warm", "lavender", "sky", "sage", "peach",
        "coral", "mint", "denim", "mauve"
    ]

    static func color(for dimension: Dimension) -> Color {
        color(forColorKey: dimension.colorKey)
    }

    static func color(forColorKey key: String) -> Color {
        TimeBankTheme.current.palette.dimensionColor(for: key)
    }

    static func soft(for dimension: Dimension) -> Color {
        color(for: dimension).opacity(TimeBankTheme.current.style.dimensionSoftOpacity)
    }

    static func soft(forColorKey key: String) -> Color {
        color(forColorKey: key).opacity(TimeBankTheme.current.style.dimensionSoftOpacity)
    }

    /// V1.0 兼容入口：仅按保留 id fallback。自定义账户应使用 `color(for:)`。
    static func color(for id: String) -> Color {
        switch id {
        case "parents": return .tbDimParents
        case "kids":    return .tbDimKids
        case "partner": return .tbDimPartner
        case "sport":   return .tbDimSport
        case "create":  return .tbDimCreate
        case "free":    return .tbDimFree
        case "lifespan": return .tbPrimary  // 时间余额用主色
        default:        return .tbInk3      // 自定义/未知 → 灰
        }
    }

    /// V1.0 兼容入口：仅按保留 id fallback。自定义账户应使用 `soft(for:)`。
    static func soft(for id: String) -> Color {
        color(for: id).opacity(TimeBankTheme.current.style.dimensionSoftOpacity)
    }
}

// MARK: - Color hex init helper (如果项目没有，请加到 Utility/Color+Extensions.swift)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8)  / 255
        let b = Double(rgb & 0x0000FF)         / 255
        self.init(red: r, green: g, blue: b)
    }
}
