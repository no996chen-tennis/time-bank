// TimeBank/Features/Home/DimensionCardView.swift

import SwiftUI

struct DimensionCardView: View {
    let dimension: Dimension
    let profile: UserProfile
    let dimensionsByID: [String: Dimension]
    let moments: [Moment]

    var body: some View {
        VStack(spacing: TBSpace.s1) {
            header
                .frame(height: 48)

            HStack(spacing: TBSpace.s4) {
                if isMemorial {
                    memorialColumn
                } else {
                    metricColumn(
                        label: consumeLabel,
                        rawHours: consumeHours,
                        primary: Formatter.hoursCompact(consumeHours),
                        secondary: subtitleText
                    )
                }

                Rectangle()
                    .fill(Color.tbHair)
                    .frame(width: 1)

                metricColumn(
                    label: "已存入",
                    rawHours: storedHours,
                    primary: Formatter.storedDuration(storedHours),
                    secondary: Formatter.momentsCount(storedMomentCount)
                )
            }
            .frame(height: 88)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, TBSpace.s2)
        .frame(maxWidth: .infinity)
        .frame(height: 156)
        .background(Color.tbSurface)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg))
        .modifier(TBSoftShadowModifier())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isMemorial ? "这是 \(dimension.name) 的纪念账户" : dimension.name)
    }

    private var header: some View {
        HStack(spacing: TBSpace.s3) {
            ZStack {
                Circle()
                    .fill(DimensionPalette.soft(for: dimension.id))

                Image(systemName: iconSystemName)
                    .font(.tbHeadS)
                    .foregroundStyle(DimensionPalette.color(for: dimension.id))
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
            dimensionsByID: dimensionsByID
        )
    }

    private var subtitleText: String {
        let subtitle = DimensionCompute.subtitleData(
            for: dimension,
            profile: profile,
            dimensionsByID: dimensionsByID
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
        switch dimension.id {
        case DimensionReservedID.parents.rawValue:
            return "heart.fill"
        case DimensionReservedID.kids.rawValue:
            return "figure.2.and.child.holdinghands"
        case DimensionReservedID.partner.rawValue:
            return "heart.circle.fill"
        case DimensionReservedID.sport.rawValue:
            return "figure.run"
        case DimensionReservedID.create.rawValue:
            return "paintbrush.fill"
        case DimensionReservedID.free.rawValue:
            return "sun.max.fill"
        default:
            return dimension.iconKey
        }
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
