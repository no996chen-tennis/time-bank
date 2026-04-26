// TimeBank/Features/Account/AccountTabView.swift

import Charts
import SwiftUI

struct AccountTabView: View {
    let dimensions: [Dimension]
    let moments: [Moment]
    let onCreateMoment: () -> Void

    private var aggregate: DimensionCompute.AccountTabAggregate {
        DimensionCompute.accountTabAggregate(dimensions: dimensions, moments: moments)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: TBSpace.s5) {
                    summaryCard

                    if aggregate.totalMoments == 0 {
                        emptyState
                    } else {
                        distributionSection
                        annualSection
                    }
                }
                .padding(.horizontal, TBSpace.s5)
                .padding(.top, TBSpace.s4)
                .padding(.bottom, TBSpace.s7)
            }
        }
        .background(Color.tbBg)
        .navigationTitle("账户")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: TBSpace.s4) {
            VStack(alignment: .leading, spacing: TBSpace.s1) {
                Text(Formatter.hoursCompact(aggregate.totalHours))
                    .font(.tbDisplayL)
                    .foregroundStyle(Color.tbInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.56)

                Text("已存入 · 包含其他时间账户")
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk2)
            }

            Divider()
                .overlay(Color.tbHair)

            HStack(alignment: .lastTextBaseline) {
                Text(Formatter.momentsCount(aggregate.totalMoments))
                    .font(.tbHeadS)
                    .foregroundStyle(Color.tbInk)

                Spacer()

                Text("跨 \(aggregate.dimensionCount) 个时间账户")
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk2)
            }
        }
        .padding(TBSpace.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tbSurface)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg))
        .modifier(AccountSoftShadowModifier())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("已存入 \(Int(aggregate.totalHours.rounded())) 小时，跨 \(aggregate.dimensionCount) 个时间账户，\(Formatter.momentsCount(aggregate.totalMoments))")
    }

    private var distributionSection: some View {
        VStack(alignment: .leading, spacing: TBSpace.s4) {
            Text("时间账户分布")
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)

            VStack(spacing: TBSpace.s4) {
                Chart(aggregate.slices) { slice in
                    SectorMark(
                        angle: .value("存入", chartWeight(for: slice)),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.5
                    )
                    .foregroundStyle(DimensionPalette.color(for: slice.dimensionID))
                    .cornerRadius(4)
                }
                .chartLegend(.hidden)
                .frame(height: 220)
                .accessibilityLabel(distributionAccessibilityLabel)

                VStack(spacing: TBSpace.s3) {
                    ForEach(aggregate.slices) { slice in
                        legendRow(slice)
                    }
                }
            }
            .padding(TBSpace.s4)
            .background(Color.tbSurface)
            .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg))
            .modifier(AccountSoftShadowModifier())
        }
    }

    private func legendRow(_ slice: DimensionCompute.AccountTabSlice) -> some View {
        HStack(alignment: .top, spacing: TBSpace.s3) {
            Circle()
                .fill(DimensionPalette.color(for: slice.dimensionID))
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: TBSpace.s1) {
                Text(legendTitle(for: slice))
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                if slice.isOther {
                    Text("曾经属于其他时间账户的瞬间")
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbInk3)
                }
            }

            Spacer()
        }
    }

    private var annualSection: some View {
        VStack(alignment: .leading, spacing: TBSpace.s4) {
            Text("年度回顾")
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)

            VStack(alignment: .leading, spacing: TBSpace.s4) {
                ForEach(aggregate.yearGroups) { yearGroup in
                    VStack(alignment: .leading, spacing: TBSpace.s2) {
                        Text("\(yearGroup.year) 年")
                            .font(.tbBody)
                            .foregroundStyle(Color.tbInk)

                        if yearGroup.months.isEmpty {
                            Text("这一年还没有存入。")
                                .font(.tbLabel)
                                .foregroundStyle(Color.tbInk3)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(yearGroup.months) { month in
                                Text("\(month.month) 月 · \(Formatter.hoursCompact(month.hours)) · \(Formatter.momentsCount(month.moments))")
                                    .font(.tbBodySm)
                                    .foregroundStyle(Color.tbInk2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, TBSpace.s1)
                            }
                        }
                    }

                    if yearGroup.id != aggregate.yearGroups.last?.id {
                        Divider()
                            .overlay(Color.tbHair)
                    }
                }
            }
            .padding(TBSpace.s4)
            .background(Color.tbSurface)
            .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg))
            .modifier(AccountSoftShadowModifier())
        }
    }

    private var emptyState: some View {
        VStack(spacing: TBSpace.s4) {
            Text("存入第一个瞬间，这里就会长出来。")
                .font(.tbBody)
                .foregroundStyle(Color.tbInk2)
                .multilineTextAlignment(.center)

            Button("存入第一个", action: onCreateMoment)
                .buttonStyle(AccountPrimaryButtonStyle())
        }
        .padding(TBSpace.s6)
        .frame(maxWidth: .infinity)
        .background(Color.tbSurface)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg))
        .modifier(AccountSoftShadowModifier())
    }

    private func chartWeight(for slice: DimensionCompute.AccountTabSlice) -> Double {
        if aggregate.totalHours > 0 {
            return max(0, slice.hours)
        }
        return Double(max(1, slice.moments))
    }

    private func legendTitle(for slice: DimensionCompute.AccountTabSlice) -> String {
        var title = "\(slice.name) · \(slice.percent)%"
        if slice.isMemorial {
            title += " · 纪念中"
        }
        return title
    }

    private var distributionAccessibilityLabel: String {
        aggregate.slices
            .map { "\($0.name) 占 \($0.percent)%" }
            .joined(separator: "，")
    }
}

private struct AccountSoftShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        TBShadow.soft(for: content)
    }
}

private struct AccountPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.tbBody)
            .foregroundStyle(Color.tbSurface)
            .padding(.horizontal, TBSpace.s6)
            .padding(.vertical, TBSpace.s3)
            .background(Color.tbPrimary.opacity(configuration.isPressed ? 0.78 : 1))
            .clipShape(Capsule())
    }
}
