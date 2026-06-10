import AppIntents
import SwiftUI
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

// MARK: - 设计 token（widget 进程内的单一配色来源）
//
// widget target 不含 DesignTokens.swift（且 DesignTokens 依赖 Dimension，整体引入会依赖爆炸）。
// 这里内建一份与 DesignTokens "magazineApartamento" 主题**完全对齐**的取色表，
// 消除散落在视图里的 Color(red:…) 硬编码。真源见 TimeBank/Utility/DesignTokens.swift 的 magazine 调色板。
// widget 进程读不到用户选的主题（UserDefaults 不共享），统一回落到 App 默认主题，视觉一致。
private enum WT {
    static func hex(_ value: UInt) -> Color {
        Color(
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0
        )
    }

    static let ink = hex(0x25231F)
    static let ink2 = hex(0x716A60)
    static let surface = hex(0xFAF6ED)
    static let bg = hex(0xF2E7D5)
    static let bg2 = hex(0xE2D3C2)
    static let gold = hex(0xB78242) // = magazine "warm"
    static let primary = hex(0x9D3F2F) // = magazine "rose"

    private static let dimension: [String: Color] = [
        "rose": hex(0x9D3F2F),
        "warm": hex(0xB78242),
        "lavender": hex(0x6B5774),
        "sky": hex(0x172B48),
        "sage": hex(0x243D32),
        "peach": hex(0xC8917E),
        "coral": hex(0xB45A4A),
        "mint": hex(0x4E7765),
        "denim": hex(0x315174),
        "mauve": hex(0x8E6178)
    ]

    static func color(_ key: String) -> Color { dimension[key] ?? ink2 }

    static let cardFill = Color.white.opacity(0.42)
    static let chipFill = Color.black.opacity(0.055)
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

