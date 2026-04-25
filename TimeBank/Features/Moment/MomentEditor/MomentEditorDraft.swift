// TimeBank/Features/Moment/MomentEditor/MomentEditorDraft.swift

import Foundation

struct MomentEditorRoute: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let initialDimensionID: String?

    static let newMoment = MomentEditorRoute(
        title: "存入一个时刻",
        initialDimensionID: nil
    )

    static func dimension(_ dimension: Dimension) -> MomentEditorRoute {
        MomentEditorRoute(
            title: "存入到 \(dimension.name)",
            initialDimensionID: dimension.id
        )
    }
}

struct MomentEditorDraft {
    var selectedDimensionID: String?
    var title: String
    var note: String
    var happenedAt: Date
    var durationMinutesText: String
    var mediaItems: [MomentEditorMediaItem]

    init(
        selectedDimensionID: String? = nil,
        title: String = "",
        note: String = "",
        happenedAt: Date = .now,
        durationMinutesText: String = "",
        mediaItems: [MomentEditorMediaItem] = []
    ) {
        self.selectedDimensionID = selectedDimensionID
        self.title = title
        self.note = note
        self.happenedAt = happenedAt
        self.durationMinutesText = durationMinutesText
        self.mediaItems = mediaItems
    }

    var saveableMediaItems: [MomentEditorMediaItem] {
        mediaItems.filter(\.isSaveable)
    }

    var hasContent: Bool {
        trimmed(title).isEmpty == false
            || trimmed(note).isEmpty == false
            || saveableMediaItems.isEmpty == false
    }

    var hasDiscardableChanges: Bool {
        trimmed(title).isEmpty == false
            || trimmed(note).isEmpty == false
            || sanitizedDurationMinutesText.isEmpty == false
            || mediaItems.isEmpty == false
    }

    var canSave: Bool {
        guard let selectedDimensionID, selectedDimensionID.isEmpty == false else {
            return false
        }
        return hasContent
    }

    var disabledSaveAccessibilityLabel: String? {
        hasContent ? nil : "请先添加照片、标题或笔记"
    }

    var sanitizedDurationMinutesText: String {
        durationMinutesText.filter(\.isNumber)
    }

    var durationSeconds: Int? {
        guard let minutes = Int(sanitizedDurationMinutesText), minutes > 0 else {
            return nil
        }
        return minutes * 60
    }

    func makeSaveRequest(id: UUID = UUID()) -> MomentStore.SaveRequest? {
        guard canSave, let selectedDimensionID else { return nil }

        let requestTitle = trimmed(title)
        return MomentStore.SaveRequest(
            id: id,
            dimensionId: selectedDimensionID,
            title: requestTitle.isEmpty ? nil : requestTitle,
            note: trimmed(note),
            happenedAt: happenedAt,
            durationSeconds: durationSeconds,
            media: saveableMediaItems.compactMap(\.pendingMedia)
        )
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct MomentEditorMediaItem: Identifiable {
    let id: UUID
    var kind: MediaKind
    var data: Data?
    var preferredFileExtension: String
    var originalFilename: String?
    var isFailed: Bool

    init(
        id: UUID = UUID(),
        kind: MediaKind,
        data: Data?,
        preferredFileExtension: String,
        originalFilename: String? = nil,
        isFailed: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.data = data
        self.preferredFileExtension = preferredFileExtension
        self.originalFilename = originalFilename
        self.isFailed = isFailed
    }

    var isSaveable: Bool {
        isFailed == false && data != nil
    }

    var pendingMedia: FileStore.PendingMedia? {
        guard let data, isFailed == false else { return nil }

        switch kind {
        case .image:
            return .image(
                data: data,
                fileExtension: preferredFileExtension,
                originalFilename: originalFilename
            )
        case .video:
            return .video(
                data: data,
                fileExtension: preferredFileExtension,
                durationSeconds: nil,
                originalFilename: originalFilename
            )
        }
    }

    static func image(
        data: Data,
        fileExtension: String = "heic",
        originalFilename: String? = nil
    ) -> MomentEditorMediaItem {
        MomentEditorMediaItem(
            kind: .image,
            data: data,
            preferredFileExtension: fileExtension,
            originalFilename: originalFilename
        )
    }

    static func video(
        data: Data,
        fileExtension: String = "mov",
        originalFilename: String? = nil
    ) -> MomentEditorMediaItem {
        MomentEditorMediaItem(
            kind: .video,
            data: data,
            preferredFileExtension: fileExtension,
            originalFilename: originalFilename
        )
    }

    static func failed(kind: MediaKind = .image) -> MomentEditorMediaItem {
        MomentEditorMediaItem(
            kind: kind,
            data: nil,
            preferredFileExtension: kind == .image ? "heic" : "mov",
            isFailed: true
        )
    }
}
