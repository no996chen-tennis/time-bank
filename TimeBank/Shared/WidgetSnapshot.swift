import AppIntents
import Foundation

/// 一天里的固定损耗段（系统预设，不可调）。所有时间用「距当天 0 点的分钟数」表示。
struct DailyRoutineParams: Equatable, Sendable, Codable {
    /// 一个损耗段：[startMinute, endMinute)，单位=距当天0点分钟。
    struct Segment: Equatable, Sendable, Codable {
        var startMinute: Int
        var endMinute: Int
    }
    /// 就寝点（"今天可支配余额"的右端 = 今晚就寝时刻）。23:00 = 1380。
    var bedtimeMinute: Int
    /// 起床点（把睡眠段闭合到"昨夜→今晨"；07:00 = 420）。
    var wakeMinute: Int
    /// 睡眠之外的损耗段（三餐 + 通勤/洗漱/碎片等杂项）。睡眠段由 bedtime/wake 隐式生成。
    var choreSegments: [Segment]

    /// 默认：睡眠8h(23:00–07:00) + 三餐各0.5h + 杂项约3.5h（晨间洗漱/通勤/午后碎片/晚间杂事），
    ///   清醒16h − 三餐1.5h − 杂项约4.5h ≈ 可支配约10h。损耗段允许重叠，并集算法自动去重。
    static let `default` = DailyRoutineParams(
        bedtimeMinute: 23 * 60,           // 23:00
        wakeMinute: 7 * 60,               // 07:00
        choreSegments: [
            Segment(startMinute: 7 * 60,       endMinute: 7 * 60 + 60),   // 晨间洗漱/通勤 1.0h
            Segment(startMinute: 7 * 60 + 30,  endMinute: 8 * 60),        // 早餐 0.5h（与晨间段并集，自动去重）
            Segment(startMinute: 12 * 60,      endMinute: 12 * 60 + 30),  // 午餐 0.5h
            Segment(startMinute: 14 * 60,      endMinute: 14 * 60 + 60),  // 午后碎片/杂事 1.0h
            Segment(startMinute: 18 * 60,      endMinute: 18 * 60 + 30),  // 通勤/晚间杂事 0.5h
            Segment(startMinute: 18 * 60 + 30, endMinute: 19 * 60),       // 晚餐 0.5h
            Segment(startMinute: 21 * 60,      endMinute: 21 * 60 + 60)   // 晚间杂事/洗漱 1.0h
        ]
    )
}

/// 今天可支配剩余的唯一真相源（App + Widget 共用，写在双成员文件 WidgetSnapshot.swift）。
enum DisposableTime {
    /// 今天从 now 到今晚就寝点之间、落在清醒且非损耗段的总秒数。
    /// 边界：① 就寝后(now 已过今日就寝点)=0；② now 处于损耗/睡眠段=数字暂停(只算未来自由段)；
    ///       ③ 跨午夜按"今晚 bedtime"建模，不跨日（00:00 后按新一天重算，凌晨睡眠段被扣，预期非 bug）。
    static func remainingSeconds(now: Date = .now,
                                 routine: DailyRoutineParams = .default,
                                 calendar: Calendar = .current) -> Double {
        let startOfDay = calendar.startOfDay(for: now)
        let nowMinutes = now.timeIntervalSince(startOfDay) / 60.0
        let bedtime = Double(routine.bedtimeMinute)

        // ① 就寝后 = 0。
        guard nowMinutes < bedtime else { return 0 }

        // ③ 损耗区间池：凌晨睡眠段（now 早于起床点）+ 全部 choreSegments。
        var intervals: [(start: Double, end: Double)] = []
        let wake = Double(routine.wakeMinute)
        if nowMinutes < wake {
            intervals.append((start: nowMinutes, end: wake))
        }
        for segment in routine.choreSegments {
            intervals.append((start: Double(segment.startMinute), end: Double(segment.endMinute)))
        }

        // ④ 裁剪进 [nowMinutes, bedtime]，过滤空区间。
        let windowStart = nowMinutes
        let windowEnd = bedtime
        let clipped = intervals.compactMap { interval -> (start: Double, end: Double)? in
            let start = max(interval.start, windowStart)
            let end = min(interval.end, windowEnd)
            guard end > start else { return nil }
            return (start: start, end: end)
        }

        // 排序后扫描求并集长度（处理重叠，自动去重）。
        let sorted = clipped.sorted { $0.start < $1.start }
        var unionMinutes = 0.0
        var currentStart = -Double.greatestFiniteMagnitude
        var currentEnd = -Double.greatestFiniteMagnitude
        for interval in sorted {
            if interval.start > currentEnd {
                if currentEnd > currentStart {
                    unionMinutes += currentEnd - currentStart
                }
                currentStart = interval.start
                currentEnd = interval.end
            } else {
                currentEnd = max(currentEnd, interval.end)
            }
        }
        if currentEnd > currentStart {
            unionMinutes += currentEnd - currentStart
        }

        // ⑤ disposable = 窗口长 − 并集长。
        let disposableMinutes = max(0, (windowEnd - windowStart) - unionMinutes)
        return disposableMinutes * 60
    }

