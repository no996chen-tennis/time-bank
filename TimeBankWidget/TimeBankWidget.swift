import AppIntents
import SwiftUI
import UIKit
import WidgetKit

// MARK: - 一键存入（iOS 17 交互式 widget · 不打开 App）
//
// 把"此刻"写进 App Group 队列 + 乐观翻转快照"今日已存入" + reload，让 widget 即时变 ✦。
// 真正的 Moment 由 App 回到前台时 drain 队列建立（见 MomentStore.drainQuickDepositQueue）。
struct QuickDepositIntent: AppIntent {
    static var title: LocalizedStringResource = "存入此刻"
    static var description = IntentDescription("把此刻存下来，不用打开 App。")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let request = QuickDepositRequest(id: UUID(), happenedAt: Date(), title: "此刻")
        QuickDepositQueueStore.append(request)

        if var snapshot = TimeBankWidgetSnapshotStore.load() {
            snapshot.todayDeposited = true
            try? TimeBankWidgetSnapshotStore.write(snapshot)
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - 主题（跟随 App 内用户选的主题）
//
// widget 进程读不到 App 的 UserDefaults，主题通过快照字段 `themeKind` 传过来
// （App 切主题时 RootView 会重写快照并 reloadTimelines）。
// 五套取色与 TimeBank/Utility/DesignTokens.swift 完全对齐；缺省回落 magazineApartamento。
private struct WT {
    let ink: Color
    let ink2: Color
    let surface: Color
    let bgTop: Color
    let bgBottom: Color
    let gold: Color
    /// 状态/按钮强调色。localRemote 主题 primary 是纯墨色，改用其 danger 红保证可识别。
    let accent: Color
    let cardFill: Color
    let chipFill: Color
    /// 内卡圆角：杂志/禅意圆润，艺廊/双栏方正。
    let radius: CGFloat
    /// 按钮圆角：软主题胶囊，方主题小圆角矩形。
    let controlRadius: CGFloat
    let dimension: [String: Color]

    func color(_ key: String) -> Color { dimension[key] ?? ink2 }

    static func hex(_ value: UInt) -> Color {
        Color(
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0
        )
    }

    static func theme(_ rawValue: String?) -> WT {
        switch rawValue {
        case "artBook": return .artBook
        case "gallery": return .gallery
        case "zenSongciTea": return .zen
        case "localRemoteEditorial": return .localRemote
        default: return .magazine
        }
    }

    static let magazine = WT(
        ink: hex(0x25231F), ink2: hex(0x716A60),
        surface: hex(0xFAF6ED), bgTop: hex(0xFAF6ED), bgBottom: hex(0xEDE3D5),
        gold: hex(0xB78242), accent: hex(0x9D3F2F),
        cardFill: Color.white.opacity(0.46), chipFill: Color.black.opacity(0.05),
        radius: 14, controlRadius: 100,
        dimension: [
            "rose": hex(0x9D3F2F), "warm": hex(0xB78242), "lavender": hex(0x6B5774),
            "sky": hex(0x172B48), "sage": hex(0x243D32), "peach": hex(0xC8917E),
            "coral": hex(0xB45A4A), "mint": hex(0x4E7765), "denim": hex(0x315174),
            "mauve": hex(0x8E6178)
        ]
    )

    static let artBook = WT(
        ink: hex(0x17130F), ink2: hex(0x4D4135),
        surface: hex(0xFBF6E9), bgTop: hex(0xFBF6E9), bgBottom: hex(0xEEE2CB),
        gold: hex(0xA9792B), accent: hex(0x7F1718),
        cardFill: Color.white.opacity(0.46), chipFill: Color.black.opacity(0.05),
        radius: 8, controlRadius: 8,
        dimension: [
            "rose": hex(0x7F1718), "warm": hex(0xA9792B), "lavender": hex(0x5E4B66),
            "sky": hex(0x1D3446), "sage": hex(0x2F4D42), "peach": hex(0xA66F4D),
            "coral": hex(0x9A3F35), "mint": hex(0x3E6E58), "denim": hex(0x2C5367),
            "mauve": hex(0x77505C)
        ]
    )

    static let gallery = WT(
        ink: hex(0x050505), ink2: hex(0x454545),
        surface: hex(0xFFFFFF), bgTop: hex(0xFFFFFF), bgBottom: hex(0xEFEFEB),
        gold: hex(0xB45F00), accent: hex(0xD93600),
        cardFill: Color.black.opacity(0.045), chipFill: Color.black.opacity(0.05),
        radius: 3, controlRadius: 4,
        dimension: [
            "rose": hex(0xD93600), "warm": hex(0xB45F00), "lavender": hex(0x6B52B8),
            "sky": hex(0x0064D2), "sage": hex(0x147A49), "peach": hex(0xB84A35),
            "coral": hex(0xD93600), "mint": hex(0x008C72), "denim": hex(0x163F9F),
            "mauve": hex(0x9F3F75)
        ]
    )

    static let zen = WT(
        ink: hex(0x27302C), ink2: hex(0x5E6961),
        surface: hex(0xF8F4EA), bgTop: hex(0xF8F4EA), bgBottom: hex(0xEEE9DF),
        gold: hex(0xB99A5F), accent: hex(0x9F3529),
        cardFill: Color.white.opacity(0.5), chipFill: Color.black.opacity(0.045),
        radius: 16, controlRadius: 100,
        dimension: [
            "rose": hex(0xA5685E), "warm": hex(0xB99A5F), "lavender": hex(0x817189),
            "sky": hex(0x5B7D88), "sage": hex(0x6F866D), "peach": hex(0x916B45),
            "coral": hex(0xC66D59), "mint": hex(0xA8BBB1), "denim": hex(0x4F6F86),
            "mauve": hex(0x9A6876)
        ]
    )

    static let localRemote = WT(
        ink: hex(0x141414), ink2: hex(0x4F4A43),
        surface: hex(0xFBFAF6), bgTop: hex(0xFBFAF6), bgBottom: hex(0xF8F4EB),
        gold: hex(0xA06B2C), accent: hex(0xA8342B),
        cardFill: Color.black.opacity(0.04), chipFill: Color.black.opacity(0.05),
        radius: 3, controlRadius: 4,
        dimension: [
            "rose": hex(0xA8342B), "warm": hex(0xA06B2C), "lavender": hex(0x675B82),
            "sky": hex(0x234B70), "sage": hex(0x2E6B55), "peach": hex(0xA96E57),
            "coral": hex(0xB6463D), "mint": hex(0x2B8066), "denim": hex(0x243F78),
            "mauve": hex(0x884F6B)
        ]
    )
}

// MARK: - 文案池（与时间账户无关的通用句，来自 文案系统.md 今日觉知池 · 观察式）
private enum WidgetCopy {
    /// 余额一句话面（不绑定用户数据）。
    static let balanceLines = [
        "被感受过的时间，永远属于你。",
        "今天的光，刚好落在今天。",
        "被你留下来的一小段，不会再走了。",
        "不必记得所有，留下一两件就好。",
        "一些时间适合什么都不做。"
    ]

    /// 冷启动（0 条记忆）邀请面。
    static let invitationLines = [
        "过去 24 小时有什么值得存下来的？",
        "最近的哪一天，你想再经历一次？",
        "今天也算。",
        "现在这一刻，以后会是「过去」。"
    ]

    /// 今日存入状态（外显主标签，蔚来"未签到"模式：一眼看到状态）。
    static func statusLabel(deposited: Bool) -> String {
        deposited ? "今天已存入 ✦" : "今日未存入"
    }

    /// 状态下的温柔一句（随一天推移变化，timeline 预排，零刷新成本）。
    static func statusLine(date: Date, deposited: Bool) -> String {
        if deposited { return "今天的瞬间，已经在账户里了。" }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = Double(comps.hour ?? 12) + Double(comps.minute ?? 0) / 60.0
        switch hour {
        case ..<5: return "新的一天。"
        case ..<18: return "今天也可以存下一段。"
        case ..<21.5: return "天黑了，今天有什么想留下的？"
        default: return "睡前，留一句给今天？"
        }
    }
}

// MARK: - 轮换面（状态已常驻外显，轮换面只负责"内容"：记忆 / 明信片 / 觉知句）
private enum WidgetFace: Equatable {
    case memory(Int)       // index into snapshot.memories
    case postcard(Int)     // index into developed memories
    case balanceLine(Int)  // index into WidgetCopy.balanceLines
    case invitation(Int)   // 冷启动 index into WidgetCopy.invitationLines
}

/// 渲染一个面所需的最小内容。
private struct FaceContent {
    var kicker: String
    var line: String
    var accentColorKey: String?
    var isMemory: Bool
    var thumbFile: String? = nil
}

private func faceContent(face: WidgetFace, snapshot: TimeBankWidgetSnapshot) -> FaceContent {
    switch face {
    case .memory(let i):
        guard snapshot.memories.indices.contains(i) else {
            return faceContent(face: .balanceLine(0), snapshot: snapshot)
        }
        let m = snapshot.memories[i]
        return FaceContent(
            kicker: m.isAnniversary ? "那年今日" : daysAgoLabel(m.daysAgo),
            line: m.title,
            accentColorKey: m.colorKey,
            isMemory: true,
            thumbFile: m.thumbFile
        )
    case .postcard(let i):
        guard snapshot.memories.indices.contains(i) else {
            return faceContent(face: .balanceLine(0), snapshot: snapshot)
        }
        let m = snapshot.memories[i]
        return FaceContent(
            kicker: "刚冲洗好",
            line: m.title,
            accentColorKey: m.colorKey,
            isMemory: true,
            thumbFile: m.thumbFile
        )
    case .balanceLine(let i):
        return FaceContent(
            kicker: "",
            line: WidgetCopy.balanceLines[i % WidgetCopy.balanceLines.count],
            accentColorKey: nil,
            isMemory: false
        )
    case .invitation(let i):
        return FaceContent(
            kicker: "",
            line: WidgetCopy.invitationLines[i % WidgetCopy.invitationLines.count],
            accentColorKey: nil,
            isMemory: false
        )
    }
}

private func daysAgoLabel(_ days: Int) -> String {
    if days <= 0 { return "今天" }
    if days == 1 { return "昨天" }
    if days >= 360 { return "约一年前" }
    return "\(days) 天前"
}

/// 确定性挑面：冷启动用邀请池；否则记忆 / 明信片 / 觉知句轮换（每 30 分钟换一面）。
private func pickFace(index i: Int, snapshot: TimeBankWidgetSnapshot) -> WidgetFace {
    let cold = snapshot.storedMomentCountTotal == 0 || snapshot.memories.isEmpty
    if cold {
        return .invitation(i)
    }

    let developed = snapshot.memories.enumerated().filter { $0.element.developed }.map { $0.offset }
    let memCount = snapshot.memories.count

    switch i % 3 {
    case 0:
        return .memory(i % memCount)
    case 1:
        if developed.isEmpty { return .balanceLine(i) }
        return .postcard(developed[(i / 3) % developed.count])
    default:
        return .balanceLine(i)
    }
}

// MARK: - Timeline
struct TimeBankWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: TimeBankWidgetSnapshot
    fileprivate let face: WidgetFace

    fileprivate init(date: Date, snapshot: TimeBankWidgetSnapshot, face: WidgetFace = .balanceLine(0)) {
        self.date = date
        self.snapshot = snapshot
        self.face = face
    }
}

struct TimeBankWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimeBankWidgetEntry {
        TimeBankWidgetEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (TimeBankWidgetEntry) -> Void) {
        let snapshot = loadSnapshot()
        completion(TimeBankWidgetEntry(date: .now, snapshot: snapshot, face: pickFace(index: 0, snapshot: snapshot)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimeBankWidgetEntry>) -> Void) {
        let snapshot = loadSnapshot()
        let now = Date()
        let calendar = Calendar.current

        // 预排 48 条 entry（每 30 分钟一条，覆盖未来 ~24h）。系统按时间自动切换，零刷新预算成本。
        var entries: [TimeBankWidgetEntry] = []
        for i in 0..<48 {
            let date = calendar.date(byAdding: .minute, value: i * 30, to: now) ?? now
            let face = pickFace(index: i, snapshot: snapshot)
            entries.append(TimeBankWidgetEntry(date: date, snapshot: snapshot, face: face))
        }

        // 每天凌晨 4 点重排：重置今日状态机 + 换一批记忆。
        completion(Timeline(entries: entries, policy: .after(nextRefreshDate(after: now))))
    }

    private func nextRefreshDate(after now: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 4
        components.minute = 0
        let todayFour = calendar.date(from: components) ?? now
        if todayFour > now { return todayFour }
        return calendar.date(byAdding: .day, value: 1, to: todayFour) ?? now.addingTimeInterval(6 * 3600)
    }

    private func loadSnapshot() -> TimeBankWidgetSnapshot {
        TimeBankWidgetSnapshotStore.load() ?? .sample
    }
}

@main
struct TimeBankWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimeBankWidget()
    }
}

