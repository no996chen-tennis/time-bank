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
    var hasSeenPrivacyIntro: Bool
    var momentCountForReviewTrigger: Int

    // 注：appearance 字段已移除（V1.3.2 + Codex review 二轮后定稿）。
    // 产品仅 Light Mode，无 Dark Mode 规划。如未来需要恢复，加字段是 SwiftData 兼容操作。
    // 详见 PRD §0.6 + §7.6 + Use-Cases UC-8.3。

    init(
        id: UUID = Settings.singletonID,
        narrativeMode: NarrativeMode = .positive,
        notificationEnabled: Bool = false,
        notificationHour: Int = 9,
        notificationTone: NotificationTone = .neutral,
        relationshipNoteOptIn: Bool = false,
        widgetPreferredDimensions: [String] = [],
        widgetTone: WidgetTone = .warm,
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
