// TimeBank/Features/Home/DimensionCardView.swift

import SwiftUI

struct DimensionCardView: View {
    let dimension: Dimension
    let profile: UserProfile
    let dimensionsByID: [String: Dimension]
    let moments: [Moment]
    let timeScope: DimensionCompute.TimeBalanceScope
    let fileStore: FileStore
    /// 小图带内单张瞬间点按：父层处理导航（本卡不放 NavigationLink）。
    var onTapMoment: (Moment) -> Void
    /// 卡片非小图区域（header / 副信息）点按：父层导航进维度详情。
    var onTapCard: () -> Void

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
                // header + 副信息 = 进维度详情的点按区（不含小图带）
                VStack(alignment: .leading, spacing: TBSpace.s3) {
                    header
                    subInfoLine
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onTapCard()
                }

                // 主体：图片为主的横滑小图带（内部各 thumb 是独立 Button，不冒泡到 onTapCard）
                DimensionMomentStrip(
                    dimension: dimension,
                    moments: moments,
                    fileStore: fileStore,
                    thumbSize: 64,
                    onTapMoment: onTapMoment
                )
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

    /// 原两个大 metric 压成一行小字副信息。复用现有 consumeHours / subtitleText / storedMomentCount 计算。
    private var subInfoLine: some View {
        HStack(spacing: TBSpace.s2) {
            Text(consumeSummary)
                .font(.tbBodySm)
                .foregroundStyle(Color.tbInk2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("·")
                .font(.tbBodySm)
                .foregroundStyle(Color.tbInk3)

            Text(storedSummary)
                .font(.tbLabel)
                .foregroundStyle(
                    storedMomentCount > 0
                        ? DimensionPalette.color(for: dimension)
                        : Color.tbInk3
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 0)
        }
    }

    // MARK: - 数据

    /// 消耗层一行小字：纪念账户给固定文案，否则「<还能共度/未来> 约 X 小时 · 副信息」。
    private var consumeSummary: String {
        if isMemorial {
            return "记录这一段。"
        }
        let primary = "\(consumeLabel) \(Formatter.hoursCompact(consumeHours))"
        let subtitle = subtitleText
        return subtitle.isEmpty ? primary : "\(primary) · \(subtitle)"
    }

    /// 存储层一行小字：只用「N 个瞬间」量词（存储层量词铁律）。
    private var storedSummary: String {
        "已存入 \(Formatter.momentsCount(storedMomentCount))"
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

    private var storedMomentCount: Int {
        DimensionCompute.storedMomentCount(for: dimension.id, moments: moments)
    }

    private var iconSystemName: String {
        DimensionDetailCopy.iconSystemName(for: dimension)
    }

    private var accessibilitySummary: String {
        if isMemorial {
            return "\(dimension.name)，纪念账户，\(storedSummary)"
        }

        let subtitle = subtitleText.isEmpty ? "" : "，\(subtitleText)"
        return "\(dimension.name)，\(consumeLabel) \(Formatter.hoursCompact(consumeHours))\(subtitle)，\(storedSummary)"
    }

    private var isMemorial: Bool {
        dimension.mode == .memorial
    }
}
