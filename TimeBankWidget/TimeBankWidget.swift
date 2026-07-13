import AppIntents
import SwiftUI
import UIKit
import WidgetKit

// 注：QuickDepositIntent（「存入此刻」）已移至 TimeBank/Shared/WidgetSnapshot.swift，
// 让它同时编进 App 本体与 Widget 扩展——否则真机上 openAppWhenRun 无法可靠唤起 App。

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
        WTQuote(text: "我珍惜人生中每一次相识，天地间每一份温暖。", source: "佚名"),
        WTQuote(text: "此刻与你同在，便是时间最温柔的馈赠。", source: "佚名"),
        // 向死而生 · 温柔版
        WTQuote(text: "向死而生，方知生之可贵。", source: "海德格尔"),
        WTQuote(text: "知道生命有期限，才更想认真过好这一天。", source: "佚名"),
        WTQuote(text: "归根结底，太阳还是温暖着我们的身骨。", source: "加缪"),
        WTQuote(text: "生命就是不断超越自身局限，从中感受幸福。", source: "史铁生"),
        // 遗憾 · 别等到来不及（看见遗憾，是为了更珍惜现在）
        WTQuote(text: "临终前最后悔的，是没勇气过自己想要的生活，活成了别人期待的样子。", source: "《临终前最后悔的5件事》"),
        WTQuote(text: "很多人临终才后悔，把太多时间给了工作，错过了孩子长大和爱人相伴。", source: "《临终前最后悔的5件事》"),
        WTQuote(text: "临终的人常说：真希望当年有勇气，把心里的话说出口。", source: "《临终前最后悔的5件事》"),
        WTQuote(text: "人走到最后才懂得，最该留住的，是那几位老朋友。", source: "《临终前最后悔的5件事》"),
        WTQuote(text: "临终前最大的遗憾之一，是没让自己活得更快乐一点。", source: "《临终前最后悔的5件事》"),
        WTQuote(text: "父母还在时总觉得来日方长，等懂得珍惜，已经来不及了。", source: "佚名"),
        WTQuote(text: "所谓父母子女一场，是今生今世不断目送他的背影渐行渐远。", source: "龙应台《目送》"),
        WTQuote(text: "等我读懂母亲的牵挂，她已经不在了。", source: "改写自史铁生《我与地坛》"),
        WTQuote(text: "子女想奉养时父母却已不在——这是人间最常见也最深的遗憾。", source: "古训今译"),
        WTQuote(text: "你有多久，没有好好看过父母的脸了。", source: "佚名"),
        WTQuote(text: "最令人心碎的一句话是：「本来可以。」", source: "惠蒂埃"),
        WTQuote(text: "真正的死亡，是世界上再没有一个人记得你。", source: "电影《寻梦环游记》"),
        WTQuote(text: "我们总要等到失去，才学会珍惜。", source: "佚名"),
        WTQuote(text: "别等到说再见时，才发现从没好好说过你好。", source: "佚名"),
        WTQuote(text: "有些人你以为来日方长，其实早已是后会无期。", source: "佚名"),
        WTQuote(text: "成年人的告别往往猝不及防，没有那么多来日方长。", source: "佚名"),
        WTQuote(text: "最大的遗憾，是把「以后再说」，活成了「再也没有」。", source: "佚名"),
        WTQuote(text: "过去都是假的，回忆是一条没有归路的路。", source: "马尔克斯《百年孤独》"),
        WTQuote(text: "记住自己终将死去，是避免患得患失的最好方法。", source: "乔布斯"),
        WTQuote(text: "若你因错过太阳而流泪，那么你也将错过群星。", source: "泰戈尔《飞鸟集》"),
        WTQuote(text: "此刻你嫌平常的一天，正是逝者奢望的明天。", source: "佚名"),
        WTQuote(text: "你之所以觉得来日方长，是因为还没尝过猝不及防的失去。", source: "佚名"),
        WTQuote(text: "趁阳光正好，趁微风不噪，趁还来得及，去见想见的人。", source: "佚名"),
        WTQuote(text: "陪伴是最长情的告白，只是很多人懂得太晚。", source: "佚名"),
        WTQuote(text: "有些门一旦关上就不再打开，别等门关了才想起进去。", source: "佚名"),
        WTQuote(text: "现在你嫌漫长的日子，将来都会成为再也回不去的好时光。", source: "佚名"),
        WTQuote(text: "别让「等有空」「等以后」，偷走你本可以拥有的当下。", source: "佚名"),
        WTQuote(text: "你以为还有很多个明天，其实能确定的只有今天。", source: "佚名"),
        WTQuote(text: "趁还来得及，把「我爱你」说出口，别留成遗憾。", source: "佚名"),
        WTQuote(text: "我们最深的遗憾，往往不是做过的事，而是没敢去爱、没敢去见。", source: "佚名")
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

