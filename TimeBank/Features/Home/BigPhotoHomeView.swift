// TimeBank/Features/Home/BigPhotoHomeView.swift

import SwiftData
import SwiftUI

/// 首页C「大图为主」首页：与经典 HomeView 平行的独立 View，由 RootView 按
/// @AppStorage(HomeLayoutKind.storageKey) 分发。
///
/// 与经典首页共享同一套计算（DimensionCompute）、同一套常驻顶部（Greeting + 今天还剩 +
/// 今年/今生选项卡）、同一套 snapshot 刷新（WidgetSnapshotWriter）；区别只在维度区：
/// 每个可见维度渲染成「一张大图卡」（封面大图 + 维度名/剩余时间小字叠加），而非经典卡的
/// 数字 + 横滑小图带。
///
/// 手势分区同 §3.3：大图卡的图片区点击 → momentRoute → MomentDetailView；卡其余区域
/// （维度名/剩余时间）点击 → dimensionRoute → DimensionDetailView。整卡不包进 NavigationLink，
/// 由父层 @State + .navigationDestination(item:) 处理导航。
struct BigPhotoHomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [UserProfile]
    @Query private var dimensions: [Dimension]
    @Query private var moments: [Moment]

    @State private var selectedTab: HomeTab = .home
    @State private var timeScope: DimensionCompute.TimeBalanceScope = .year
    @State private var fileStore = FileStore()
    @State private var momentRoute: Moment?
    @State private var dimensionRoute: BigPhotoDimensionRoute?
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

    // MARK: - 主页 Tab（大图为主）

    private func homeContent(profile: UserProfile) -> some View {
        VStack(spacing: 0) {
            GreetingHeaderView()
                .padding(.horizontal, TBSpace.s5)
                .padding(.top, TBSpace.s4)
                .padding(.bottom, TBSpace.s2)

            // 「今天还剩」已并进 hero 大卡（DoubleLayerAccountCardView），此处不再单独展示，避免重复。

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

    /// 随 scope 变化的大图首页主体（每页内部 ScrollView，高度由外层 TabView .frame(maxHeight:.infinity) 确定）。
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

                LazyVStack(spacing: TBSpace.s4) {
                    ForEach(visibleDimensions, id: \.id) { dimension in
                        BigPhotoDimensionCard(
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
                                dimensionRoute = BigPhotoDimensionRoute(id: dimension.id, scope: scope)
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

/// 维度卡非图片区域点按 → 维度详情的导航路由（dimension.id 为 String，需 Identifiable 包装）。
private struct BigPhotoDimensionRoute: Identifiable, Hashable {
    let id: String
    let scope: DimensionCompute.TimeBalanceScope
}

// MARK: - 大图维度卡

/// 「大图为主」的单张维度卡：一张大封面图（该维度最新带图瞬间的首图），
/// 维度名 + 剩余时间作小字叠加在图片底部渐变上；无图维度用维度色占位 + 邀请文案。
///
/// 手势分区（§3.3）：图片区 = 独立 Button(onTapPhoto)；维度名/剩余时间小字区 = 独立 Button(onTapDimension)。
/// 整卡不包 NavigationLink，避免手势叠加；导航由父层 @State + .navigationDestination 处理。
private struct BigPhotoDimensionCard: View {
    let dimension: Dimension
    let profile: UserProfile
    let dimensionsByID: [String: Dimension]
    /// 传 normalMoments（外部已过滤 status == .normal）。
    let moments: [Moment]
    let timeScope: DimensionCompute.TimeBalanceScope
    let fileStore: FileStore
    /// 图片区点按：父层导航到瞬间详情。
    var onTapPhoto: (Moment) -> Void
    /// 维度名/剩余时间区点按：父层导航进维度详情。
    var onTapDimension: () -> Void

    @Environment(\.displayScale) private var displayScale

    private let heroHeight: CGFloat = 300

    var body: some View {
        VStack(spacing: 0) {
            heroArea
            captionBar
        }
        .tbThemedSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - 大图区

    @ViewBuilder
    private var heroArea: some View {
        if let cover = coverEntry {
            Button {
                onTapPhoto(cover.moment)
            } label: {
                AsyncThumbnailImageView(source: source(for: cover.media)) {
                    placeholderFill
                }
                .frame(maxWidth: .infinity)
                .frame(height: heroHeight)
                .clipped()
                .overlay(alignment: .bottomLeading) {
                    photoFooterOverlay(isVideo: cover.media.mediaKind == .video)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            // 无带图瞬间：维度色占位 + 邀请式文案，点按进维度详情（去存照片）。
            Button {
                onTapDimension()
            } label: {
                ZStack {
                    placeholderFill
                    VStack(spacing: TBSpace.s2) {
                        Image(systemName: "photo")
                            .font(.tbHeadM)
                            .foregroundStyle(Color.tbInk3)
                        Text("还没有照片，去存一张")
                            .font(.tbBodySm)
                            .foregroundStyle(Color.tbInk3)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: heroHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var placeholderFill: some View {
        DimensionPalette.soft(for: dimension)
    }

    /// 图片叠加：仅保留右上角视频角标。维度名/剩余时间/已存入信息已下沉到卡下信息块，避免重复。
    private func photoFooterOverlay(isVideo: Bool) -> some View {
        Color.clear
            .overlay(alignment: .topTrailing) {
                if isVideo {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .padding(6)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                        .padding(TBSpace.s3)
                }
            }
    }

    // MARK: - 卡下信息块（维度名主标题 + 剩余时间 + 已存入）

    private var captionBar: some View {
        Button {
            onTapDimension()
        } label: {
            HStack(alignment: .center, spacing: TBSpace.s3) {
                VStack(alignment: .leading, spacing: TBSpace.s1) {
                    // 主标题：维度名（+ 纪念标签）
                    HStack(spacing: TBSpace.s2) {
                        Text(dimension.name)
                            .font(.tbHeadS)
                            .foregroundStyle(Color.tbInk)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        if isMemorial {
                            Text("纪念")
                                .font(.tbLabel)
                                .foregroundStyle(DimensionPalette.color(for: dimension))
                                .padding(.horizontal, TBSpace.s2)
                                .padding(.vertical, 2)
                                .background(DimensionPalette.soft(for: dimension))
                                .clipShape(Capsule())
                        }
                    }

                    // 副信息：剩余时间（数字放大更醒目）· 已存入 N 个瞬间
                    captionInfoLine
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk3)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, TBSpace.s4)
            .padding(.vertical, TBSpace.s3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 副信息行：非纪念 = 「还能共度 X 小时 · 已存入 N 个瞬间」，其中剩余时间数字用 .tbHeadS 放大；
    /// 纪念账户无消耗层，仅显示「已存入 N 个瞬间」。放不下自动折到两行。
    @ViewBuilder
    private var captionInfoLine: some View {
        if isMemorial {
            Text(storedSummary)
                .font(.tbBodySm)
                .foregroundStyle(
                    storedMomentCount > 0
                        ? DimensionPalette.color(for: dimension)
                        : Color.tbInk3
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        } else {
            // 用换行 baseline 对齐的 HStack 组合，剩余时间数字明显更大。
            (
                Text("\(consumeLabel) ")
                    .font(.tbBodySm)
                    .foregroundColor(.tbInk2)
                    + Text(Formatter.hoursCompact(consumeHours))
                        .font(.tbHeadS)
                        .foregroundColor(.tbInk)
                    + Text(" · \(storedSummary)")
                        .font(.tbBodySm)
                        .foregroundColor(
                            storedMomentCount > 0
                                ? DimensionPalette.color(for: dimension)
                                : Color.tbInk3
                        )
            )
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 取封面图

    private struct CoverEntry {
        let moment: Moment
        let media: MediaItem
    }

    /// 该维度下、按 happenedAt 倒序（同刻 createdAt 倒序）取第一个有首图的瞬间。
    private var coverEntry: CoverEntry? {
        let sortedMoments = moments
            .filter { $0.dimensionId == dimension.id && $0.status == .normal }
            .sorted { lhs, rhs in
                if lhs.happenedAt == rhs.happenedAt {
                    return lhs.createdAt > rhs.createdAt
                }
                return lhs.happenedAt > rhs.happenedAt
            }

        for moment in sortedMoments {
            let media = moment.mediaItems.sorted { $0.sortIndex < $1.sortIndex }
            if let first = media.first(where: { $0.mediaKind == .image || $0.thumbnailPath != nil }) {
                return CoverEntry(moment: moment, media: first)
            }
        }
        return nil
    }

    private func source(for media: MediaItem) -> ThumbnailImageSource {
        // 大图：按卡片宽度估算降采样目标（屏宽量级），视频走 .videoFile，图片走 .fileDownsampled。
        let targetPixels = max(600, Int((heroHeight * 2 * displayScale).rounded()))
        if media.mediaKind == .video {
            return .videoFile(relativePath: media.relativePath, fileStore: fileStore, maxPixelSize: targetPixels)
        }
        return .fileDownsampled(relativePath: media.relativePath, fileStore: fileStore, maxPixelSize: targetPixels)
    }

    // MARK: - 文案 / 计算（复用经典卡同款）

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

    private var isMemorial: Bool {
        dimension.mode == .memorial
    }

    private var accessibilitySummary: String {
        if isMemorial {
            return "\(dimension.name)，纪念账户，\(storedSummary)"
        }
        let subtitle = subtitleText.isEmpty ? "" : "，\(subtitleText)"
        return "\(dimension.name)，\(consumeLabel) \(Formatter.hoursCompact(consumeHours))\(subtitle)，\(storedSummary)"
    }
}