    /// 展示文案（小时1位小数）。例：6.5h → "约 6.5 小时"。
    /// 格式逻辑内联，不依赖 Utility/Formatter.swift（对 Widget 不可见）。
    static func remainingText(now: Date = .now, routine: DailyRoutineParams = .default) -> String {
        let h = remainingSeconds(now: now, routine: routine) / 3600.0
        let v = (max(0, h) * 10).rounded() / 10
        let s = v == v.rounded() ? "\(Int(v))" : String(format: "%.1f", v)
        return "约 \(s) 小时"
    }
}

struct TimeBankWidgetSnapshot: Codable, Equatable, Sendable {
    var generatedAt: Date
    var yearBalanceWeeks: Int
    var storedMomentCountTotal: Int
    var topText: String
    var dimensions: [TimeBankWidgetDimensionSnapshot]
    /// 今天是否已经存入过一个新瞬间（按 createdAt 落在今天判定）。驱动 widget 状态机的"已存入 ✦"面。
    var todayDeposited: Bool
    /// widget 轮换用的记忆池（"一颗星的回忆 / 冲洗好的明信片"两个面共用）。
    var memories: [TimeBankWidgetMemory]
    /// App 内用户选的主题 rawValue（widget 进程读不到 App 的 UserDefaults，经快照传递）。
    /// nil / 未知值时 widget 回落默认主题 magazineApartamento。
    var themeKind: String?
    /// 今天可支配损耗模型（Widget 用 entry.date 现算今天剩余，保证与 App 同模型）。nil = 用 .default。
    var dailyRoutine: DailyRoutineParams?
    /// 用户存入最多的 top3 分类，每类一张可轮换照片 + 今年余额（W1 新增，widget "分类照片墙"面用）。
    /// nil = 老快照未写入，widget 端按无数据处理。
    var topCategories: [TimeBankWidgetTopCategory]?

    init(
        generatedAt: Date,
        yearBalanceWeeks: Int,
        storedMomentCountTotal: Int,
        topText: String,
        dimensions: [TimeBankWidgetDimensionSnapshot],
        todayDeposited: Bool = false,
        memories: [TimeBankWidgetMemory] = [],
        themeKind: String? = nil,
        dailyRoutine: DailyRoutineParams? = nil,
        topCategories: [TimeBankWidgetTopCategory]? = nil
    ) {
        self.generatedAt = generatedAt
        self.yearBalanceWeeks = yearBalanceWeeks
        self.storedMomentCountTotal = storedMomentCountTotal
        self.topText = topText
        self.dimensions = dimensions
        self.todayDeposited = todayDeposited
        self.memories = memories
        self.themeKind = themeKind
        self.dailyRoutine = dailyRoutine
        self.topCategories = topCategories
    }

