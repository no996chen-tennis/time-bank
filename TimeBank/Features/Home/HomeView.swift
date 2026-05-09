// TimeBank/Features/Home/HomeView.swift

import Combine
import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [UserProfile]
    @Query private var dimensions: [Dimension]
    @Query private var moments: [Moment]

    @StateObject private var undoToastController = UndoToastController()
    @State private var selectedTab: HomeTab = .home
    @State private var momentEditorRoute: MomentEditorRoute?
    @State private var dimensionEditorRoute: DimensionEditorRoute?
    @State private var sharedMomentStore: MomentStore?
    @State private var homeEditMode: HomeDimensionEditMode = .inactive
    @State private var orderedDimensionIDs: [String] = []
    @State private var draggingDimensionID: String?
    @State private var dimensionDeleteRequest: HomeDimensionDeleteRequest?
    @State private var homeToastMessage: String?
    @State private var homeToastDismissTask: Task<Void, Never>?
    @State private var timeScope: DimensionCompute.TimeBalanceScope = .lifetime

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
            .sheet(item: $momentEditorRoute) { route in
                MomentEditorView(route: route)
            }
            .sheet(item: $dimensionEditorRoute) { route in
                NavigationStack {
                    DimensionEditorView(route: route)
                }
            }
            .alert(dimensionDeleteRequest?.title ?? "", isPresented: Binding(
                get: { dimensionDeleteRequest != nil },
                set: { if $0 == false { dimensionDeleteRequest = nil } }
            )) {
                Button("取消", role: .cancel) {
                    dimensionDeleteRequest = nil
                }

                Button("删除", role: .destructive) {
                    confirmDeleteDimension()
                }
            } message: {
                Text(dimensionDeleteRequest?.message ?? "")
            }
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: TBSpace.s2) {
                if let homeToastMessage {
                    Text(homeToastMessage)
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbSurface)
                        .padding(.horizontal, TBSpace.s4)
                        .padding(.vertical, TBSpace.s3)
                        .background(Color.tbInk.opacity(0.88))
                        .clipShape(Capsule())
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                UndoToastView()
                    .environmentObject(undoToastController)
            }
            .padding(.bottom, 96)
        }
        .environmentObject(undoToastController)
        .environment(\.sharedMomentStore, sharedMomentStore)
        .onAppear {
            if sharedMomentStore == nil {
                sharedMomentStore = MomentStore(modelContext: modelContext)
            }
        }
        .onChange(of: widgetSnapshotQueryFingerprint) { _, _ in
            guard let profile = profiles.first else { return }
            refreshWidgetSnapshot(profile: profile)
        }
    }

    private func homeContent(profile: UserProfile) -> some View {
        let visibleDimensions = visibleAccountDimensions
        let displayDimensions = displayDimensions(from: visibleDimensions)
        let isEditing = homeEditMode.isEditing
        let dimensionsByID = Dictionary(uniqueKeysWithValues: dimensions.map { ($0.id, $0) })
        let normalMoments = moments.filter { $0.status == .normal }
        let projection = DimensionCompute.projection(profile: profile, scope: timeScope)
        let totalAccount = DimensionCompute.totalAccount(
            dimensions: visibleDimensions,
            moments: normalMoments
        )

        return VStack(spacing: 0) {
            GreetingHeaderView()
                .padding(.horizontal, TBSpace.s5)
                .padding(.top, TBSpace.s4)
                .padding(.bottom, TBSpace.s2)

            TimeBalanceScopeControl(scope: $timeScope)
                .padding(.horizontal, TBSpace.s5)
                .padding(.bottom, TBSpace.s2)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: TBSpace.s3) {
                    DoubleLayerAccountCardView(
                        projection: projection,
                        totalAccount: totalAccount,
                        scope: timeScope,
                        onDepositsTap: {
                            selectedTab = .account
                        }
                    )
                    .opacity(isEditing ? 0.4 : 1)
                    .allowsHitTesting(isEditing == false)

                    dimensionSectionHeader(count: visibleDimensions.count)
                        .padding(.top, TBSpace.s1)

                    VStack(spacing: TBSpace.s2) {
                        ForEach(Array(displayDimensions.enumerated()), id: \.element.id) { index, dimension in
                            dimensionCard(
                                index: index,
                                dimension: dimension,
                                profile: profile,
                                dimensionsByID: dimensionsByID,
                                moments: normalMoments,
                                timeScope: timeScope
                            )
                        }

                        if isEditing == false {
                            Color.clear
                                .frame(height: TBSpace.s3)
                        } else {
                            Color.clear
                                .frame(height: TBSpace.s6)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    finishDimensionEditing()
                                }
                        }
                    }
                }
                .padding(.horizontal, TBSpace.s5)
                .padding(.bottom, TBSpace.s5)
            }
            .onChange(of: visibleDimensions.map(\.id)) { _, newIDs in
                reconcileOrderedDimensionIDs(visibleIDs: newIDs)
            }

            tabBar
        }
        .task(id: widgetSnapshotFingerprint(profile: profile)) {
            refreshWidgetSnapshot(profile: profile)
        }
    }

    private func meContent(profile: UserProfile) -> some View {
        VStack(spacing: 0) {
            SettingsHomeView(profile: profile)
            tabBar
        }
    }

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

    private func dimensionSectionHeader(count: Int) -> some View {
        HStack(alignment: .center, spacing: TBSpace.s3) {
            Text(homeEditMode.isEditing ? "长按拖动 · 调整顺序" : "时间账户 · \(count) 个")
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)

            Spacer()

            if homeEditMode.isEditing {
                Button {
                    finishDimensionEditing()
                } label: {
                    Label("完成", systemImage: "checkmark")
                        .font(.tbBodySm)
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(HomeHeaderActionButtonStyle(role: .primary))
                .accessibilityLabel("完成编辑时间账户")
            } else {
                Button {
                    enterDimensionEditing(haptic: false)
                } label: {
                    Label("编辑", systemImage: "pencil")
                        .font(.tbBodySm)
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(HomeHeaderActionButtonStyle(role: .secondary))
                .accessibilityLabel("编辑时间账户顺序")

                Button {
                    dimensionEditorRoute = .create
                } label: {
                    Label("新增", systemImage: "plus")
                        .font(.tbBodySm)
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(HomeHeaderActionButtonStyle(role: .accent))
                .accessibilityLabel("添加自定义时间账户")
            }
        }
    }

    @ViewBuilder
    private func dimensionCard(
        index: Int,
        dimension: Dimension,
        profile: UserProfile,
        dimensionsByID: [String: Dimension],
        moments: [Moment],
        timeScope: DimensionCompute.TimeBalanceScope
    ) -> some View {
        let card = DimensionCardView(
            dimension: dimension,
            profile: profile,
            dimensionsByID: dimensionsByID,
            moments: moments,
            timeScope: timeScope
        )

        if homeEditMode.isEditing {
            card
                .modifier(HomeDimensionJiggleEffect(
                    isActive: true,
                    phaseDelay: Double(index) * 0.04
                ))
                .overlay(alignment: .topLeading) {
                    if dimension.kind == .custom {
                        HomeDimensionDeleteBadge {
                            prepareDeleteDimension(dimension)
                        }
                        .offset(x: -8, y: -8)
                    }
                }
                .onDrag {
                    draggingDimensionID = dimension.id
                    return NSItemProvider(object: dimension.id as NSString)
                }
                .onDrop(
                    of: [UTType.text],
                    delegate: HomeDimensionDropDelegate(
                        targetID: dimension.id,
                        orderedIDs: $orderedDimensionIDs,
                        draggingID: $draggingDimensionID
                    )
                )
        } else {
            NavigationLink {
                DimensionDetailView(dimensionID: dimension.id, initialTimeScope: timeScope)
            } label: {
                card
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        enterDimensionEditing(haptic: true)
                    }
            )
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

    private var visibleAccountDimensions: [Dimension] {
        CustomDimensionAccount.visibleAccountDimensions(from: dimensions)
    }

    private func displayDimensions(from visibleDimensions: [Dimension]) -> [Dimension] {
        guard homeEditMode.isEditing, orderedDimensionIDs.isEmpty == false else {
            return visibleDimensions
        }

        let lookup = Dictionary(uniqueKeysWithValues: visibleDimensions.map { ($0.id, $0) })
        let ordered = orderedDimensionIDs.compactMap { lookup[$0] }
        let appended = visibleDimensions.filter { orderedDimensionIDs.contains($0.id) == false }
        return ordered + appended
    }

    private func enterDimensionEditing(haptic: Bool) {
        guard homeEditMode.isEditing == false else { return }
        if haptic {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        orderedDimensionIDs = visibleAccountDimensions.map(\.id)
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            homeEditMode = .editing
        }
    }

    private func finishDimensionEditing() {
        let idsToPersist = orderedDimensionIDs.isEmpty
            ? visibleAccountDimensions.map(\.id)
            : orderedDimensionIDs

        do {
            try CustomDimensionAccount.persistSortOrder(
                orderedIDs: idsToPersist,
                dimensions: dimensions,
                modelContext: modelContext
            )
        } catch {
            showHomeToast("顺序没保存上。再试一次")
        }

        draggingDimensionID = nil
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            homeEditMode = .inactive
        }
    }

    private func reconcileOrderedDimensionIDs(visibleIDs: [String]) {
        guard homeEditMode.isEditing else { return }
        let visibleSet = Set(visibleIDs)
        orderedDimensionIDs = orderedDimensionIDs.filter { visibleSet.contains($0) }
        for id in visibleIDs where orderedDimensionIDs.contains(id) == false {
            orderedDimensionIDs.append(id)
        }
    }

    private func prepareDeleteDimension(_ dimension: Dimension) {
        do {
            let count = try DimensionDemotionStore(modelContext: modelContext)
                .sourceMomentCount(for: dimension.id)
            let message = count > 0
                ? "已存入的 \(Formatter.momentsCount(count))会移到「其他」时间账户，仍然可以查看。"
                : "这个时间账户还没有存入瞬间。删除后会从主页隐藏。"
            dimensionDeleteRequest = HomeDimensionDeleteRequest(
                dimensionID: dimension.id,
                name: dimension.name,
                message: message
            )
        } catch {
            showHomeToast("没删上。再试一次")
        }
    }

    private func confirmDeleteDimension() {
        guard let request = dimensionDeleteRequest else { return }
        do {
            let movedCount = try DimensionDemotionStore(modelContext: modelContext)
                .demote(dimensionID: request.dimensionID)
            dimensionDeleteRequest = nil
            reconcileOrderedDimensionIDs(visibleIDs: visibleAccountDimensions.map(\.id))
            showHomeToast("已删除 · \(Formatter.momentsCount(movedCount))已转入「其他」")
        } catch {
            dimensionDeleteRequest = nil
            showHomeToast("没删上。再试一次")
        }
    }

    private func showHomeToast(_ message: String) {
        homeToastDismissTask?.cancel()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            homeToastMessage = message
        }
        homeToastDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                homeToastMessage = nil
            }
        }
    }

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

    private func widgetSnapshotFingerprint(profile: UserProfile) -> String {
        let profilePart = "\(profile.updatedAt.timeIntervalSince1970)"
        let dimensionPart = dimensions
            .map { "\($0.id):\($0.status.rawValue):\($0.mode.rawValue):\($0.sortIndex):\($0.updatedAt.timeIntervalSince1970)" }
            .joined(separator: "|")
        let momentPart = moments
            .map { "\($0.id.uuidString):\($0.dimensionId):\($0.status.rawValue):\($0.updatedAt.timeIntervalSince1970)" }
            .joined(separator: "|")
        return "\(profilePart)#\(dimensionPart)#\(momentPart)"
    }

    private var widgetSnapshotQueryFingerprint: String {
        guard let profile = profiles.first else { return "no-profile" }
        return widgetSnapshotFingerprint(profile: profile)
    }
}

