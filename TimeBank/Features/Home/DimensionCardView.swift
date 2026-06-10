// TimeBank/Features/Home/DimensionCardView.swift

import SwiftUI

struct DimensionCardView: View {
    let dimension: Dimension
    let profile: UserProfile
    let dimensionsByID: [String: Dimension]
    let moments: [Moment]
    let timeScope: DimensionCompute.TimeBalanceScope

    var body: some View {
        card
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilitySummary)
    }

    private var card: some View {
        HStack(spacing: 0) {
            // 账户色书脊：像存折侧边的索引条
            Rectangle()
                .fill(DimensionPalette.color(for: dimension))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: TBSpace.s3) {
                header

                HStack(alignment: .top, spacing: TBSpace.s4) {
                    metric(
                        label: consumeLabel,
                        primary: consumePrimary,
                        secondary: isMemorial ? "纪念账户" : subtitleText,
                        primaryColor: Color.tbInk
                    )

                    Rectangle()
                        .fill(Color.tbHair.opacity(0.8))
                        .frame(width: 1)
                        .padding(.vertical, 2)

                    metric(
                        label: "已存入",
                        primary: storedPrimary,
                        secondary: storedSecondary,
                        primaryColor: storedMomentCount > 0
                            ? DimensionPalette.color(for: dimension)
                            : Color.tbInk3
                    )
                }
            }
            .padding(.vertical, TBSpace.s4)
            .padding(.horizontal, TBSpace.s4)
        }
        .frame(maxWidth: .infinity)
        .tbThemedSurface()
    }

    private var header: some View {
        HStack(spacing: TBSpace.s2) {
            ZStack {
                RoundedRectangle(cornerRadius: TBRadius.sm, style: .continuous)
                    .fill(DimensionPalette.soft(for: dimension))

                Image(systemName: iconSystemName)
                    .font(.tbBodySm)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(DimensionPalette.color(for: dimension))
            }
            .frame(width: 30, height: 30)

            Text(dimension.name)
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)
                .lineLimit(1)

            if isMemorial {
                Text("纪念")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk2)
                    .padding(.horizontal, TBSpace.s2)
                    .padding(.vertical, 2)
                    .background(Color.tbInk2.opacity(0.10))
                    .clipShape(Capsule())
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.tbLabel)
                .foregroundStyle(Color.tbInk3)
                .accessibilityHidden(true)
        }
    }

    private func metric(
        label: String,
        primary: String,
        secondary: String,
        primaryColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: TBSpace.s1) {
            Text(label)
                .font(.tbLabel)
                .foregroundStyle(Color.tbInk3)

            Text(primary)
                .font(.tbNumM)
                .foregroundStyle(primaryColor)
                .lineLimit(1)
                .minimumScaleFactor(0.66)
                .contentTransition(.numericText())

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

    // MARK: - 数据

    private var consumePrimary: String {
        isMemorial ? "记录这一段。" : Formatter.hoursCompact(consumeHours)
    }

    private var storedPrimary: String {
        Formatter.storedDuration(storedHours)
    }

    private var storedSecondary: String {
        Formatter.momentsCount(storedMomentCount)
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
