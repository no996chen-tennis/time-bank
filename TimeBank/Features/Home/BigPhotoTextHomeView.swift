// TimeBank/Features/Home/BigPhotoTextHomeView.swift

import SwiftData
import SwiftUI

/// 首页变体「大图·带文字」：与 BigPhotoHomeView 平行的独立 View，由 RootView 按
/// @AppStorage(HomeLayoutKind.storageKey) 分发（case .bigPhotoText）。
///
/// 与「大图·单图」共享同一套结构母版（Greeting + 今年/今生选项卡 + hero 双层账户卡 +
/// snapshot 刷新），区别只在维度区：每张卡是一张大封面（该维度最近带图瞬间的首图），
/// 底部渐变遮罩上叠加**用户记录的那句话** moment.title（杂志/明信片风，白字），
/// 卡上再放「● 维度名 + 今年余额」小字。核心是把用户写下的标题露出来。
struct BigPhotoTextHomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [UserProfile]
    @Query private var dimensions: [Dimension]
    @Query private var moments: [Moment]

    @State private var selectedTab: HomeTab = .home
    @State private var timeScope: DimensionCompute.TimeBalanceScope = .year
    @State private var fileStore = FileStore()
    @State private var momentRoute: Moment?
    @State private var dimensionRoute: BigPhotoTextDimensionRoute?
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

    // MARK: - 主页 Tab（大图·带文字）

    private func homeContent(profile: UserProfile) -> some View {
        VStack(spacing: 0) {
            GreetingHeaderView()
                .padding(.horizontal, TBSpace.s5)
                .padding(.top, TBSpace.s4)
                .padding(.bottom, TBSpace.s2)

            // 「今天还剩」已并进 hero 大卡（DoubleLayerAccountCardView），此处不再单独展示，避免重复。

            TimeBalanceScopeControl(scope: $timeScope)
                .padding(.horizontal, TBSpace.s5)
                .padding(.bottom, TBSpace.s2)

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
                        BigPhotoTextDimensionCard(
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
                                dimensionRoute = BigPhotoTextDimensionRoute(id: dimension.id, scope: scope)
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
private struct BigPhotoTextDimensionRoute: Identifiable, Hashable {
    let id: String
    let scope: DimensionCompute.TimeBalanceScope
}

// MARK: - 大图·带文字 维度卡

/// 「大图·带文字」的单张维度卡：一张大封面图（该维度最新带图瞬间的首图），
/// 底部黑色渐变遮罩上叠加**用户记录的标题** moment.title（白字、明信片风、最多两行），
/// 左上角另有「● 维度名 + 今年余额」小字。核心是把用户写下的那句话露出来。
///
/// 降级：
/// - 瞬间无 title：只显示图 + 维度名/余额，不叠空文字。
/// - 维度无带图瞬间：DimensionPalette.soft 纯色块 + 维度名 + 「还没有照片，去存一张」。
///
/// 手势分区（§3.3）：点封面 → onTapPhoto → 瞬间详情；点维度名/余额小字 → onTapDimension → 维度详情。
/// 整卡不包 NavigationLink，导航由父层 @State + .navigationDestination 处理。
private struct BigPhotoTextDimensionCard: View {
    let dimension: Dimension
    let profile: UserProfile
    let dimensionsByID: [String: Dimension]
    /// 传 normalMoments（外部已过滤 status == .normal）。
    let moments: [Moment]
    let timeScope: DimensionCompute.TimeBalanceScope
    let fileStore: FileStore
    /// 图片区点按：父层导航到瞬间详情。
    var onTapPhoto: (Moment) -> Void
    /// 维度名/余额区点按：父层导航进维度详情。
    var onTapDimension: () -> Void

    @Environment(\.displayScale) private var displayScale

    private let heroHeight: CGFloat = 200

    var body: some View {
        Group {
            if let cover = coverEntry {
                photoCard(cover: cover)
            } else {
                emptyCard
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.xl, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - 有封面：图 + 底部渐变 + 标题叠加

    private func photoCard(cover: CoverEntry) -> some View {
        AsyncThumbnailImageView(source: source(for: cover.media)) {
            placeholderFill
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight)
        .clipped()
        .overlay {
            // 底部黑色渐变遮罩：保证白字标题可读。
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.62)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .overlay(alignment: .bottomLeading) {
            captionOverlay(title: cover.moment.title)
        }
        .overlay(alignment: .topTrailing) {
            if cover.media.mediaKind == .video {
                videoBadge
            }
        }
        .contentShape(Rectangle())
        // 整张封面可点：进对应瞬间详情。
        .onTapGesture {
            onTapPhoto(cover.moment)
        }
    }

    /// 底部叠加：用户标题（大字、明信片风）+「● 维度名 · 今年余额」小字。
    /// 无 title 时只显示维度名/余额小字，不留空行。
    private func captionOverlay(title: String?) -> some View {
        VStack(alignment: .leading, spacing: TBSpace.s2) {
            if let title = title?.trimmingCharacters(in: .whitespacesAndNewlines),
               !title.isEmpty {
                Text(title)
                    .font(.tbHeadM)
                    .foregroundStyle(Color.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.85)
                    .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 1)
            }

            dimensionMetaRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, TBSpace.s4)
        .padding(.vertical, TBSpace.s3)
        .contentShape(Rectangle())
        // 小字区（维度名/余额）单独点按 → 维度详情，与封面点按分区。
        .onTapGesture {
            onTapDimension()
        }
    }

    /// 「● 维度名 · 今年余额」小字行（白字，压在渐变上）。
    private var dimensionMetaRow: some View {
        HStack(spacing: TBSpace.s2) {
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 7, height: 7)

                Text(dimension.name)
                    .font(.tbLabel)
                    .foregroundStyle(Color.white)
                    .lineLimit(1)

                if isMemorial {
                    Text("纪念")
                        .font(.tbLabel)
                        .foregroundStyle(Color.white.opacity(0.92))
                        .padding(.horizontal, TBSpace.s2)
                        .padding(.vertical, 1)
                        .background(Color.white.opacity(0.20))
                        .clipShape(Capsule())
                }
            }

            Text("·")
                .font(.tbLabel)
                .foregroundStyle(Color.white.opacity(0.7))

            Text(balanceSummary)
                .font(.tbLabel)
                .foregroundStyle(Color.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
    }

    private var videoBadge: some View {
        Image(systemName: "play.fill")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(6)
            .background(Color.black.opacity(0.45))
            .clipShape(Circle())
            .padding(TBSpace.s3)
    }

    // MARK: - 无封面：纯色块 + 邀请文案

    private var emptyCard: some View {
        ZStack {
            placeholderFill
            VStack(spacing: TBSpace.s2) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(DimensionPalette.color(for: dimension))
                        .frame(width: 7, height: 7)
                    Text(dimension.name)
                        .font(.tbHeadS)
                        .foregroundStyle(Color.tbInk)
                        .lineLimit(1)
                }
                Text("还没有照片，去存一张")
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk3)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            onTapDimension()
        }
    }

    private var placeholderFill: some View {
        DimensionPalette.soft(for: dimension)
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
        let targetPixels = max(600, Int((heroHeight * 2 * displayScale).rounded()))
        if media.mediaKind == .video {
            return .videoFile(relativePath: media.relativePath, fileStore: fileStore, maxPixelSize: targetPixels)
        }
        return .fileDownsampled(relativePath: media.relativePath, fileStore: fileStore, maxPixelSize: targetPixels)
    }

    // MARK: - 文案 / 计算（复用经典卡同款）

    /// 卡上小字的余额摘要，纪念账户走「记录这一段。」。
    private var balanceSummary: String {
        if isMemorial {
            return "记录这一段。"
        }
        return "\(consumeLabel) \(Formatter.hoursCompact(consumeHours))"
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

    private var storedMomentCount: Int {
        DimensionCompute.storedMomentCount(for: dimension.id, moments: moments)
    }

    private var isMemorial: Bool {
        dimension.mode == .memorial
    }

    private var accessibilitySummary: String {
        let titlePart: String
        if let title = coverEntry?.moment.title?.trimmingCharacters(in: .whitespacesAndNewlines),
           !title.isEmpty {
            titlePart = "，\(title)"
        } else {
            titlePart = ""
        }
        if isMemorial {
            return "\(dimension.name)，纪念账户\(titlePart)"
        }
        return "\(dimension.name)，\(consumeLabel) \(Formatter.hoursCompact(consumeHours))\(titlePart)"
    }
}
