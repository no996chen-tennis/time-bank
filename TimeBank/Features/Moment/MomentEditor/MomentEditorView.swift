// TimeBank/Features/Moment/MomentEditor/MomentEditorView.swift

import AVKit
import CoreTransferable
import PhotosUI
import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// 把相册视频导入成临时文件 URL（系统给的临时文件即将被回收，先拷到我们自己的临时目录）。
/// 关键：避免 loadTransferable(type: Data.self) 把整段视频读进内存——这是存视频卡顿的根因。
private struct PickedVideoFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("TimeBankImport-\(UUID().uuidString).\(ext)")
            try FileManager.default.copyItem(at: received.file, to: destination)
            return PickedVideoFile(url: destination)
        }
    }
}

struct MomentEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var dimensions: [Dimension]
    @Query private var moments: [Moment]

    let route: MomentEditorRoute

    @State private var draft: MomentEditorDraft
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var fileStore = FileStore()
    @State private var isSaving = false
    @State private var isLoadingMedia = false
    @State private var showDiscardAlert = false
    @State private var toastMessage: String?
    @State private var playableVideo: MomentEditorPlayableVideo?
    @State private var playableVideoTempDirectory: URL?
    @State private var slowSaveTask: Task<Void, Never>?
    @State private var didPrefillEditDraft = false
    @State private var draggingMediaID: UUID?
    @State private var importedTempURLs: [URL] = []
    @State private var showDatePicker = false
    @FocusState private var durationFocused: Bool

    init(route: MomentEditorRoute) {
        self.route = route
        _draft = State(initialValue: MomentEditorDraft(selectedDimensionID: route.initialDimensionID))
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: TBSpace.s5) {
                    detailsSection
                    textSection
                    mediaSection
                }
                .padding(.horizontal, TBSpace.s5)
                .padding(.top, TBSpace.s4)
                .padding(.bottom, TBSpace.s8)
            }
            .background(Color.tbBg)
            .navigationTitle(route.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        requestDismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveMoment()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(Color.tbPrimary)
                        } else {
                            Text(saveButtonTitle)
                        }
                    }
                    .disabled(isSaving || draft.canSave == false)
                    .accessibilityLabel(saveAccessibilityLabel)
                }
            }
            .interactiveDismissDisabled(isSaving || draft.hasDiscardableChanges)
            .sheet(item: $playableVideo, onDismiss: cleanupPlayableVideo) { video in
                MomentEditorSystemVideoPlayerView(url: video.url)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showDatePicker) {
                datePickerSheet
            }
            .alert("还没存呢。先这样吗？", isPresented: $showDiscardAlert) {
                Button("继续编辑", role: .cancel) {}
                Button("不存了", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("你写的内容会丢。")
            }
            .overlay(alignment: .bottom) {
                toastView
            }
            .onAppear {
                prefillEditDraftIfNeeded()
                ensureSelectedDimension()
            }
            .onChange(of: editMoment?.id) { _, _ in
                prefillEditDraftIfNeeded()
            }
            .onChange(of: availableDimensionIDs) { _, _ in
                ensureSelectedDimension()
            }
            .onChange(of: pickerItems) { _, newItems in
                guard newItems.isEmpty == false else { return }
                let itemsToLoad = Array(newItems.prefix(remainingMediaSlots))
                pickerItems = []
                loadPickedItems(itemsToLoad)
            }
            .onDisappear {
                slowSaveTask?.cancel()
                // 保存仍在进行时（含用户切后台触发的 onDisappear）绝不清临时文件：
                // 跨卷 copy 回退分支正在读源文件，删源会把拷贝打断成半截 → 视频损坏。
                // 保存收尾（saveMoment 里）会在真正落库完成后再统一清理。
                if isSaving == false {
                    cleanupImportedTempFiles()
                }
            }
            .timeBankKeyboardDismissBehavior()
        }
    }

    // 合并「存入 / 发生在 / 持续」为一张紧凑卡，每行 label 左、值右，消除右侧空白。
    private var detailsSection: some View {
        editorCard {
            VStack(spacing: 0) {
                // 整行可点：用 Menu 包住整行做 label，点这一栏任意位置都能选账户（不必精准点右侧小胶囊）。
                Menu {
                    Picker("存入", selection: selectedDimensionBinding) {
                        ForEach(availableDimensions, id: \.id) { dimension in
                            Text(dimension.name)
                                .tag(dimension.id)
                        }
                    }
                } label: {
                    HStack(spacing: TBSpace.s3) {
                        Text("存入")
                            .font(.tbBody)
                            .foregroundStyle(Color.tbInk)

                        Spacer(minLength: TBSpace.s3)

                        Text(selectedDimensionName)
                            .font(.tbBody)
                            .foregroundStyle(Color.tbPrimary)
                            .lineLimit(1)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.tbLabel)
                            .foregroundStyle(Color.tbInk3)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .tint(Color.tbPrimary)

                Divider().overlay(Color.tbHair)

                // 发生在：用主题字体显示日期（不用系统灰色胶囊），点击在 sheet 里选。
                Button {
                    showDatePicker = true
                } label: {
                    HStack(spacing: TBSpace.s3) {
                        Text("发生在")
                            .font(.tbBody)
                            .foregroundStyle(Color.tbInk)

                        Spacer(minLength: TBSpace.s3)

                        Text(Formatter.absoluteDate(draft.happenedAt))
                            .font(.tbBody)
                            .foregroundStyle(Color.tbPrimary)

                        Image(systemName: "chevron.right")
                            .font(.tbLabel)
                            .foregroundStyle(Color.tbInk3)
                    }
                    .frame(minHeight: 36)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Divider().overlay(Color.tbHair)

                HStack(spacing: TBSpace.s3) {
                    Text("持续")
                        .font(.tbBody)
                        .foregroundStyle(Color.tbInk)

                    Spacer(minLength: TBSpace.s3)

                    TextField("", text: durationBinding)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.tbBody)
                        .foregroundStyle(Color.tbInk)
                        .focused($durationFocused)
                        .frame(maxWidth: 90)

                    Text("小时")
                        .font(.tbBody)
                        .foregroundStyle(Color.tbInk3)
                }
                .frame(minHeight: 36)
                .contentShape(Rectangle())
                .onTapGesture { durationFocused = true }
            }
        }
    }

    private var datePickerSheet: some View {
        NavigationStack {
            DatePicker(
                "发生在",
                selection: $draft.happenedAt,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(Color.tbPrimary)
            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
            .padding(.horizontal, TBSpace.s4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.tbBg)
            .navigationTitle("发生在")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { showDatePicker = false }
                        .foregroundStyle(Color.tbPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // 只保留「一句话概括」。它本身可写长：用 vertical-axis TextField，按内容增高。
    private var textSection: some View {
        editorCard {
            VStack(alignment: .leading, spacing: TBSpace.s2) {
                Text("回忆")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk3)

                TextField("一句话概括，也可以多写几句", text: $draft.title, axis: .vertical)
                    .font(.tbBody)
                    .foregroundStyle(Color.tbInk)
                    .lineLimit(1...8)
            }
        }
    }

    private var mediaSection: some View {
        editorCard {
            VStack(alignment: .leading, spacing: TBSpace.s3) {
                HStack(alignment: .firstTextBaseline) {
                    Text("照片和视频")
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbInk3)

                    Spacer()

                    Text(isLoadingMedia ? "正在导入" : "最多 9 张")
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbInk3)
                }

                if draft.mediaItems.isEmpty {
                    emptyMediaPicker
                } else {
                    mediaGrid
                }

                if isLoadingMedia {
                    Label("正在导入媒体，视频可能需要几秒钟", systemImage: "arrow.down.circle")
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbPrimary)
                        .transition(.opacity)
                }

                Text("图片和视频存在你的 iPhone 里，不会上传任何服务器。")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk3)
                    .lineSpacing(TBSpace.s1)
            }
        }
    }

    private var emptyMediaPicker: some View {
        PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: max(1, remainingMediaSlots),
            matching: .any(of: [.images, .videos])
        ) {
            VStack(spacing: TBSpace.s2) {
                if isLoadingMedia {
                    ProgressView()
                        .tint(Color.tbPrimary)
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 28, weight: .medium))
                }

                Text(isLoadingMedia ? "正在导入媒体" : "选照片或视频")
                    .font(.tbBody)

                if isLoadingMedia {
                    Text("视频会比照片慢一点")
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbInk3)
                }
            }
            .foregroundStyle(Color.tbPrimary)
            .frame(maxWidth: .infinity, minHeight: 112)
            .tbThemedSurface(.media)
        }
        .disabled(isLoadingMedia || remainingMediaSlots <= 0)
        .accessibilityLabel(remainingMediaSlots <= 0 ? "最多 9 张了" : "选照片或视频")
    }

    // 固定 3 列等宽方形格子，避免 .adaptive + 内层图片真实比例导致的大小不一。
    private var mediaGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: TBSpace.s3), count: 3),
            alignment: .leading,
            spacing: TBSpace.s3
        ) {
            ForEach(draft.mediaItems) { item in
                mediaTile(item)
                    .onDrag {
                        draggingMediaID = item.id
                        return NSItemProvider(object: item.id.uuidString as NSString)
                    }
                    .onDrop(
                        of: [UTType.text],
                        delegate: MomentEditorMediaDropDelegate(
                            targetItem: item,
                            mediaItems: $draft.mediaItems,
                            draggingMediaID: $draggingMediaID
                        )
                    )
            }

            if remainingMediaSlots > 0 {
                addMediaButton
            }

            if isLoadingMedia {
                mediaLoadingTile
            }
        }
    }

    private var mediaLoadingTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: TBRadius.md, style: .continuous)
                .fill(Color.tbBg3)

            VStack(spacing: TBSpace.s2) {
                ProgressView()
                    .tint(Color.tbPrimary)
                Text("导入中")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk3)
            }
        }
        .tbThemedSurface(.media)
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("正在导入媒体")
    }

    private var addMediaButton: some View {
        PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: remainingMediaSlots,
            matching: .any(of: [.images, .videos])
        ) {
            ZStack {
                RoundedRectangle(cornerRadius: TBRadius.md, style: .continuous)
                    .fill(Color.clear)
                Image(systemName: isLoadingMedia ? "hourglass" : "plus")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color.tbPrimary)
            }
            .tbThemedSurface(.media)
            .aspectRatio(1, contentMode: .fit)
        }
        .disabled(isLoadingMedia)
        .accessibilityLabel("再加一张")
    }

    @ViewBuilder
    private func mediaTile(_ item: MomentEditorMediaItem) -> some View {
        ZStack(alignment: .topTrailing) {
            // Color.clear 撑出正方形，图片以 overlay 填充并裁切——格子尺寸恒定，与图片真实比例无关。
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    mediaPreview(item)
                }
                .clipShape(RoundedRectangle(cornerRadius: TBRadius.md, style: .continuous))
                .contentShape(Rectangle())
                .onTapGesture {
                    playVideoIfPossible(item)
                }

            if item.isFailed {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.tbSurface)
                    .padding(TBSpace.s1)
                    .background(Color.tbDanger)
                    .clipShape(Circle())
                    .padding(TBSpace.s1)
                    .accessibilityLabel("这张没加载上")
            } else {
                Button {
                    removeMedia(item)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.tbSurface, Color.tbInk.opacity(0.72))
                        .padding(TBSpace.s1)
                }
                .accessibilityLabel("把这张拿掉")
            }

            if item.kind == .video, item.isFailed == false {
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.tbSurface)
                    .padding(TBSpace.s2)
                    .background(Color.tbInk.opacity(0.52))
                    .clipShape(Circle())
            }
        }
    }

    @ViewBuilder
    private func mediaPreview(_ item: MomentEditorMediaItem) -> some View {
        if item.isFailed {
            Rectangle()
                .fill(Color.tbBg3)
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.tbInk3)
                }
        } else if let relativePath = item.thumbnailPath ?? item.relativePath {
            AsyncThumbnailImageView(
                source: .file(
                    relativePath: relativePath,
                    fileStore: fileStore
                )
            ) {
                Rectangle()
                    .fill(Color.tbBg3)
                    .overlay {
                        Image(systemName: item.kind == .video ? "video.fill" : "photo")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color.tbInk3)
                    }
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else if let previewData = item.previewThumbnailData {
            AsyncThumbnailImageView(
                source: .data(
                    key: "moment-editor-preview-\(item.id.uuidString)",
                    data: previewData
                )
            ) {
                Rectangle()
                    .fill(Color.tbBg3)
                    .overlay {
                        ProgressView()
                            .tint(Color.tbPrimary)
                    }
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else if item.kind == .image,
                  let data = item.data {
            AsyncThumbnailImageView(
                source: .data(
                    key: "moment-editor-\(item.id.uuidString)",
                    data: data
                )
            ) {
                Rectangle()
                    .fill(Color.tbBg3)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color.tbInk3)
                    }
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            Rectangle()
                .fill(Color.tbBg3)
                .overlay {
                    ProgressView()
                        .tint(Color.tbPrimary)
                }
        }
    }

    private func editorCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(TBSpace.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tbThemedSurface()
    }

    @ViewBuilder
    private var toastView: some View {
        if let toastMessage {
            Text(toastMessage)
                .font(.tbBodySm)
                .foregroundStyle(Color.tbSurface)
                .padding(.horizontal, TBSpace.s4)
                .padding(.vertical, TBSpace.s3)
                .background(Color.tbInk.opacity(0.9))
                .clipShape(Capsule())
                .padding(.bottom, TBSpace.s5)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private var selectedDimensionBinding: Binding<String> {
        Binding(
            get: {
                draft.selectedDimensionID ?? availableDimensions.first?.id ?? ""
            },
            set: { newValue in
                draft.selectedDimensionID = newValue.isEmpty ? nil : newValue
            }
        )
    }

    /// 存入行 Menu label 上显示的当前所选账户名。
    private var selectedDimensionName: String {
        let id = draft.selectedDimensionID ?? availableDimensions.first?.id
        return availableDimensions.first { $0.id == id }?.name ?? ""
    }

    private var durationBinding: Binding<String> {
        Binding(
            get: { draft.durationHoursText },
            set: { newValue in
                var seenDot = false
                draft.durationHoursText = newValue.reduce(into: "") { result, char in
                    if char.isNumber {
                        result.append(char)
                    } else if char == "." && seenDot == false {
                        seenDot = true
                        result.append(char)
                    }
                }
            }
        )
    }

    private var availableDimensions: [Dimension] {
        dimensions
            .filter { dimension in
                (dimension.kind == .builtin || dimension.kind == .custom)
                    && dimension.name.hasPrefix("__") == false
                    && (dimension.status == .visible || dimension.id == route.initialDimensionID)
                    && (dimension.mode == .normal || canKeepInitialMemorialDimension(dimension))
            }
            .sorted { lhs, rhs in
                if lhs.sortIndex == rhs.sortIndex {
                    return lhs.name < rhs.name
                }
                return lhs.sortIndex < rhs.sortIndex
            }
    }

    private func canKeepInitialMemorialDimension(_ dimension: Dimension) -> Bool {
        guard dimension.id == route.initialDimensionID else { return false }
        if case .edit = route.mode {
            return true
        }
        return false
    }

    private var availableDimensionIDs: [String] {
        availableDimensions.map(\.id)
    }

    private var remainingMediaSlots: Int {
        max(0, 9 - draft.mediaItems.count)
    }

    private var saveAccessibilityLabel: String {
        if draft.canSave {
            return saveButtonTitle
        }
        return draft.disabledSaveAccessibilityLabel ?? saveButtonTitle
    }

    private var saveButtonTitle: String {
        switch route.mode {
        case .create:
            return "存入时间银行"
        case .edit:
            return "保存"
        }
    }

    private var editMoment: Moment? {
        guard case .edit(let momentID) = route.mode else { return nil }
        return moments.first { $0.id == momentID }
    }

    private var editMomentID: UUID? {
        guard case .edit(let momentID) = route.mode else { return nil }
        return momentID
    }

    private func ensureSelectedDimension() {
        if let selected = draft.selectedDimensionID,
           availableDimensionIDs.contains(selected) {
            return
        }
        draft.selectedDimensionID = availableDimensions.first?.id
    }

    private func prefillEditDraftIfNeeded() {
        guard didPrefillEditDraft == false,
              case .edit = route.mode,
              let editMoment else {
            return
        }
        draft = MomentEditorDraft.editing(moment: editMoment)
        didPrefillEditDraft = true
    }

    private func loadPickedItems(_ items: [PhotosPickerItem]) {
        guard items.isEmpty == false else { return }

        isLoadingMedia = true

        Task { @MainActor in
            // 大视频导入（loadTransferable 把系统资产整段拷到我们的临时目录）非常慢。
            // 同样用后台任务保护：用户在"正在导入"时切后台/划走，系统不会立刻挂起进程把拷贝打断，
            // 避免留下一个截断的临时视频（之后保存时会 move/copy 这半截文件 → 封面空白 + 视频损坏）。
            await withBackgroundTask(name: "TimeBank.ImportMedia") {
                var loadedItems: [MomentEditorMediaItem] = []

                for item in items {
                    let kind = mediaKind(for: item)
                    do {
                        switch kind {
                        case .image:
                            guard let data = try await item.loadTransferable(type: Data.self) else {
                                loadedItems.append(.failed(kind: .image))
                                continue
                            }
                            let fileExtension = preferredFileExtension(for: item, kind: .image)
                            loadedItems.append(.image(data: data, fileExtension: fileExtension))

                        case .video:
                            // 视频以文件 URL 导入，不整段读进内存（存视频卡顿的根因修复）。
                            guard let picked = try await item.loadTransferable(type: PickedVideoFile.self) else {
                                loadedItems.append(.failed(kind: .video))
                                continue
                            }
                            importedTempURLs.append(picked.url)
                            loadedItems.append(.video(fileURL: picked.url))
                        }
                    } catch {
                        loadedItems.append(.failed(kind: kind))
                    }
                }

                draft.mediaItems.append(contentsOf: loadedItems)
                isLoadingMedia = false
                generatePreviewThumbnails(for: loadedItems)

                if loadedItems.isEmpty == false,
                   loadedItems.allSatisfy(\.isFailed) {
                    showToast("照片没加载上。换一张试试？")
                }
            }
        }
    }

    private func generatePreviewThumbnails(for items: [MomentEditorMediaItem]) {
        for item in items where item.isFailed == false && item.thumbnailPath == nil {
            Task { @MainActor in
                let previewData: Data?
                if let fileURL = item.fileURL {
                    // 视频/文件 URL：封面直接从文件首帧生成（秒显）。
                    previewData = await fileStore.makeInMemoryThumbnailData(
                        fromMediaURL: fileURL,
                        kind: item.kind
                    )
                } else if let data = item.data {
                    previewData = await fileStore.makeInMemoryThumbnailData(
                        from: data,
                        kind: item.kind,
                        fileExtension: item.preferredFileExtension
                    )
                } else {
                    previewData = nil
                }

                guard let previewData,
                      let index = draft.mediaItems.firstIndex(where: { $0.id == item.id }) else {
                    return
                }

                draft.mediaItems[index].previewThumbnailData = previewData
            }
        }
    }

    private func mediaKind(for item: PhotosPickerItem) -> MediaKind {
        if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) || $0.conforms(to: .video) }) {
            return .video
        }
        return .image
    }

    private func preferredFileExtension(for item: PhotosPickerItem, kind: MediaKind) -> String {
        let matchingType = item.supportedContentTypes.first { type in
            switch kind {
            case .image:
                return type.conforms(to: .image)
            case .video:
                return type.conforms(to: .movie) || type.conforms(to: .video)
            }
        }

        return matchingType?.preferredFilenameExtension ?? (kind == .image ? "heic" : "mov")
    }

    private func removeMedia(_ item: MomentEditorMediaItem) {
        draft.mediaItems.removeAll { $0.id == item.id }
    }

    private func playVideoIfPossible(_ item: MomentEditorMediaItem) {
        guard item.kind == .video, item.isFailed == false else { return }

        if let relativePath = item.relativePath {
            playableVideo = MomentEditorPlayableVideo(url: fileStore.url(forRelativePath: relativePath))
            return
        }

        // 以文件 URL 导入的视频：直接播放该临时文件，无需写临时副本。
        if let fileURL = item.fileURL {
            playableVideo = MomentEditorPlayableVideo(url: fileURL)
            return
        }

        guard let data = item.data else { return }
        Task { @MainActor in
            guard let playable = await makeTemporaryPlayableVideo(
                data: data,
                fileExtension: item.preferredFileExtension
            ) else {
                showToast("视频暂时打不开。再试试？")
                return
            }

            playableVideoTempDirectory = playable.temporaryDirectory
            playableVideo = MomentEditorPlayableVideo(url: playable.url)
        }
    }

    private func makeTemporaryPlayableVideo(
        data: Data,
        fileExtension: String
    ) async -> (url: URL, temporaryDirectory: URL)? {
        await Task.detached(priority: .userInitiated) {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("TimeBankEditorPlayback-\(UUID().uuidString)", isDirectory: true)
            let ext = fileExtension
                .trimmingCharacters(in: CharacterSet(charactersIn: "."))
                .lowercased()
            let url = directory.appendingPathComponent("preview.\(ext.isEmpty ? "mov" : ext)")

            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try data.write(to: url, options: .atomic)
                return (url, directory)
            } catch {
                try? FileManager.default.removeItem(at: directory)
                return nil
            }
        }.value
    }

    private func cleanupImportedTempFiles() {
        for url in importedTempURLs {
            try? FileManager.default.removeItem(at: url)
        }
        importedTempURLs = []
    }

    private func cleanupPlayableVideo() {
        if let playableVideoTempDirectory {
            try? FileManager.default.removeItem(at: playableVideoTempDirectory)
        }
        playableVideoTempDirectory = nil
    }

    private func requestDismiss() {
        if draft.hasDiscardableChanges {
            showDiscardAlert = true
        } else {
            dismiss()
        }
    }

    private func saveMoment() {
        guard draft.canSave else { return }

        isSaving = true
        slowSaveTask?.cancel()
        slowSaveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            if Task.isCancelled == false, isSaving {
                showToast("保存比想象中慢了一点，再等等")
            }
        }

        Task { @MainActor in
            // 关键：整个保存（写媒体文件 → moveItem/copy → 生成缩略图 → modelContext.save() 落库）
            // 包在 begin/endBackgroundTask 里。大视频保存很慢，用户存完立刻退到桌面/划走 App 时，
            // 若没有后台任务，iOS 会立刻挂起进程 → 保存被打断在"文件已 move 进 moment 目录但 DB 还没提交"，
            // 下次启动孤儿清理会把这个没被记录引用的视频目录删掉 → 封面空白 + 视频永久丢失。
            // 有了后台任务，系统会继续给几十秒把保存跑完再挂起。
            await withBackgroundTask(name: "TimeBank.SaveMoment") {
                do {
                    let store = MomentStore(modelContext: modelContext)
                    switch route.mode {
                    case .create:
                        guard let request = draft.makeSaveRequest() else {
                            isSaving = false
                            slowSaveTask?.cancel()
                            return
                        }
                        _ = try await store.save(moment: request)
                        isSaving = false
                        slowSaveTask?.cancel()
                        // 已落库成功：媒体文件此时要么已 move 进 moment 目录、要么已 copy 完毕，
                        // 源临时文件不再需要，在这里显式清理（不依赖 onDisappear 的时序，避免泄漏）。
                        cleanupImportedTempFiles()
                        showToast("存下了。")
                        try? await Task.sleep(nanoseconds: 650_000_000)
                        dismiss()

                    case .edit(let momentID):
                        guard let updateRequest = draft.makeUpdateRequest(momentID: momentID) else {
                            isSaving = false
                            slowSaveTask?.cancel()
                            return
                        }
                        _ = try await store.update(moment: updateRequest)
                        isSaving = false
                        slowSaveTask?.cancel()
                        cleanupImportedTempFiles()
                        dismiss()
                    }
                } catch {
                    isSaving = false
                    slowSaveTask?.cancel()
                    showToast("没存下。再试试？")
                }
            }
        }
    }

    /// 在一个 UIApplication 后台任务的保护下执行 `work`，避免大视频导入/保存这类耗时操作
    /// 在用户切后台/划走 App 时被系统立刻挂起而中断（拷贝写一半、DB 没提交 → 数据丢失）。
    /// begin/end 严格成对：无论 work 正常返回还是抛错，defer 都会 endBackgroundTask，杜绝后台任务泄漏。
    @MainActor
    private func withBackgroundTask(
        name: String,
        _ work: () async -> Void
    ) async {
        let application = UIApplication.shared
        var taskID: UIBackgroundTaskIdentifier = .invalid
        taskID = application.beginBackgroundTask(withName: name) {
            // 系统后台时间即将耗尽时的兜底回调：结束任务，防止被强杀。
            if taskID != .invalid {
                application.endBackgroundTask(taskID)
                taskID = .invalid
            }
        }

        defer {
            if taskID != .invalid {
                application.endBackgroundTask(taskID)
                taskID = .invalid
            }
        }

        await work()
    }

    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            toastMessage = message
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            withAnimation(.easeOut(duration: 0.2)) {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }
}

private struct MomentEditorMediaDropDelegate: DropDelegate {
    let targetItem: MomentEditorMediaItem
    @Binding var mediaItems: [MomentEditorMediaItem]
    @Binding var draggingMediaID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggingMediaID,
              draggingMediaID != targetItem.id,
              let fromIndex = mediaItems.firstIndex(where: { $0.id == draggingMediaID }),
              let toIndex = mediaItems.firstIndex(where: { $0.id == targetItem.id }) else {
            return
        }

        withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
            let item = mediaItems.remove(at: fromIndex)
            mediaItems.insert(item, at: toIndex)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingMediaID = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

private struct MomentEditorPlayableVideo: Identifiable {
    let id = UUID()
    let url: URL
}

private struct MomentEditorSystemVideoPlayerView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let viewController = AVPlayerViewController()
        viewController.player = AVPlayer(url: url)
        viewController.player?.play()
        return viewController
    }

    func updateUIViewController(_ viewController: AVPlayerViewController, context: Context) {}
}
