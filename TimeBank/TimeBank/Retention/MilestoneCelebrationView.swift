// TimeBank/TimeBank/Retention/MilestoneCelebrationView.swift
//
// 里程碑庆典（第 10/50/100 个瞬间）。回顾性措辞、用户自己照片的蒙太奇，绝不打分/排行。

import SwiftUI

struct MilestoneCelebrationView: View {
    let milestone: Int
    let moments: [Moment]
    let onContinue: () -> Void

    @State private var fileStore = FileStore()

    private var montage: [MediaItem] {
        moments
            .filter { $0.status == .normal }
            .sorted { $0.createdAt > $1.createdAt }
            .compactMap { $0.mediaItems.sorted { $0.sortIndex < $1.sortIndex }.first }
            .prefix(9)
            .map { $0 }
    }

    private let grid = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        VStack(spacing: TBSpace.s5) {
            Spacer(minLength: TBSpace.s4)

            VStack(spacing: TBSpace.s2) {
                Image(systemName: "sparkles")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(Color.tbPrimary)
                Text("第 \(milestone) 个瞬间")
                    .font(.tbDisplayL)
                    .foregroundStyle(Color.tbInk)
                Text("第 \(milestone) 个被你认真留下的瞬间。这些时间，都还在。")
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, TBSpace.s5)
            }

            if montage.isEmpty == false {
                LazyVGrid(columns: grid, spacing: 6) {
                    ForEach(montage) { media in
                        AsyncThumbnailImageView(source: .file(relativePath: media.relativePath, fileStore: fileStore)) {
                            Color.tbBg2
                        }
                        .aspectRatio(1, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: TBRadius.sm, style: .continuous))
                    }
                }
                .padding(.horizontal, TBSpace.s5)
            }

            Spacer()

            Button(action: onContinue) {
                Text("继续")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbSurface)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.tbPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: TBRadius.pill, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, TBSpace.s5)
            .padding(.bottom, TBSpace.s6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tbBg)
    }
}
