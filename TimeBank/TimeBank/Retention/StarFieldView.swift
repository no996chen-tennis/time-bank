// TimeBank/TimeBank/Retention/StarFieldView.swift
//
// 星空账本（闭环③：看得见的资产）：每个账户一个星座，每条已存入瞬间一颗星。
// 只渲染已点亮的星（红线：绝不显示总数/剩余/未解锁灰格）。连续存入越多，夜空越亮、偶有流星。

import SwiftUI

struct StarFieldView: View {
    let dimensions: [Dimension]
    let moments: [Moment]

    private var model: StarFieldModel { StarFieldModel.build(dimensions: dimensions, moments: moments) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: TBSpace.s4) {
                header

                if model.litCount == 0 {
                    emptyState
                } else {
                    skyCard
                    legend
                }
            }
            .padding(.horizontal, TBSpace.s5)
            .padding(.top, TBSpace.s3)
            .padding(.bottom, TBSpace.s7)
        }
        .background(Color.tbBg)
        .navigationTitle("星空")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: TBSpace.s1) {
            Text("你已点亮 \(model.litCount) 颗星")
                .font(.tbHeadM)
                .foregroundStyle(Color.tbInk)
            Text("每一段被你认真留下的时间，都是夜空里的一颗星。")
                .font(.tbBodySm)
                .foregroundStyle(Color.tbInk2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var skyCard: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: false)) { timeline in
            Canvas { context, size in
                drawSky(context: context, size: size, time: timeline.date.timeIntervalSinceReferenceDate)
            }
            .frame(height: 360)
            .background(
                LinearGradient(
                    colors: [StarSky.top, StarSky.mid, StarSky.bottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: TBRadius.lg, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            }
        }
    }

    private func drawSky(context: GraphicsContext, size: CGSize, time: Double) {
        // 连线：同一星座内按顺序连出极淡的星座线
        for constellation in model.constellations {
            guard constellation.stars.count >= 2 else { continue }
            var path = Path()
            for (index, star) in constellation.stars.enumerated() {
                let point = CGPoint(x: star.x * size.width, y: star.y * size.height)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            context.stroke(path, with: .color(.white.opacity(0.10)), lineWidth: 0.8)
        }

        // 流星：连续存入活跃（近 7 天 ≥3 笔）时偶尔划过一道
        if model.recentStreak >= 3 {
            drawShootingStar(context: context, size: size, time: time)
        }

        // 星：发光圆 + 亮核，twinkle 调制透明度
        for constellation in model.constellations {
            for star in constellation.stars {
                let center = CGPoint(x: star.x * size.width, y: star.y * size.height)
                let twinkle = 0.72 + 0.28 * sin(time * star.twinkleSpeed + star.phase)
                let alpha = min(1.0, star.brightness * twinkle)
                let core = star.radius

                // 光晕
                let glowRect = CGRect(x: center.x - core * 3, y: center.y - core * 3, width: core * 6, height: core * 6)
                context.fill(
                    Circle().path(in: glowRect),
                    with: .radialGradient(
                        Gradient(colors: [star.tint.opacity(0.45 * alpha), .clear]),
                        center: center, startRadius: 0, endRadius: core * 3
                    )
                )
                // 亮核
                let coreRect = CGRect(x: center.x - core, y: center.y - core, width: core * 2, height: core * 2)
                context.fill(Circle().path(in: coreRect), with: .color(.white.opacity(alpha)))
            }
        }
    }

    private func drawShootingStar(context: GraphicsContext, size: CGSize, time: Double) {
        // 每 ~8 秒一道，划过 1.2 秒
        let cycle = 8.0
        let t = time.truncatingRemainder(dividingBy: cycle)
        guard t < 1.2 else { return }
        let progress = t / 1.2
        let startX = size.width * 0.15
        let startY = size.height * 0.18
        let dx = size.width * 0.6
        let dy = size.height * 0.32
        let head = CGPoint(x: startX + dx * progress, y: startY + dy * progress)
        let tail = CGPoint(x: head.x - dx * 0.16, y: head.y - dy * 0.16)
        var path = Path()
        path.move(to: tail)
        path.addLine(to: head)
        context.stroke(path, with: .linearGradient(
            Gradient(colors: [.clear, .white.opacity(0.85)]),
            startPoint: tail, endPoint: head
        ), lineWidth: 2)
    }

    private var legend: some View {
        VStack(spacing: TBSpace.s3) {
            ForEach(model.constellations) { constellation in
                HStack(spacing: TBSpace.s3) {
                    Circle()
                        .fill(DimensionPalette.color(forColorKey: constellation.colorKey))
                        .frame(width: 10, height: 10)
                    Text(constellation.name)
                        .font(.tbBodySm)
                        .foregroundStyle(Color.tbInk)
                    Spacer()
                    Text("\(constellation.stars.count) 颗")
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbInk2)
                }
            }
        }
        .padding(TBSpace.s4)
        .frame(maxWidth: .infinity)
        .tbThemedSurface()
    }

    private var emptyState: some View {
        VStack(spacing: TBSpace.s3) {
            Image(systemName: "sparkles")
                .font(.tbHeadL)
                .foregroundStyle(Color.tbInk3)
            Text("存入第一个瞬间，夜空就会亮起第一颗星。")
                .font(.tbBodySm)
                .foregroundStyle(Color.tbInk2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
        .tbThemedSurface()
    }
}

private enum StarSky {
    static let top = Color(red: 0.07, green: 0.06, blue: 0.10)
    static let mid = Color(red: 0.10, green: 0.13, blue: 0.16)
    static let bottom = Color(red: 0.14, green: 0.16, blue: 0.13)
}

struct StarFieldModel {
    struct Star: Identifiable {
        let id: UUID
        let x: Double
        let y: Double
        let radius: CGFloat
        let brightness: Double
        let twinkleSpeed: Double
        let phase: Double
        let tint: Color
    }

    struct Constellation: Identifiable {
        let id: String
        let name: String
        let colorKey: String
        let stars: [Star]
    }

    let constellations: [Constellation]
    let litCount: Int
    let recentStreak: Int

    static func build(dimensions: [Dimension], moments: [Moment], now: Date = .now) -> StarFieldModel {
        let dimById = Dictionary(uniqueKeysWithValues: dimensions.map { ($0.id, $0) })
        let normal = moments.filter { $0.status == .normal }

        // 按账户分组，保留有瞬间的账户，按账户 sortIndex 排
        let grouped = Dictionary(grouping: normal, by: { $0.dimensionId })
        let orderedDimIDs = grouped.keys.sorted { lhs, rhs in
            (dimById[lhs]?.sortIndex ?? 99) < (dimById[rhs]?.sortIndex ?? 99)
        }

        let count = orderedDimIDs.count
        let cols = max(1, Int(ceil(Double(count).squareRoot())))
        let rows = max(1, Int(ceil(Double(count) / Double(cols))))

        var constellations: [Constellation] = []
        for (index, dimID) in orderedDimIDs.enumerated() {
            let col = index % cols
            let row = index / cols
            let cx = cols > 1 ? 0.16 + 0.68 * Double(col) / Double(cols - 1) : 0.5
            let cy = rows > 1 ? 0.18 + 0.64 * Double(row) / Double(rows - 1) : 0.5

            let colorKey = dimById[dimID]?.colorKey ?? "rose"
            let tint = DimensionPalette.color(forColorKey: colorKey)
            let dimMoments = (grouped[dimID] ?? []).sorted { $0.happenedAt < $1.happenedAt }

            let stars: [Star] = dimMoments.map { moment in
                let h = stableHash(moment.id.uuidString)
                let angle = Double(h & 0xFFFF) / Double(0xFFFF) * 2 * .pi
                let radius = 0.035 + 0.085 * Double((h >> 16) & 0xFFFF) / Double(0xFFFF)
                let x = min(0.97, max(0.03, cx + cos(angle) * radius))
                let y = min(0.95, max(0.05, cy + sin(angle) * radius * 0.92))
                let bright = 0.6 + 0.4 * Double((h >> 32) & 0xFF) / Double(0xFF)
                let speed = 0.8 + 1.4 * Double((h >> 40) & 0xFF) / Double(0xFF)
                let phase = Double((h >> 48) & 0xFF) / Double(0xFF) * 2 * .pi
                let coreRadius: CGFloat = (moment.durationSeconds ?? 0) > 3600 ? 2.6 : 1.9
                return Star(
                    id: moment.id, x: x, y: y, radius: coreRadius,
                    brightness: bright, twinkleSpeed: speed, phase: phase, tint: tint
                )
            }

            constellations.append(Constellation(
                id: dimID,
                name: dimById[dimID]?.name ?? "时间账户",
                colorKey: colorKey,
                stars: stars
            ))
        }

        // 近 7 天存入笔数（连续活跃的轻量度量，喂流星特效；不惩罚、不显示断签）
        let weekAgo = now.addingTimeInterval(-7 * 86_400)
        let recent = normal.filter { $0.createdAt >= weekAgo }.count

        return StarFieldModel(
            constellations: constellations,
            litCount: normal.count,
            recentStreak: recent
        )
    }

    private static func stableHash(_ string: String) -> UInt64 {
        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in string.utf8 {
            hash = (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
        return hash
    }
}
