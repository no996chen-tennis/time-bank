// TimeBank/Features/Home/BigPhotoMultiHomeView.swift

import SwiftData
import SwiftUI

/// 首页变体「大图·多图」：与 BigPhotoHomeView 平行的独立 View，由 RootView 按
/// @AppStorage(HomeLayoutKind.storageKey) 分发（case .bigPhotoMulti）。
///
/// 与 BigPhotoHomeView 共用同一套骨架：常驻顶部（Greeting + 今年/今生选项卡）、
/// hero 双层账户卡（今天还剩已并进 hero）、TabView(.page) 今年/今生、BottomTabBar、
/// momentRoute/dimensionRoute 导航、WidgetSnapshotWriter.writeSnapshot 刷新。
///
/// 唯一区别在维度区：每个可见维度渲染成「一块」——顶部一行「● 维度名 + 今年余额」
/// （点进维度详情），下面是该维度最近瞬间的横向多图带（复用 DimensionMomentStrip，
/// thumbSize 调大到约 120，可横滑、点图进瞬间详情）。无带图瞬间时走 Strip 既有占位。
///
/// 手势分区同 §3.3：横滑带内每张图 = 独立 Button(onTapPhoto) → momentRoute；
/// 维度名行 = 独立 Button(onTapDimension) → dimensionRoute。整块不包 NavigationLink。
struct BigPhotoMultiHomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [UserProfile]
    @Query private var dimensions: [Dimension]
    @Query private var moments: [Moment]

    @State private var selectedTab: HomeTab = .home
    @State private var timeScope: DimensionCompute.TimeBalanceScope = .year
    @State private var fileStore = FileStore()
    @State private var momentRoute: Moment?
    @State private var dimensionRoute: BigPhotoMultiDimensionRoute?
    @State private var momentEditorRoute: MomentEditorRoute?

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first {
                    switch selectedTab {
                    case .home:
                        homeContent(profile: profile)
                    case .account:
                        accountContent()
                    case .me:
                        meContent(profile: profile)
                    }
                } else {
                    Text("未找到用户信息")
                        .font(.tbBodySm)
                        .foregroundStyle(Color.tbInk2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.tbBg)
            .navigationDestination(item: $momentRoute) { moment in
                MomentDetailView(momentID: moment.id)
            }
            .navigationDestination(item: $dimensionRoute) { route in
                DimensionDetailView(dimensionID: route.id, initialTimeScope: route.scope)
            }
            .sheet(item: $momentEditorRoute) { route in
                MomentEditorView(route: route)
            }
        }
        .onChange(of: widgetSnapshotQueryFingerprint) { _, _ in
            guard let profile = profiles.first else { return }
            refreshWidgetSnapshot(profile: profile)
        }
    }

    // MARK: - 主页 Tab（大图·多图）

    private func homeContent(profile: UserProfile) -> some View {
        VStack(spacing: 0) {
            GreetingHeaderView()
                .padding(.horizontal, TBSpace.s5)
                .padding(.top, TBSpace.s4)
                .padding(.bottom, TBSpace.s2)

            // 「今天还剩」已并进 hero 大卡（DoubleLayerAccountCardView），此处不再单独展示。

            // 顶部选项卡，与 TabView 共用 $timeScope 双向同步
            TimeBalanceScopeControl(scope: $timeScope)
                .padding(.horizontal, TBSpace.s5)
                .padding(.bottom, TBSpace.s2)

            // §3.2 确定布局：TabView 占满剩余高度，每页内部才是 ScrollView，页高确定。
            TabView(selection: $timeScope) {
                scopedScrollPage(profile: profile, scope: .year)
                    .tag(DimensionCompute.TimeBalanceScope.year)

                scopedScrollPage(profile: profile, scope: .lifetime)
                    .tag(DimensionCompute.TimeBalanceScope.lifetime)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: .infinity)

            tabBar
        }
        .task(id: widgetSnapshotQueryFingerprint) {
            refreshWidgetSnapshot(profile: profile)
        }
    }

    /// 随 scope 变化的多图首页主体（每页内部 ScrollView，高度由外层 TabView 确定）。
    @ViewBuilder
    private func scopedScrollPage(
        profile: UserProfile,
        scope: DimensionCompute.TimeBalanceScope
    ) -> some View {
        let visibleDimensions = visibleAccountDimensions
        let dimensionsByID = Dictionary(uniqueKeysWithValues: dimensions.map { ($0.id, $0) })
        let normalMoments = moments.filter { $0.status == .normal }
        let projection = DimensionCompute.projection(profile: profile, scope: scope)
        let totalAccount = DimensionCompute.totalAccount(
            dimensions: visibleDimensions,
            moments: normalMoments
        )

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: TBSpace.s4) {
                // hero：复用经典首页同款双层账户卡
                DoubleLayerAccountCardView(
                    projection: projection,
                    totalAccount: totalAccount,
                    scope: scope,
                    elapsedProgress: elapsedProgress(profile: profile, scope: scope),
                    onDepositsTap: {
                        selectedTab = .account
                    }
                )

                dimensionSectionHeader(count: visibleDimensions.count)

                LazyVStack(spacing: TBSpace.s5) {
                    ForEach(visibleDimensions, id: \.id) { dimension in
                        BigPhotoMultiDimensionBlock(
                            dimension: dimension,
                            profile: profile,
                            dimensionsByID: dimensionsByID,
                            moments: normalMoments,
                            timeScope: scope,
                            fileStore: fileStore,
                            onTapPhoto: { moment in
                                momentRoute = moment
                            },
                            onTapDimension: {
                                dimensionRoute = BigPhotoMultiDimensionRoute(id: dimension.id, scope: scope)
                            }
                        )
                    }
                }

                Color.clear.frame(height: TBSpace.s3)
            }
            .padding(.horizontal, TBSpace.s5)
            .padding(.bottom, TBSpace.s5)
        }
    }

    private func dimensionSectionHeader(count: Int) -> some View {
        HStack(alignment: .center, spacing: TBSpace.s3) {
            Text("时间账户 · \(count) 个")
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)

            Spacer()
        }
        .padding(.top, TBSpace.s1)
    }

    // MARK: - 账户 / 我 Tab（与经典首页一致复用）

    private func accountContent() -> some View {
        VStack(spacing: 0) {
            AccountTabView(
                dimensions: dimensions,
                moments: moments,
                onCreateMoment: {
                    momentEditorRoute = .newMoment
                }
            )
            tabBar
        }
    }

    private func meContent(profile: UserProfile) -> some View {
        VStack(spacing: 0) {
            SettingsHomeView(profile: profile)
            tabBar
        }
    }

    private var tabBar: some View {
        BottomTabBar(
            selectedTab: selectedTab,
            onSelect: { tab in
                selectedTab = tab
            }
        )
    }

    // MARK: - 数据 / 计算（复用经典首页同款）

    private var visibleAccountDimensions: [Dimension] {
        CustomDimensionAccount.visibleAccountDimensions(from: dimensions)
    }

    /// 今生 = 已度过的人生比例；今年 = 今年已过去的比例。用于 hero 卡进度条。
    private func elapsedProgress(profile: UserProfile, scope: DimensionCompute.TimeBalanceScope) -> Double {
        switch scope {
        case .lifetime:
            let age = DimensionCompute.ageYears(birthday: profile.birthday)
            let expected = Double(profile.expectedLifespanYears)
            guard expected > 0 else { return 0 }
            return min(1, max(0, age / expected))

        case .year:
            let calendar = Calendar.current
            let now = Date.now
            guard
                let yearStart = calendar.date(from: calendar.dateComponents([.year], from: now)),
                let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart)
            else { return 0 }
            let total = yearEnd.timeIntervalSince(yearStart)
            guard total > 0 else { return 0 }
            return min(1, max(0, now.timeIntervalSince(yearStart) / total))
        }
    }

    // MARK: - Widget snapshot 刷新（复用经典首页同款签名）

    private func refreshWidgetSnapshot(profile: UserProfile) {
        do {
            let settings = try Settings.fetch(in: modelContext)
            try WidgetSnapshotWriter.writeSnapshot(
                profile: profile,
                dimensions: dimensions,
                moments: moments,
                settings: settings
            )
        } catch {
            // Widget snapshot should never block the main app experience.
        }
    }

    private var widgetSnapshotQueryFingerprint: String {
        guard let profile = profiles.first else { return "no-profile" }
        let profilePart = "\(profile.updatedAt.timeIntervalSince1970)"
        let dimensionPart = dimensions
            .map { "\($0.id):\($0.status.rawValue):\($0.mode.rawValue):\($0.sortIndex):\($0.updatedAt.timeIntervalSince1970)" }
            .joined(separator: "|")
        let momentPart = moments
            .map { "\($0.id.uuidString):\($0.dimensionId):\($0.status.rawValue):\($0.updatedAt.timeIntervalSince1970)" }
            .joined(separator: "|")
        return "\(profilePart)#\(dimensionPart)#\(momentPart)"
    }
}

