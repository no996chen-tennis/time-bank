// TimeBank/Features/DimensionDetail/CalculationSummaryCard.swift

import SwiftUI

struct CalculationSummaryCard: View {
    let dimension: Dimension
    let profile: UserProfile
    let dimensionsByID: [String: Dimension]

    private var summary: String {
        DimensionDetailCopy.calculationSummary(
            for: dimension,
            profile: profile,
            dimensionsByID: dimensionsByID
        )
    }

    var body: some View {
        HStack(alignment: .center, spacing: TBSpace.s3) {
            VStack(alignment: .leading, spacing: TBSpace.s2) {
                Text(DimensionDetailCopy.calculationTitle)
                    .font(.tbHeadS)
                    .foregroundStyle(Color.tbInk)

                Text(summary)
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk2)
                    .lineSpacing(TBSpace.s1)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: TBSpace.s3)

            Image(systemName: "chevron.right")
                .font(.tbBodySm)
                .foregroundStyle(Color.tbInk3.opacity(0.55))
                .accessibilityHidden(true)
        }
        .padding(TBSpace.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tbSurface)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg))
        .modifier(DimensionDetailSoftShadowModifier())
    }
}

struct DimensionDetailSoftShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        TBShadow.soft(for: content)
    }
}
