// TimeBank/Features/DimensionDetail/DimensionDetailHeaderView.swift

import SwiftUI

struct DimensionDetailHeaderView: View {
    let dimension: Dimension
    let profile: UserProfile
    let dimensionsByID: [String: Dimension]
    let timeScope: DimensionCompute.TimeBalanceScope

    private var consumeHours: Double {
        DimensionCompute.consumeHours(
            for: dimension,
            profile: profile,
            dimensionsByID: dimensionsByID,
            scope: timeScope
        )
    }

    private var subtitleLines: [String] {
        DimensionDetailCopy.headerSubtitleLines(
            for: dimension,
            profile: profile,
            dimensionsByID: dimensionsByID,
            scope: timeScope
        )
    }

    var body: some View {
        softBody
    }

    private var softBody: some View {
        HStack(alignment: .center, spacing: TBSpace.s3) {
            headerSymbol(size: 56)
            headerTextBlock(alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TBSpace.s4)
        .tbThemedSurface()
    }

    private var editorialBody: some View {
        HStack(alignment: .top, spacing: TBSpace.s5) {
            headerSymbol(size: 56)

            VStack(alignment: .leading, spacing: TBSpace.s3) {
                Text("账户详情")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk3)
                    .textCase(.uppercase)

                headerTextBlock(alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TBSpace.s5)
        .tbThemedSurface()
    }

    private func headerSymbol(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(DimensionPalette.soft(for: dimension))

            Image(systemName: DimensionDetailCopy.iconSystemName(for: dimension))
                .font(.tbHeadL)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(DimensionPalette.color(for: dimension))
        }
        .frame(width: size, height: size)
    }

    private func headerTextBlock(alignment: HorizontalAlignment, isLeading: Bool = true) -> some View {
        VStack(alignment: alignment, spacing: TBSpace.s2) {
            Text(dimension.name)
                .font(.tbHeadM)
                .foregroundStyle(Color.tbInk)

            if let memorialSubtitle {
                Text(memorialSubtitle)
                    .font(.tbBody)
                    .foregroundStyle(Color.tbInk2)
                    .multilineTextAlignment(isLeading ? .leading : .center)
                    .lineSpacing(TBSpace.s1)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, TBSpace.s2)
            } else {
                Text(Formatter.hoursCompact(consumeHours))
                    .font(.tbDisplayM)
                    .foregroundStyle(Color.tbInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.52)
                    .frame(maxWidth: .infinity, alignment: isLeading ? .leading : .center)

                VStack(alignment: alignment, spacing: TBSpace.s1) {
                    ForEach(subtitleLines, id: \.self) { line in
                        Text(line)
                            .font(.tbBodySm)
                            .foregroundStyle(Color.tbInk2)
                            .multilineTextAlignment(isLeading ? .leading : .center)
                    }
                }
            }
        }
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
