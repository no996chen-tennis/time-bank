// TimeBank/Features/Home/DoubleLayerAccountCardView.swift

import SwiftUI

struct DoubleLayerAccountCardView: View {
    let projection: DimensionCompute.LifespanProjection
    let totalAccount: DimensionCompute.TotalAccount
    let scope: DimensionCompute.TimeBalanceScope
    /// 0...1，今生 = 已度过的人生比例；今年 = 今年已过去的比例
    let elapsedProgress: Double
    let onDepositsTap: () -> Void

    var body: some View {
        heroCard
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
    }

    // MARK: - Hero（深色存折面板：上半 = 时间余额，下半 = 已存入）

    private var heroCard: some View {
        let theme = TimeBankTheme.current

        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: TBSpace.s3) {
                HStack(spacing: TBSpace.s1) {
                    Image(systemName: TimeBankIconography.lifespanIconSystemName)
                        .font(.tbLabel)
                        .symbolRenderingMode(.hierarchical)

                    Text(scope == .year ? "时间余额 · 今年" : "时间余额 · 今生")
                        .font(.tbLabel)
                        .tracking(1.5)

                    Spacer()
                }
                .foregroundStyle(heroInkSoft)

                // 两个对等大数字：左 = 今年/今生余额 N 周；右 = 今天还剩 约 X 小时（秒级跳动）
                HStack(alignment: .top, spacing: TBSpace.s4) {
                    balanceMetric

                    Rectangle()
                        .fill(heroInk.opacity(0.16))
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 2)

                    todayRemainingMetric
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(TBSpace.s5)

            Button(action: onDepositsTap) {
                HStack(spacing: TBSpace.s2) {
                    Image(systemName: TimeBankIconography.depositIconSystemName)
                        .font(.tbBodySm)
                        .symbolRenderingMode(.hierarchical)

                    Text("已存入")
                        .font(.tbLabel)
                        .tracking(1.5)

                    Spacer(minLength: TBSpace.s2)

                    Text(depositSummaryText)
                        .font(.tbBodySm)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Image(systemName: "chevron.right")
                        .font(.tbLabel)
                        .opacity(0.7)
                }
                .foregroundStyle(heroInk)
                .padding(.horizontal, TBSpace.s5)
                .padding(.vertical, TBSpace.s3)
                .frame(maxWidth: .infinity)
                .background(heroInk.opacity(0.10))
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(heroInk.opacity(0.16))
                        .frame(height: 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("查看所有已存入瞬间，\(momentsText)")
        }
        .background(theme.palette.ink)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.xl, style: .continuous))
        .shadow(
            color: theme.palette.shadowTint.opacity(theme.style.usesShadow ? theme.style.shadowOpacity * 1.3 : 0),
            radius: theme.style.shadowRadius,
            x: 0,
            y: theme.style.shadowYOffset
        )
    }

    // MARK: - 两个对等大数字

    /// 左：今年/今生 时间余额（周）
    private var balanceMetric: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(scope == .year ? "今年还剩" : "今生还剩")
                .font(.tbLabel)
                .tracking(1)
                .foregroundStyle(heroInkSoft)

            HStack(alignment: .firstTextBaseline, spacing: TBSpace.s1) {
                Text(weeksNumberText)
                    .font(.tbDisplayM)
                    .foregroundStyle(heroInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .contentTransition(.numericText())

                Text("周")
                    .font(.tbHeadM)
                    .foregroundStyle(heroInkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 右：今天还剩（秒级跳动，经 DimensionCompute.disposableRemainingText 现算）
    private var todayRemainingMetric: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("今天还剩")
                .font(.tbLabel)
                .tracking(1)
                .foregroundStyle(heroInkSoft)

            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                let parts = todayRemainingParts(now: ctx.date)
                HStack(alignment: .firstTextBaseline, spacing: TBSpace.s1) {
                    Text(parts.number)
                        .font(.tbDisplayM)
                        .foregroundStyle(heroInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .contentTransition(.numericText())

                    Text(parts.unit)
                        .font(.tbHeadM)
                        .foregroundStyle(heroInkSoft)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 把 "约 X 小时"拆成【大数字】+【小单位】，大数字与左侧周数同级。
    /// 唯一真相源 = DimensionCompute.disposableRemainingText(now:)，不另写公式。
    private func todayRemainingParts(now: Date) -> (number: String, unit: String) {
        let text = DimensionCompute.disposableRemainingText(now: now)
        // 形如 "约 6.5 小时"：中间的数字段作大字，其余（约 / 小时）作小字单位。
        let tokens = text.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        if let numberIndex = tokens.firstIndex(where: { $0.first?.isNumber == true }) {
            let number = tokens[numberIndex]
            let unit = tokens[(numberIndex + 1)...].joined()
            return (number, unit.isEmpty ? "小时" : unit)
        }
        // 兜底：保持整串可见
        return (text, "")
    }

    // MARK: - Hero 配色（深色面板上的墨色系统）

    private var heroInk: Color {
        TimeBankTheme.current.palette.surface
    }

    private var heroInkSoft: Color {
        TimeBankTheme.current.palette.surface.opacity(0.72)
    }

    // MARK: - 文案

    private var weeksNumberText: String {
        let weeks = Int(projection.remainingWeeks.rounded(.down))
        let formatted = weeks.formatted(.number.grouping(.automatic))
        return scope == .lifetime ? "约 \(formatted)" : formatted
    }

    private var storedText: String {
        Formatter.storedDuration(totalAccount.hours)
    }

    private var momentsText: String {
        Formatter.momentsCount(totalAccount.moments)
    }

    private var depositSummaryText: String {
        "\(storedText) · \(momentsText)"
    }
}