/// 维度块非图片区域点按 → 维度详情的导航路由（dimension.id 为 String，需 Identifiable 包装）。
private struct BigPhotoMultiDimensionRoute: Identifiable, Hashable {
    let id: String
    let scope: DimensionCompute.TimeBalanceScope
}

// MARK: - 大图·多图维度块

/// 「大图·多图」的单个维度块：顶部一行「● 维度名 + 右侧今年余额」（点进维度详情），
/// 下面是该维度最近瞬间的横向多图带（复用 DimensionMomentStrip，thumbSize≈120，可横滑）。
///
/// 手势分区（§3.3）：横滑带内每张图 = 独立 Button(onTapPhoto)；维度名标题行 = 独立
/// Button(onTapDimension)。整块不包 NavigationLink，导航由父层 @State + .navigationDestination 处理。
private struct BigPhotoMultiDimensionBlock: View {
    let dimension: Dimension
    let profile: UserProfile
    let dimensionsByID: [String: Dimension]
    /// 传 normalMoments（外部已过滤 status == .normal）。
    let moments: [Moment]
    let timeScope: DimensionCompute.TimeBalanceScope
    let fileStore: FileStore
    /// 横滑带内单张瞬间点按：父层导航到瞬间详情。
    var onTapPhoto: (Moment) -> Void
    /// 维度名标题行点按：父层导航进维度详情。
    var onTapDimension: () -> Void

