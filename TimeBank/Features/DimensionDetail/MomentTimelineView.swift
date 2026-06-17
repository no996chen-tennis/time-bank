// TimeBank/Features/DimensionDetail/MomentTimelineView.swift

import SwiftUI
import SwiftData

struct MomentTimelineView: View {
    @Environment(\.sharedMomentStore) private var sharedMomentStore
    @EnvironmentObject private var undoToastController: UndoToastController
    @Query private var dimensions: [Dimension]

    let dimension: Dimension
    let moments: [Moment]
    let fileStore: FileStore

    @State private var visibleCount = 20
    @State private var isLoadingNextPage = false
    @State private var momentEditorRoute: MomentEditorRoute?
    @State private var deleteCandidate: Moment?
    @State private var isSelectionMode = false
    @State private var selectedMomentIDs: Set<UUID> = []
    @State private var showBatchDimensionPicker = false
    @State private var toastMessage: String?
    @State private var toastDismissTask: Task<Void, Never>?

    private let pageSize = 20
    private let loadMoreThreshold = 5

    private var storedHours: Double {
        DimensionCompute.storedHours(for: dimension.id, moments: moments)
    }

    private var storedMomentCount: Int {
        DimensionCompute.storedMomentCount(for: dimension.id, moments: moments)
    }

    private var timelineMoments: [Moment] {
        moments
            .filter { $0.dimensionId == dimension.id }
            .sorted { lhs, rhs in
                if lhs.happenedAt == rhs.happenedAt {
                    return lhs.createdAt > rhs.createdAt
                }
                return lhs.happenedAt > rhs.happenedAt
            }
    }

    private var visibleMoments: [Moment] {
        Array(timelineMoments.prefix(visibleCount))
    }

    private var selectedMoments: [Moment] {
        timelineMoments.filter { selectedMomentIDs.contains($0.id) }
    }

    private var timelineMomentIDs: [UUID] {
        timelineMoments.map(\.id)
    }

