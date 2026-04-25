// TimeBank/Features/DimensionDetail/MomentTimelineView.swift

import SwiftUI

struct MomentTimelineView: View {
    let dimension: Dimension
    let moments: [Moment]
    let fileStore: FileStore

    @State private var visibleCount = 20
    @State private var isLoadingNextPage = false

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
                Text(DimensionDetailCopy.depositedSectionHeader(
                    momentCount: storedMomentCount,
                    storedHours: storedHours
                ))
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)

                VStack(spacing: TBSpace.s3) {
                    ForEach(Array(visibleMoments.enumerated()), id: \.element.id) { index, moment in
                        NavigationLink {
                            MomentDetailView(momentID: moment.id)
                        } label: {
                            MomentTimelineRowView(
                                moment: moment,
                                fileStore: fileStore
                            )
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            loadNextPageIfNeeded(currentIndex: index)
                        }
                    }
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
