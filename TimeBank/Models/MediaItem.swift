// TimeBank/Models/MediaItem.swift

import Foundation
import SwiftData

enum MediaKind: String, Codable, CaseIterable, Sendable {
    case image
    case video
}

@Model
final class MediaItem {
    @Attribute(.unique) var id: UUID
    var momentId: UUID
    var type: String
    var relativePath: String
    var thumbnailPath: String?
    var fileSize: Int64
    var durationSeconds: Int?
    var sortIndex: Int
    var createdAt: Date

    var moment: Moment?

    init(
        id: UUID = UUID(),
        momentId: UUID = UUID(),
        type: String = MediaKind.image.rawValue,
        relativePath: String = "",
        thumbnailPath: String? = nil,
        fileSize: Int64 = 0,
        durationSeconds: Int? = nil,
        sortIndex: Int = 0,
        createdAt: Date = .now,
        moment: Moment? = nil
    ) {
        self.id = id
        self.momentId = momentId
        self.type = type
        self.relativePath = relativePath
        self.thumbnailPath = thumbnailPath
        self.fileSize = fileSize
        self.durationSeconds = durationSeconds
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.moment = moment
    }

    var mediaKind: MediaKind {
        get { MediaKind(rawValue: type) ?? .image }
        set { type = newValue.rawValue }
    }
}