private struct HomeDimensionDeleteRequest {
    let dimensionID: String
    let name: String
    let message: String

    var title: String { "删除「\(name)」？" }
}

@MainActor
final class UndoToastController: ObservableObject {
    @Published private(set) var message: String?
    @Published private(set) var actionTitle: String?

    private var action: (() -> Void)?
    private var dismissTask: Task<Void, Never>?

    func show(
        message: String,
        actionTitle: String = "撤销",
        duration: TimeInterval = 5.0,
        action: @escaping () -> Void
    ) {
        dismissTask?.cancel()
        self.message = message
        self.actionTitle = actionTitle
        self.action = action

        dismissTask = Task { @MainActor in
            let nanoseconds = UInt64(max(0, duration) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            clear()
        }
    }

    func performAction() {
        action?()
        clear()
    }

    func clear() {
        dismissTask?.cancel()
        dismissTask = nil
        message = nil
        actionTitle = nil
        action = nil
    }
}

private struct UndoToastView: View {
    @EnvironmentObject private var controller: UndoToastController

    var body: some View {
        if let message = controller.message,
           let actionTitle = controller.actionTitle {
            HStack(spacing: TBSpace.s2) {
                Text(message)
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbSurface)

                Text("·")
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbSurface.opacity(0.72))

                Button(actionTitle) {
                    controller.performAction()
                }
                .font(.tbBodySm)
                .foregroundStyle(Color.tbSurface)
            }
            .padding(.horizontal, TBSpace.s4)
            .padding(.vertical, TBSpace.s3)
            .background(Color.tbInk.opacity(0.92))
            .clipShape(Capsule())
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
}

struct TimeBalanceScopeControl: View {
    @Binding var scope: DimensionCompute.TimeBalanceScope

    var body: some View {
        Picker("时间窗口", selection: $scope) {
            ForEach(DimensionCompute.TimeBalanceScope.allCases) { option in
                Text(option.title).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .tint(Color.tbPrimary)
        .accessibilityLabel("时间窗口")
    }
}

private struct SharedMomentStoreKey: EnvironmentKey {
    static let defaultValue: MomentStore? = nil
}

extension EnvironmentValues {
    var sharedMomentStore: MomentStore? {
        get { self[SharedMomentStoreKey.self] }
        set { self[SharedMomentStoreKey.self] = newValue }
    }
}
