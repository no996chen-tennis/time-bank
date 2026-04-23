// TimeBank/Models/Settings.swift

import Foundation
import SwiftData

enum NarrativeMode: String, Codable, CaseIterable, Sendable {
    case positive
    case reverse
}

enum NotificationTone: String, Codable, CaseIterable, Sendable {
    case neutral
    case reflective
    case poetic
}

enum WidgetTone: String, Codable, CaseIterable, Sendable {
    case warm
    case minimal
    case poetic
}

/// 仅 Light Mode（无 Dark Mode 规划，参考 PRD §0.6 + §7.6）。
/// 字段保留是为了让 SwiftData schema 稳定，方便未来若产品方向变化能加 case 兼容旧数据。
enum Appearance: String, Codable, CaseIterable, Sendable {
    case systemLight
}

@Model
final class Settings {
    static let singletonID = UUID(uuidString: "0F5D71FB-C180-4CB6-9A42-B4263C3F0202")!

    @Attribute(.unique) var id: UUID

    var narrativeMode: NarrativeMode
    var notificationEnabled: Bool
    var notificationHour: Int
    var notificationTone: NotificationTone
    var relationshipNoteOptIn: Bool
    var widgetPreferredDimensions: [String]
    var widgetTone: WidgetTone
    var appearance: Appearance
    var hasSeenPrivacyIntro: Bool
    var momentCountForReviewTrigger: Int

    init(
        id: UUID = Settings.singletonID,
        narrativeMode: NarrativeMode = .positive,
        notificationEnabled: Bool = false,
        notificationHour: Int = 9,
        notificationTone: NotificationTone = .neutral,
        relationshipNoteOptIn: Bool = false,
        widgetPreferredDimensions: [String] = [],
        widgetTone: WidgetTone = .warm,
        appearance: Appearance = .systemLight,
        hasSeenPrivacyIntro: Bool = false,
        momentCountForReviewTrigger: Int = 0
    ) {
        self.id = id
        self.narrativeMode = narrativeMode
        self.notificationEnabled = notificationEnabled
        self.notificationHour = notificationHour
        self.notificationTone = notificationTone
        self.relationshipNoteOptIn = relationshipNoteOptIn
        self.widgetPreferredDimensions = widgetPreferredDimensions
        self.widgetTone = widgetTone
        self.appearance = appearance
        self.hasSeenPrivacyIntro = hasSeenPrivacyIntro
        self.momentCountForReviewTrigger = momentCountForReviewTrigger
    }

    static func fetch(in modelContext: ModelContext) throws -> Settings? {
        let id = Settings.singletonID
        let descriptor = FetchDescriptor<Settings>(predicate: #Predicate { $0.id == id })
        return try modelContext.fetch(descriptor).first
    }

    @discardableResult
    static func fetchOrCreateDefault(in modelContext: ModelContext) throws -> Settings {
        if let existing = try fetch(in: modelContext) {
            return existing
        }

        let settings = Settings()
        modelContext.insert(settings)
        try modelContext.save()
        return settings
    }
}