    // 向后兼容：旧快照 JSON 没有 todayDeposited / memories / topCategories，缺失时给默认值，
    // 避免老的 widget 进程在 App 还没重写快照前解码失败回落到 .sample。
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = try c.decode(Date.self, forKey: .generatedAt)
        yearBalanceWeeks = try c.decode(Int.self, forKey: .yearBalanceWeeks)
        storedMomentCountTotal = try c.decode(Int.self, forKey: .storedMomentCountTotal)
        topText = try c.decode(String.self, forKey: .topText)
        dimensions = try c.decode([TimeBankWidgetDimensionSnapshot].self, forKey: .dimensions)
        todayDeposited = try c.decodeIfPresent(Bool.self, forKey: .todayDeposited) ?? false
        memories = try c.decodeIfPresent([TimeBankWidgetMemory].self, forKey: .memories) ?? []
        themeKind = try c.decodeIfPresent(String.self, forKey: .themeKind)
        dailyRoutine = try c.decodeIfPresent(DailyRoutineParams.self, forKey: .dailyRoutine)
        topCategories = try c.decodeIfPresent([TimeBankWidgetTopCategory].self, forKey: .topCategories)
    }

    static let sample = TimeBankWidgetSnapshot(
        generatedAt: .now,
        yearBalanceWeeks: 34,
        storedMomentCountTotal: 12,
        topText: "把重要的时间放在眼前。",
        dimensions: [
            TimeBankWidgetDimensionSnapshot(
                id: "parents",
                name: "父母",
                iconKey: "heart.fill",
                colorKey: "rose",
                lifetimeConsumeHours: 552,
                yearConsumeHours: 96,
                storedHours: 31,
                momentCount: 7,
                subtitle: "约 16 次",
                lastMoment: TimeBankWidgetLastMoment(title: "晚饭后的散步", happenedAt: .now)
            ),
            TimeBankWidgetDimensionSnapshot(
                id: "kids",
                name: "孩子",
                iconKey: "person.2",
                colorKey: "warm",
                lifetimeConsumeHours: 15_226,
                yearConsumeHours: 680,
                storedHours: 12,
                momentCount: 3,
                subtitle: "每周 20h",
                lastMoment: nil
            ),
            TimeBankWidgetDimensionSnapshot(
                id: "partner",
                name: "伴侣",
                iconKey: "heart.circle.fill",
                colorKey: "lavender",
                lifetimeConsumeHours: 65_745,
                yearConsumeHours: 956,
                storedHours: 8,
                momentCount: 2,
                subtitle: "每天 4h",
                lastMoment: nil
            )
        ],
        todayDeposited: false,
        memories: [
            TimeBankWidgetMemory(title: "晚饭后的散步", daysAgo: 365, colorKey: "rose", isAnniversary: true, developed: false),
            TimeBankWidgetMemory(title: "周末爬了座小山", daysAgo: 3, colorKey: "sage", isAnniversary: false, developed: true),
            TimeBankWidgetMemory(title: "她第一次自己系鞋带", daysAgo: 47, colorKey: "warm", isAnniversary: false, developed: false)
        ],
        dailyRoutine: .default,
        topCategories: [
            TimeBankWidgetTopCategory(
                name: "父母", colorKey: "rose", yearRemainingText: "还能共度 96 小时",
                thumbFiles: [], thumbTitles: ["晚饭后的散步", "陪爸妈逛菜市场"]
            ),
            TimeBankWidgetTopCategory(
                name: "孩子", colorKey: "warm", yearRemainingText: "还能共度 680 小时",
                thumbFiles: [], thumbTitles: ["她第一次自己系鞋带", "周末的游乐场"]
            ),
            TimeBankWidgetTopCategory(
                name: "运动", colorKey: "sage", yearRemainingText: "未来 210 小时",
                thumbFiles: [], thumbTitles: ["周末爬了座小山", "清晨的操场"]
            )
        ]
    )
}

/// widget「分类照片墙」面用的 top 分类投影：用户存入最多的分类之一。
/// thumbFiles = 该分类最近带图瞬间的首图缩略图文件名（App Group widget-thumbs/ 下，最近优先），
/// widget 端可按 entry.date 轮换选一张展示。yearRemainingText = 与首页维度卡同源的"今年余额"文案。
/// thumbTitles = 与 thumbFiles 一一对应（同顺序、同数量）的瞬间标题，供中号 widget 每张图叠加标题遮罩用。
struct TimeBankWidgetTopCategory: Codable, Hashable, Sendable {
    var name: String
    var colorKey: String
    var yearRemainingText: String
    var thumbFiles: [String]
    /// 与 thumbFiles 平行的瞬间标题（顺序/数量一一对应）。老快照没有此字段时解码为空数组，
    /// widget 端按下标取 title 时须做越界兜底（thumbTitles 可能比 thumbFiles 短）。
    var thumbTitles: [String]

