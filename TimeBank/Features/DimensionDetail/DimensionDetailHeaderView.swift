// TimeBank/Features/DimensionDetail/DimensionDetailHeaderView.swift

import SwiftUI

struct DimensionDetailHeaderView: View {
    let dimension: Dimension
    let profile: UserProfile
    let dimensionsByID: [String: Dimension]

    private var consumeHours: Double {
        DimensionCompute.consumeHours(
            for: dimension,
            profile: profile,
            dimensionsByID: dimensionsByID
        )
    }

    private var subtitleLines: [String] {
        DimensionDetailCopy.headerSubtitleLines(
            for: dimension,
            profile: profile,
            dimensionsByID: dimensionsByID
        )
    }

    var body: some View {
        VStack(spacing: TBSpace.s4) {
            ZStack {
                Circle()
                    .fill(DimensionPalette.soft(for: dimension.id))

                Image(systemName: DimensionDetailCopy.iconSystemName(for: dimension))
                    .font(.tbHeadL)
                    .foregroundStyle(DimensionPalette.color(for: dimension.id))
            }
            .frame(width: 72, height: 72)

            VStack(spacing: TBSpace.s2) {
                Text(dimension.name)
                    .font(.tbHeadM)
                    .foregroundStyle(Color.tbInk)

                Text(Formatter.hoursCompact(consumeHours))
                    .font(.tbDisplayL)
                    .foregroundStyle(Color.tbInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.52)
                    .frame(maxWidth: .infinity)

                VStack(spacing: TBSpace.s1) {
                    ForEach(subtitleLines, id: \.self) { line in
                        Text(line)
                            .font(.tbBodySm)
                            .foregroundStyle(Color.tbInk2)
                            .multilineTextAlignment(.center)
                    }
                }
            }

            if let insight = DimensionDetailCopy.insight(for: dimension, profile: profile) {
                Text(insight)
                    .font(.tbBody)
                    .foregroundStyle(Color.tbInk2)
                    .multilineTextAlignment(.center)
                    .lineSpacing(TBSpace.s1)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, TBSpace.s2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TBSpace.s6)
    }
}