    /// 多图带缩略图尺寸：比经典卡（64）显著加大，展示 3+ 张、可横滑。
    private let stripThumbSize: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            titleRow
            DimensionMomentStrip(
                dimension: dimension,
                moments: moments,
                fileStore: fileStore,
                thumbSize: stripThumbSize,
                cornerRadius: TBRadius.md,
                onTapMoment: onTapPhoto
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - 标题行（● 维度名 + 右侧余额）

    private var titleRow: some View {
        Button {
            onTapDimension()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: TBSpace.s2) {
                Circle()
                    .fill(DimensionPalette.color(for: dimension))
                    .frame(width: 8, height: 8)
                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] }

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

                Spacer(minLength: TBSpace.s2)

                Text(balanceSummary)
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Image(systemName: "chevron.right")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk3)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 文案 / 计算（复用经典卡同款）

    /// 右侧小字余额：纪念账户不显示余额（给固定文案）；否则「今年余额 约 X 小时 / 今生余额 …」。
    private var balanceSummary: String {
        if isMemorial {
            return "记录这一段"
        }
        return "\(balanceLabel) \(Formatter.hoursCompact(consumeHours))"
    }

    private var balanceLabel: String {
        switch timeScope {
        case .year:
            return "今年余额"
        case .lifetime:
            return "今生余额"
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

    private var storedMomentCount: Int {
        DimensionCompute.storedMomentCount(for: dimension.id, moments: moments)
    }

    private var isMemorial: Bool {
        dimension.mode == .memorial
    }

    private var accessibilitySummary: String {
        let stored = "已存入 \(Formatter.momentsCount(storedMomentCount))"
        if isMemorial {
            return "\(dimension.name)，纪念账户，\(stored)"
        }
        return "\(dimension.name)，\(balanceLabel) \(Formatter.hoursCompact(consumeHours))，\(stored)"
    }
}
