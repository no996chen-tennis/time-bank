// TimeBank/Features/Moment/MomentEditor/MomentEditorView.swift

import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct MomentEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var dimensions: [Dimension]

    let route: MomentEditorRoute

    @State private var draft: MomentEditorDraft
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isSaving = false
    @State private var isLoadingMedia = false
    @State private var showDiscardAlert = false
    @State private var toastMessage: String?
    @State private var slowSaveTask: Task<Void, Never>?

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
                            Text("存入时间银行")
                        }
                    }
                    .disabled(isSaving || draft.canSave == false)
                    .accessibilityLabel(saveAccessibilityLabel)
                }
            }
            .interactiveDismissDisabled(isSaving || draft.hasDiscardableChanges)
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
                ensureSelectedDimension()
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
                    title: "叫什么",
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

                    Text("最多 9 张")
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbInk3)
                }

                if draft.mediaItems.isEmpty {
                    emptyMediaPicker
                } else {
                    mediaGrid
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
                Image(systemName: isLoadingMedia ? "hourglass" : "photo.on.rectangle.angled")
                    .font(.system(size: 28, weight: .medium))

                Text("选照片或视频")
                    .font(.tbBody)
            }
            .foregroundStyle(Color.tbPrimary)
            .frame(maxWidth: .infinity, minHeight: 136)
            .background(Color.tbBg2)
            .clipShape(RoundedRectangle(cornerRadius: TBRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TBRadius.md, style: .continuous)
                    .stroke(Color.tbHair, lineWidth: 1)
            )
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
            }

            if remainingMediaSlots > 0 {
                addMediaButton
            }
        }
    }

    private var addMediaButton: some View {
        PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: remainingMediaSlots,
            matching: .any(of: [.images, .videos])
        ) {
            ZStack {
                RoundedRectangle(cornerRadius: TBRadius.md, style: .continuous)
                    .fill(Color.tbBg2)
                Image(systemName: isLoadingMedia ? "hourglass" : "plus")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color.tbPrimary)
            }
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
        } else {
            Rectangle()
                .fill(Color.tbBg3)
                .overlay {
                    Image(systemName: "video.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color.tbInk3)
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
            .background(Color.tbSurface)
            .clipShape(RoundedRectangle(cornerRadius: TBRadius.md, style: .continuous))
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
            }
            .sorted { lhs, rhs in
                if lhs.sortIndex == rhs.sortIndex {
                    return lhs.name < rhs.name
                }
                return lhs.sortIndex < rhs.sortIndex
            }
    }

    private var availableDimensionIDs: [String] {
        availableDimensions.map(\.id)
    }

    private var remainingMediaSlots: Int {
        max(0, 9 - draft.mediaItems.count)
    }

    private var saveAccessibilityLabel: String {
        if draft.canSave {
            return "存入时间银行"
        }
        return draft.disabledSaveAccessibilityLabel ?? "存入时间银行"
    }

    private func ensureSelectedDimension() {
        if let selected = draft.selectedDimensionID,
           availableDimensionIDs.contains(selected) {
            return
        }
        draft.selectedDimensionID = availableDimensions.first?.id
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

            if loadedItems.isEmpty == false,
               loadedItems.allSatisfy(\.isFailed) {
                showToast("照片没加载上。换一张试试？")
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

    private func requestDismiss() {
        if draft.hasDiscardableChanges {
            showDiscardAlert = true
        } else {
            dismiss()
        }
    }

    private func saveMoment() {
        guard let request = draft.makeSaveRequest() else { return }

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
                _ = try await store.save(moment: request)
                isSaving = false
                slowSaveTask?.cancel()
                showToast("存下了。")
                try? await Task.sleep(nanoseconds: 650_000_000)
                dismiss()
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