    init(
        name: String,
        colorKey: String,
        yearRemainingText: String,
        thumbFiles: [String],
        thumbTitles: [String] = []
    ) {
        self.name = name
        self.colorKey = colorKey
        self.yearRemainingText = yearRemainingText
        self.thumbFiles = thumbFiles
        self.thumbTitles = thumbTitles
    }

    // 向后兼容：老快照 JSON 没有 thumbTitles，缺失时给空数组，避免老 widget 进程解码失败。
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        colorKey = try c.decode(String.self, forKey: .colorKey)
        yearRemainingText = try c.decode(String.self, forKey: .yearRemainingText)
        thumbFiles = try c.decodeIfPresent([String].self, forKey: .thumbFiles) ?? []
        thumbTitles = try c.decodeIfPresent([String].self, forKey: .thumbTitles) ?? []
    }
}

/// widget 轮换记忆面的最小投影。来自某条已存入 Moment，剥离了媒体与隐私细节。
struct TimeBankWidgetMemory: Codable, Equatable, Sendable {
    var title: String
    /// 距今天数（按 happenedAt 算）。0 = 今天，约 365 = 一年前。
    var daysAgo: Int
    var colorKey: String
    /// 同月同日（"那年今日"），文案用"一年前的今天"。
    var isAnniversary: Bool
    /// createdAt 落在 2-4 天前 = 刚"冲洗好"，可走明信片面。
    var developed: Bool
    /// App Group widget-thumbs/ 目录下的缩略图文件名（widget 进程读不到 App 沙盒媒体，
    /// 由 WidgetSnapshotWriter 导出小图到共享容器）。nil = 无图，widget 显示账户色点。
    var thumbFile: String? = nil
}

struct TimeBankWidgetDimensionSnapshot: Codable, Identifiable, Equatable, Sendable {
    var id: String
    var name: String
    var iconKey: String
    var colorKey: String
    var lifetimeConsumeHours: Double
    var yearConsumeHours: Double
    var storedHours: Double
    var momentCount: Int
    var subtitle: String
    var lastMoment: TimeBankWidgetLastMoment?
}

struct TimeBankWidgetLastMoment: Codable, Equatable, Sendable {
    var title: String
    var happenedAt: Date
}

/// widget「存入此刻」按钮按下时置位；App 回到前台消费一次，弹出新存入编辑器。
/// 用 App Group 里的一个标志文件跨进程传递（与 snapshot.json 同机制，比 UserDefaults(suiteName:) 更可靠、可测）。
enum QuickDepositOpenFlag {
    static let fileName = "pending-open-deposit.flag"

    private static func flagURL(fileManager: FileManager = .default) -> URL? {
        fileManager
            .containerURL(forSecurityApplicationGroupIdentifier: TimeBankWidgetSnapshotStore.appGroupID)?
            .appendingPathComponent(fileName)
    }

    static func set(fileManager: FileManager = .default) {
        guard let url = flagURL(fileManager: fileManager) else { return }
        try? Data([1]).write(to: url, options: .atomic)
    }

    /// 存在标志文件即视为有一次待处理请求；读到后删除（消费一次）。
    static func consume(fileManager: FileManager = .default) -> Bool {
        guard let url = flagURL(fileManager: fileManager),
              fileManager.fileExists(atPath: url.path)
        else {
            return false
        }
        try? fileManager.removeItem(at: url)
        return true
    }
}

// MARK: - 存入此刻 AppIntent（App + Widget 双 target 都编译）
//
// 关键：这个 intent 必须同时编进 App 本体与 Widget 扩展，openAppWhenRun 才能在真机可靠把 App 唤到前台。
// 之前它只在 widget 扩展里定义（App target 不认识它），导致真机点「存入此刻」没反应。
// 按下后打开 App，置位「待打开存入页」标志；RootView 回前台消费一次，弹出新存入编辑器
//（用户自己选账户、写内容、加图）。不在 widget 里静默落库——存入是用户主动完成的动作。
struct QuickDepositIntent: AppIntent {
    static var title: LocalizedStringResource = "存入此刻"
    static var description = IntentDescription("打开时间银行，存下此刻。")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        QuickDepositOpenFlag.set()
        return .result()
    }
}

