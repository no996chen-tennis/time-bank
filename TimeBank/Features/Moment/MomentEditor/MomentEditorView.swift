// TimeBank/Features/Moment/MomentEditor/MomentEditorView.swift

import AVKit
import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

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

    init(route: MomentEditorRoute) {
        self.route = route
        _draft = State(initialValue: MomentEditorDraft(selectedDimensionID: route.initialDimensionID))
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: TBSpace.s5) {
                    dimensionSection
                    timeSection
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
            }
            .timeBankKeyboardDismissBehavior()
        }
    }

    private var dimensionSection: some View {
        editorCard {
            VStack(alignment: .leading, spacing: TBSpace.s3) {
                Text("存入")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk3)

                Picker("存入", selection: selectedDimensionBinding) {
                    ForEach(availableDimensions, id: \.id) { dimension in
                        Text(dimension.name)
                            .tag(dimension.id)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.tbPrimary)
            }
        }
    }

    private var timeSection: some View {
        editorCard {
            VStack(alignment: .leading, spacing: TBSpace.s4) {
                DatePicker(
                    "发生在",
                    selection: $draft.happenedAt,
                    displayedComponents: [.date]
                )
                .font(.tbBody)
                .foregroundStyle(Color.tbInk)
                .tint(Color.tbPrimary)
                .environment(\.locale, Locale(identifier: "zh_Hans_CN"))

                Divider()
                    .overlay(Color.tbHair)

                HStack(spacing: TBSpace.s3) {
                    Text("持续")
                        .font(.tbBody)
                        .foregroundStyle(Color.tbInk)

                    Spacer(minLength: TBSpace.s3)

                    TextField("不计（也是一种）", text: durationBinding)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(.tbBody)
                        .foregroundStyle(Color.tbInk)

                    if draft.sanitizedDurationMinutesText.isEmpty == false {
                        Text("分钟")
                            .font(.tbBodySm)
                            .foregroundStyle(Color.tbInk3)
                    }
                }
            }
        }
    }

    private var textSection: some View {
        editorCard {
            VStack(alignment: .leading, spacing: TBSpace.s4) {
                labeledTextField(
                    title: "回忆",
                    placeholder: "一句话概括",
                    text: $draft.title
                )

                Divider()
                    .overlay(Color.tbHair)

                VStack(alignment: .leading, spacing: TBSpace.s2) {
                    Text("想说点什么")
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbInk3)

                    ZStack(alignment: .topLeading) {
                        if draft.note.isEmpty {
                            Text("过了几年，你会想看到什么？")
                                .font(.tbBody)
                                .foregroundStyle(Color.tbInk3)
                                .padding(.top, TBSpace.s2)
                                .padding(.horizontal, TBSpace.s1)
                        }

                        TextEditor(text: $draft.note)
                            .font(.tbBody)
                            .foregroundStyle(Color.tbInk)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 120)
                            .padding(.horizontal, -TBSpace.s1)
                    }
                }
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

    private var mediaGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 82), spacing: TBSpace.s3)],
            alignment: .leading,
            spacing: TBSpace.s3
        ) {
            ForEach(draft.mediaItems) { item in
                mediaTile(item)
                    .frame(maxWidth: .infinity)
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
            mediaPreview(item)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: TBRadius.md, style: .continuous))
                .frame(maxWidth: .infinity)
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
                .aspectRatio(1, contentMode: .fill)
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
                .aspectRatio(1, contentMode: .fill)
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
                .aspectRatio(1, contentMode: .fill)
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

    private func labeledTextField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: TBSpace.s2) {
            Text(title)
                .font(.tbLabel)
                .foregroundStyle(Color.tbInk3)

            TextField(placeholder, text: text)
                .font(.tbBody)
                .foregroundStyle(Color.tbInk)
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

    private var durationBinding: Binding<String> {
        Binding(
            get: { draft.durationMinutesText },
            set: { draft.durationMinutesText = $0.filter(\.isNumber) }
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
            var loadedItems: [MomentEditorMediaItem] = []

            for item in items {
                let kind = mediaKind(for: item)
                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        loadedItems.append(.failed(kind: kind))
                        continue
                    }

                    let fileExtension = preferredFileExtension(for: item, kind: kind)
                    switch kind {
                    case .image:
                        loadedItems.append(.image(data: data, fileExtension: fileExtension))
                    case .video:
                        loadedItems.append(.video(data: data, fileExtension: fileExtension))
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

    private func generatePreviewThumbnails(for items: [MomentEditorMediaItem]) {
        for item in items where item.isFailed == false && item.thumbnailPath == nil {
            guard let data = item.data else { continue }

            Task { @MainActor in
                let previewData = await fileStore.makeInMemoryThumbnailData(
                    from: data,
                    kind: item.kind,
                    fileExtension: item.preferredFileExtension
                )

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
                    dismiss()
                }
            } catch {
                isSaving = false
                slowSaveTask?.cancel()
                showToast("没存下。再试试？")
            }
        }
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
