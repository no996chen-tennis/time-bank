// TimeBank/Utility/FileStore.swift

import AVFoundation
import CoreGraphics
import Dispatch
import Foundation
import ImageIO
import UniformTypeIdentifiers

final class FileStore {
    enum FileStoreError: Error, LocalizedError {
        case invalidImageSource
        case thumbnailGenerationFailed
        case cannotCreateThumbnailDestination
        case cannotPersistThumbnail
        case invalidRelativePath(String)
        case injectedFailure(String)
        case blockingLoadFailed

        var errorDescription: String? {
            switch self {
            case .invalidImageSource:
                return "无法读取图片源文件。"
            case .thumbnailGenerationFailed:
                return "无法生成缩略图。"
            case .cannotCreateThumbnailDestination:
                return "无法创建缩略图写入目标。"
            case .cannotPersistThumbnail:
                return "无法写入缩略图。"
            case .invalidRelativePath(let path):
                return "非法相对路径：\(path)"
            case .injectedFailure(let message):
                return message
            case .blockingLoadFailed:
                return "异步媒体属性加载失败。"
            }
        }
    }

    enum FailureStage: Sendable {
        case beforeWriteOriginal
        case afterWriteOriginal
        case beforeGenerateThumbnail
        case afterGenerateThumbnail
    }

    enum MediaSource: Sendable {
        case data(Data)
        case fileURL(URL)
    }

    struct PendingMedia: Sendable {
        let source: MediaSource
        let type: MediaKind
        let preferredFileExtension: String?
        let originalFilename: String?
        let durationSeconds: Int?

        init(
            source: MediaSource,
            type: MediaKind,
            preferredFileExtension: String? = nil,
            originalFilename: String? = nil,
            durationSeconds: Int? = nil
        ) {
            self.source = source
            self.type = type
            self.preferredFileExtension = preferredFileExtension
            self.originalFilename = originalFilename
            self.durationSeconds = durationSeconds
        }

        static func image(
            data: Data,
            fileExtension: String = "heic",
            originalFilename: String? = nil
        ) -> PendingMedia {
            PendingMedia(
                source: .data(data),
                type: .image,
                preferredFileExtension: fileExtension,
                originalFilename: originalFilename,
                durationSeconds: nil
            )
        }

        static func image(fileURL: URL) -> PendingMedia {
            PendingMedia(
                source: .fileURL(fileURL),
                type: .image,
                preferredFileExtension: fileURL.pathExtension,
                originalFilename: fileURL.lastPathComponent,
                durationSeconds: nil
            )
        }

        static func video(
            data: Data,
            fileExtension: String = "mov",
            durationSeconds: Int? = nil,
            originalFilename: String? = nil
        ) -> PendingMedia {
            PendingMedia(
                source: .data(data),
                type: .video,
                preferredFileExtension: fileExtension,
                originalFilename: originalFilename,
                durationSeconds: durationSeconds
            )
        }

        static func video(fileURL: URL, durationSeconds: Int? = nil) -> PendingMedia {
            PendingMedia(
                source: .fileURL(fileURL),
                type: .video,
                preferredFileExtension: fileURL.pathExtension,
                originalFilename: fileURL.lastPathComponent,
                durationSeconds: durationSeconds
            )
        }
    }

    struct WrittenMedia: Sendable {
        let kind: MediaKind
        let relativePath: String
        let thumbnailPath: String?
        let fileSize: Int64
        let durationSeconds: Int?
        let sortIndex: Int
    }

    typealias FailureInjector = @Sendable (_ media: PendingMedia, _ index: Int, _ stage: FailureStage) throws -> Void

    nonisolated let baseURL: URL
    private nonisolated let failureInjector: FailureInjector?

    nonisolated init(
        baseURL: URL? = nil,
        fileManager: FileManager = .default,
        failureInjector: FailureInjector? = nil
    ) {
        self.failureInjector = failureInjector

        if let baseURL {
            self.baseURL = baseURL
        } else {
            let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            self.baseURL = documents.appendingPathComponent("TimeBank", isDirectory: true)
        }
    }

