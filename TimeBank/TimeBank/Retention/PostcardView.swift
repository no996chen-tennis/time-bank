// TimeBank/TimeBank/Retention/PostcardView.swift
//
// 明信片查看页（闭环④）：把一条已存入的瞬间冲洗成明信片——照片、邮票、邮戳、日期脚注。
// 看过后写 postcardSeenAt，避免重复推送、并让盲盒切回普通成色。

import SwiftData
import SwiftUI

struct PostcardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let momentID: UUID

    @Query private var moments: [Moment]
    @Query private var dimensions: [Dimension]
    @State private var fileStore = FileStore()

    private var moment: Moment? { moments.first { $0.id == momentID } }

    var body: some View {
        Group {
            if let moment {
                content(for: moment)
            } else {
                ProgressView()
                    .tint(Color.tbPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.tbBg)
            }
        }
        .navigationTitle("明信片")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func dimension(for moment: Moment) -> Dimension? {
        dimensions.first { $0.id == moment.dimensionId }
    }

    private func content(for moment: Moment) -> some View {
        let dimension = dimension(for: moment)
        let color = DimensionPalette.color(for: moment.dimensionId)
        let firstMedia = moment.mediaItems.sorted { $0.sortIndex < $1.sortIndex }.first

        return ScrollView(showsIndicators: false) {
            VStack(spacing: TBSpace.s5) {
                postcard(moment: moment, dimension: dimension, color: color, media: firstMedia)

                Button {
                    markSeen(moment)
                } label: {
                    Text(moment.postcardSeenAt == nil ? "收下这张明信片" : "已收下")
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbSurface)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(moment.postcardSeenAt == nil ? Color.tbPrimary : Color.tbInk3)
                        .clipShape(RoundedRectangle(cornerRadius: TBRadius.pill, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(moment.postcardSeenAt != nil)
            }
            .padding(.horizontal, TBSpace.s5)
            .padding(.top, TBSpace.s5)
            .padding(.bottom, TBSpace.s8)
        }
        .background(Color.tbBg)
    }

    private func postcard(moment: Moment, dimension: Dimension?, color: Color, media: MediaItem?) -> some View {
        VStack(spacing: 0) {
            // 上半：照片 / 账户色，叠邮票 + 邮戳
            ZStack(alignment: .topTrailing) {
                Group {
                    if let media {
                        AsyncThumbnailImageView(source: .file(relativePath: media.relativePath, fileStore: fileStore)) {
                            LinearGradient(colors: [color.opacity(0.55), color.opacity(0.28)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 208)
                        .clipped()
                    } else {
                        LinearGradient(colors: [color.opacity(0.55), color.opacity(0.28)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(height: 208)
                            .overlay {
                                Image(systemName: DimensionDetailCopy.iconSystemName(for: dimension ?? placeholderDimension))
                                    .font(.system(size: 40, weight: .light))
                                    .foregroundStyle(Color.tbSurface.opacity(0.9))
                            }
                    }
                }

                HStack(alignment: .top, spacing: TBSpace.s2) {
                    postmark(date: moment.happenedAt)
                    stamp(dimension: dimension, color: color)
                }
                .padding(TBSpace.s3)
            }

            // 下半：信纸
            VStack(alignment: .leading, spacing: TBSpace.s3) {
                Text(DimensionDetailCopy.timelineTitle(for: moment))
                    .font(.tbHeadM)
                    .foregroundStyle(Color.tbInk)
                    .fixedSize(horizontal: false, vertical: true)

                let note = moment.note.trimmingCharacters(in: .whitespacesAndNewlines)
                if note.isEmpty == false {
                    Text(note)
                        .font(.tbBody)
                        .foregroundStyle(Color.tbInk2)
                        .lineSpacing(TBSpace.s1)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Rectangle()
                    .fill(Color.tbHair)
                    .frame(height: 1)
                    .padding(.vertical, TBSpace.s1)

                HStack {
                    Text("寄自 · \(dimension?.name ?? "过去的你")")
                        .font(.tbLabel)
                        .foregroundStyle(color)
                    Spacer()
                    Text(Formatter.absoluteDate(moment.happenedAt))
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbInk3)
                }
            }
            .padding(TBSpace.s5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.tbSurface)
        }
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: TBRadius.lg, style: .continuous)
                .stroke(Color.tbInk.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: Color.tbInk.opacity(0.14), radius: 18, x: 0, y: 8)
    }

    /// 邮戳：虚线圆 + 日期。
    private func postmark(date: Date) -> some View {
        VStack(spacing: 0) {
            Text(Formatter.absoluteDate(date))
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.tbInk.opacity(0.7))
        }
        .frame(width: 58, height: 58)
        .background(Color.tbSurface.opacity(0.82), in: Circle())
        .overlay {
            Circle().strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [3, 2]))
                .foregroundStyle(Color.tbInk.opacity(0.45))
        }
        .rotationEffect(.degrees(-8))
    }

    /// 邮票：账户色小方块 + 账户图标 + 锯齿边。
    private func stamp(dimension: Dimension?, color: Color) -> some View {
        Image(systemName: DimensionDetailCopy.iconSystemName(for: dimension ?? placeholderDimension))
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(color)
            .frame(width: 46, height: 56)
            .background(Color.tbSurface.opacity(0.92))
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.4, dash: [2, 2]))
                    .foregroundStyle(color.opacity(0.55))
            }
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private var placeholderDimension: Dimension {
        Dimension(id: "__postcard_placeholder", name: "时间银行", kind: .custom, iconKey: "sparkles", colorKey: "rose")
    }

    private func markSeen(_ moment: Moment) {
        guard moment.postcardSeenAt == nil else { return }
        moment.postcardSeenAt = .now
        moment.updatedAt = .now
        try? modelContext.save()
        try? WidgetSnapshotWriter.writeSnapshot(modelContext: modelContext)
        PostcardCenter.shared.clear()
        dismiss()
    }
}
