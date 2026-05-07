// TimeBank/Features/Home/DimensionCardView.swift

import SwiftUI

struct DimensionCardView: View {
    let dimension: Dimension
    let profile: UserProfile
    let dimensionsByID: [String: Dimension]
    let moments: [Moment]
    let timeScope: DimensionCompute.TimeBalanceScope

    var body: some View {
        semanticCard
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var consumePrimary: String {
        isMemorial ? "记录这一段。" : Formatter.hoursCompact(consumeHours)
    }

    private var storedPrimary: String {
        Formatter.storedDuration(storedHours)
    }

    private var storedSecondary: String {
        Formatter.momentsCount(storedMomentCount)
    }

    private var dimensionCode: String {
        switch dimension.id {
        case DimensionReservedID.parents.rawValue: return "父母"
        case DimensionReservedID.kids.rawValue: return "孩子"
        case DimensionReservedID.partner.rawValue: return "伴侣"
        case DimensionReservedID.sport.rawValue: return "运动"
        case DimensionReservedID.create.rawValue: return "创造"
        case DimensionReservedID.free.rawValue: return "自由"
        default: return "自定义"
        }
    }

    private var semanticCard: some View {
        VStack(spacing: TBSpace.s2) {
            header
                .frame(height: 40)

            HStack(spacing: TBSpace.s3) {
                semanticMetric(label: consumeLabel, primary: consumePrimary, secondary: isMemorial ? "纪念账户" : subtitleText)

                Rectangle()
                    .fill(Color.tbHair)
                    .frame(width: 1)

                semanticMetric(label: "已存入", primary: storedPrimary, secondary: storedSecondary)
            }
            .frame(height: 52)
        }
        .padding(TBSpace.s3)
        .frame(maxWidth: .infinity)
        .frame(height: 116)
        .tbThemedSurface()
    }

    private func semanticMetric(label: String, primary: String, secondary: String) -> some View {
        VStack(alignment: .leading, spacing: TBSpace.s1) {
            Text(label)
                .font(.tbLabel)
                .foregroundStyle(Color.tbInk3)

            Text(primary)
                .font(.tbHeadM)
                .foregroundStyle(Color.tbInk)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            if secondary.isEmpty == false {
                Text(secondary)
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var magazineCard: some View {
        VStack(spacing: TBSpace.s2) {
            header
                .frame(height: 34)

            HStack(spacing: TBSpace.s3) {
                magazineMetric(label: consumeLabel, primary: consumePrimary, secondary: isMemorial ? "" : subtitleText)
                Rectangle().fill(Color.tbHair).frame(width: 1)
                magazineMetric(label: "已存入", primary: storedPrimary, secondary: storedSecondary)
            }
            .frame(height: 52)
        }
        .padding(.horizontal, TBSpace.s3)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .frame(height: 108)
        .background(Color.tbSurface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(DimensionPalette.color(for: dimension))
                .frame(height: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg, style: .continuous))
        .modifier(TBSoftShadowModifier())
    }

    private func magazineMetric(label: String, primary: String, secondary: String) -> some View {
        VStack(alignment: .leading, spacing: TBSpace.s1) {
            Text(label)
                .font(.tbLabel)
                .foregroundStyle(Color.tbInk3)

            Text(primary)
                .font(.tbHeadM)
                .foregroundStyle(Color.tbInk)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            if secondary.isEmpty == false {
                Text(secondary)
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var artBookCard: some View {
        HStack(alignment: .top, spacing: TBSpace.s3) {
            Image(systemName: iconSystemName)
                .font(.tbHeadM)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(DimensionPalette.color(for: dimension))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: TBSpace.s2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(dimension.name)
                        .font(.tbHeadS)
                        .foregroundStyle(Color.tbInk)
                    Spacer()
                    Text(consumePrimary)
                        .font(.tbHeadS)
                        .foregroundStyle(Color.tbInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                HStack {
                    Text(isMemorial ? "纪念账户" : subtitleText)
                    Spacer()
                    Text("\(storedPrimary) · \(storedSecondary)")
                }
                .font(.tbBodySm)
                .foregroundStyle(Color.tbInk2)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
            }
        }
        .padding(.vertical, TBSpace.s3)
        .padding(.horizontal, TBSpace.s2)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 66)
        .background(Color.tbSurface.opacity(0.72))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.tbHair).frame(height: 1)
        }
    }

    private var galleryCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text(dimensionCode)
                    .font(.tbLabelEn)
                Spacer()
                Image(systemName: iconSystemName)
                    .font(.tbBodySm)
                    .symbolRenderingMode(.hierarchical)
                Text(dimension.name)
                    .font(.tbHeadS)
            }
            .foregroundStyle(Color.tbSurface)
            .padding(.horizontal, TBSpace.s3)
            .frame(height: 34)
            .background(DimensionPalette.color(for: dimension))

            HStack(spacing: 0) {
                galleryMetric(label: consumeLabel, value: consumePrimary, detail: isMemorial ? "纪念账户" : subtitleText)
                Rectangle().fill(Color.tbInk).frame(width: 1)
                galleryMetric(label: "已存入", value: storedPrimary, detail: storedSecondary)
            }
        }
        .frame(height: 102)
        .background(Color.tbSurface)
        .overlay {
            Rectangle().stroke(Color.tbInk, lineWidth: TimeBankTheme.current.style.cardBorderWidth)
        }
    }

    private func galleryMetric(label: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: TBSpace.s1) {
            Text(label.uppercased())
                .font(.tbLabelEn)
                .foregroundStyle(Color.tbInk3)
            Text(value)
                .font(.tbHeadM)
                .foregroundStyle(Color.tbInk)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
            Text(detail)
                .font(.tbLabel)
                .foregroundStyle(Color.tbInk2)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
        .padding(TBSpace.s3)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var zenCard: some View {
        HStack(alignment: .center, spacing: TBSpace.s3) {
            Circle()
                .stroke(DimensionPalette.color(for: dimension).opacity(0.72), lineWidth: 1)
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: iconSystemName)
                        .font(.tbHeadS)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(DimensionPalette.color(for: dimension))
                }

            VStack(alignment: .leading, spacing: TBSpace.s1) {
                Text(dimension.name)
                    .font(.tbHeadS)
                    .foregroundStyle(Color.tbInk)

                Text("\(consumeLabel) \(consumePrimary) · \(isMemorial ? "纪念账户" : subtitleText)")
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text("已存入 \(storedPrimary) · \(storedSecondary)")
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbPrimary)
                    .lineLimit(1)
            }
        }
        .padding(TBSpace.s3)
        .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
        .background(Color.tbSurface)
        .overlay {
            RoundedRectangle(cornerRadius: TBRadius.xl, style: .continuous)
                .stroke(Color.tbHair, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.xl, style: .continuous))
        .modifier(TBSoftShadowModifier())
    }

    private var localRemoteCard: some View {
        HStack(spacing: 0) {
            Text(dimensionCode)
                .font(.tbLabelEn)
                .foregroundStyle(Color.tbInk2)
                .rotationEffect(.degrees(90))
                .frame(width: 36, height: 96)
                .overlay(alignment: .trailing) {
                    Rectangle().fill(Color.tbInk).frame(width: 1)
                }

            VStack(alignment: .leading, spacing: TBSpace.s1) {
                HStack(alignment: .firstTextBaseline) {
                    Text(dimension.name)
                        .font(.tbHeadS)
                        .foregroundStyle(Color.tbInk)
                    Spacer()
                    Image(systemName: iconSystemName)
                        .font(.tbBody)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(DimensionPalette.color(for: dimension))
                }

                Text("\(consumeLabel) \(consumePrimary) · \(isMemorial ? "纪念账户" : subtitleText)")
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Rectangle().fill(Color.tbHair).frame(height: 1)

                HStack(spacing: TBSpace.s3) {
                    Text("已存入")
                        .font(.tbLabelEn)
                        .padding(.horizontal, TBSpace.s2)
                        .padding(.vertical, TBSpace.s1)
                        .overlay {
                            Rectangle().stroke(Color.tbInk, lineWidth: 1)
                        }
                    Text("\(storedPrimary) · \(storedSecondary)")
                        .font(.tbBodySm)
                        .foregroundStyle(Color.tbInk2)
                        .lineLimit(1)
                }
            }
            .padding(TBSpace.s3)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 96)
        .background(Color.tbSurface)
        .overlay {
            LocalRemoteCardGridTexture()
                .stroke(Color.tbInk.opacity(0.06), lineWidth: 1)
        }
        .overlay {
            Rectangle().stroke(Color.tbInk, lineWidth: TimeBankTheme.current.style.cardBorderWidth)
        }
    }

    private var header: some View {
        HStack(spacing: TBSpace.s3) {
            ZStack {
                Circle()
                    .fill(DimensionPalette.soft(for: dimension))

                Image(systemName: iconSystemName)
                    .font(.tbHeadS)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(DimensionPalette.color(for: dimension))
            }
            .frame(width: 40, height: 40)

            Text(dimension.name)
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)
                .lineLimit(1)

            Spacer()

            if isMemorial {
                Text("纪念")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk2)
                    .padding(.horizontal, TBSpace.s2)
                    .padding(.vertical, TBSpace.s1)
                    .background(Color.tbInk2.opacity(0.10))
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.tbBodySm)
                .foregroundStyle(Color.tbInk3)
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)
        }
    }

    private func metricColumn(
        label: String,
        rawHours: Double,
        primary: String,
        secondary: String
    ) -> some View {
        VStack(alignment: .leading, spacing: TBSpace.s1) {
            Text(label)
                .font(.tbLabel)
                .foregroundStyle(Color.tbInk3)

            Text(primary)
                .font(.tbHeadM)
                .foregroundStyle(Color.tbInk)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            if rawHours >= 24 {
                Text(Formatter.hoursInDays(rawHours))
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Text(secondary)
                .font(.tbBodySm)
                .foregroundStyle(Color.tbInk2)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var memorialColumn: some View {
        VStack(alignment: .leading, spacing: TBSpace.s1) {
            Text(consumeLabel)
                .font(.tbLabel)
                .foregroundStyle(Color.tbInk3)

            Text("记录这一段。")
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var consumeLabel: String {
        switch dimension.id {
        case DimensionReservedID.parents.rawValue,
             DimensionReservedID.kids.rawValue,
             DimensionReservedID.partner.rawValue:
            return "还能共度"

        case DimensionReservedID.sport.rawValue,
             DimensionReservedID.create.rawValue,
             DimensionReservedID.free.rawValue:
            return "未来"

        default:
            return "还能共度"
        }
    }

    private var consumeHours: Double {
        DimensionCompute.consumeHours(
            for: dimension,
            profile: profile,
            dimensionsByID: dimensionsByID,
            scope: timeScope
        )
    }

    private var subtitleText: String {
        let subtitle = DimensionCompute.subtitleData(
            for: dimension,
            profile: profile,
            dimensionsByID: dimensionsByID,
            scope: timeScope
        )

        switch subtitle {
        case .occurrence(let count, let noun):
            return Formatter.occurrenceCount(count, noun: noun)
        case .weeklyHours(let hours):
            return Formatter.weeklyHours(hours)
        case .dailyHoursWith(let hours, let action):
            return Formatter.dailyHoursWith(hours, action: action)
        case .percentOfAwake(let percent):
            return Formatter.percentOfAwake(percent)
        case .lifespan, .none:
            return ""
        }
    }

    private var storedHours: Double {
        DimensionCompute.storedHours(for: dimension.id, moments: moments)
    }

    private var storedMomentCount: Int {
        DimensionCompute.storedMomentCount(for: dimension.id, moments: moments)
    }

    private var iconSystemName: String {
        DimensionDetailCopy.iconSystemName(for: dimension)
    }

    private var accessibilitySummary: String {
        if isMemorial {
            return "\(dimension.name)，纪念账户，已存入 \(storedPrimary)，\(storedSecondary)"
        }

        let subtitle = subtitleText.isEmpty ? "" : "，\(subtitleText)"
        return "\(dimension.name)，\(consumeLabel) \(consumePrimary)\(subtitle)，已存入 \(storedPrimary)，\(storedSecondary)"
    }

    private var isMemorial: Bool {
        dimension.mode == .memorial
    }
}

private struct TBSoftShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        TBShadow.soft(for: content)
    }
}

private struct LocalRemoteCardGridTexture: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 28

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