enum TimeBankWidgetSnapshotStore {
    static let appGroupID = "group.com.adamchen.timebank"
    static let fileName = "snapshot.widget.json"

    static func load(fileManager: FileManager = .default) -> TimeBankWidgetSnapshot? {
        for url in readableSnapshotURLs(fileManager: fileManager) {
            guard let data = try? Data(contentsOf: url),
                  let snapshot = try? decoder.decode(TimeBankWidgetSnapshot.self, from: data)
            else {
                continue
            }
            return snapshot
        }
        return nil
    }

    static func write(
        _ snapshot: TimeBankWidgetSnapshot,
        fileManager: FileManager = .default
    ) throws {
        let url = writableSnapshotURL(fileManager: fileManager)
        try fileManager.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try encoder.encode(snapshot)
        try data.write(to: url, options: [.atomic])
    }

    static func snapshotURL(fileManager: FileManager = .default) -> URL {
        writableSnapshotURL(fileManager: fileManager)
    }

    /// widget 缩略图目录（App Group 下，App 写、widget 读）。无 App Group 时返回 nil，调用方静默降级。
    static func thumbsDirectoryURL(fileManager: FileManager = .default) -> URL? {
        guard let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }
        let dir = groupURL.appendingPathComponent("widget-thumbs", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func writableSnapshotURL(fileManager: FileManager) -> URL {
        if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return groupURL.appendingPathComponent(fileName)
        }

        return fallbackSnapshotURL(fileManager: fileManager)
    }

    private static func readableSnapshotURLs(fileManager: FileManager) -> [URL] {
        var urls: [URL] = []
        if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            urls.append(groupURL.appendingPathComponent(fileName))
        }
        urls.append(fallbackSnapshotURL(fileManager: fileManager))
        return urls
    }

    private static func fallbackSnapshotURL(fileManager: FileManager) -> URL {
        let baseURL = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("TimeBank", isDirectory: true)
            .appendingPathComponent(fileName)
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

// MARK: - 一键存入队列（widget App Intent 写，App 启动/前台 drain）
//
// SwiftData store 不在 App Group（不迁移以保历史数据），所以 widget 无法直写库。
// widget 的一键存入把请求 append 到 App Group 的 JSON 队列（持久化、不丢），
// 翻转快照"今日已存入"做即时反馈；App 回到前台时 drain 队列、建真 Moment。
struct QuickDepositRequest: Codable, Equatable, Sendable {
    var id: UUID
    var happenedAt: Date
    var title: String
}

enum QuickDepositQueueStore {
    static let fileName = "quickdeposit.queue.json"

    static func loadAll(fileManager: FileManager = .default) -> [QuickDepositRequest] {
        guard let data = try? Data(contentsOf: queueURL(fileManager: fileManager)) else { return [] }
        return (try? decoder.decode([QuickDepositRequest].self, from: data)) ?? []
    }

    static func append(_ request: QuickDepositRequest, fileManager: FileManager = .default) {
        var all = loadAll(fileManager: fileManager)
        all.append(request)
        write(all, fileManager: fileManager)
    }

    /// drain 后按 id 移除已处理的请求；保留 drain 期间新 append 进来的（避免竞态丢失）。
    static func remove(ids: Set<UUID>, fileManager: FileManager = .default) {
        let remaining = loadAll(fileManager: fileManager).filter { ids.contains($0.id) == false }
        write(remaining, fileManager: fileManager)
    }

    private static func write(_ requests: [QuickDepositRequest], fileManager: FileManager) {
        let url = queueURL(fileManager: fileManager)
        try? fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let data = try? encoder.encode(requests) {
            try? data.write(to: url, options: [.atomic])
        }
    }

    private static func queueURL(fileManager: FileManager) -> URL {
        if let groupURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: TimeBankWidgetSnapshotStore.appGroupID
        ) {
            return groupURL.appendingPathComponent(fileName)
        }
        let base = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory
        return base
            .appendingPathComponent("TimeBank", isDirectory: true)
            .appendingPathComponent(fileName)
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
