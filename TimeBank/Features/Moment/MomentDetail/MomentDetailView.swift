// TimeBank/Features/Moment/MomentDetail/MomentDetailView.swift

import SwiftData
import SwiftUI

struct MomentDetailView: View {
    let momentID: UUID

    @Query private var moments: [Moment]

    var body: some View {
        ProgressView()
            .tint(Color.tbPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.tbBg)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
    }

    private var navigationTitle: String {
        guard let moment = moments.first(where: { $0.id == momentID }) else {
            return ""
        }
        return DimensionDetailCopy.timelineTitle(for: moment)
    }
}