    private var hasMoreMoments: Bool {
        visibleCount < timelineMoments.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TBSpace.s4) {
            if timelineMoments.isEmpty {
                emptyState
            } else {
                if isSelectionMode {
                    selectionHeader
                }

                HStack(alignment: .firstTextBaseline, spacing: TBSpace.s3) {
                    Text(DimensionDetailCopy.depositedSectionHeader(
                        momentCount: storedMomentCount,
                        storedHours: storedHours
                    ))
                    .font(.tbHeadS)
                    .foregroundStyle(Color.tbInk)

                    Spacer(minLength: TBSpace.s2)

                    if isSelectionMode == false {
                        depositButton(title: "存入", compact: true)
                    }
                }

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: TBSpace.s3),
                        GridItem(.flexible(), spacing: TBSpace.s3)
                    ],
                    spacing: TBSpace.s3
                ) {
                    ForEach(Array(visibleMoments.enumerated()), id: \.element.id) { index, moment in
                        momentCard(moment: moment, index: index)
                    }
                }

                if isSelectionMode, selectedMomentIDs.isEmpty == false {
                    batchActionBar
                }

                if isLoadingNextPage {
                    ProgressView()
                        .tint(Color.tbPrimary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, TBSpace.s2)
                } else if hasMoreMoments == false {
                    Text(DimensionDetailCopy.timelineEnd)
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbInk3)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, TBSpace.s2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: timelineMomentIDs) { _, _ in
            resetPagination()
            reconcileSelection()
        }
        .sheet(item: $momentEditorRoute) { route in
            MomentEditorView(route: route)
        }
        .sheet(isPresented: $showBatchDimensionPicker) {
            DimensionPickerSheet(
                title: "换时间账户",
                dimensions: dimensions,
                excludedDimensionID: nil
            ) { targetDimension in
                moveSelectedMoments(to: targetDimension)
            }
        }
        .alert("确定删除这个时刻？", isPresented: deleteAlertBinding) {
            Button("取消", role: .cancel) {
                deleteCandidate = nil
            }
            Button("删除", role: .destructive) {
                if let deleteCandidate {
                    delete(moment: deleteCandidate)
                }
            }
        } message: {
            if let deleteCandidate {
                Text(MomentActionCopy.deleteMessage(mediaCount: deleteCandidate.mediaItems.count))
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage {
                Text(toastMessage)
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbSurface)
                    .padding(.horizontal, TBSpace.s4)
                    .padding(.vertical, TBSpace.s3)
                    .background(Color.tbInk.opacity(0.88))
                    .clipShape(Capsule())
                    .padding(.bottom, TBSpace.s2)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: toastMessage)
    }

    private var selectionHeader: some View {
        HStack(spacing: TBSpace.s3) {
            Button("取消") {
                exitSelectionMode()
            }
            .font(.tbBodySm)
            .foregroundStyle(Color.tbInk2)

            Spacer()

            Text("已选 \(selectedMomentIDs.count)")
                .font(.tbBody)
                .foregroundStyle(Color.tbInk)

            Spacer()

            Button("全选") {
                selectedMomentIDs = Set(timelineMomentIDs)
            }
            .font(.tbBodySm)
            .foregroundStyle(Color.tbPrimary)
        }
        .padding(.horizontal, TBSpace.s3)
        .padding(.vertical, TBSpace.s2)
        .tbThemedSurface(.row)
    }

    private var batchActionBar: some View {
        HStack(spacing: TBSpace.s3) {
            Button {
                showBatchDimensionPicker = true
            } label: {
                Label("换时间账户", systemImage: "arrow.left.arrow.right")
            }
            .buttonStyle(MomentTimelineBatchActionButtonStyle())

            Button(role: .destructive) {
                deleteSelectedMoments()
            } label: {
                Label("删除", systemImage: "trash")
            }
            .buttonStyle(MomentTimelineBatchActionButtonStyle(isDestructive: true))
        }
        .padding(.top, TBSpace.s1)
    }

    @ViewBuilder
    private func momentCard(moment: Moment, index: Int) -> some View {
        if isSelectionMode {
            Button {
                toggleSelection(for: moment)
            } label: {
                MomentCardView(moment: moment, fileStore: fileStore)
                    .overlay(alignment: .topLeading) {
                        MomentSelectionIndicator(isSelected: selectedMomentIDs.contains(moment.id))
                            .padding(TBSpace.s2)
                    }
                    .opacity(selectedMomentIDs.contains(moment.id) ? 1 : 0.7)
            }
            .buttonStyle(.plain)
            .onAppear {
                loadNextPageIfNeeded(currentIndex: index)
            }
        } else {
            NavigationLink {
                MomentDetailView(momentID: moment.id)
            } label: {
                MomentCardView(moment: moment, fileStore: fileStore)
            }
            .buttonStyle(.plain)
            .onLongPressGesture(minimumDuration: 0.5) {
                enterSelectionMode(selecting: moment)
            }
            .onAppear {
                loadNextPageIfNeeded(currentIndex: index)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: TBSpace.s4) {
            ZStack {
                Circle()
                    .fill(DimensionPalette.soft(for: dimension))

                Image(systemName: TimeBankIconography.depositIconSystemName)
                    .font(.tbHeadL)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(DimensionPalette.color(for: dimension))
            }
            .frame(width: 60, height: 60)

            Text(DimensionDetailCopy.timelineEmptyText(for: dimension.id))
                .font(.tbBody)
                .foregroundStyle(Color.tbInk2)
                .multilineTextAlignment(.center)
                .lineSpacing(TBSpace.s1)
                .fixedSize(horizontal: false, vertical: true)

            depositButton(title: DimensionDetailCopy.firstDepositCTA)
        }
        .padding(TBSpace.s6)
        .frame(maxWidth: .infinity)
        .tbThemedSurface()
    }

    private func depositButton(title: String, compact: Bool = false) -> some View {
        Button {
            guard canDeposit else { return }
            momentEditorRoute = .dimension(dimension)
        } label: {
            if compact {
                Label(title, systemImage: "plus")
                    .labelStyle(.titleAndIcon)
            } else {
                Text(title)
            }
        }
        .buttonStyle(DimensionDetailDepositButtonStyle(compact: compact))
        .disabled(canDeposit == false)
        .opacity(canDeposit ? 1 : 0.45)
        .accessibilityLabel(canDeposit
            ? title
            : "\(dimension.name)已标记纪念，不再添加新瞬间")
    }

    private var canDeposit: Bool {
        (dimension.kind == .builtin || dimension.kind == .custom)
            && dimension.mode == .normal
    }

    private func loadNextPageIfNeeded(currentIndex: Int) {
        guard hasMoreMoments, isLoadingNextPage == false else { return }

        let triggerIndex = max(0, visibleMoments.count - loadMoreThreshold)
        guard currentIndex >= triggerIndex else { return }

        isLoadingNextPage = true

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
            visibleCount = min(visibleCount + pageSize, timelineMoments.count)
            isLoadingNextPage = false
        }
    }

    private func resetPagination() {
        visibleCount = pageSize
        isLoadingNextPage = false
    }

    private func enterSelectionMode(selecting moment: Moment) {
        isSelectionMode = true
        selectedMomentIDs = [moment.id]
    }

    private func exitSelectionMode() {
        isSelectionMode = false
        selectedMomentIDs = []
    }

    private func toggleSelection(for moment: Moment) {
        if selectedMomentIDs.contains(moment.id) {
            selectedMomentIDs.remove(moment.id)
        } else {
            selectedMomentIDs.insert(moment.id)
        }
    }

    private func reconcileSelection() {
        let currentIDs = Set(timelineMomentIDs)
        selectedMomentIDs.formIntersection(currentIDs)
        if selectedMomentIDs.isEmpty {
            isSelectionMode = false
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { deleteCandidate != nil },
            set: { newValue in
                if newValue == false {
                    deleteCandidate = nil
                }
            }
        )
    }

    private func delete(moment: Moment) {
        guard let store = sharedMomentStore else { return }
        do {
            try store.delete(moment: moment)
            undoToastController.show(message: "已删除") {
                try? store.undoDelete(moment: moment)
            }
            deleteCandidate = nil
        } catch {
            deleteCandidate = nil
        }
    }

    private func deleteSelectedMoments() {
        guard let store = sharedMomentStore else { return }
        let momentsToDelete = selectedMoments
        guard momentsToDelete.isEmpty == false else { return }

        var deletedMoments: [Moment] = []
        for moment in momentsToDelete {
            do {
                try store.delete(moment: moment)
                deletedMoments.append(moment)
            } catch {
                continue
            }
        }

        exitSelectionMode()

        guard deletedMoments.isEmpty == false else { return }
        undoToastController.show(message: "已删除 \(Formatter.momentsCount(deletedMoments.count))") {
            for moment in deletedMoments {
                try? store.undoDelete(moment: moment)
            }
        }
    }

    private func moveSelectedMoments(to targetDimension: Dimension) {
        guard let store = sharedMomentStore else { return }
        let momentsToMove = selectedMoments
        guard momentsToMove.isEmpty == false else { return }

        do {
            try store.move(moments: momentsToMove, to: targetDimension.id)
            let count = momentsToMove.count
            exitSelectionMode()
            showToast("\(Formatter.momentsCount(count))换到了 \(targetDimension.name)")
        } catch {
            return
        }
    }

    private func showToast(_ message: String) {
        toastDismissTask?.cancel()
        toastMessage = message
        toastDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }
}

