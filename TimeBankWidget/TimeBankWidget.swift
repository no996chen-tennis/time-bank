import AppIntents
import SwiftUI
import UIKit
import WidgetKit

// MARK: - 存入此刻（打开 App 进入存入编辑器）
//
// 按下后打开 App，置位"待打开存入页"标志；RootView 回到前台消费一次，弹出新存入编辑器
// （用户在编辑器里自己选账户、写内容、加图）。不在 widget 里静默落库——存入是用户主动完成的动作。
struct QuickDepositIntent: AppIntent {
    static var title: LocalizedStringResource = "存入此刻"
    static var description = IntentDescription("打开时间银行，存下此刻。")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        QuickDepositOpenFlag.set()
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

// MARK: - 时间金句库（名著 / 哲人 / 诗词，55 条 · 反焦虑 tone）
//
// 每次点亮屏幕轮换一条，配出处。来源经筛选，剔除催促/励志/guilt 类（"岁月不待人""一寸光阴"等）。
struct WTQuote {
    let text: String
    let source: String
}

private enum TimeQuotes {
    static let all: [WTQuote] = [
        // 当下 · 此刻即永恒
        WTQuote(text: "我们都是时间的旅人，途经此刻，便不算白来。", source: "佚名"),
        WTQuote(text: "当下即是永恒，此刻便是全部。", source: "佚名"),
        WTQuote(text: "被感受过的时间，永远属于你。", source: "佚名"),
        WTQuote(text: "对未来真正的慷慨，是把一切献给现在。", source: "加缪"),
        WTQuote(text: "每个人只能活在当下，所能失去的，也只有当下。", source: "奥勒留《沉思录》"),
        WTQuote(text: "人所拥有的，只是此刻正在度过的生活。", source: "奥勒留《沉思录》"),
        WTQuote(text: "当下，是我们唯一可以生活的地方。", source: "奥勒留《沉思录》"),
        WTQuote(text: "趁你还活着，还有能力，要好好地活着。", source: "奥勒留《沉思录》"),
        WTQuote(text: "过去的已过去，未来还未来，让此刻变得美好就好。", source: "佚名"),
        WTQuote(text: "好好照顾自己，温柔地过好当下的每一天。", source: "佚名"),
        // 时间流逝 · 温柔的觉察
        WTQuote(text: "时间无需通知我们，就可以改变一切。", source: "余华"),
        WTQuote(text: "死亡不是失去生命，而是走出了时间。", source: "余华"),
        WTQuote(text: "人生天地之间，若白驹过隙，忽然而已。", source: "庄子"),
        WTQuote(text: "向之所欣，俯仰之间，已为陈迹。", source: "王羲之《兰亭集序》"),
        WTQuote(text: "逝者如斯夫，不舍昼夜。", source: "《论语》"),
        WTQuote(text: "时间是一条由过去、现在与永恒织成的经线。", source: "博尔赫斯"),
        WTQuote(text: "在时间之中，我们终将窥见真正的自己。", source: "博尔赫斯"),
        WTQuote(text: "时间是变化的财富，时钟只模仿了变化。", source: "泰戈尔《飞鸟集》"),
        WTQuote(text: "我们从未真正拥有一整个星期，因为下一周未必会来。", source: "《四千周》"),
        WTQuote(text: "接纳时间的有限，反而活得更从容。", source: "《四千周》"),
        // 慢 · 从前的日色
        WTQuote(text: "从前的日色变得慢，车，马，邮件都慢。", source: "木心《从前慢》"),
        WTQuote(text: "从前的慢，是一种朴素的精致，一种生命的哲学。", source: "佚名"),
        WTQuote(text: "唯有我们觉醒之际，天才会破晓。", source: "梭罗《瓦尔登湖》"),
        WTQuote(text: "黎明，是一天里最值得纪念的时辰。", source: "梭罗《瓦尔登湖》"),
        WTQuote(text: "驻足于过去与未来的交汇处，我便从此刻开始生活。", source: "梭罗《瓦尔登湖》"),
        WTQuote(text: "我步入丛林，只为汲取生命里所有的精华。", source: "梭罗《瓦尔登湖》"),
        WTQuote(text: "太阳，不过是一颗清晨的星。", source: "梭罗《瓦尔登湖》"),
        WTQuote(text: "也无风雨也无晴。", source: "苏轼《定风波》"),
        WTQuote(text: "人间烟火气，最抚凡人心。", source: "佚名"),
        WTQuote(text: "且将新火试新茶，诗酒趁年华。", source: "苏轼《望江南》"),
        // 记忆 · 眷恋
        WTQuote(text: "生命只是一连串孤立的片刻，靠回忆，许多意义才浮现。", source: "普鲁斯特"),
        WTQuote(text: "那些逝去的时光，其实仍在那儿，随时准备再生。", source: "普鲁斯特"),
        WTQuote(text: "回忆动人之处，在于可以重新选择。", source: "余华"),
        WTQuote(text: "我什么也没忘，只是有些事，只适合收藏。", source: "史铁生"),
        WTQuote(text: "记得生命里那些明亮温暖的日子，带着期许度过余生。", source: "杨绛"),
        WTQuote(text: "停留在记忆里不易磨灭的，是那一道含着光和热的金边。", source: "杨绛"),
        WTQuote(text: "有些事不能说，也不能想，却又不能忘。", source: "史铁生"),
        WTQuote(text: "唯有被你认真感受过的瞬间，才真正发生过。", source: "佚名"),
        WTQuote(text: "时光会把我们带远，但带不走被记住的温度。", source: "佚名"),
        WTQuote(text: "把日子过成可以回头看的样子。", source: "佚名"),
        // 陪伴 · 相聚
        WTQuote(text: "一生只够爱一个人。", source: "木心《从前慢》"),
        WTQuote(text: "我们都以为来日方长，其实人生是减法，见一面少一面。", source: "网络"),
        WTQuote(text: "真正的拥有，是此刻紧握的温度。", source: "佚名"),
        WTQuote(text: "相聚不言过往，离别不问归期。", source: "佚名"),
        WTQuote(text: "把每一次离别，都看作重逢时加倍的欢喜。", source: "佚名"),
        WTQuote(text: "落地为兄弟，何必骨肉亲。", source: "陶渊明"),
        WTQuote(text: "得欢当作乐，斗酒聚比邻。", source: "陶渊明"),
        WTQuote(text: "海内存知己，天涯若比邻。", source: "王勃"),
        WTQuote(text: "我珍惜人生中每一次相识，天地间每一份温暖。", source: "佚名"),
        WTQuote(text: "此刻与你同在，便是时间最温柔的馈赠。", source: "佚名"),
        // 向死而生 · 温柔版
        WTQuote(text: "向死而生，方知生之可贵。", source: "海德格尔"),
        WTQuote(text: "知道生命有期限，才更想认真过好这一天。", source: "佚名"),
        WTQuote(text: "安时而处顺，哀乐不能入也。", source: "庄子"),
        WTQuote(text: "归根结底，太阳还是温暖着我们的身骨。", source: "加缪"),
        WTQuote(text: "生命就是不断超越自身局限，从中感受幸福。", source: "史铁生")
    ]
}

private enum WidgetCopy {
    /// 今日存入状态（外显，蔚来"未签到"模式）。"还空着"= 账本这一页在等你，
    /// 比"未存入"多一层想把它填上的张力，且是观察式不是审判式。
    static func statusLabel(deposited: Bool) -> String {
        deposited ? "今天已存入 ✦" : "今天还空着"
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

// MARK: - 轮换面（状态已常驻外显，轮换面只负责"内容"：记忆 / 明信片 / 金句）
private enum WidgetFace: Equatable {
    case memory(Int)   // index into snapshot.memories
    case postcard(Int) // index into developed memories
    case quote(Int)    // index into TimeQuotes.all
}

/// 渲染一个面所需的最小内容。
private struct FaceContent {
    var kicker: String
    var line: String
    var accentColorKey: String?
    /// 主行用深墨（记忆 / 金句），否则次级灰。
    var prominent: Bool
    var thumbFile: String? = nil
}

private func faceContent(face: WidgetFace, snapshot: TimeBankWidgetSnapshot) -> FaceContent {
    switch face {
    case .memory(let i):
        guard snapshot.memories.indices.contains(i) else {
            return faceContent(face: .quote(i), snapshot: snapshot)
        }
        let m = snapshot.memories[i]
        return FaceContent(
            kicker: m.isAnniversary ? "那年今日" : daysAgoLabel(m.daysAgo),
            line: m.title,
            accentColorKey: m.colorKey,
            prominent: true,
            thumbFile: m.thumbFile
        )
    case .postcard(let i):
        guard snapshot.memories.indices.contains(i) else {
            return faceContent(face: .quote(i), snapshot: snapshot)
        }
        let m = snapshot.memories[i]
        return FaceContent(
            kicker: "刚冲洗好",
            line: m.title,
            accentColorKey: m.colorKey,
            prominent: true,
            thumbFile: m.thumbFile
        )
    case .quote(let i):
        let quote = TimeQuotes.all[((i % TimeQuotes.all.count) + TimeQuotes.all.count) % TimeQuotes.all.count]
        return FaceContent(
            kicker: "—— \(quote.source)",
            line: quote.text,
            accentColorKey: nil,
            prominent: true
        )
    }
}

private func daysAgoLabel(_ days: Int) -> String {
    if days <= 0 { return "今天" }
    if days == 1 { return "昨天" }
    if days >= 360 { return "约一年前" }
    return "\(days) 天前"
}

/// 确定性挑面：无记忆时纯金句轮换；有记忆时记忆 / 明信片 / 金句交替（每 30 分钟换一面）。
/// daySeed 让不同日子从不同金句起步，避免每天看到同一序列。
private func pickFace(index i: Int, daySeed: Int, snapshot: TimeBankWidgetSnapshot) -> WidgetFace {
    let cold = snapshot.storedMomentCountTotal == 0 || snapshot.memories.isEmpty
    if cold {
        return .quote(i + daySeed)
    }

    let developed = snapshot.memories.enumerated().filter { $0.element.developed }.map { $0.offset }
    let memCount = snapshot.memories.count

    switch i % 3 {
    case 0:
        return .memory(i % memCount)
    case 1:
        if developed.isEmpty { return .quote(i + daySeed) }
        return .postcard(developed[(i / 3) % developed.count])
    default:
        return .quote(i + daySeed)
    }
}

// MARK: - Timeline
struct TimeBankWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: TimeBankWidgetSnapshot
    fileprivate let face: WidgetFace

    fileprivate init(date: Date, snapshot: TimeBankWidgetSnapshot, face: WidgetFace = .quote(0)) {
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
        let daySeed = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        completion(TimeBankWidgetEntry(date: .now, snapshot: snapshot, face: pickFace(index: 0, daySeed: daySeed, snapshot: snapshot)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimeBankWidgetEntry>) -> Void) {
        let snapshot = loadSnapshot()
        let now = Date()
        let calendar = Calendar.current
        let daySeed = calendar.ordinality(of: .day, in: .era, for: now) ?? 0

        // 预排 48 条 entry（每 30 分钟一条，覆盖未来 ~24h）。系统按时间自动切换，零刷新预算成本。
        var entries: [TimeBankWidgetEntry] = []
        for i in 0..<48 {
            let date = calendar.date(byAdding: .minute, value: i * 30, to: now) ?? now
            let face = pickFace(index: i, daySeed: daySeed, snapshot: snapshot)
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

// MARK: - 状态即按钮（蔚来"未签到"模式：状态和动作合一）

/// 「今天还空着 / 存入此刻」按钮（App Intent，不打开 App）。
/// 未存入 = 实心强调色 + "今天还空着"（状态即 CTA）；已存入 = 安静的次级"存入此刻"（还能再存）。
private struct DepositButton: View {
    let wt: WT
    var title = "存入此刻"
    var prominent = true
    var fillsWidth = false

    var body: some View {
        Button(intent: QuickDepositIntent()) {
            HStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(prominent ? wt.surface : wt.ink2)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .background(
                prominent ? AnyShapeStyle(wt.accent) : AnyShapeStyle(wt.chipFill),
                in: RoundedRectangle(cornerRadius: wt.controlRadius, style: .continuous)
            )
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

            if snapshot.todayDeposited {
                Text("今天已存入 ✦")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(wt.gold)
            } else {
                Text(WidgetCopy.statusLine(date: entry.date, deposited: false))
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(wt.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }

            Text(content.line)
                .font(.system(size: 10.5, weight: .regular))
                .foregroundStyle(wt.ink2)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .padding(.top, 3)

            Spacer(minLength: 6)

            DepositButton(
                wt: wt,
                title: snapshot.todayDeposited ? "存入此刻" : "今天还空着",
                prominent: snapshot.todayDeposited == false,
                fillsWidth: true
            )
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

                VStack(alignment: .trailing, spacing: 5) {
                    if snapshot.todayDeposited {
                        Text("今天已存入 ✦")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(wt.gold)
                        DepositButton(wt: wt, prominent: false)
                    } else {
                        DepositButton(wt: wt, title: "今天还空着", prominent: true)
                        Text("\(snapshot.storedMomentCountTotal) 个瞬间在等你回看")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(wt.ink2)
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

// MARK: - 轮换面行（记忆：缩略图/色点 + 标题单行；金句：两行引文 + 出处）
private struct FaceLine: View {
    let content: FaceContent
    let wt: WT

    /// 金句面没有缩略图也没有账户色点。
    private var isQuote: Bool {
        content.thumbFile == nil && content.accentColorKey == nil
    }

    var body: some View {
        if isQuote {
            VStack(alignment: .leading, spacing: 2) {
                Text(content.line)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(wt.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                Text(content.kicker)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(wt.ink2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
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
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(wt.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)
            }
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
    TimeBankWidgetEntry(date: .now, snapshot: .sample, face: .quote(0))
}

#Preview(as: .accessoryRectangular) {
    TimeBankWidget()
} timeline: {
    TimeBankWidgetEntry(date: .now, snapshot: .sample)
}
