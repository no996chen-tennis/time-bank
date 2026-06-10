// TimeBank/Models/Moment.swift

import Foundation
import SwiftData

enum MomentStatus: String, Codable, CaseIterable, Sendable {
    case normal
    case pendingDelete
}

@Model
final class Moment {
    @Attribute(.unique) var id: UUID
    var dimensionId: String
    var originDimensionId: String?
    var title: String?
    var note: String
    var happenedAt: Date
    var durationSeconds: Int?
    var status: MomentStatus
    var pendingDeleteAt: Date?
    var createdAt: Date
    var updatedAt: Date

    /// 「现在的我想说」回信。回看旧瞬间时写给当时自己的一句话 = 老内容产生新内容 = 再投入。
    /// SwiftData 加可选字段是兼容操作（见 Settings.swift 既有说明），不迁移 store、不丢历史数据。
    var reply: String?
    var repliedAt: Date?
    /// 明信片"冲洗好"后被查看过的时间。用于避免重复推送 / 切换盲盒的明信片成色。
    var postcardSeenAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \MediaItem.moment)
    var mediaItems: [MediaItem] = []

    init(
        id: UUID = UUID(),
        dimensionId: String = DimensionReservedID.other.rawValue,
        originDimensionId: String? = nil,
        title: String? = nil,
        note: String = "",
        happenedAt: Date = .now,
        durationSeconds: Int? = nil,
        status: MomentStatus = .normal,
        pendingDeleteAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        reply: String? = nil,
        repliedAt: Date? = nil,
        postcardSeenAt: Date? = nil,
        mediaItems: [MediaItem] = []
    ) {
        self.id = id
        self.dimensionId = dimensionId
        self.originDimensionId = originDimensionId
        self.title = title
        self.note = note
        self.happenedAt = happenedAt
        self.durationSeconds = durationSeconds
        self.status = status
        self.pendingDeleteAt = pendingDeleteAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.reply = reply
        self.repliedAt = repliedAt
        self.postcardSeenAt = postcardSeenAt
        self.mediaItems = mediaItems
    }
}