private struct MomentSelectionIndicator: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? Color.tbPrimary : Color.tbInk3.opacity(0.5), lineWidth: 1.5)
                .background(
                    Circle()
                        .fill(isSelected ? Color.tbPrimary : Color.clear)
                )

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.tbSurface)
            }
        }
        .frame(width: 24, height: 24)
    }
}

private struct MomentTimelineBatchActionButtonStyle: ButtonStyle {
    var isDestructive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.tbBodySm)
            .foregroundStyle(isDestructive ? Color.tbDanger : Color.tbInk)
            .labelStyle(.titleAndIcon)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color.tbSurface.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(RoundedRectangle(cornerRadius: actionRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: actionRadius, style: .continuous)
                    .stroke(isDestructive ? Color.tbDanger.opacity(0.35) : TimeBankTheme.current.style.cardBorderColor, lineWidth: TimeBankTheme.current.style.cardBorderWidth)
            }
    }

    private var actionRadius: CGFloat {
        switch TimeBankTheme.current.kind {
        case .gallery, .localRemoteEditorial:
            return 0
        default:
            return TBRadius.pill
        }
    }
}

// 卡片：顶部 2×2 照片网格（>4 张横滑翻页），底部标题 + 元信息。一眼看到那天拍了哪些。
private struct MomentCardView: View {
    let moment: Moment
    let fileStore: FileStore

