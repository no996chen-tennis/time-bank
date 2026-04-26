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

                Text(DimensionDetailCopy.depositedSectionHeader(
                    momentCount: storedMomentCount,
                    storedHours: storedHours
                ))
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)

                VStack(spacing: TBSpace.s3) {
                    ForEach(Array(visibleMoments.enumerated()), id: \.element.id) { index, moment in
                        timelineRow(moment: moment, index: index)
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
        .background(Color.tbSurface)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.md))
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
    private func timelineRow(moment: Moment, index: Int) -> some View {
        if isSelectionMode {
            Button {
                toggleSelection(for: moment)
            } label: {
                HStack(spacing: TBSpace.s3) {
                    MomentSelectionIndicator(isSelected: selectedMomentIDs.contains(moment.id))

                    MomentTimelineRowView(
                        moment: moment,
                        fileStore: fileStore
                    )
                }
            }
            .buttonStyle(.plain)
            .onAppear {
                loadNextPageIfNeeded(currentIndex: index)
            }
        } else {
            NavigationLink {
                MomentDetailView(momentID: moment.id)
            } label: {
                MomentTimelineRowView(
                    moment: moment,
                    fileStore: fileStore
                )
            }
            .buttonStyle(.plain)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    deleteCandidate = moment
                } label: {
                    Label("删除", systemImage: "trash")
                }

                Button {
                    momentEditorRoute = .edit(moment)
                } label: {
                    Label("编辑", systemImage: "pencil")
                }
                .tint(Color.tbInk3)
            }
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
                    .fill(DimensionPalette.soft(for: dimension.id))

                Image(systemName: "tray")
                    .font(.tbHeadL)
                    .foregroundStyle(DimensionPalette.color(for: dimension.id))
            }
            .frame(width: 60, height: 60)

            Text(DimensionDetailCopy.timelineEmptyText(for: dimension.id))
                .font(.tbBody)
                .foregroundStyle(Color.tbInk2)
                .multilineTextAlignment(.center)
                .lineSpacing(TBSpace.s1)
                .fixedSize(horizontal: false, vertical: true)

            Button(DimensionDetailCopy.firstDepositCTA) {}
                .buttonStyle(DimensionDetailDisabledButtonStyle())
                .disabled(true)
                .accessibilityLabel(DimensionDetailCopy.depositAccessibilityLabel)
        }
        .padding(TBSpace.s6)
        .frame(maxWidth: .infinity)
        .background(Color.tbSurface)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg))
        .modifier(DimensionDetailSoftShadowModifier())
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
            .frame(maxWidth: .infinity)
            .padding(.vertical, TBSpace.s3)
            .background(Color.tbSurface.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(Capsule())
    }
}

private struct MomentTimelineRowView: View {
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
        HStack(alignment: .top, spacing: TBSpace.s3) {
            MomentThumbnailView(
                mediaItems: sortedMedia,
                fileStore: fileStore
            )

            VStack(alignment: .leading, spacing: TBSpace.s1) {
                Text(DimensionDetailCopy.timelineTitle(for: moment))
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk)
                    .lineLimit(1)

                Text(metaText)
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                if let note = DimensionDetailCopy.timelineNote(for: moment) {
                    Text(note)
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbInk3)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .padding(TBSpace.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tbSurface)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.md))
    }
}

private struct MomentThumbnailView: View {
    let mediaItems: [MediaItem]
    let fileStore: FileStore

    private var firstMedia: MediaItem? {
        mediaItems.first
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            thumbnail
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: TBRadius.sm))

            if mediaItems.count > 1 {
                Text("\(mediaItems.count)")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbSurface)
                    .padding(.horizontal, TBSpace.s2)
                    .padding(.vertical, TBSpace.s1)
                    .background(Color.tbInk.opacity(0.62))
                    .clipShape(Capsule())
                    .padding(TBSpace.s1)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if firstMedia?.mediaKind == .video {
                Image(systemName: "play.fill")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbSurface)
                    .padding(TBSpace.s1)
                    .background(Color.tbInk.opacity(0.62))
                    .clipShape(Circle())
                    .padding(TBSpace.s1)
            }
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        AsyncThumbnailImageView(
            source: thumbnailSource
        ) {
            ZStack {
                Color.tbBg2

                Image(systemName: "photo")
                    .font(.tbHeadS)
                    .foregroundStyle(Color.tbInk3)
            }
        }
    }

    private var thumbnailSource: ThumbnailImageSource? {
        guard let firstMedia else { return nil }
        return .file(
            relativePath: firstMedia.thumbnailPath ?? firstMedia.relativePath,
            fileStore: fileStore
        )
    }
}

private struct DimensionDetailDisabledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.tbBody)
            .foregroundStyle(Color.tbInk2)
            .padding(.horizontal, TBSpace.s6)
            .padding(.vertical, TBSpace.s3)
            .background(Color.tbBg2.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(Capsule())
    }
}
