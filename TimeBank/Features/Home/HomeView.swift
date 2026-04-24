// TimeBank/Features/Home/HomeView.swift

import SwiftData
import SwiftUI

struct HomeView: View {
    @Query private var profiles: [UserProfile]
    @Query private var dimensions: [Dimension]
    @Query private var moments: [Moment]

    var body: some View {
        Group {
            if let profile = profiles.first {
                homeContent(profile: profile)
            } else {
                Text("未找到用户信息")
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbInk2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tbBg)
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
                            DimensionCardView(
                                dimension: dimension,
                                profile: profile,
                                dimensionsByID: dimensionsByID,
                                moments: normalMoments
                            )
                        }
                    }
                }
                .padding(.horizontal, TBSpace.s5)
                .padding(.bottom, TBSpace.s7)
            }

            BottomTabBar()
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
