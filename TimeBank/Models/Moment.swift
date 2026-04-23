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
        self.mediaItems = mediaItems
    }
}
