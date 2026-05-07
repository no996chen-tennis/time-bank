// TimeBank/Features/Home/DoubleLayerAccountCardView.swift

import SwiftUI

struct DoubleLayerAccountCardView: View {
    let projection: DimensionCompute.LifespanProjection
    let totalAccount: DimensionCompute.TotalAccount
    let scope: DimensionCompute.TimeBalanceScope
    let onDepositsTap: () -> Void

    var body: some View {
        semanticCard
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var semanticCard: some View {
        HStack(spacing: 0) {
            semanticPane(
                icon: TimeBankIconography.lifespanIconSystemName,
                title: "时间余额",
                number: weeksText,
                detail: yearsText
            )

            Rectangle()
                .fill(Color.tbHair)
                .frame(width: 1)
                .padding(.vertical, TBSpace.s4)

            Button(action: onDepositsTap) {
                semanticPane(
                    icon: TimeBankIconography.depositIconSystemName,
                    title: "已存入",
                    number: storedText,
                    detail: compactDepositDetail
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("查看所有已存入瞬间，\(momentsText)")
        }
        .frame(height: 144)
        .tbThemedSurface()
    }

    private func semanticPane(icon: String, title: String, number: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: TBSpace.s2) {
            HStack(spacing: TBSpace.s1) {
                Image(systemName: icon)
                    .font(.tbLabel)
                    .symbolRenderingMode(.hierarchical)

                Text(title)
                    .font(.tbLabel)
            }
            .foregroundStyle(Color.tbPrimary)

            Spacer(minLength: 0)

            Text(number)
                .font(.tbDisplayS)
                .foregroundStyle(Color.tbInk)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            detailLines(detail)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(TBSpace.s4)
    }

    private var weeksText: String {
        switch scope {
        case .lifetime:
            return "约 \(Int(projection.remainingWeeks.rounded(.down))) 周"
        case .year:
            return "\(Int(projection.remainingWeeks.rounded(.down))) 周"
        }
    }

    private var weeksValue: Int {
        Int(projection.remainingWeeks.rounded(.down))
    }

    private var yearsValue: Int {
        Int(projection.remainingYears.rounded())
    }

    private var hoursKText: String {
        "\(Int(projection.remainingHoursK.rounded())) Kh"
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

    private var storedText: String {
        Formatter.storedDuration(totalAccount.hours)
    }

    private var momentsText: String {
        Formatter.momentsCount(totalAccount.moments)
    }

    private var accountCountText: String {
        "\(totalAccount.dimensionCount) 个账户"
    }

    private var compactDepositDetail: String {
        "\(momentsText)\n\(accountCountText)"
    }

    private var dimensionText: String {
        "跨 \(totalAccount.dimensionCount) 个时间账户"
    }

    private var magazineCard: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.tbPrimary)
                .frame(height: 6)

            HStack(spacing: 0) {
                magazinePane(icon: TimeBankIconography.lifespanIconSystemName, title: "时间余额", number: weeksText, detail: yearsText)
                Divider().background(Color.tbHair)
                magazinePane(icon: TimeBankIconography.depositIconSystemName, title: "已存入", number: storedText, detail: compactDepositDetail)
            }
        }
        .frame(height: 136)
        .background(Color.tbSurface)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: TBRadius.lg, style: .continuous)
                .stroke(TimeBankTheme.current.style.cardBorderColor, lineWidth: TimeBankTheme.current.style.cardBorderWidth)
        }
        .modifier(ThemeShadowModifier())
    }

    private func magazinePane(icon: String, title: String, number: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            HStack(spacing: TBSpace.s1) {
                Image(systemName: icon)
                    .font(.tbLabel)
                    .symbolRenderingMode(.hierarchical)
                Text(title)
                    .font(.tbLabel)
            }
            .foregroundStyle(Color.tbPrimary)

            Spacer(minLength: 0)

            Text(number)
                .font(.tbDisplayS)
                .foregroundStyle(Color.tbInk)
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            detailLines(detail)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(TBSpace.s4)
    }

    private var artBookCard: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: TBSpace.s3) {
                HStack(spacing: TBSpace.s1) {
                    Image(systemName: TimeBankIconography.lifespanIconSystemName)
                        .font(.tbLabel)
                        .symbolRenderingMode(.hierarchical)
                    Text("I · 时间余额")
                        .font(.tbLabel)
                }
                .foregroundStyle(Color.tbPrimary)

                VStack(alignment: .leading, spacing: 0) {
                    Text("约 \(weeksValue)")
                        .font(.tbDisplayS)
                        .foregroundStyle(Color.tbInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.64)

                    Text("周")
                        .font(.tbHeadM)
                        .foregroundStyle(Color.tbInk2)
                }

                Text(yearsText)
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk2)
                Spacer(minLength: 0)
                HStack {
                    Rectangle().fill(Color.tbHair).frame(height: 1)
                    Text("✦").font(.tbHeadS).foregroundStyle(Color.tbPrimary)
                    Rectangle().fill(Color.tbHair).frame(height: 1)
                }
            }
            .padding(TBSpace.s5)

            VStack(alignment: .leading, spacing: TBSpace.s2) {
                HStack(spacing: TBSpace.s1) {
                    Image(systemName: TimeBankIconography.depositIconSystemName)
                        .font(.tbLabel)
                        .symbolRenderingMode(.hierarchical)
                    Text("已存入")
                        .font(.tbLabel)
                }
                .foregroundStyle(Color.tbPrimary)
                Spacer(minLength: 0)
                Text(storedText)
                    .font(.tbHeadM)
                    .foregroundStyle(Color.tbInk)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                detailLines(compactDepositDetail)
            }
            .frame(width: 126)
            .padding(TBSpace.s4)
            .background(Color.tbBg2.opacity(0.72))
        }
        .frame(height: 162)
        .background(Color.tbSurface)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.tbPrimary)
                .frame(width: 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: TBRadius.lg, style: .continuous)
                .stroke(Color.tbHair, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg, style: .continuous))
        .modifier(ThemeShadowModifier())
    }

    private var galleryCard: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: TBSpace.s1) {
                    Image(systemName: TimeBankIconography.lifespanIconSystemName)
                        .font(.tbLabel)
                        .symbolRenderingMode(.hierarchical)
                    Text("时间余额")
                        .font(.tbLabel)
                }
                Spacer()
                Text("系统账户")
                    .font(.tbLabel)
            }
            .padding(.horizontal, TBSpace.s4)
            .frame(height: 34)
            .foregroundStyle(Color.tbSurface)
            .background(Color.tbInk)

            HStack(spacing: 0) {
                galleryMetric(icon: TimeBankIconography.lifespanIconSystemName, title: "时间余额", value: weeksText, detail: yearsText)
                Rectangle().fill(Color.tbInk).frame(width: 1)
                galleryMetric(icon: TimeBankIconography.depositIconSystemName, title: "已存入", value: storedText, detail: compactDepositDetail)
            }
        }
        .frame(height: 146)
        .background(Color.tbSurface)
        .overlay {
            Rectangle().stroke(Color.tbInk, lineWidth: TimeBankTheme.current.style.strongBorderWidth)
        }
    }

    private func galleryMetric(icon: String, title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: TBSpace.s2) {
            HStack(spacing: TBSpace.s1) {
                Image(systemName: icon)
                    .font(.tbLabel)
                    .symbolRenderingMode(.hierarchical)
                Text(title.uppercased())
                    .font(.tbLabelEn)
            }
            .foregroundStyle(Color.tbInk2)
            Text(value)
                .font(.tbDisplayS)
                .foregroundStyle(Color.tbInk)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
            Spacer(minLength: 0)
            detailLines(detail)
        }
        .padding(TBSpace.s4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func detailLines(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(text.split(separator: "\n", omittingEmptySubsequences: false).enumerated()), id: \.offset) { _, line in
                Text(String(line))
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
        }
    }

    private var zenCard: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: TBSpace.s2) {
                    HStack(spacing: TBSpace.s1) {
                        Image(systemName: TimeBankIconography.lifespanIconSystemName)
                            .font(.tbLabel)
                            .symbolRenderingMode(.hierarchical)
                        Text("时间余额")
                            .font(.tbLabel)
                    }
                    .foregroundStyle(Color.tbInk2)
                    Text(weeksText)
                        .font(.tbDisplayS)
                        .foregroundStyle(Color.tbInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(yearsText)
                        .font(.tbBodySm)
                        .foregroundStyle(Color.tbInk2)
                }

                Spacer()

                Circle()
                    .stroke(Color.tbPrimary.opacity(0.62), lineWidth: 1)
                    .frame(width: 46, height: 46)
                    .overlay {
                        Image(systemName: TimeBankIconography.lifespanIconSystemName)
                            .font(.tbHeadS)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.tbPrimary)
                    }
            }

            Rectangle().fill(Color.tbHair).frame(height: 1)

            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: TBSpace.s1) {
                    Image(systemName: TimeBankIconography.depositIconSystemName)
                        .font(.tbLabel)
                        .symbolRenderingMode(.hierarchical)
                    Text("已存入")
                        .font(.tbLabel)
                }
                .foregroundStyle(Color.tbInk2)
                Spacer()
                Text(storedText)
                    .font(.tbHeadM)
                    .foregroundStyle(Color.tbInk)
            }

            Text("\(momentsText) · \(dimensionText)")
                .font(.tbBodySm)
                .foregroundStyle(Color.tbInk2)
        }
        .padding(TBSpace.s5)
        .frame(height: 166)
        .background(Color.tbSurface)
        .overlay {
            RoundedRectangle(cornerRadius: TBRadius.xl, style: .continuous)
                .stroke(Color.tbHair, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.xl, style: .continuous))
        .modifier(ThemeShadowModifier())
    }

    private var localRemoteCard: some View {
        HStack(spacing: 0) {
            VStack {
                Image(systemName: TimeBankIconography.lifespanIconSystemName)
                    .font(.tbBody)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.tbInk2)
                Text("\(yearsValue)")
                    .font(.tbDisplayS)
                    .foregroundStyle(Color.tbInk)
                Spacer()
                Text("年\n\(hoursKText)\n时间余额")
                    .font(.tbLabelEn)
                    .foregroundStyle(Color.tbInk2)
                    .lineSpacing(2)
            }
            .frame(width: 78)
            .padding(TBSpace.s3)
            .overlay(alignment: .trailing) {
                Rectangle().fill(Color.tbInk).frame(width: 1)
            }

            VStack(alignment: .leading, spacing: TBSpace.s2) {
                HStack(spacing: TBSpace.s1) {
                    Image(systemName: TimeBankIconography.lifespanIconSystemName)
                        .font(.tbLabel)
                        .symbolRenderingMode(.hierarchical)
                    Text("时间余额")
                        .font(.tbLabelEn)
                }
                .foregroundStyle(Color.tbInk2)

                Text("约 \(weeksValue) 周")
                    .font(.tbDisplayS)
                    .foregroundStyle(Color.tbInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.56)

                Text("约 \(Int(projection.remainingWeeks.rounded(.down))) 周可用。把还在展开的时间，安静地记在这里。")
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Rectangle().fill(Color.tbInk).frame(height: 1)

                HStack(alignment: .top, spacing: TBSpace.s4) {
                    VStack(alignment: .leading, spacing: TBSpace.s1) {
                        Image(systemName: TimeBankIconography.depositIconSystemName)
                            .font(.tbBodySm)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.tbInk2)
                        Text(storedText)
                            .font(.tbHeadM)
                            .foregroundStyle(Color.tbInk)
                        Text("已存入")
                            .font(.tbLabel)
                            .foregroundStyle(Color.tbInk2)
                    }
                    VStack(alignment: .leading, spacing: TBSpace.s1) {
                        Text("\(totalAccount.moments)")
                            .font(.tbHeadM)
                            .foregroundStyle(Color.tbInk)
                        Text("\(momentsText) · \(accountCountText)")
                            .font(.tbLabel)
                            .foregroundStyle(Color.tbInk2)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(TBSpace.s4)
        }
        .frame(height: 174)
        .background(Color.tbSurface)
        .overlay {
            GridTexture()
                .stroke(Color.tbInk.opacity(0.08), lineWidth: 1)
        }
        .overlay {
            Rectangle().stroke(Color.tbInk, lineWidth: TimeBankTheme.current.style.strongBorderWidth)
        }
    }
}

private struct ThemeShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        let theme = TimeBankTheme.current
        content
            .shadow(
                color: theme.palette.shadowTint.opacity(theme.style.usesShadow ? theme.style.shadowOpacity : 0),
                radius: theme.style.shadowRadius,
                x: 0,
                y: theme.style.shadowYOffset
            )
    }
}

private struct GridTexture: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 32

        var x = rect.minX
        while x <= rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += step
        }

        var y = rect.minY
        while y <= rect.maxY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += step
        }

        return path
    }
}
