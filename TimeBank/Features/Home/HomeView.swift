// TimeBank/Features/Home/HomeView.swift

import Combine
import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [UserProfile]
    @Query private var dimensions: [Dimension]
    @Query private var moments: [Moment]

    @StateObject private var undoToastController = UndoToastController()
    @State private var selectedTab: HomeTab = .home
    @State private var momentEditorRoute: MomentEditorRoute?
    @State private var sharedMomentStore: MomentStore?

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
        }
        .overlay(alignment: .bottom) {
            UndoToastView()
                .environmentObject(undoToastController)
                .padding(.bottom, 96)
        }
        .environmentObject(undoToastController)
        .environment(\.sharedMomentStore, sharedMomentStore)
        .onAppear {
            if sharedMomentStore == nil {
                sharedMomentStore = MomentStore(modelContext: modelContext)
            }
        }
    }

    private func homeContent(profile: UserProfile) -> some View {
        let visibleDimensions = visibleAccountDimensions
        let dimensionsByID = Dictionary(uniqueKeysWithValues: dimensions.map { ($0.id, $0) })
        let normalMoments = moments.filter { $0.status == .normal }
        let projection = DimensionCompute.projection(profile: profile)
        let totalAccount = DimensionCompute.totalAccount(
            dimensions: visibleDimensions,
            moments: normalMoments
        )

        return VStack(spacing: 0) {
            GreetingHeaderView()
                .padding(.horizontal, TBSpace.s5)
                .padding(.top, TBSpace.s4)
                .padding(.bottom, TBSpace.s3)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: TBSpace.s4) {
                    DoubleLayerAccountCardView(
                        projection: projection,
                        totalAccount: totalAccount
                    )

                    Text("时间账户 · \(visibleDimensions.count) 个")
                        .font(.tbHeadS)
                        .foregroundStyle(Color.tbInk)
                        .padding(.top, TBSpace.s2)

                    VStack(spacing: TBSpace.s3) {
                        ForEach(visibleDimensions, id: \.id) { dimension in
                            NavigationLink {
                                DimensionDetailView(dimensionID: dimension.id)
                            } label: {
                                DimensionCardView(
                                    dimension: dimension,
                                    profile: profile,
                                    dimensionsByID: dimensionsByID,
                                    moments: normalMoments
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, TBSpace.s5)
                .padding(.bottom, TBSpace.s7)
            }

            tabBar
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

    private var tabBar: some View {
        BottomTabBar(
            selectedTab: selectedTab,
            onSelect: { tab in
                selectedTab = tab
            },
            onCreateMoment: {
                momentEditorRoute = .newMoment
            }
        )
    }

    private var visibleAccountDimensions: [Dimension] {
        dimensions
            .filter { dimension in
                dimension.status == .visible
                    && (dimension.kind == .builtin || dimension.kind == .custom)
                    && dimension.name.hasPrefix("__") == false
            }
            .sorted { lhs, rhs in
                if lhs.sortIndex == rhs.sortIndex {
                    return lhs.name < rhs.name
                }
                return lhs.sortIndex < rhs.sortIndex
            }
    }
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

private struct SharedMomentStoreKey: EnvironmentKey {
    static let defaultValue: MomentStore? = nil
}

extension EnvironmentValues {
    var sharedMomentStore: MomentStore? {
        get { self[SharedMomentStoreKey.self] }
        set { self[SharedMomentStoreKey.self] = newValue }
    }
}