/// 从 App Group 的 widget-thumbs 目录按文件名读缩略图（small / 分类图 / 记忆面共用）。
private func loadThumbImage(_ name: String?) -> UIImage? {
    guard let name, let dir = TimeBankWidgetSnapshotStore.thumbsDirectoryURL() else { return nil }
    return UIImage(contentsOfFile: dir.appendingPathComponent(name).path)
}

/// 随 timeline 推进的旋转下标：用「距当天 0 点的分钟数」直接做步进种子，
/// 每条 entry（每分钟）就顺着 files 循环往前走一张，遍历整个数组后再从头开始
/// ——避免老停在同几张、也避免感觉"随机/重复"。素材已提到每类最多 10 张，循环周期约 10 分钟。
/// offset 让同一时刻不同栏各自 +1/+2 错开，三栏落在不同下标、不撞图（files ≥3 时必然互不相同）。
private func rotatingThumb(_ files: [String], date: Date, offset: Int = 0) -> String? {
    guard let index = rotatingThumbIndex(count: files.count, date: date, offset: offset) else { return nil }
    return files[index]
}

/// 轮换下标（不取值，只给下标）：让"文件名 + 对应标题"用同一下标各取一次，保证图与标题严格配对。
/// 语义与 rotatingThumb 完全一致：以「距当天 0 点的分钟数 + offset」对 count 取模。count==0 返回 nil。
private func rotatingThumbIndex(count: Int, date: Date, offset: Int = 0) -> Int? {
    guard count > 0 else { return nil }
    let minutes = Int(date.timeIntervalSince(Calendar.current.startOfDay(for: date)) / 60.0)
    return ((minutes + offset) % count + count) % count
}

// MARK: - 跨维度轮换池（让 widget 随时间展示各个维度存入的瞬间，而不是永远只显示存得最多的那个维度）

struct WidgetMomentPick {
    let file: String
    let title: String?
    let dimensionName: String
    let colorKey: String
    let yearRemainingText: String
}

/// 把各 top 分类的缩略图交错(round-robin)成一个扁平池：
/// pool[0]=分类0图0, pool[1]=分类1图0, … 再图1。相邻元素来自不同维度，按时间轮换即可让各维度都露脸。
private func widgetMomentPool(_ cats: [TimeBankWidgetTopCategory]) -> [WidgetMomentPick] {
    guard cats.isEmpty == false else { return [] }
    let maxThumbs = cats.map { $0.thumbFiles.count }.max() ?? 0
    var pool: [WidgetMomentPick] = []
    for i in 0..<maxThumbs {
        for cat in cats where cat.thumbFiles.indices.contains(i) {
            let rawTitle = cat.thumbTitles.indices.contains(i) ? cat.thumbTitles[i] : nil
            pool.append(
                WidgetMomentPick(
                    file: cat.thumbFiles[i],
                    title: (rawTitle?.isEmpty == false) ? rawTitle : nil,
                    dimensionName: cat.name,
                    colorKey: cat.colorKey,
                    yearRemainingText: cat.yearRemainingText
                )
            )
        }
    }
    return pool
}