struct TimeBankWidget: Widget {
    let kind = "TimeBankWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeBankWidgetProvider()) { entry in
            TimeBankWidgetView(entry: entry)
        }
        .configurationDisplayName("时间银行")
        .description("今年还剩多少周、今天存了没，和一段被留下的时间。")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

private struct TimeBankWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TimeBankWidgetEntry

    private var wt: WT { WT.theme(entry.snapshot.themeKind) }

    var body: some View {
        switch family {
        case .accessoryRectangular:
            LockScreenWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        case .systemSmall:
            HomeScreenSmallWidgetView(entry: entry)
                .containerBackground(widgetBackground, for: .widget)
        default:
            HomeScreenMediumWidgetView(entry: entry)
                .containerBackground(widgetBackground, for: .widget)
        }
    }

    private var widgetBackground: some ShapeStyle {
        LinearGradient(
            colors: [wt.bgTop, wt.bgBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - 状态 + 按钮（蔚来"未签到"模式的核心组件）

/// 今日状态行：色点 + "今日未存入 / 今天已存入 ✦"。
private struct TodayStatusLabel: View {
    let deposited: Bool
    let wt: WT
    var size: CGFloat = 13

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(deposited ? wt.gold : wt.accent)
                .frame(width: 6, height: 6)
            Text(WidgetCopy.statusLabel(deposited: deposited))
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(deposited ? wt.gold : wt.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

/// 「存入此刻」实心按钮（App Intent，不打开 App）。
private struct DepositButton: View {
    let wt: WT
    var fillsWidth = false

    var body: some View {
        Button(intent: QuickDepositIntent()) {
            HStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("存入此刻")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(wt.surface)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .background(wt.accent, in: RoundedRectangle(cornerRadius: wt.controlRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 锁屏 accessoryRectangular
private struct LockScreenWidgetView: View {
    let entry: TimeBankWidgetEntry

    private var snapshot: TimeBankWidgetSnapshot { entry.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(WidgetCopy.statusLabel(deposited: snapshot.todayDeposited))
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 4)
                Text("\(snapshot.yearBalanceWeeks)周")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Text(secondLine)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var secondLine: String {
        // 第二行优先端一条记忆，否则状态机的温柔一句。
        if let memory = snapshot.memories.first {
            let prefix = memory.isAnniversary ? "那年今日 · " : "\(daysAgoLabel(memory.daysAgo)) · "
            return prefix + memory.title
        }
        return WidgetCopy.statusLine(date: entry.date, deposited: snapshot.todayDeposited)
    }
}

// MARK: - 桌面 systemSmall（状态优先：一眼看到"今日未存入"+ 一键按钮）
private struct HomeScreenSmallWidgetView: View {
    let entry: TimeBankWidgetEntry

    private var snapshot: TimeBankWidgetSnapshot { entry.snapshot }
    private var wt: WT { WT.theme(snapshot.themeKind) }
    private var content: FaceContent { faceContent(face: entry.face, snapshot: snapshot) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("今年余额")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(wt.ink2)
                Spacer(minLength: 4)
                Text("\(snapshot.yearBalanceWeeks)周")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(wt.ink)
            }

            Spacer(minLength: 5)

            TodayStatusLabel(deposited: snapshot.todayDeposited, wt: wt, size: 15)

            Text(snapshot.todayDeposited ? content.line : WidgetCopy.statusLine(date: entry.date, deposited: false))
                .font(.system(size: 10.5, weight: .regular))
                .foregroundStyle(wt.ink2)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .padding(.top, 3)

            Spacer(minLength: 6)

            if snapshot.todayDeposited {
                Text("\(snapshot.storedMomentCountTotal) 个瞬间 · 都还在")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(wt.ink2)
            } else {
                DepositButton(wt: wt, fillsWidth: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - 桌面 systemMedium（余额 + 状态/按钮 + 轮换面 + 3 账户）
private struct HomeScreenMediumWidgetView: View {
    let entry: TimeBankWidgetEntry

    private var snapshot: TimeBankWidgetSnapshot { entry.snapshot }
    private var wt: WT { WT.theme(snapshot.themeKind) }
    private var dimensions: [TimeBankWidgetDimensionSnapshot] { Array(snapshot.dimensions.prefix(3)) }
    private var content: FaceContent { faceContent(face: entry.face, snapshot: snapshot) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("今年余额")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(wt.ink2)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(snapshot.yearBalanceWeeks)")
                            .font(.system(size: 27, weight: .semibold, design: .rounded))
                            .foregroundStyle(wt.ink)
                            .contentTransition(.numericText())
                        Text("周")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(wt.ink2)
                    }
                }

                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 6) {
                    TodayStatusLabel(deposited: snapshot.todayDeposited, wt: wt)
                    if snapshot.todayDeposited {
                        Text("\(snapshot.storedMomentCountTotal) 个瞬间 · 都还在")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(wt.ink2)
                    } else {
                        DepositButton(wt: wt)
                    }
                }
            }

            FaceLine(content: content, wt: wt)

            HStack(spacing: 7) {
                ForEach(dimensions) { dimension in
                    DimensionMiniCard(dimension: dimension, wt: wt)
                }
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - 轮换面行（单行：缩略图/色点 + kicker + 内容）
private struct FaceLine: View {
    let content: FaceContent
    let wt: WT

    var body: some View {
        HStack(spacing: 6) {
            if let image = thumbImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: max(4, wt.radius * 0.4), style: .continuous))
            } else if let key = content.accentColorKey {
                Circle().fill(wt.color(key)).frame(width: 6, height: 6)
            }

            if content.kicker.isEmpty == false {
                Text(content.kicker)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(content.accentColorKey.map(wt.color) ?? wt.ink2)
                    .lineLimit(1)
                    .fixedSize()
            }

            Text(content.line)
                .font(.system(size: 12, weight: content.isMemory ? .semibold : .regular))
                .foregroundStyle(content.isMemory ? wt.ink : wt.ink2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
    }

    private var thumbImage: UIImage? {
        guard let name = content.thumbFile,
              let dir = TimeBankWidgetSnapshotStore.thumbsDirectoryURL()
        else {
            return nil
        }
        return UIImage(contentsOfFile: dir.appendingPathComponent(name).path)
    }
}

private struct DimensionMiniCard: View {
    let dimension: TimeBankWidgetDimensionSnapshot
    let wt: WT

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Circle()
                    .fill(wt.color(dimension.colorKey))
                    .frame(width: 6, height: 6)
                Text(dimension.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(wt.ink2)
                    .lineLimit(1)
            }

            Text(hoursShort(dimension.yearConsumeHours))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(wt.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.74)

            Text(dimension.subtitle)
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(wt.ink2)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(wt.cardFill, in: RoundedRectangle(cornerRadius: wt.radius, style: .continuous))
    }
}

private func hoursShort(_ hours: Double) -> String {
    let rounded = max(0, Int(hours.rounded()))
    if rounded < 10_000 {
        return "\(rounded.formatted(.number.grouping(.automatic)))h"
    }
    let wan = Double(rounded) / 10_000
    if wan < 10 {
        return "\(String(format: "%.1f", wan))万h"
    }
    return "\(Int(wan.rounded()))万h"
}

#Preview(as: .systemSmall) {
    TimeBankWidget()
} timeline: {
    TimeBankWidgetEntry(date: .now, snapshot: .sample, face: .memory(0))
}

#Preview(as: .systemMedium) {
    TimeBankWidget()
} timeline: {
    TimeBankWidgetEntry(date: .now, snapshot: .sample, face: .memory(0))
    TimeBankWidgetEntry(date: .now, snapshot: .sample, face: .balanceLine(0))
}

#Preview(as: .accessoryRectangular) {
    TimeBankWidget()
} timeline: {
    TimeBankWidgetEntry(date: .now, snapshot: .sample)
}
