// TimeBank/Features/Home/DoubleLayerAccountCardView.swift

import SwiftUI

struct DoubleLayerAccountCardView: View {
    let projection: DimensionCompute.LifespanProjection
    let totalAccount: DimensionCompute.TotalAccount

    var body: some View {
        VStack(spacing: 0) {
            lifespanLayer
                .frame(height: 120)

            Rectangle()
                .fill(Color.tbInk.opacity(0.1))
                .frame(height: TBSpace.s2)

            depositedLayer
                .frame(height: 112)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: 240)
        .background(
            LinearGradient(
                colors: [
                    Color.tbDimKids.opacity(0.95),
                    Color.tbPrimary,
                    Color.tbDimFree
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg))
    }

    private var lifespanLayer: some View {
        VStack(spacing: TBSpace.s2) {
            HStack {
                Image(systemName: "hourglass")
                    .font(.tbHeadM)
                    .foregroundStyle(Color.tbInk)

                Text("时间余额")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk.opacity(0.8))

                Spacer()
            }

            Spacer(minLength: 0)

            // TODO Formatter §21.weeksCompact(w)
            Text("约 \(Int(projection.remainingWeeks.rounded(.down))) 周")
                .font(.tbDisplayS)
                .foregroundStyle(Color.tbInk)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(Formatter.lifespanSubtitle(
                years: projection.remainingYears,
                hoursK: projection.remainingHoursK
            ))
            .font(.tbBodySm)
            .foregroundStyle(Color.tbInk.opacity(0.78))
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 0)
        }
        .padding(TBSpace.s5)
    }

    private var depositedLayer: some View {
        VStack(alignment: .leading, spacing: TBSpace.s2) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "heart.fill")
                    .font(.tbHeadS)
                    .foregroundStyle(Color.tbInk)

                Text("已存入")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk.opacity(0.8))

                Spacer()

                Text(Formatter.hoursReadable(totalAccount.hours))
                    .font(.tbHeadM)
                    .foregroundStyle(Color.tbInk)
            }

            Text(Formatter.momentsCount(totalAccount.moments))
                .font(.tbDisplayS)
                .foregroundStyle(Color.tbInk)

            Text("跨 \(totalAccount.dimensionCount) 个时间账户")
                .font(.tbBodySm)
                .foregroundStyle(Color.tbInk.opacity(0.78))
        }
        .padding(TBSpace.s5)
    }
}