/// 按分钟在跨维度池里轮换取一个瞬间；池空返回 nil。
private func currentMomentPick(_ snapshot: TimeBankWidgetSnapshot, date: Date) -> WidgetMomentPick? {
    let pool = widgetMomentPool(snapshot.topCategories ?? [])
    guard let idx = rotatingThumbIndex(count: pool.count, date: date) else { return nil }
    return pool[idx]
}

/// 竖排标题的一个格：中文字逐字竖排；英文/数字单词整体一格(渲染时横躺旋转90°，不被逐字母拉长)。
enum VTitleToken: Hashable {
    case cjk(Character)
    case latin(String)
}

/// 英文单词横躺后占的竖向高度估算（≈字符数×每字宽），并封顶不超过列高。
private func latinTokenHeight(_ s: String, colHeight: CGFloat) -> CGFloat {
    min(max(20, colHeight * 0.85), max(15, CGFloat(s.count) * 7.5))
}

/// 把标题切成 token：连续的 ASCII 字母/数字合成一个 latin 词，其余每个字符各自成 cjk 格；空白丢弃。
private func tokenizeVTitle(_ title: String) -> [VTitleToken] {
    var tokens: [VTitleToken] = []
    var latin = ""
    func flush() {
        if latin.isEmpty == false { tokens.append(.latin(latin)); latin = "" }
    }
    for ch in title {
        if ch.isASCII && (ch.isLetter || ch.isNumber) {
            latin.append(ch)
        } else if ch == " " || ch == "\n" || ch == "\t" {
            flush()
        } else {
            flush()
            tokens.append(.cjk(ch))
        }
    }
    flush()
    return tokens
}

/// 竖排标题分列：按 token 高度装列(中文字≈15pt / 英文词横躺占更高)，一列装满排下一列，最多 maxCols 列；
/// 装不下则在末列补"…"。返回 cols[0] = 最先的内容（渲染时放最左列，从左往右——现代中文直觉，不同于日文右→左）。
private func verticalTitleColumns(_ title: String, height: CGFloat, maxCols: Int = 3) -> [[VTitleToken]] {
    let tokens = tokenizeVTitle(title)
    guard tokens.isEmpty == false else { return [] }
    let spacing: CGFloat = 2
    var cols: [[VTitleToken]] = []
    var cur: [VTitleToken] = []
    var curH: CGFloat = 0
    for tok in tokens {
        let h: CGFloat
        switch tok {
        case .cjk: h = 16   // 与渲染实际行高(13pt字≈16)对齐，避免装列估算偏小导致底部轻微超界
        case .latin(let s): h = latinTokenHeight(s, colHeight: height)
        }
        if cur.isEmpty == false && curH + spacing + h > height {
            cols.append(cur); cur = []; curH = 0
            if cols.count >= maxCols { break }
        }
        curH += cur.isEmpty ? h : spacing + h
        cur.append(tok)
    }
    if cols.count < maxCols && cur.isEmpty == false { cols.append(cur) }
    let placed = cols.reduce(0) { $0 + $1.count }
    if placed < tokens.count, cols.isEmpty == false {
        // 末列已装满，先腾一格再补"…"，避免加"…"后该列超出列高、溢出到下方 caption。
        if cols[cols.count - 1].isEmpty == false {
            cols[cols.count - 1].removeLast()
        }
        cols[cols.count - 1].append(.cjk("…"))
    }
    return cols
}

private func daysAgoLabel(_ days: Int) -> String {
    if days <= 0 { return "今天" }
    if days == 1 { return "昨天" }
    if days >= 360 { return "约一年前" }
    return "\(days) 天前"
}

