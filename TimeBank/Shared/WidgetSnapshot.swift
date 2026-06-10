import Foundation

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

    init(
        generatedAt: Date,
        yearBalanceWeeks: Int,
        storedMomentCountTotal: Int,
        topText: String,
        dimensions: [TimeBankWidgetDimensionSnapshot],
        todayDeposited: Bool = false,
        memories: [TimeBankWidgetMemory] = []
    ) {
        self.generatedAt = generatedAt
        self.yearBalanceWeeks = yearBalanceWeeks
        self.storedMomentCountTotal = storedMomentCountTotal
        self.topText = topText
        self.dimensions = dimensions
        self.todayDeposited = todayDeposited
        self.memories = memories
    }

    // 向后兼容：旧快照 JSON 没有 todayDeposited / memories，缺失时给默认值，
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
        ]
    )
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