    /// 今日存入状态机（确定性时间函数，timeline 预排，零刷新成本）。
    static func todayStatus(date: Date, deposited: Bool) -> String {
        if deposited { return "今天已存入 ✦" }
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

// MARK: - 轮换面
private enum WidgetFace: Equatable {
    case todayStatus
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
}

private func faceContent(face: WidgetFace, snapshot: TimeBankWidgetSnapshot, date: Date) -> FaceContent {
    switch face {
    case .todayStatus:
        return FaceContent(
            kicker: "今日",
            line: WidgetCopy.todayStatus(date: date, deposited: snapshot.todayDeposited),
            accentColorKey: nil,
            isMemory: false
        )
    case .memory(let i):
        guard snapshot.memories.indices.contains(i) else {
            return faceContent(face: .balanceLine(0), snapshot: snapshot, date: date)
        }
        let m = snapshot.memories[i]
        return FaceContent(
            kicker: m.isAnniversary ? "那年今日" : daysAgoLabel(m.daysAgo),
            line: m.title,
            accentColorKey: m.colorKey,
            isMemory: true
        )
    case .postcard(let i):
        guard snapshot.memories.indices.contains(i) else {
            return faceContent(face: .balanceLine(0), snapshot: snapshot, date: date)
        }
        let m = snapshot.memories[i]
        return FaceContent(
            kicker: "刚冲洗好",
            line: m.title,
            accentColorKey: m.colorKey,
            isMemory: true
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

/// 确定性挑面：傍晚/睡前偏向状态机；白天在记忆/明信片/余额间轮换；冷启动用邀请面。
private func pickFace(index i: Int, date: Date, snapshot: TimeBankWidgetSnapshot) -> WidgetFace {
    let cold = snapshot.storedMomentCountTotal == 0 || snapshot.memories.isEmpty
    let hour = Calendar.current.component(.hour, from: date)
    let developed = snapshot.memories.enumerated().filter { $0.element.developed }.map { $0.offset }
    let memCount = snapshot.memories.count

    // 傍晚后、今天还没存：每隔一格端出状态机（温柔催 / 睡前邀请）。
    if snapshot.todayDeposited == false && hour >= 18 && i % 2 == 0 {
        return .todayStatus
    }

    if cold {
        return i % 2 == 0 ? .todayStatus : .invitation(i)
    }

    switch i % 4 {
    case 0:
        return .todayStatus
    case 1:
        return .memory(i % memCount)
    case 2:
        if developed.isEmpty { return .balanceLine(i) }
        return .postcard(developed[(i / 4) % developed.count])
    default:
        return .balanceLine(i)
    }
}

// MARK: - Timeline
struct TimeBankWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: TimeBankWidgetSnapshot
    fileprivate let face: WidgetFace

    fileprivate init(date: Date, snapshot: TimeBankWidgetSnapshot, face: WidgetFace = .todayStatus) {
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
        let now = Date()
        completion(TimeBankWidgetEntry(date: now, snapshot: snapshot, face: pickFace(index: 0, date: now, snapshot: snapshot)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimeBankWidgetEntry>) -> Void) {
        let snapshot = loadSnapshot()
        let now = Date()
        let calendar = Calendar.current

        // 预排 48 条 entry（每 30 分钟一条，覆盖未来 ~24h）。系统按时间自动切换，零刷新预算成本。
        var entries: [TimeBankWidgetEntry] = []
        for i in 0..<48 {
            let date = calendar.date(byAdding: .minute, value: i * 30, to: now) ?? now
            let face = pickFace(index: i, date: date, snapshot: snapshot)
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
    }
}

private struct TimeBankWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TimeBankWidgetEntry

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
            colors: [WT.surface, WT.bg2],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - 锁屏 accessoryRectangular
private struct LockScreenWidgetView: View {
    let entry: TimeBankWidgetEntry

    private var snapshot: TimeBankWidgetSnapshot { entry.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(WidgetCopy.todayStatus(date: entry.date, deposited: snapshot.todayDeposited))
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
        // 锁屏第二行优先端一条记忆，否则一句余额观察。
        if let memory = snapshot.memories.first {
            let prefix = memory.isAnniversary ? "那年今日 · " : "\(daysAgoLabel(memory.daysAgo)) · "
            return prefix + memory.title
        }
        return WidgetCopy.balanceLines[0]
    }
}

// MARK: - 桌面 systemSmall
private struct HomeScreenSmallWidgetView: View {
    let entry: TimeBankWidgetEntry

    private var content: FaceContent {
        faceContent(face: entry.face, snapshot: entry.snapshot, date: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text("今年余额")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(entry.snapshot.yearBalanceWeeks)")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("周")
                        .font(.system(size: 15, weight: .medium))
                }
            }

            Spacer(minLength: 0)

            FaceBlock(content: content)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(WT.ink)
    }
}

// MARK: - 桌面 systemMedium
private struct HomeScreenMediumWidgetView: View {
    let entry: TimeBankWidgetEntry

    private var snapshot: TimeBankWidgetSnapshot { entry.snapshot }
    private var dimensions: [TimeBankWidgetDimensionSnapshot] { Array(snapshot.dimensions.prefix(3)) }
    private var content: FaceContent {
        faceContent(face: entry.face, snapshot: snapshot, date: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("今年余额")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(snapshot.yearBalanceWeeks)")
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .contentTransition(.numericText())
                        Text("周")
                            .font(.system(size: 18, weight: .medium))
                    }
                }

                Spacer(minLength: 8)

                FaceBlock(content: content)
                    .frame(maxWidth: 150, alignment: .trailing)
                    .multilineTextAlignment(.trailing)
            }

            HStack(spacing: 8) {
                ForEach(dimensions) { dimension in
                    DimensionMiniCard(dimension: dimension)
                }
            }

            HStack(spacing: 8) {
                if snapshot.todayDeposited {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(WT.gold)
                    Text("今天已存入")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                } else {
                    Button(intent: QuickDepositIntent()) {
                        HStack(spacing: 5) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("存入此刻")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(WT.primary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 8)
                Text("\(snapshot.storedMomentCountTotal) 个瞬间")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(WT.chipFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .foregroundStyle(WT.ink)
    }
}

// MARK: - 轮换面块（kicker + 主行，记忆面带账户色圆点）
private struct FaceBlock: View {
    let content: FaceContent

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if content.kicker.isEmpty == false {
                HStack(spacing: 4) {
                    if let key = content.accentColorKey {
                        Circle().fill(WT.color(key)).frame(width: 6, height: 6)
                    }
                    Text(content.kicker)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(content.accentColorKey.map(WT.color) ?? WT.ink2)
                }
            }
            Text(content.line)
                .font(.system(size: content.isMemory ? 13 : 12, weight: content.isMemory ? .semibold : .medium))
                .foregroundStyle(content.isMemory ? WT.ink : WT.ink2)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
    }
}

private struct DimensionMiniCard: View {
    let dimension: TimeBankWidgetDimensionSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Circle()
                    .fill(WT.color(dimension.colorKey))
                    .frame(width: 7, height: 7)
                Text(dimension.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(hoursShort(dimension.yearConsumeHours))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.74)

            Text(dimension.subtitle)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(WT.cardFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
    TimeBankWidgetEntry(date: .now, snapshot: .sample, face: .todayStatus)
    TimeBankWidgetEntry(date: .now, snapshot: .sample, face: .memory(0))
}

#Preview(as: .accessoryRectangular) {
    TimeBankWidget()
} timeline: {
    TimeBankWidgetEntry(date: .now, snapshot: .sample)
}
