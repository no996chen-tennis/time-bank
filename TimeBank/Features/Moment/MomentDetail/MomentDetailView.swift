// TimeBank/Features/Moment/MomentDetail/MomentDetailView.swift

import AVKit
import SwiftData
import SwiftUI

struct MomentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.sharedMomentStore) private var sharedMomentStore
    @EnvironmentObject private var undoToastController: UndoToastController

    let momentID: UUID

    @State private var fileStore = FileStore()
    @State private var selectedMediaID: UUID?
    @State private var playableVideo: PlayableVideo?
    @State private var momentEditorRoute: MomentEditorRoute?
    @State private var showDimensionPicker = false
    @State private var showDeleteAlert = false

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
        .sheet(item: $momentEditorRoute) { route in
            MomentEditorView(route: route)
        }
        .sheet(isPresented: $showDimensionPicker) {
            if let moment,
               let dimension = dimension(for: moment) {
                DimensionPickerSheet(
                    title: "换时间账户",
                    dimensions: dimensions,
                    excludedDimensionID: dimension.id
                ) { targetDimension in
                    move(moment: moment, to: targetDimension)
                }
            }
        }
        .alert("确定删除这个时刻？", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let moment {
                    delete(moment: moment)
                }
            }
        } message: {
            if let moment {
                Text(MomentActionCopy.deleteMessage(mediaCount: moment.mediaItems.count))
            }
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

                bottomActions(for: moment)
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

    private func bottomActions(for moment: Moment) -> some View {
        HStack(spacing: TBSpace.s3) {
            Button {
                momentEditorRoute = .edit(moment)
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            .buttonStyle(MomentDetailActionButtonStyle())

            Button {
                showDimensionPicker = true
            } label: {
                Label("换时间账户", systemImage: "arrow.left.arrow.right")
            }
            .buttonStyle(MomentDetailActionButtonStyle())

            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("删除", systemImage: "trash")
            }
            .buttonStyle(MomentDetailActionButtonStyle(isDestructive: true))
        }
    }

    private func move(moment: Moment, to dimension: Dimension) {
        let store = sharedMomentStore ?? MomentStore(modelContext: modelContext)
        do {
            try store.move(moment: moment, to: dimension.id)
            showDimensionPicker = false
        } catch {
            showDimensionPicker = false
        }
    }

    private func delete(moment: Moment) {
        let store = sharedMomentStore ?? MomentStore(modelContext: modelContext)
        do {
            try store.delete(moment: moment)
            dismiss()
            Task { @MainActor in
                await Task.yield()
                undoToastController.show(message: "已删除") {
                    try? store.undoDelete(moment: moment)
                }
            }
        } catch {
            return
        }
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
        if days < 30 {
            return "发生在 \(max(1, days)) 天前"
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
        return Formatter.hoursWithMinutes(durationSeconds)
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

enum MomentActionCopy {
    static func deleteMessage(mediaCount: Int) -> String {
        if let mediaText = DimensionDetailCopy.mediaCountText(mediaCount) {
            return "存入的内容（包括 \(mediaText)）会从这里消失。你的手机相册里不受影响。"
        }
        return "存入的内容会从这里消失。你的手机相册里不受影响。"
    }
}

struct DimensionPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let dimensions: [Dimension]
    let excludedDimensionID: String?
    let onSelect: (Dimension) -> Void

    private var availableDimensions: [Dimension] {
        dimensions
            .filter { dimension in
                dimension.id != excludedDimensionID
                    && dimension.status == .visible
                    && dimension.mode == .normal
                    && (dimension.kind == .builtin || dimension.kind == .custom)
                    && dimension.name.hasPrefix("__") == false
            }
            .sorted { lhs, rhs in
                if lhs.sortIndex == rhs.sortIndex {
                    return lhs.name < rhs.name
                }
                return lhs.sortIndex < rhs.sortIndex
            }
    }

    var body: some View {
        NavigationStack {
            List(availableDimensions, id: \.id) { dimension in
                Button {
                    onSelect(dimension)
                    dismiss()
                } label: {
                    HStack(spacing: TBSpace.s3) {
                        Circle()
                            .fill(DimensionPalette.soft(for: dimension.id))
                            .frame(width: 28, height: 28)
                            .overlay {
                                Image(systemName: DimensionDetailCopy.iconSystemName(for: dimension))
                                    .font(.tbLabel)
                                    .foregroundStyle(DimensionPalette.color(for: dimension.id))
                            }

                        Text(dimension.name)
                            .font(.tbBody)
                            .foregroundStyle(Color.tbInk)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.tbBg)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct MomentDetailActionButtonStyle: ButtonStyle {
    var isDestructive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.tbLabel)
            .foregroundStyle(isDestructive ? Color.tbDanger : Color.tbInk2)
            .labelStyle(.titleAndIcon)
            .frame(maxWidth: .infinity)
            .padding(.vertical, TBSpace.s3)
            .background(Color.tbSurface.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(Capsule())
    }
}
