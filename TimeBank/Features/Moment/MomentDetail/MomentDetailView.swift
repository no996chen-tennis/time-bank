// TimeBank/Features/Moment/MomentDetail/MomentDetailView.swift

import AVKit
import SwiftData
import SwiftUI

struct MomentDetailView: View {
    let momentID: UUID

    @State private var fileStore = FileStore()
    @State private var selectedMediaID: UUID?
    @State private var playableVideo: PlayableVideo?

    @Query private var dimensions: [Dimension]
    @Query private var moments: [Moment]

    var body: some View {
        Group {
            if let moment {
                detailContent(for: moment)
            } else {
                ProgressView()
                    .tint(Color.tbPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.tbBg)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $playableVideo) { video in
            SystemVideoPlayerView(url: video.url)
                .ignoresSafeArea()
        }
    }

    private var moment: Moment? {
        moments.first { $0.id == momentID }
    }

    private var navigationTitle: String {
        guard let moment else {
            return ""
        }
        return MomentDetailPresentation.title(for: moment)
    }

    private func dimension(for moment: Moment) -> Dimension? {
        dimensions.first { $0.id == moment.dimensionId }
    }

    private func sortedMedia(for moment: Moment) -> [MediaItem] {
        moment.mediaItems.sorted { lhs, rhs in
            if lhs.sortIndex == rhs.sortIndex {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.sortIndex < rhs.sortIndex
        }
    }

    private func detailContent(for moment: Moment) -> some View {
        let mediaItems = sortedMedia(for: moment)
        let dimension = dimension(for: moment)

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: TBSpace.s5) {
                if mediaItems.isEmpty == false {
                    mediaCarousel(mediaItems)
                }

                VStack(alignment: .leading, spacing: TBSpace.s4) {
                    Text(MomentDetailPresentation.title(for: moment))
                        .font(.tbHeadL)
                        .foregroundStyle(Color.tbInk)
                        .lineSpacing(TBSpace.s1)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(MomentDetailPresentation.infoLine(for: moment))
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbInk3)

                    chipGrid(
                        chips: MomentDetailPresentation.chips(
                            for: moment,
                            dimension: dimension
                        ),
                        dimensionID: dimension?.id
                    )

                    if let note = MomentDetailPresentation.note(for: moment) {
                        Text(note)
                            .font(.tbBody)
                            .foregroundStyle(Color.tbInk2)
                            .lineSpacing(TBSpace.s1)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, TBSpace.s1)
                    }
                }
                .padding(TBSpace.s5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.tbSurface)
                .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg, style: .continuous))
                .modifier(DimensionDetailSoftShadowModifier())
            }
            .padding(.horizontal, TBSpace.s5)
            .padding(.top, TBSpace.s4)
            .padding(.bottom, TBSpace.s8)
        }
        .background(Color.tbBg)
    }

    private func mediaCarousel(_ mediaItems: [MediaItem]) -> some View {
        TabView(selection: $selectedMediaID) {
            ForEach(mediaItems) { media in
                mediaPage(media)
                    .tag(Optional(media.id))
            }
        }
        .tabViewStyle(.page(indexDisplayMode: mediaItems.count > 1 ? .automatic : .never))
        .frame(height: 396)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: TBRadius.lg, style: .continuous)
                .fill(Color.tbSurface)
        )
        .modifier(DimensionDetailSoftShadowModifier())
        .onAppear {
            if selectedMediaID == nil {
                selectedMediaID = mediaItems.first?.id
            }
        }
    }

    @ViewBuilder
    private func mediaPage(_ media: MediaItem) -> some View {
        let displayPath = media.mediaKind == .video
            ? (media.thumbnailPath ?? media.relativePath)
            : media.relativePath

        ZStack {
            AsyncThumbnailImageView(
                source: .file(
                    relativePath: displayPath,
                    fileStore: fileStore
                )
            ) {
                ZStack {
                    Color.tbBg2

                    Image(systemName: media.mediaKind == .video ? "video.fill" : "photo")
                        .font(.tbHeadL)
                        .foregroundStyle(Color.tbInk3)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            if media.mediaKind == .video {
                Button {
                    playableVideo = PlayableVideo(url: fileStore.url(forRelativePath: media.relativePath))
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.tbSurface)
                        .padding(TBSpace.s5)
                        .background(Color.tbInk.opacity(0.62))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("播放视频")
            }
        }
    }

    private func chipGrid(chips: [String], dimensionID: String?) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 92), spacing: TBSpace.s2, alignment: .leading)],
            alignment: .leading,
            spacing: TBSpace.s2
        ) {
            ForEach(chips, id: \.self) { chip in
                detailChip(chip, dimensionID: chip.hasPrefix("♡") ? dimensionID : nil)
            }
        }
    }

    private func detailChip(_ text: String, dimensionID: String?) -> some View {
        Text(text)
            .font(.tbLabel)
            .foregroundStyle(dimensionID.map { DimensionPalette.color(for: $0) } ?? Color.tbInk2)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, TBSpace.s3)
            .padding(.vertical, TBSpace.s2)
            .background(dimensionID.map { DimensionPalette.soft(for: $0) } ?? Color.tbBg2)
            .clipShape(Capsule())
            .accessibilityLabel(text)
    }
}

enum MomentDetailPresentation {
    static func title(for moment: Moment) -> String {
        DimensionDetailCopy.timelineTitle(for: moment)
    }

    static func note(for moment: Moment) -> String? {
        let note = moment.note.trimmingCharacters(in: .whitespacesAndNewlines)
        return note.isEmpty ? nil : note
    }

    static func infoLine(for moment: Moment, now: Date = .now) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let referenceNow = max(now, moment.happenedAt)
        let seconds = max(0, referenceNow.timeIntervalSince(moment.happenedAt))

        if seconds < 24 * 60 * 60 {
            let hours = max(0, Int(seconds / 3600))
            return "发生在 \(hours) 小时前"
        }

        let days = calendar.dateComponents([.day], from: moment.happenedAt, to: referenceNow).day ?? 0
        if days < 7 {
            return "发生在 \(max(1, days)) 天前"
        }
        if days < 30 {
            return Formatter.relativeTime(moment.happenedAt, relativeTo: referenceNow)
        }

        let months = calendar.dateComponents([.month], from: moment.happenedAt, to: referenceNow).month ?? 0
        if months < 12 {
            return "\(max(1, months)) 个月前 · \(Formatter.absoluteDate(moment.happenedAt))"
        }

        return Formatter.relativeTime(moment.happenedAt, relativeTo: referenceNow)
    }

    static func chips(for moment: Moment, dimension: Dimension?) -> [String] {
        var chips: [String] = []

        if let dimension {
            chips.append("♡ \(dimension.name)")
        }

        chips.append(durationChip(for: moment))

        if let mediaText = DimensionDetailCopy.mediaCountText(moment.mediaItems.count) {
            chips.append(mediaText)
        }

        return chips
    }

    private static func durationChip(for moment: Moment) -> String {
        guard let durationSeconds = moment.durationSeconds else {
            return "不计时长"
        }
        return Formatter.hoursReadable(Double(durationSeconds) / 3600.0)
    }
}

private struct PlayableVideo: Identifiable {
    let id = UUID()
    let url: URL
}

private struct SystemVideoPlayerView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let viewController = AVPlayerViewController()
        viewController.player = AVPlayer(url: url)
        viewController.player?.play()
        return viewController
    }

    func updateUIViewController(_ viewController: AVPlayerViewController, context: Context) {}

    static func dismantleUIViewController(_ viewController: AVPlayerViewController, coordinator: ()) {
        viewController.player?.pause()
    }
}
