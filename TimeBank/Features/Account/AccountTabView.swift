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
                        allMomentsSection
                        annualSection
                    }
                }
                .padding(.horizontal, TBSpace.s5)
                .padding(.top, TBSpace.s3)
                .padding(.bottom, TBSpace.s7)
            }
        }
        .background(Color.tbBg)
        .navigationTitle("账户")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: TBSpace.s4) {
            HStack(alignment: .top, spacing: TBSpace.s3) {
                Image(systemName: TimeBankIconography.depositIconSystemName)
                    .font(.tbHeadM)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.tbPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.tbPrimary.opacity(0.12))
                    .clipShape(Circle())

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
        .tbThemedSurface()
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
                    .foregroundStyle(DimensionPalette.color(forColorKey: slice.colorKey))
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
            .tbThemedSurface()
        }
    }

    private func legendRow(_ slice: DimensionCompute.AccountTabSlice) -> some View {
        HStack(alignment: .top, spacing: TBSpace.s3) {
            Image(systemName: TimeBankIconography.dimensionIconSystemName(for: slice.dimensionID))
                .font(.tbLabel)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(DimensionPalette.color(forColorKey: slice.colorKey))
                .frame(width: 24, height: 24)
                .background(DimensionPalette.soft(forColorKey: slice.colorKey))
                .clipShape(Circle())

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
            .tbThemedSurface()
        }
    }

    private var allMomentsSection: some View {
        VStack(alignment: .leading, spacing: TBSpace.s4) {
            Text("所有已存入瞬间")
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)

            VStack(spacing: 0) {
                ForEach(sortedMoments) { moment in
                    NavigationLink {
                        MomentDetailView(momentID: moment.id)
                    } label: {
                        allMomentRow(moment)
                    }
                    .buttonStyle(.plain)

                    if moment.id != sortedMoments.last?.id {
                        Divider()
                            .overlay(Color.tbHair)
                    }
                }
            }
            .padding(.horizontal, TBSpace.s4)
            .tbThemedSurface()
        }
    }

    private var sortedMoments: [Moment] {
        moments
            .filter { $0.status == .normal }
            .sorted { lhs, rhs in
                if lhs.happenedAt == rhs.happenedAt {
                    return lhs.createdAt > rhs.createdAt
                }
                return lhs.happenedAt > rhs.happenedAt
            }
    }

    private func allMomentRow(_ moment: Moment) -> some View {
        HStack(alignment: .center, spacing: TBSpace.s3) {
            VStack(alignment: .leading, spacing: TBSpace.s1) {
                Text(DimensionDetailCopy.timelineTitle(for: moment))
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk)
                    .lineLimit(1)

                Text(momentRowSubtitle(moment))
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk3)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.tbLabel)
                .foregroundStyle(Color.tbInk3)
        }
        .padding(.vertical, TBSpace.s3)
        .contentShape(Rectangle())
    }

    private func momentRowSubtitle(_ moment: Moment) -> String {
        let dimensionName = dimensions.first { $0.id == moment.dimensionId }?.name ?? "时间账户"
        let duration = moment.durationSeconds.map { Formatter.hoursWithMinutes($0) } ?? "未计时长"
        return "\(dimensionName) · \(Formatter.absoluteDate(moment.happenedAt)) · \(duration)"
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: TBSpace.s4) {
            HStack(spacing: TBSpace.s3) {
                ZStack {
                    Circle()
                        .fill(Color.tbPrimary.opacity(0.14))

                    Image(systemName: TimeBankIconography.depositIconSystemName)
                        .font(.tbHeadS)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.tbPrimary)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: TBSpace.s1) {
                    Text("还没有存入")
                        .font(.tbHeadS)
                        .foregroundStyle(Color.tbInk)

                    Text(emptyStateSubtitle)
                        .font(.tbBodySm)
                        .foregroundStyle(Color.tbInk2)
                        .lineSpacing(TBSpace.s1)
                }
            }

            Button(action: onCreateMoment) {
                Label("存入第一个", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TBPrimaryActionButtonStyle(fillsWidth: true))
        }
        .padding(TBSpace.s5)
        .frame(maxWidth: .infinity)
        .tbThemedSurface()
    }

    private var emptyStateSubtitle: String {
        "第一段被认真感受过的时间，会从这里进入账户索引。"
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
