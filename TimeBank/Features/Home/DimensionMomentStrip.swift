// TimeBank/Features/Home/DimensionMomentStrip.swift

import SwiftUI

/// 维度卡内的横滑小图带：把某维度下已存入的瞬间首图横向铺开。
/// 纯展示组件——靠入参，不持 @Query，不放 NavigationLink（导航由父层经 onTapMoment 处理）。
struct DimensionMomentStrip: View {
    let dimension: Dimension
    /// 传 normalMoments（外部已过滤 status == .normal）。
    let moments: [Moment]
    let fileStore: FileStore
    var thumbSize: CGFloat = 64
    var cornerRadius: CGFloat = TBRadius.sm
    var onTapMoment: (Moment) -> Void

    @Environment(\.displayScale) private var displayScale

    /// 该维度下、按 happenedAt 倒序（同刻按 createdAt 倒序）排好、且能取到首图的瞬间。
    private var displayMoments: [Moment] {
        moments
            .filter { $0.dimensionId == dimension.id && $0.status == .normal }
            .sorted { lhs, rhs in
                if lhs.happenedAt == rhs.happenedAt {
                    return lhs.createdAt > rhs.createdAt
                }
                return lhs.happenedAt > rhs.happenedAt
            }
    }

    var body: some View {
        let withImage = nonEmptyMoments()
        if withImage.isEmpty == false {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: TBSpace.s2) {
                    ForEach(withImage, id: \.moment.id) { entry in
                        thumb(for: entry.moment, media: entry.media)
                    }
                }
                .padding(.trailing, TBSpace.s6)   // 右侧留白：让卡片右缘空白区可触发 TabView 翻页
            }
            .frame(height: thumbSize)
        } else {
            placeholder
        }
    }

    private struct StripEntry {
        let moment: Moment
        let media: MediaItem
    }

    /// 每个 moment 取首图（sortIndex 最小、优先 mediaKind==.image 或 thumbnailPath != nil）。
    private func nonEmptyMoments() -> [StripEntry] {
        displayMoments.compactMap { moment in
            let sorted = moment.mediaItems.sorted { $0.sortIndex < $1.sortIndex }
            guard let media = sorted.first(where: { $0.mediaKind == .image || $0.thumbnailPath != nil }) else {
                return nil
            }
            return StripEntry(moment: moment, media: media)
        }
    }

    private func thumb(for moment: Moment, media: MediaItem) -> some View {
        let targetPixels = max(200, Int((thumbSize * displayScale).rounded()))
        return Button {
            onTapMoment(moment)
        } label: {
            AsyncThumbnailImageView(source: source(for: media, maxPixelSize: targetPixels)) {
                ZStack {
                    Color.tbBg2
                    Image(systemName: "photo")
                        .font(.tbBodySm)
                        .foregroundStyle(Color.tbInk3)
                }
            }
            .frame(width: thumbSize, height: thumbSize)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                if media.mediaKind == .video {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.tbSurface)
                        .padding(3)
                        .background(Color.tbInk.opacity(0.6))
                        .clipShape(Circle())
                        .padding(3)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func source(for media: MediaItem, maxPixelSize: Int) -> ThumbnailImageSource {
        if media.mediaKind == .video {
            return .videoFile(relativePath: media.relativePath, fileStore: fileStore, maxPixelSize: maxPixelSize)
        }
        return .fileDownsampled(relativePath: media.relativePath, fileStore: fileStore, maxPixelSize: maxPixelSize)
    }

    /// 无带图瞬间：占位块 + photo icon + 邀请式文案。
    private var placeholder: some View {
        HStack(spacing: TBSpace.s2) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(DimensionPalette.soft(for: dimension))
                Image(systemName: "photo")
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk3)
            }
            .frame(width: thumbSize, height: thumbSize)

            Text("还没有照片，去存一张")
                .font(.tbBodySm)
                .foregroundStyle(Color.tbInk3)

            Spacer(minLength: 0)
        }
        .frame(height: thumbSize)
    }
}
