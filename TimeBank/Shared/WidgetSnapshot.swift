import Foundation

struct TimeBankWidgetSnapshot: Codable, Equatable, Sendable {
    var generatedAt: Date
    var yearBalanceWeeks: Int
    var storedMomentCountTotal: Int
    var topText: String
    var dimensions: [TimeBankWidgetDimensionSnapshot]

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
        ]
    )
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
