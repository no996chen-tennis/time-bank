// TimeBank/Features/DimensionDetail/DimensionDetailView.swift

import SwiftData
import SwiftUI

struct DimensionDetailView: View {
    let dimensionID: String

    @Query private var profiles: [UserProfile]
    @Query private var dimensions: [Dimension]
    @Query private var moments: [Moment]

    private let fileStore = FileStore()

    @State private var momentEditorRoute: MomentEditorRoute?

    var body: some View {
        Group {
            if let profile = profiles.first,
               let dimension = dimensions.first(where: { $0.id == dimensionID }) {
                detailContent(
                    dimension: dimension,
                    profile: profile
                )
            } else {
                ProgressView()
                    .tint(Color.tbPrimary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tbBg)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let dimension = dimensions.first(where: { $0.id == dimensionID }),
               dimension.kind == .builtin || dimension.kind == .custom {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        momentEditorRoute = .dimension(dimension)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(DimensionDetailCopy.depositAccessibilityLabel)
                }
            }
        }
        .sheet(item: $momentEditorRoute) { route in
            MomentEditorView(route: route)
        }
    }

    private func detailContent(
        dimension: Dimension,
        profile: UserProfile
    ) -> some View {
        let dimensionsByID = Dictionary(uniqueKeysWithValues: dimensions.map { ($0.id, $0) })
        let normalMoments = moments.filter { $0.status == .normal }

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: TBSpace.s5) {
                DimensionDetailHeaderView(
                    dimension: dimension,
                    profile: profile,
                    dimensionsByID: dimensionsByID
                )

                NavigationLink {
                    DimensionParameterEditorView(dimensionID: dimension.id)
                } label: {
                    CalculationSummaryCard(
                        dimension: dimension,
                        profile: profile,
                        dimensionsByID: dimensionsByID
                    )
                }
                .buttonStyle(.plain)

                MomentTimelineView(
                    dimension: dimension,
                    moments: normalMoments,
                    fileStore: fileStore
                )
            }
            .padding(.horizontal, TBSpace.s5)
            .padding(.top, TBSpace.s4)
            .padding(.bottom, TBSpace.s8)
        }
    }

    private var navigationTitle: String {
        dimensions.first(where: { $0.id == dimensionID })?.name ?? ""
    }
}
