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

                if let memorialSubtitle {
                    Text(memorialSubtitle)
                        .font(.tbBody)
                        .foregroundStyle(Color.tbInk2)
                        .multilineTextAlignment(.center)
                        .lineSpacing(TBSpace.s1)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, TBSpace.s2)
                } else {
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
            }

            if memorialSubtitle == nil,
               let insight = DimensionDetailCopy.insight(for: dimension, profile: profile) {
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

    private var memorialSubtitle: String? {
        guard dimension.mode == .memorial else { return nil }
        switch dimension.id {
        case DimensionReservedID.parents.rawValue:
            return "你和父母一起度过的时光，都在这里。"
        case DimensionReservedID.kids.rawValue:
            return "你和孩子一起度过的时光，都在这里。"
        case DimensionReservedID.partner.rawValue:
            return "你和伴侣一起度过的时光，都在这里。"
        default:
            return nil
        }
    }
}