/// 确定性挑面：无记忆时纯金句轮换；有记忆时记忆 / 明信片 / 金句交替（每 30 分钟换一面）。
/// daySeed 让不同日子从不同金句起步，避免每天看到同一序列。
/// 比例（决策#4）：记忆面占比更高，i % 5 中 0/1/2 = 记忆，3 = 明信片，其余 = 金句。
private func pickFace(index i: Int, daySeed: Int, snapshot: TimeBankWidgetSnapshot) -> WidgetFace {
    let cold = snapshot.storedMomentCountTotal == 0 || snapshot.memories.isEmpty
    if cold {
        return .quote(i + daySeed)
    }

    let developed = snapshot.memories.enumerated().filter { $0.element.developed }.map { $0.offset }
    let memCount = snapshot.memories.count

    switch i % 5 {
    case 0, 1, 2:
        return .memory(i % memCount)
    case 3:
        if developed.isEmpty { return .quote(i + daySeed) }
        return .postcard(developed[(i / 5) % developed.count])
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
        let reset = nextRefreshDate(after: now)   // 次日（或今日）凌晨 4 点（既有逻辑保留）

        // 每分钟一条 entry，只排到未来约 3 小时（~180 条）；窗口末尾若跨过凌晨 4 点则截到 4 点，
        // 用 policy:.after(windowEnd) 滚动续期。reload ≈ 每 3h 一次，entry 数稳定 ~180，无截断风险。
        let windowEnd = min(calendar.date(byAdding: .hour, value: 3, to: now) ?? reset, reset)

        var entries: [TimeBankWidgetEntry] = []
        var t = now
        var minuteIndex = 0
        while t < windowEnd {
            // face 仍每 ~30 分钟换一次：用相对 now 的「30 分钟桶」做 face index（每分钟换面太快）。
            let faceBucket = minuteIndex / 30
            let face = pickFace(index: faceBucket, daySeed: daySeed, snapshot: snapshot)
            entries.append(TimeBankWidgetEntry(date: t, snapshot: snapshot, face: face))
            t = calendar.date(byAdding: .minute, value: 1, to: t) ?? windowEnd
            minuteIndex += 1
        }

        // 至少 1 条兜底。
        if entries.isEmpty {
            entries.append(TimeBankWidgetEntry(date: now, snapshot: snapshot, face: pickFace(index: 0, daySeed: daySeed, snapshot: snapshot)))
        }

        completion(Timeline(entries: entries, policy: .after(windowEnd)))
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

// MARK: - 锁屏 accessoryRectangular（文字为主，不塞图：周数 + 今天剩 + 一行回忆/状态）
private struct LockScreenWidgetView: View {
    let entry: TimeBankWidgetEntry

    private var snapshot: TimeBankWidgetSnapshot { entry.snapshot }
    private var content: FaceContent { faceContent(face: entry.face, snapshot: snapshot) }

    /// 今天剩余短式（锁屏空间极小）：「Xh」。
    private var todayLeftShort: String {
        let h = DisposableTime.remainingSeconds(now: entry.date, routine: snapshot.dailyRoutine ?? .default) / 3600.0
        let v = (max(0, h) * 10).rounded() / 10
        let s = v == v.rounded() ? "\(Int(v))" : String(format: "%.1f", v)
        return "\(s)h"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // 第一行：年余额 + 今天剩（数字为主）+ 存入按钮。
            HStack(spacing: 5) {
                Text(secondLine)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 2)
                Button(intent: QuickDepositIntent()) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.plain)
            }

            // 第二行：一行回忆 / 状态（纯文字）。
            Text(titleLine)
                .font(.system(size: 11.5, weight: .regular))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    /// 标题为主：有记忆面端记忆标题（kicker 前缀），否则今日状态。
    private var titleLine: String {
        if let kickered = memoryTitle { return kickered }
        return WidgetCopy.statusLabel(deposited: snapshot.todayDeposited)
    }

    private var memoryTitle: String? {
        // 当前轮换面是记忆/明信片且有标题时优先它，否则回落首条记忆。
        if content.thumbFile != nil || content.accentColorKey != nil {
            return content.line
        }
        if let memory = snapshot.memories.first {
            let prefix = memory.isAnniversary ? "那年今日 · " : "\(daysAgoLabel(memory.daysAgo)) · "
            return prefix + memory.title
        }
        return nil
    }

    private var secondLine: String {
        // 第二行：年余额 + 今天剩余。
        "\(snapshot.yearBalanceWeeks)周 · 剩\(todayLeftShort)"
    }
}

// MARK: - 桌面 systemSmall（精简版：今天还剩醒目 + 一张轮换 top 分类图 + 存入按钮）
private struct HomeScreenSmallWidgetView: View {
    let entry: TimeBankWidgetEntry

    private var snapshot: TimeBankWidgetSnapshot { entry.snapshot }
    private var wt: WT { WT.theme(snapshot.themeKind) }
    private var content: FaceContent { faceContent(face: entry.face, snapshot: snapshot) }

    /// 顶部醒目「今天还剩 约X小时」的数字部分（"约 X"），单位另排。
    private var todayLeft: String {
        DisposableTime.remainingText(now: entry.date, routine: snapshot.dailyRoutine ?? .default)
    }

    private var todayLeftValue: String {
        if let range = todayLeft.range(of: " 小时") {
            return String(todayLeft[todayLeft.startIndex..<range.lowerBound])
        }
        return todayLeft
    }

    /// small 展示一栏：从【有图的】各维度里按分钟轮换取一个（不再恒定存入最多的那个；
    /// 过滤掉无图维度，避免轮到它时回落记忆图却仍标注该维度名导致图文错配）。nil = 无可展示分类。
    private var topCategory: TimeBankWidgetTopCategory? {
        let cats = (snapshot.topCategories ?? []).filter { $0.thumbFiles.isEmpty == false }
        guard let idx = rotatingThumbIndex(count: cats.count, date: entry.date) else { return nil }
        return cats[idx]
    }

    /// 该分类按 entry.date 轮换到的一张照片；分类无图时回落到当前记忆面的缩略图。
    private var rotatingImage: UIImage? {
        if let cat = topCategory,
           let name = rotatingThumb(cat.thumbFiles, date: entry.date) {
            return loadThumbImage(name)
        }
        return loadThumbImage(content.thumbFile)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 顶部：今天还剩（醒目）。
            VStack(alignment: .leading, spacing: 0) {
                Text("今天还剩")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(wt.ink2)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(todayLeftValue)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(wt.ink)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("小时")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(wt.ink2)
                }
            }

            // 一张轮换的 top 分类图（无图时该分类色块占位；无分类时省略，留给按钮呼吸）。
            categoryImageBlock

            Spacer(minLength: 4)

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

    /// 图为主的分类块：有图放图；有分类无图放分类色块占位；连分类都没有则放一行温柔文案。
    @ViewBuilder
    private var categoryImageBlock: some View {
        if let image = rotatingImage {
            VStack(alignment: .leading, spacing: 4) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: max(6, wt.radius * 0.7), style: .continuous))
                if let cat = topCategory {
                    categoryLabel(cat)
                }
            }
        } else if let cat = topCategory {
            VStack(alignment: .leading, spacing: 4) {
                wt.color(cat.colorKey).opacity(0.14)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: max(6, wt.radius * 0.7), style: .continuous))
                categoryLabel(cat)
            }
        } else {
            Text(content.line)
                .font(.system(size: 11.5, weight: .regular))
                .foregroundStyle(wt.ink2)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// 「● 分类名」一行（色点用 WT color(colorKey)）。
    private func categoryLabel(_ cat: TimeBankWidgetTopCategory) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(wt.color(cat.colorKey))
                .frame(width: 6, height: 6)
            Text(cat.name)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(wt.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

// MARK: - 桌面 systemMedium（左栏双大数字 + 存入按钮；右栏竖排 2 张带标题分类图）
//
// 【为什么整块用 GeometryReader 确定性布局】
// 旧版用 HStack + 图片 .frame(maxHeight:.infinity) + 左栏靠两个大数字的"内在高度"撑开 + minimumScaleFactor。
// 大数字的内在高度会随取值（"约1小时" vs "约10小时"）、随字体度量在 widget 固定边界里偶尔超出可用高，
// WidgetKit 对"内容内在尺寸 > 容器"的处理不稳定：有时把左栏整体按比例放大（数字看着被撑大/像裁切），
// 过一会重排又恢复。根治办法 = 不让任何子视图用内在高度去"猜"，改成先拿到 geo.size，
// 显式算出左右两栏宽度、每个数字块的固定高度、右侧每张图的固定高宽，所有子视图尺寸都由 geo 推导；
// 数字用固定字号 + minimumScaleFactor 仅在"已知高度盒子"内做兜底缩放，绝不反过来影响布局高度。
private struct HomeScreenMediumWidgetView: View {
    let entry: TimeBankWidgetEntry

    private var snapshot: TimeBankWidgetSnapshot { entry.snapshot }
    private var wt: WT { WT.theme(snapshot.themeKind) }

    // MARK: 布局常量（全部显式，绝不依赖内在高度）
    private let outerPadding: CGFloat = 16   // 内容四周留白（自管，不用 .padding 修饰符以便纳入 geo 计算）
    private let columnGap: CGFloat = 12       // 左右两栏间距
    private let leftWidthRatio: CGFloat = 0.48 // 左栏占（去掉列间距后）宽度比，右栏约 0.52
    private let imageGap: CGFloat = 6         // 右栏两张图之间的竖向间距
    private let buttonZoneHeight: CGFloat = 30 // 左栏底部「存入此刻」按钮预留高
    private let statGap: CGFloat = 8          // 左栏两个数字块之间的间距
    private let leftBottomGap: CGFloat = 8    // 数字区与按钮区之间的间距

    /// 存得最多的分类（右栏图取自它的 thumbFiles / thumbTitles）。nil = 无数据。
    private var topCategory: TimeBankWidgetTopCategory? {
        snapshot.topCategories?.first
    }

    /// 今天还剩（用 entry.date 现算，直调唯一真相源 DisposableTime）。
    private var todayLeft: String {
        DisposableTime.remainingText(now: entry.date, routine: snapshot.dailyRoutine ?? .default)
    }

    var body: some View {
        GeometryReader { geo in
            // 去掉四周 padding 后的确定性内容盒子。
            let contentW = max(0, geo.size.width - outerPadding * 2)
            let contentH = max(0, geo.size.height - outerPadding * 2)

            // 两栏宽度：先扣列间距，再按比例切；右栏拿剩余（避免累加误差）。
            let usableW = max(0, contentW - columnGap)
            let leftW = usableW * leftWidthRatio
            let rightW = usableW - leftW

            HStack(alignment: .top, spacing: columnGap) {
                leftColumn(width: leftW, height: contentH)
                    .frame(width: leftW, height: contentH, alignment: .topLeading)

                rightColumn(width: rightW, height: contentH)
                    .frame(width: rightW, height: contentH, alignment: .top)
            }
            .frame(width: contentW, height: contentH, alignment: .topLeading)
            .padding(outerPadding)
        }
    }

    // MARK: - 左栏：两个大数字 + 底部按钮，全部按 geo 给定高度切分
    //
    // 高度分配：contentH = 数字区 + leftBottomGap + 按钮区(buttonZoneHeight)。
    // 数字区 = (contentH - leftBottomGap - buttonZoneHeight)，再减去 statGap 后对半分给两个数字块。
    // 每个数字块拿到"显式高度"，块内 caption+数字+单位靠 Spacer 竖向分布，数字用 minimumScaleFactor 只在块内缩。
    private func leftColumn(width: CGFloat, height: CGFloat) -> some View {
        let statsAreaH = max(0, height - leftBottomGap - buttonZoneHeight)
        let statBlockH = max(0, (statsAreaH - statGap) / 2)

        return VStack(alignment: .leading, spacing: 0) {
            balanceStat(
                caption: "今年余额",
                value: "\(snapshot.yearBalanceWeeks)",
                unit: "周",
                width: width,
                height: statBlockH
            )

            Spacer(minLength: statGap).frame(height: statGap)

            balanceStat(
                caption: "今天还剩",
                value: todayLeftValue,
                unit: todayLeftUnit,
                width: width,
                height: statBlockH
            )

            Spacer(minLength: leftBottomGap).frame(height: leftBottomGap)

            DepositButton(wt: wt, prominent: snapshot.todayDeposited == false)
                .frame(width: width, height: buttonZoneHeight, alignment: .leading)
        }
        .frame(width: width, height: height, alignment: .topLeading)
    }

    /// 一个数字块：拿到显式(width,height)，caption 小字在上、数字在下、单位小字尾随。
    /// 数字字号 34（比旧版 32 更大更醒目），minimumScaleFactor 0.6 兜底 2-3 位数在窄栏内不溢出。
    /// 关键：外层 .frame 固定高度 + 内部 clipped，数字的内在高度再也不会把布局撑大。
    private func balanceStat(
        caption: String,
        value: String,
        unit: String,
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(caption)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(wt.ink2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(wt.ink)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .layoutPriority(1)
                Text(unit)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(wt.ink2)
                    .lineLimit(1)
            }
        }
        .frame(width: width, height: height, alignment: .leading)
        .clipped()
    }

    // MARK: - 右栏：图旁竖排标题(占旁边空白) + 一张正常比例的图 + 图下「● 维度名 · 还剩」
    //
    // 版式回到"单张图"：图取自 top 分类当前轮换到的那张(offset 0)，其对应的瞬间标题以【竖排】
    // 放在图左侧的窄条空白里。所有尺寸由 geo 给定的(width,height)显式切分，保持确定性不溢出。
    private func rightColumn(width: CGFloat, height: CGFloat) -> some View {
        Group {
            if let pick = currentMomentPick(snapshot, date: entry.date) {
                let cols = verticalTitleColumns(pick.title ?? "", height: height)
                let hasTitle = cols.isEmpty == false
                let colW: CGFloat = 18
                let stripW: CGFloat = hasTitle ? CGFloat(cols.count) * colW : 0
                let innerGap: CGFloat = hasTitle ? 8 : 0
                let imageColW = max(0, width - stripW - innerGap)

                HStack(alignment: .top, spacing: innerGap) {
                    if hasTitle {
                        verticalTitle(cols: cols, width: stripW, height: height)
                    }
                    imageColumn(
                        pick: pick,
                        image: loadThumbImage(pick.file),
                        width: imageColW,
                        height: height
                    )
                }
                .frame(width: width, height: height, alignment: .top)
            } else {
                emptyRight(width: width, height: height)
            }
        }
    }

    /// 一张正常比例的图(scaledToFill 到确定盒子, 圆角) + 图下一行「● 维度名 · 今年余额」。
    private func imageColumn(
        pick: WidgetMomentPick,
        image: UIImage?,
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        let captionH: CGFloat = 20
        let imageH = max(0, height - captionH - 6)
        let corner = max(8, wt.radius)

        return VStack(alignment: .leading, spacing: 6) {
            Group {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    wt.color(pick.colorKey).opacity(0.14)
                        .overlay(
                            Circle()
                                .fill(wt.color(pick.colorKey).opacity(0.5))
                                .frame(width: 12, height: 12)
                        )
                }
            }
            .frame(width: width, height: imageH)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))

            HStack(spacing: 5) {
                Circle().fill(wt.color(pick.colorKey)).frame(width: 6, height: 6)
                Text(pick.dimensionName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(wt.ink)
                    .lineLimit(1)
                Text(pick.yearRemainingText)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(wt.ink2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: width, height: captionH, alignment: .leading)
        }
        .frame(width: width, height: height, alignment: .top)
    }

    /// 竖排标题(可多列)：cols[0] 放【最左】列，从左往右排（现代中文直觉，不同于日文的右→左）；每格竖向堆叠。
    private func verticalTitle(cols: [[VTitleToken]], width: CGFloat, height: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 3) {
            ForEach(Array(cols.enumerated()), id: \.offset) { _, col in
                VStack(spacing: 2) {
                    ForEach(Array(col.enumerated()), id: \.offset) { _, tok in
                        tokenCell(tok, colHeight: height)
                    }
                }
            }
        }
        .frame(width: width, height: height, alignment: .top)
        .clipped()   // 兜底：即便极端长标题估算略超，也绝不画到下方 caption 上
    }

    /// 中文字 → 竖排一格；英文/数字单词 → 整体横躺旋转 90° 占一格(不被逐字母拉长)。
    @ViewBuilder
    private func tokenCell(_ tok: VTitleToken, colHeight: CGFloat) -> some View {
        switch tok {
        case .cjk(let ch):
            Text(String(ch))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(wt.ink2)
                .lineLimit(1)
        case .latin(let s):
            let est = latinTokenHeight(s, colHeight: colHeight)
            Text(s)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(wt.ink2)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: est, height: 15)
                .rotationEffect(.degrees(90))
                .frame(width: 15, height: est)
        }
    }

    /// 无分类时右栏兜底：一段轮换金句 + 引导存入（占满右侧盒子）。
    private func emptyRight(width: CGFloat, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(faceContent(face: entry.face, snapshot: snapshot).line)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(wt.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
            Text("存下第一段，这里会长出你的照片墙。")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(wt.ink2)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
        }
        .frame(width: width, height: height, alignment: .topLeading)
    }

    /// 用同一轮换下标取"文件名 + 对应标题"，保证两者严格配对。
    /// thumbTitles 可能比 thumbFiles 短（老快照）→ 标题按下标越界兜底为 nil。
    private func rotatingThumbPick(
        cat: TimeBankWidgetTopCategory,
        offset: Int
    ) -> (file: String?, title: String?) {
        guard let idx = rotatingThumbIndex(count: cat.thumbFiles.count, date: entry.date, offset: offset) else {
            return (nil, nil)
        }
        let file = cat.thumbFiles[idx]
        let title = cat.thumbTitles.indices.contains(idx) ? cat.thumbTitles[idx] : nil
        return (file, title)
    }

    /// 今天还剩：把「约 X 小时」拆成数字（"约 X"）+ 单位（"小时"），与周数对等排版。
    private var todayLeftValue: String {
        let text = todayLeft                       // 形如 "约 6.5 小时"
        if let range = text.range(of: " 小时") {
            return String(text[text.startIndex..<range.lowerBound])
        }
        return text
    }

    private var todayLeftUnit: String { "小时" }
}

