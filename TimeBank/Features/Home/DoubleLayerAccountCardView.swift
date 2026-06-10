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

                HStack(alignment: .firstTextBaseline, spacing: TBSpace.s2) {
                    Text(weeksNumberText)
                        .font(.tbDisplayM)
                        .foregroundStyle(heroInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .contentTransition(.numericText())

                    Text("周")
                        .font(.tbHeadM)
                        .foregroundStyle(heroInkSoft)
                }

                VStack(alignment: .leading, spacing: TBSpace.s2) {
                    progressStrip

                    HStack {
                        Text(yearsText)
                            .font(.tbBodySm)
                            .foregroundStyle(heroInkSoft)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Spacer()

                        Text(elapsedCaption)
                            .font(.tbLabel)
                            .foregroundStyle(heroInkSoft.opacity(0.85))
                    }
                }
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

    /// 人生进度条：已度过（亮色） vs 余下（暗色轨道）
    private var progressStrip: some View {
        GeometryReader { proxy in
            let clamped = min(1, max(0, elapsedProgress))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(heroInk.opacity(0.18))

                Capsule()
                    .fill(heroAccent)
                    .frame(width: max(6, proxy.size.width * clamped))
            }
        }
        .frame(height: 5)
        .accessibilityHidden(true)
    }

    // MARK: - Hero 配色（深色面板上的墨色系统）

    private var heroInk: Color {
        TimeBankTheme.current.palette.surface
    }

    private var heroInkSoft: Color {
        TimeBankTheme.current.palette.surface.opacity(0.72)
    }

    private var heroAccent: Color {
        TimeBankTheme.current.palette.background
    }

    // MARK: - 文案

    private var weeksNumberText: String {
        let weeks = Int(projection.remainingWeeks.rounded(.down))
        let formatted = weeks.formatted(.number.grouping(.automatic))
        return scope == .lifetime ? "约 \(formatted)" : formatted
    }

    private var yearsText: String {
        if scope == .year {
            let days = Int((projection.remainingYears * DimensionCompute.daysPerYear).rounded(.down))
            return "\(days) 天 · \(Formatter.hoursCompact(projection.remainingHoursK * 1_000))"
        }

        return Formatter.lifespanSubtitle(
            years: projection.remainingYears,
            hoursK: projection.remainingHoursK
        )
    }

    private var elapsedCaption: String {
        let percent = Int((min(1, max(0, elapsedProgress)) * 100).rounded())
        return scope == .year ? "今年已过 \(percent)%" : "已走过 \(percent)%"
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
