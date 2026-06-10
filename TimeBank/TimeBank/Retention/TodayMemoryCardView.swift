// TimeBank/TimeBank/Retention/TodayMemoryCardView.swift
//
// 今日回忆卡（盲盒）：主页存折 hero 下第一张卡。"打开 App 第一眼就有东西等我"。
// 有记忆 → TodayMemoryCardView；0 条记忆 → TodayMemoryInviteView（冷启动邀请态）。

import SwiftUI

struct TodayMemoryCardView: View {
    let selection: TodayMemory.Selection

    @State private var fileStore = FileStore()

    private var accentColor: Color { DimensionPalette.color(forColorKey: selection.colorKey) }

    var body: some View {
        HStack(spacing: TBSpace.s4) {
            thumbnail

            VStack(alignment: .leading, spacing: TBSpace.s2) {
                HStack(spacing: TBSpace.s1) {
                    Image(systemName: selection.isPostcard ? "envelope.open" : "sparkle")
                        .font(.tbLabelEn)
                        .foregroundStyle(accentColor)
                    Text(selection.isPostcard ? "刚冲洗好 · \(selection.label)" : "今日回忆 · \(selection.label)")
                        .font(.tbLabel)
                        .foregroundStyle(accentColor)
                }

                Text(selection.title)
                    .font(.tbHeadS)
                    .foregroundStyle(Color.tbInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: TBSpace.s2)

            Image(systemName: "chevron.right")
                .font(.tbLabel)
                .foregroundStyle(Color.tbInk3)
        }
        .padding(TBSpace.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tbThemedSurface()
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(accentColor)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("今日回忆，\(selection.label)，\(selection.title)")
    }

    @ViewBuilder
    private var thumbnail: some View {
        Group {
            if let path = selection.firstMediaRelativePath {
                AsyncThumbnailImageView(source: .file(relativePath: path, fileStore: fileStore)) {
                    placeholder
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: TBRadius.md, style: .continuous))
            } else {
                placeholder
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: TBRadius.md, style: .continuous))
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            DimensionPalette.soft(forColorKey: selection.colorKey)
            Image(systemName: selection.isPostcard ? "envelope" : "sparkles")
                .font(.tbBody)
                .foregroundStyle(accentColor)
        }
    }
}

/// 冷启动（0 条记忆）邀请卡。点击 → 新建瞬间。
struct TodayMemoryInviteView: View {
    var body: some View {
        HStack(spacing: TBSpace.s4) {
            ZStack {
                RoundedRectangle(cornerRadius: TBRadius.md, style: .continuous)
                    .fill(Color.tbBg2)
                    .frame(width: 60, height: 60)
                Image(systemName: "sparkles")
                    .font(.tbBody)
                    .foregroundStyle(Color.tbInk3)
            }

            VStack(alignment: .leading, spacing: TBSpace.s2) {
                Text("今日回忆")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk3)
                Text("存入第一个瞬间，这里会长出回忆。")
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk2)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: TBSpace.s2)

            Image(systemName: "plus.circle.fill")
                .font(.tbHeadS)
                .foregroundStyle(Color.tbPrimary)
        }
        .padding(TBSpace.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tbThemedSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("今日回忆，存入第一个瞬间")
    }
}