    private var sortedMedia: [MediaItem] {
        moment.mediaItems.sorted { lhs, rhs in
            if lhs.sortIndex == rhs.sortIndex {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.sortIndex < rhs.sortIndex
        }
    }

    private var pages: [[MediaItem]] {
        stride(from: 0, to: sortedMedia.count, by: 4).map {
            Array(sortedMedia[$0..<min($0 + 4, sortedMedia.count)])
        }
    }

    private var metaText: String {
        var parts: [String] = [Formatter.relativeTime(moment.happenedAt)]
        if let mediaText = DimensionDetailCopy.mediaCountText(sortedMedia.count) {
            parts.append(mediaText)
        }
        if let duration = moment.durationSeconds {
            parts.append(Formatter.hoursWithMinutes(duration))
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            photoArea

            VStack(alignment: .leading, spacing: 3) {
                Text(DimensionDetailCopy.timelineTitle(for: moment))
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(metaText)
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(TBSpace.s3)
        }
        .contentShape(Rectangle())
        .tbThemedSurface(.card)
    }

    @ViewBuilder
    private var photoArea: some View {
        // 用正方形 GeometryReader 给翻页 TabView 一个确定高度。
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    let side = geo.size.width
                    Group {
                        if sortedMedia.isEmpty {
                            emptyPhotoPlaceholder
                        } else if pages.count <= 1 {
                            PhotoQuadGrid(items: pages.first ?? [], fileStore: fileStore)
                        } else {
                            TabView {
                                ForEach(Array(pages.enumerated()), id: \.offset) { _, page in
                                    PhotoQuadGrid(items: page, fileStore: fileStore)
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: .automatic))
                            .frame(width: side, height: side)
                        }
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                if sortedMedia.count > 1 {
                    Text("\(sortedMedia.count)")
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbSurface)
                        .padding(.horizontal, TBSpace.s2)
                        .padding(.vertical, 2)
                        .background(Color.tbInk.opacity(0.6))
                        .clipShape(Capsule())
                        .padding(TBSpace.s2)
                }
            }
    }

    private var emptyPhotoPlaceholder: some View {
        ZStack {
            DimensionPalette.color(forColorKey: "warm").opacity(0.12)
            Image(systemName: "text.alignleft")
                .font(.tbHeadM)
                .foregroundStyle(Color.tbInk3)
        }
    }
}

// 一页里最多 4 张照片，2×2 等分填满正方形；不足 4 张时空位留浅底。
private struct PhotoQuadGrid: View {
    let items: [MediaItem]
    let fileStore: FileStore

    var body: some View {
        VStack(spacing: 1.5) {
            row(0)
            row(2)
        }
    }

    private func row(_ start: Int) -> some View {
        HStack(spacing: 1.5) {
            cell(start)
            cell(start + 1)
        }
    }

    @ViewBuilder
    private func cell(_ index: Int) -> some View {
        if index < items.count {
            let media = items[index]
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    AsyncThumbnailImageView(
                        source: .file(
                            relativePath: media.thumbnailPath ?? media.relativePath,
                            fileStore: fileStore
                        )
                    ) {
                        ZStack {
                            Color.tbBg2
                            Image(systemName: "photo")
                                .font(.tbBodySm)
                                .foregroundStyle(Color.tbInk3)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                }
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
                .clipped()
        } else {
            Color.tbBg2.opacity(0.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct DimensionDetailDepositButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(compact ? .tbBodySm : .tbBody)
            .foregroundStyle(Color.tbSurface)
            .frame(minHeight: compact ? 34 : 44)
            .padding(.horizontal, compact ? TBSpace.s4 : TBSpace.s5)
            .background(Color.tbPrimary.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(RoundedRectangle(cornerRadius: actionRadius, style: .continuous))
    }

    private var actionRadius: CGFloat {
        switch TimeBankTheme.current.kind {
        case .gallery, .localRemoteEditorial:
            return 0
        default:
            return TBRadius.pill
        }
    }
}