    nonisolated func ensureBaseDirectories() throws {
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: momentsRootURL(), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: exportsRootURL(), withIntermediateDirectories: true)
    }

    nonisolated func momentsRootURL() -> URL {
        baseURL.appendingPathComponent("moments", isDirectory: true)
    }

    nonisolated func exportsRootURL() -> URL {
        baseURL.appendingPathComponent("exports", isDirectory: true)
    }

    nonisolated func momentDirectory(for momentID: UUID) -> URL {
        momentsRootURL().appendingPathComponent(momentID.uuidString, isDirectory: true)
    }

    @discardableResult
    nonisolated func createMomentDirectory(for momentID: UUID) throws -> URL {
        try ensureBaseDirectories()
        let directoryURL = momentDirectory(for: momentID)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }

    nonisolated func removeMomentDirectoryIfExists(for momentID: UUID) throws {
        let directoryURL = momentDirectory(for: momentID)
        guard FileManager.default.fileExists(atPath: directoryURL.path) else { return }
        try FileManager.default.removeItem(at: directoryURL)
    }

    nonisolated func url(forRelativePath relativePath: String) -> URL {
        baseURL.appendingPathComponent(relativePath, isDirectory: false)
    }

    nonisolated func relativePath(forAbsoluteURL absoluteURL: URL) throws -> String {
        let standardizedBase = baseURL.standardizedFileURL.path
        let standardizedTarget = absoluteURL.standardizedFileURL.path

        guard standardizedTarget.hasPrefix(standardizedBase) else {
            throw FileStoreError.invalidRelativePath(absoluteURL.path)
        }

        var relative = String(standardizedTarget.dropFirst(standardizedBase.count))
        if relative.hasPrefix("/") {
            relative.removeFirst()
        }
        return relative
    }

    nonisolated func fileExists(atRelativePath relativePath: String) -> Bool {
        FileManager.default.fileExists(atPath: url(forRelativePath: relativePath).path)
    }

    nonisolated func data(atRelativePath relativePath: String) throws -> Data {
        try Data(contentsOf: url(forRelativePath: relativePath))
    }

    nonisolated func writeMedia(_ media: [PendingMedia], to momentID: UUID) throws -> [WrittenMedia] {
        try writeMedia(
            media,
            to: momentID,
            startingSortIndex: 0,
            startingFileNumber: 1,
            cleanupOnFailure: false
        )
    }

    nonisolated func writeMediaOffMain(_ media: [PendingMedia], to momentID: UUID) async throws -> [WrittenMedia] {
        try await Task.detached(priority: .userInitiated) { [self, media, momentID] in
            try self.writeMedia(media, to: momentID)
        }.value
    }

    nonisolated func writeAdditionalMedia(
        _ media: [PendingMedia],
        to momentID: UUID,
        startingSortIndex: Int,
        startingFileNumber: Int
    ) throws -> [WrittenMedia] {
        try writeMedia(
            media,
            to: momentID,
            startingSortIndex: startingSortIndex,
            startingFileNumber: startingFileNumber,
            cleanupOnFailure: true
        )
    }

    nonisolated func writeAdditionalMediaOffMain(
        _ media: [PendingMedia],
        to momentID: UUID,
        startingSortIndex: Int,
        startingFileNumber: Int
    ) async throws -> [WrittenMedia] {
        try await Task.detached(priority: .userInitiated) { [self, media, momentID, startingSortIndex, startingFileNumber] in
            try self.writeAdditionalMedia(
                media,
                to: momentID,
                startingSortIndex: startingSortIndex,
                startingFileNumber: startingFileNumber
            )
        }.value
    }

    nonisolated func removeFilesIfExist(atRelativePaths relativePaths: [String]) throws {
        for relativePath in relativePaths {
            let url = url(forRelativePath: relativePath)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        }
    }

    private nonisolated func writeMedia(
        _ media: [PendingMedia],
        to momentID: UUID,
        startingSortIndex: Int,
        startingFileNumber: Int,
        cleanupOnFailure: Bool
    ) throws -> [WrittenMedia] {
        let momentDir = try createMomentDirectory(for: momentID)
        var written: [WrittenMedia] = []
        var createdURLs: [URL] = []

        do {
            for (index, item) in media.enumerated() {
                let ext = resolvedExtension(for: item)
                let basename = String(format: "%02d", startingFileNumber + index)
                let fileURL = momentDir.appendingPathComponent("\(basename).\(ext)", isDirectory: false)
                let thumbURL = momentDir.appendingPathComponent("\(basename).thumb.jpg", isDirectory: false)

                try failureInjector?(item, index, .beforeWriteOriginal)
                try persistOriginal(item, to: fileURL)
                createdURLs.append(fileURL)
                try failureInjector?(item, index, .afterWriteOriginal)

                let fileSize = try fileSize(at: fileURL)

                try failureInjector?(item, index, .beforeGenerateThumbnail)
                try generateThumbnail(from: fileURL, type: item.type, output: thumbURL, maxPixelSize: 200)
                createdURLs.append(thumbURL)
                try failureInjector?(item, index, .afterGenerateThumbnail)

                let savedOriginalPath = try relativePath(forAbsoluteURL: fileURL)
                let savedThumbnailPath = try relativePath(forAbsoluteURL: thumbURL)
                let durationSeconds = try resolvedDurationSeconds(for: item, fileURL: fileURL)

                written.append(
                    WrittenMedia(
                        kind: item.type,
                        relativePath: savedOriginalPath,
                        thumbnailPath: savedThumbnailPath,
                        fileSize: fileSize,
                        durationSeconds: durationSeconds,
                        sortIndex: startingSortIndex + index
                    )
                )
            }
        } catch {
            if cleanupOnFailure {
                for url in createdURLs where FileManager.default.fileExists(atPath: url.path) {
                    try? FileManager.default.removeItem(at: url)
                }
            }
            throw error
        }

        return written
    }

    nonisolated func generateThumbnail(
        from fileURL: URL,
        type: MediaKind,
        output: URL,
        maxPixelSize: Int = 720
    ) throws {
        switch type {
        case .image:
            guard let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
                throw FileStoreError.invalidImageSource
            }

            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
            ]

            guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(
                imageSource,
                0,
                options as CFDictionary
            ) else {
                throw FileStoreError.thumbnailGenerationFailed
            }

            try persistJPEG(cgImage: thumbnail, to: output)

        case .video:
            let asset = AVURLAsset(url: fileURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: maxPixelSize, height: maxPixelSize)

            let thumbnail = try generateVideoThumbnail(
                generator: generator,
                requestedTime: CMTime(seconds: 0.1, preferredTimescale: 600)
            )

            try persistJPEG(cgImage: thumbnail, to: output)
        }
    }

    nonisolated func makeInMemoryThumbnailData(
        from data: Data,
        kind: MediaKind,
        fileExtension: String,
        maxPixelSize: Int = 400
    ) async -> Data? {
        await Task.detached(priority: .utility) { [self, data, kind, fileExtension, maxPixelSize] in
            let tempRoot = FileManager.default.temporaryDirectory
                .appendingPathComponent("TimeBankPreview-\(UUID().uuidString)", isDirectory: true)
            let sourceURL = tempRoot.appendingPathComponent("source.\(normalizedExtension(fileExtension))")
            let thumbnailURL = tempRoot.appendingPathComponent("thumb.jpg")

            do {
                try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
                defer { try? FileManager.default.removeItem(at: tempRoot) }

                try data.write(to: sourceURL, options: .atomic)
                try generateThumbnail(
                    from: sourceURL,
                    type: kind,
                    output: thumbnailURL,
                    maxPixelSize: maxPixelSize
                )
                return try Data(contentsOf: thumbnailURL)
            } catch {
                try? FileManager.default.removeItem(at: tempRoot)
                return nil
            }
        }.value
    }

    nonisolated func orphanMomentDirectories(referencedMomentIDs: Set<UUID>) throws -> [URL] {
        try ensureBaseDirectories()

        let root = momentsRootURL()
        let urls = try FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        return urls.compactMap { url in
            guard let uuid = UUID(uuidString: url.lastPathComponent) else { return url }
            return referencedMomentIDs.contains(uuid) ? nil : url
        }
    }

    @discardableResult
    nonisolated func removeOrphanMomentDirectories(referencedMomentIDs: Set<UUID>) throws -> [URL] {
        let orphans = try orphanMomentDirectories(referencedMomentIDs: referencedMomentIDs)
        for orphan in orphans {
            try FileManager.default.removeItem(at: orphan)
        }
        return orphans
    }

    private nonisolated func persistOriginal(_ media: PendingMedia, to targetURL: URL) throws {
        switch media.source {
        case .data(let data):
            try data.write(to: targetURL, options: .atomic)

        case .fileURL(let sourceURL):
            if FileManager.default.fileExists(atPath: targetURL.path) {
                try FileManager.default.removeItem(at: targetURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: targetURL)
        }
    }

    private nonisolated func fileSize(at url: URL) throws -> Int64 {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values.fileSize ?? 0)
    }

    private nonisolated func resolvedExtension(for media: PendingMedia) -> String {
        let ext = media.preferredFileExtension?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if ext.isEmpty == false {
            return normalizedExtension(ext)
        }

        switch media.source {
        case .data:
            return media.type == .image ? "heic" : "mov"
        case .fileURL(let url):
            if url.pathExtension.isEmpty == false {
                return normalizedExtension(url.pathExtension)
            }
            return media.type == .image ? "heic" : "mov"
        }
    }

    private nonisolated func normalizedExtension(_ ext: String) -> String {
        ext
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .lowercased()
    }

    private nonisolated func persistJPEG(cgImage: CGImage, to outputURL: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw FileStoreError.cannotCreateThumbnailDestination
        }

        CGImageDestinationAddImage(destination, cgImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw FileStoreError.cannotPersistThumbnail
        }
    }

    private nonisolated func resolvedDurationSeconds(for media: PendingMedia, fileURL: URL) throws -> Int? {
        guard media.type == .video else { return nil }
        if let durationSeconds = media.durationSeconds {
            return durationSeconds
        }
        return try videoDurationSeconds(at: fileURL)
    }

    private nonisolated func generateVideoThumbnail(
        generator: AVAssetImageGenerator,
        requestedTime: CMTime
    ) throws -> CGImage {
        let semaphore = DispatchSemaphore(value: 0)
        let box = BlockingResultBox<CGImage>()

        generator.generateCGImageAsynchronously(for: requestedTime) { image, _, error in
            if let error {
                box.set(.failure(error))
            } else if let image {
                box.set(.success(image))
            } else {
                box.set(.failure(FileStoreError.thumbnailGenerationFailed))
            }
            semaphore.signal()
        }

        semaphore.wait()

        guard let result = box.get() else {
            throw FileStoreError.blockingLoadFailed
        }

        return try result.get()
    }

    private nonisolated func videoDurationSeconds(at fileURL: URL) throws -> Int? {
        let duration: CMTime = try blockingLoad { [fileURL] in
            let options: [String: Any] = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
            let asset = AVURLAsset(url: fileURL, options: options)
            return try await asset.load(.duration)
        }

        let seconds = CMTimeGetSeconds(duration)
        guard seconds.isFinite, seconds > 0 else { return nil }
        return Int(seconds.rounded())
    }

    private nonisolated func blockingLoad<Value>(
        priority: TaskPriority = .userInitiated,
        _ operation: @escaping @Sendable () async throws -> Value
    ) throws -> Value {
        let semaphore = DispatchSemaphore(value: 0)
        let box = BlockingResultBox<Value>()

        Task.detached(priority: priority) {
            do {
                box.set(.success(try await operation()))
            } catch {
                box.set(.failure(error))
            }
            semaphore.signal()
        }

        semaphore.wait()

        guard let result = box.get() else {
            throw FileStoreError.blockingLoadFailed
        }

        return try result.get()
    }
}

extension FileStore: @unchecked Sendable {}

private nonisolated final class BlockingResultBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<Value, Error>?

    nonisolated func set(_ result: Result<Value, Error>) {
        lock.lock()
        self.result = result
        lock.unlock()
    }

    nonisolated func get() -> Result<Value, Error>? {
        lock.lock()
        defer { lock.unlock() }
        return result
    }
}
