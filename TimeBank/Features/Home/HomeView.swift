// TimeBank/Features/Home/HomeView.swift

import SwiftData
import SwiftUI

struct HomeView: View {
    @Query private var profiles: [UserProfile]
    @Query private var dimensions: [Dimension]
    @Query private var moments: [Moment]

    @State private var selectedTab: HomeTab = .home
    @State private var toastMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first {
                    switch selectedTab {
                    case .home, .account:
                        homeContent(profile: profile)
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
            .overlay(alignment: .bottom) {
                if let toastMessage {
                    Text(toastMessage)
                        .font(.tbBodySm)
                        .foregroundStyle(Color.tbSurface)
                        .padding(.horizontal, TBSpace.s4)
                        .padding(.vertical, TBSpace.s3)
                        .background(Color.tbInk.opacity(0.9))
                        .clipShape(Capsule())
                        .padding(.bottom, 96)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
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

    private var tabBar: some View {
        BottomTabBar(
            selectedTab: selectedTab,
            onSelect: { tab in
                if tab == .account {
                    selectedTab = .home
                    showToast("账户 Tab 还在搭建中")
                } else {
                    selectedTab = tab
                }
            },
            onCreateMoment: {
                showToast("存入功能马上就来")
            }
        )
    }

    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            toastMessage = message
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            withAnimation(.easeOut(duration: 0.2)) {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
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
