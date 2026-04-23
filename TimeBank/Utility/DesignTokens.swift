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

// MARK: - Colors

extension Color {
    // ─── Backgrounds ──────────────────────────────────────────
    /// 主背景 · 奶咖色
    static let tbBg        = Color(hex: "#FBF4EC")
    /// 卡片背景 · 稍深一档的米黄
    static let tbBg2       = Color(hex: "#F5EADD")
    /// Hover / active 态
    static let tbBg3       = Color(hex: "#EFE0CE")
    /// 白色悬浮卡片（最亮层）
    static let tbSurface   = Color(hex: "#FFFFFF")

    // ─── Text ─────────────────────────────────────────────────
    /// 深巧克力主文字
    static let tbInk       = Color(hex: "#3A2E24")
    /// 次文字
    static let tbInk2      = Color(hex: "#6B5A47")
    /// 占位 / 更次文字
    static let tbInk3      = Color(hex: "#A8957C")
    /// 细线 · 分隔
    static let tbHair      = Color(hex: "#E8D9C4")

    // ─── Time Account Colors (6 内置时间账户) ─────────────────
    // 工程类名 Dimension，UI 文案「时间账户」
    /// 陪父母 · 珊瑚橘
    static let tbDimParents = Color(hex: "#E89A7C")
    /// 陪孩子 · 金黄
    static let tbDimKids    = Color(hex: "#E8C47C")
    /// 陪伴侣 · 薰衣草紫
    static let tbDimPartner = Color(hex: "#C29DD4")
    /// 创造 · 晨雾蓝
    static let tbDimCreate  = Color(hex: "#A8C4D9")
    /// 运动 · 薄荷绿
    static let tbDimSport   = Color(hex: "#8EC7A8")
    /// 自由 · 蜜桃
    static let tbDimFree    = Color(hex: "#D6B89A")

    // ─── Semantic ─────────────────────────────────────────────
    /// 主 CTA / 强调色 = dimParents（产品核心色）
    static let tbPrimary   = Color(hex: "#E89A7C")
    /// 警告/删除
    static let tbDanger    = Color(hex: "#C66B5A")
    /// 成功
    static let tbSuccess   = Color(hex: "#8EC7A8")

    // Helper for hex init（ChatGPT 写代码时如果项目还没有，请在 Utility 里加这个扩展）
}

// MARK: - Typography

/// 时间银行专用字阶。显示层必须通过这些 Font extension 使用，不得 `.font(.system(size:))` 裸写。
extension Font {
    /// Display XL · 96pt · 维度详情 hero 大数字（视觉锚）
    static let tbDisplayXL  = Font.custom("DM Sans", size: 96).weight(.semibold)
    /// Display L · 72pt
    static let tbDisplayL   = Font.custom("DM Sans", size: 72).weight(.semibold)
    /// Display M · 48pt · 主页总账户 128 小时
    static let tbDisplayM   = Font.custom("DM Sans", size: 48).weight(.semibold)
    /// Display S · 32pt
    static let tbDisplayS   = Font.custom("DM Sans", size: 32).weight(.semibold)

    /// 大标题 · 26pt Medium
    static let tbHeadL      = Font.custom("PingFang SC", size: 26).weight(.medium)
    /// 中标题 · 20pt Medium
    static let tbHeadM      = Font.custom("PingFang SC", size: 20).weight(.medium)
    /// 小标题 · 16pt Medium · 维度名 / section label
    static let tbHeadS      = Font.custom("PingFang SC", size: 16).weight(.medium)

    /// 正文 · 15pt Medium
    static let tbBody       = Font.custom("PingFang SC", size: 15).weight(.medium)
    /// 次级正文 · 13pt Medium · 时刻笔记摘要
    static let tbBodySm     = Font.custom("PingFang SC", size: 13).weight(.medium)

    /// 小字标签 · 12pt Medium · 元信息
    static let tbLabel      = Font.custom("PingFang SC", size: 12).weight(.medium)
    /// 英文 label · 11pt uppercase spacing
    static let tbLabelEn    = Font.custom("DM Sans", size: 11).weight(.medium)
}

// MARK: - Spacing

/// 8pt grid
enum TBSpace {
    static let s1: CGFloat = 4    // 最小间距
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12   // 卡片间 gap
    static let s4: CGFloat = 16
    static let s5: CGFloat = 20   // 卡片内 padding（小）
    static let s6: CGFloat = 24   // 卡片内 padding（大）
    static let s7: CGFloat = 32
    static let s8: CGFloat = 40
    static let s9: CGFloat = 56
}

// MARK: - Radius

/// 圆润系统 · 小 12 · 卡片 20-24 · 胶囊 100
enum TBRadius {
    static let sm: CGFloat  = 12   // 输入框 / chip 小
    static let md: CGFloat  = 20   // 按钮 / FormRow
    static let lg: CGFloat  = 24   // 卡片（标准）
    static let xl: CGFloat  = 32   // 大卡片 / 媒体容器
    static let pill: CGFloat = 100 // 胶囊按钮
}

// MARK: - Shadow

/// 温暖柔和阴影（浅色模式专用）
enum TBShadow {
    /// 卡片 resting · 0/4/12 rgba(232,154,124,0.12) + 0/2/4 rgba(58,46,36,0.04)
    static func soft<V: View>(for view: V) -> some View {
        view
            .shadow(color: Color(hex: "#E89A7C").opacity(0.12), radius: 12, x: 0, y: 4)
            .shadow(color: Color(hex: "#3A2E24").opacity(0.04), radius: 4, x: 0, y: 2)
    }

    /// 卡片 elevated
    static func medium<V: View>(for view: V) -> some View {
        view
            .shadow(color: Color(hex: "#E89A7C").opacity(0.18), radius: 20, x: 0, y: 6)
            .shadow(color: Color(hex: "#3A2E24").opacity(0.06), radius: 6, x: 0, y: 2)
    }

    /// Modal / Sheet lift
    static func lift<V: View>(for view: V) -> some View {
        view
            .shadow(color: Color(hex: "#E89A7C").opacity(0.22), radius: 32, x: 0, y: 12)
            .shadow(color: Color(hex: "#3A2E24").opacity(0.08), radius: 12, x: 0, y: 4)
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

/// 根据 `Dimension.id` 获取对应的维度色（UI 文案层叫"时间账户色"）
enum DimensionPalette {
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

    /// 轻色版本（卡片背景/chip 背景用）
    static func soft(for id: String) -> Color {
        color(for: id).opacity(0.18)
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
