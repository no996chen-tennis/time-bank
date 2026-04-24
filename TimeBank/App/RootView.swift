// TimeBank/App/RootView.swift

import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var launchState: LaunchState = .bootstrapping

    var body: some View {
        ZStack {
            routedContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tbBg)
        .task {
            await bootstrapIfNeeded()
        }
    }

    @ViewBuilder
    private var routedContent: some View {
        switch launchState {
        case .bootstrapping:
            ProgressView()
                .tint(Color.tbPrimary)

        case .needsOnboarding:
            OnboardingFlowView(onFinish: {
                Task { @MainActor in
                    launchState = .bootstrapping
                    await bootstrapIfNeeded()
                }
            })

        case .readyForHome:
            Text("TODO §3.2D")
                .foregroundStyle(Color.tbInk)

        case .failed(let message):
            Text(message)
                .font(.tbBodySm)
                .foregroundStyle(Color.tbInk2)
                .multilineTextAlignment(.center)
                .padding(TBSpace.s6)
        }
    }

    @MainActor
    private func bootstrapIfNeeded() async {
        guard case .bootstrapping = launchState else { return }

        do {
            let store = MomentStore(modelContext: modelContext)
            _ = try store.bootstrapReservedData()
            _ = try await store.commitPendingDeletes()

            let profile = try UserProfile.fetchSingleton(in: modelContext)
            launchState = profile == nil ? .needsOnboarding : .readyForHome
        } catch {
            launchState = .failed(error.localizedDescription)
        }
    }

    private enum LaunchState {
        case bootstrapping
        case needsOnboarding
        case readyForHome
        case failed(String)
    }
}
