// TimeBank/App/RootView.swift

import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(TimeBankThemeKind.storageKey) private var selectedThemeRawValue = TimeBankThemeKind.magazineApartamento.rawValue
    @AppStorage(TimeBankIconSetKind.storageKey) private var selectedIconSetRawValue = TimeBankIconSetKind.nativeFilled.rawValue
    @Environment(\.scenePhase) private var scenePhase
    @State private var launchState: LaunchState = .bootstrapping
    @State private var showQuickDeposit = false
    @State private var isPollingDepositFlag = false

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
            PostcardCenter.shared.register()
            await bootstrapIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, case .readyForHome = launchState else { return }
            consumeQuickDepositOpenFlag()
            refreshPostcardNotifications()
        }
        .onChange(of: selectedThemeRawValue) { _, _ in
            // widget 进程读不到 UserDefaults 的主题，切主题后重写快照让 widget 跟随换肤。
            try? WidgetSnapshotWriter.writeSnapshot(modelContext: modelContext)
        }
        .sheet(isPresented: $showQuickDeposit) {
            MomentEditorView(route: .newMoment)
        }
    }

    /// 从 widget「存入此刻」打开时，弹出新存入编辑器（用户自己选账户、写内容）。
    /// widget 的 AppIntent.perform() 可能在 App 激活之后才写入标志，所以激活后轮询 ~2 秒兜住时序竞态。
    @MainActor
    private func consumeQuickDepositOpenFlag() {
        guard isPollingDepositFlag == false else { return }
        isPollingDepositFlag = true
        Task { @MainActor in
            defer { isPollingDepositFlag = false }
            for _ in 0..<12 {
                if showQuickDeposit { return }
                if QuickDepositOpenFlag.consume() {
                    showQuickDeposit = true
                    return
                }
                try? await Task.sleep(nanoseconds: 180_000_000)
            }
        }
    }

    /// 扫描"冲洗好"的瞬间，按红线排明信片本地通知。
    @MainActor
    private func refreshPostcardNotifications() {
        let moments = (try? modelContext.fetch(FetchDescriptor<Moment>())) ?? []
        let todayDeposited = moments.contains {
            $0.status == .normal && Calendar.current.isDateInToday($0.createdAt)
        }
        PostcardNotificationScheduler.refresh(moments: moments, todayDeposited: todayDeposited)
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
                refreshPostcardNotifications()
            }
            launchState = profile == nil ? .needsOnboarding : .readyForHome
            // 冷启动时 scenePhase 的 .active 早于 readyForHome，那次 onChange 会被 guard 挡掉；
            // 这里在 bootstrap 落定后补消费一次 widget 的"打开存入页"标志。
            if case .readyForHome = launchState {
                consumeQuickDepositOpenFlag()
            }
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
