// TimeBank/Features/Moment/Components/AsyncThumbnailImageView.swift

import Foundation
import AVFoundation
import ImageIO
import SwiftUI
import UIKit

@MainActor
final class ThumbnailImageCache {
    static let shared = ThumbnailImageCache()

    private let capacity: Int
    private var images: [String: UIImage] = [:]
    private var accessOrder: [String] = []

    init(capacity: Int = 160) {
        self.capacity = max(1, capacity)
    }

    func image(for source: ThumbnailImageSource) async -> UIImage? {
        let key = source.cacheKey
        if let cached = cachedImage(for: key) {
            return cached
        }

        guard let image = await source.loadImage() else {
            return nil
        }

        store(image, for: key)
        return image
    }

    private func cachedImage(for key: String) -> UIImage? {
        guard let image = images[key] else { return nil }
        markRecentlyUsed(key)
        return image
    }

    private func store(_ image: UIImage, for key: String) {
        images[key] = image
        markRecentlyUsed(key)

        while accessOrder.count > capacity, let oldestKey = accessOrder.first {
            accessOrder.removeFirst()
            images.removeValue(forKey: oldestKey)
        }
    }

    private func markRecentlyUsed(_ key: String) {
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
    }
}

enum ThumbnailImageSource {
    case file(relativePath: String, fileStore: FileStore)
    /// 从原图按需降采样到 maxPixelSize（卡片用，比 200px 小缩略图清晰，又比原图省内存）。
    case fileDownsampled(relativePath: String, fileStore: FileStore, maxPixelSize: Int)
    case videoFile(relativePath: String, fileStore: FileStore, maxPixelSize: Int)
    case data(key: String, data: Data)

    var cacheKey: String {
        switch self {
        case .file(let relativePath, let fileStore):
            return "file:\(fileStore.baseURL.path):\(relativePath)"
        case .fileDownsampled(let relativePath, let fileStore, let maxPixelSize):
            return "file-ds:\(fileStore.baseURL.path):\(relativePath):\(maxPixelSize)"
        case .videoFile(let relativePath, let fileStore, let maxPixelSize):
            return "video-file:\(fileStore.baseURL.path):\(relativePath):\(maxPixelSize)"
        case .data(let key, _):
            return "data:\(key)"
        }
    }

    @MainActor
    func loadImage() async -> UIImage? {
        switch self {
        case .file(let relativePath, let fileStore):
            let url = fileStore.url(forRelativePath: relativePath)
            let data = try? await Task.detached(priority: .utility) {
                try Data(contentsOf: url)
            }.value

            guard let data else {
                return nil
            }
            return UIImage(data: data)

        case .fileDownsampled(let relativePath, let fileStore, let maxPixelSize):
            let url = fileStore.url(forRelativePath: relativePath)
            return await Task.detached(priority: .utility) {
                guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                    return nil
                }
                let options: [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: max(1, maxPixelSize)
                ]
                guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                    // 原图降采样失败时回退到读全图，至少不空白。
                    if let data = try? Data(contentsOf: url) {
                        return UIImage(data: data)
                    }
                    return nil
                }
                return UIImage(cgImage: cgImage)
            }.value

        case .videoFile(let relativePath, let fileStore, let maxPixelSize):
            let url = fileStore.url(forRelativePath: relativePath)
            return await Task.detached(priority: .utility) {
                let asset = AVURLAsset(url: url)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = CGSize(width: maxPixelSize, height: maxPixelSize)

                do {
                    let image = try generator.copyCGImage(
                        at: CMTime(seconds: 0.1, preferredTimescale: 600),
                        actualTime: nil
                    )
                    return UIImage(cgImage: image)
                } catch {
                    return nil
                }
            }.value

        case .data(_, let data):
            return await Task.detached(priority: .utility) {
                guard let image = UIImage(data: data) else {
                    return nil
                }
                return image.preparingThumbnail(of: CGSize(width: 256, height: 256)) ?? image
            }.value
        }
    }
}

struct AsyncThumbnailImageView<Placeholder: View>: View {
    let source: ThumbnailImageSource?
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder()
            }
        }
        .task(id: source?.cacheKey) {
            guard let source else {
                image = nil
                return
            }

            image = await ThumbnailImageCache.shared.image(for: source)
        }
    }
}