// MARK: - 分类照片墙一栏（图为主 + 色点分类名 + 今年余额文案）
private struct CategoryColumn: View {
    let category: TimeBankWidgetTopCategory
    let wt: WT
    /// 本栏当前轮换到的缩略图文件名（可能为 nil = 该类暂无图）。
    let thumbName: String?

    private var image: UIImage? { loadThumbImage(thumbName) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            imageBlock
                .frame(maxWidth: .infinity)
                .frame(height: 84)
                .clipShape(RoundedRectangle(cornerRadius: max(6, wt.radius * 0.7), style: .continuous))

            // 分类名 + 今年余额并在一行（腾出竖向空间给图）。名字优先，余额不够宽时先缩。
            // 维度名略加粗（.bold），让"这张图属于哪个维度"一眼可辨。
            HStack(spacing: 5) {
                Circle()
                    .fill(wt.color(category.colorKey))
                    .frame(width: 6, height: 6)
                Text(category.name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(wt.ink)
                    .lineLimit(1)
                    .layoutPriority(1)
                Text(category.yearRemainingText)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(wt.ink2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 有图放图；无图放该分类色块占位（不塞文字，保留照片墙的视觉节奏）。
    @ViewBuilder
    private var imageBlock: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            wt.color(category.colorKey).opacity(0.14)
                .overlay(
                    Circle()
                        .fill(wt.color(category.colorKey).opacity(0.5))
                        .frame(width: 10, height: 10)
                )
        }
    }
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
