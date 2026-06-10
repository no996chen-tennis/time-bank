// TimeBank/App/RootView.swift

import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(TimeBankThemeKind.storageKey) private var selectedThemeRawValue = TimeBankThemeKind.magazineApartamento.rawValue
    @AppStorage(TimeBankIconSetKind.storageKey) private var selectedIconSetRawValue = TimeBankIconSetKind.nativeFilled.rawValue
    @Environment(\.scenePhase) private var scenePhase
    @State private var launchState: LaunchState = .bootstrapping

    var body: some View {
        ZStack {
            routedContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tbBg)
        .tint(Color.tbPrimary)
        .accessibilityIdentifier("time-bank-root-\(selectedThemeRawValue)-\(selectedIconSetRawValue)")
        .animation(.easeInOut(duration: 0.18), value: selectedThemeRawValue)
        .animation(.easeInOut(duration: 0.18), value: selectedIconSetRawValue)
        .timeBankKeyboardDismissBehavior()
        .task {
            await bootstrapIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, case .readyForHome = launchState else { return }
            drainQuickDepositsOnForeground()
        }
    }

    /// 从 widget 一键存入返回前台时，把队列里的"此刻"落库并刷新 widget。
    @MainActor
    private func drainQuickDepositsOnForeground() {
        let store = MomentStore(modelContext: modelContext)
        let count = (try? store.drainQuickDepositQueue()) ?? 0
        if count > 0 {
            try? WidgetSnapshotWriter.writeSnapshot(modelContext: modelContext)
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
            HomeView()

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
            _ = try? store.drainQuickDepositQueue()

            let profile = try UserProfile.fetchSingleton(in: modelContext)
            if profile != nil {
                try? WidgetSnapshotWriter.writeSnapshot(modelContext: modelContext)
            }
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
