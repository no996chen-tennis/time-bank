// TimeBank/Features/SettingsUI/DimensionManager/DimensionManagerView.swift

import SwiftData
import SwiftUI

struct DimensionManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var dimensions: [Dimension]

    @State private var editorRoute: DimensionEditorRoute?
    @State private var deleteRequest: DimensionDeletionRequest?
    @State private var toastMessage: String?
    @State private var toastDismissTask: Task<Void, Never>?

    private var managerDimensions: [Dimension] {
        CustomDimensionAccount.managerDimensions(from: dimensions)
    }

    private var customCount: Int {
        CustomDimensionAccount.customCount(in: dimensions)
    }

    var body: some View {
        List {
            Section {
                ForEach(managerDimensions, id: \.id) { dimension in
                    managerRow(for: dimension)
                        .listRowInsets(EdgeInsets(
                            top: TBSpace.s1,
                            leading: TBSpace.s5,
                            bottom: TBSpace.s1,
                            trailing: TBSpace.s5
                        ))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if dimension.kind == .custom {
                                Button(role: .destructive) {
                                    prepareDelete(dimension)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                }
            } header: {
                managerHeader
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.tbBg)
        .navigationTitle("时间账户管理")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            addButton
        }
        .sheet(item: $editorRoute) { route in
            NavigationStack {
                DimensionEditorView(route: route)
            }
        }
        .alert(deleteRequest?.title ?? "", isPresented: Binding(
            get: { deleteRequest != nil },
            set: { if $0 == false { deleteRequest = nil } }
        )) {
            Button("取消", role: .cancel) {
                deleteRequest = nil
            }

            Button("删除", role: .destructive) {
                confirmDelete()
            }
        } message: {
            Text(deleteRequest?.message ?? "")
        }
        .overlay(alignment: .bottom) {
            if let toastMessage {
                Text(toastMessage)
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbSurface)
                    .padding(.horizontal, TBSpace.s4)
                    .padding(.vertical, TBSpace.s3)
                    .background(Color.tbInk.opacity(0.88))
                    .clipShape(Capsule())
                    .padding(.bottom, 76)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var managerHeader: some View {
        VStack(alignment: .leading, spacing: TBSpace.s2) {
            Text("内置账户可以调整时间公式；自定义账户可以改名、换图标、换颜色和删除。")
                .font(.tbBodySm)
                .foregroundStyle(Color.tbInk2)
                .textCase(nil)
                .lineSpacing(TBSpace.s1)

            Text("自定义 \(customCount)/\(CustomDimensionAccount.maxCustomCount)")
                .font(.tbLabel)
                .foregroundStyle(Color.tbInk3)
                .textCase(nil)
        }
        .padding(.top, TBSpace.s3)
        .padding(.horizontal, TBSpace.s5)
        .padding(.bottom, TBSpace.s3)
        .textCase(nil)
    }

    @ViewBuilder
    private func managerRow(for dimension: Dimension) -> some View {
        if dimension.kind == .custom {
            Button {
                editorRoute = .edit(dimension.id)
            } label: {
                DimensionManagerRow(
                    dimension: dimension,
                    subtitle: customSubtitle(for: dimension),
                    badge: "自定义"
                )
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                DimensionParameterEditorView(dimensionID: dimension.id)
            } label: {
                DimensionManagerRow(
                    dimension: dimension,
                    subtitle: dimension.status == .visible ? "内置 · 可调整公式" : "内置 · 未显示",
                    badge: "内置"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var addButton: some View {
        VStack(spacing: TBSpace.s2) {
            Button {
                editorRoute = .create
            } label: {
                Label(
                    customCount >= CustomDimensionAccount.maxCustomCount ? "已达上限 10 个" : "添加自定义时间账户",
                    systemImage: "plus"
                )
                .font(.tbBody)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(TBPrimaryActionButtonStyle(fillsWidth: true))
            .disabled(customCount >= CustomDimensionAccount.maxCustomCount)
        }
        .padding(.horizontal, TBSpace.s5)
        .padding(.top, TBSpace.s3)
        .padding(.bottom, TBSpace.s4)
        .background(Color.tbBg)
    }

    private func customSubtitle(for dimension: Dimension) -> String {
        let params = dimension.decodeParams(CustomDimensionParams.self, default: CustomDimensionParams())
        return "自定义 · \(CustomDimensionAccount.formulaSummary(params))"
    }

    private func prepareDelete(_ dimension: Dimension) {
        do {
            let count = try DimensionDemotionStore(modelContext: modelContext)
                .sourceMomentCount(for: dimension.id)
            let message = count > 0
                ? "已存入的 \(Formatter.momentsCount(count))会移到「其他」时间账户，仍然可以查看。"
                : "这个时间账户还没有存入瞬间。删除后会从主页隐藏。"
            deleteRequest = DimensionDeletionRequest(
                dimensionID: dimension.id,
                name: dimension.name,
                movedMomentCount: count,
                message: message
            )
        } catch {
            showToast("没删上。再试一次")
        }
    }

    private func confirmDelete() {
        guard let request = deleteRequest else { return }
        do {
            let movedCount = try DimensionDemotionStore(modelContext: modelContext)
                .demote(dimensionID: request.dimensionID)
            deleteRequest = nil
            showToast("已删除 · \(Formatter.momentsCount(movedCount))已转入「其他」")
        } catch {
            deleteRequest = nil
            showToast("没删上。再试一次")
        }
    }

    private func showToast(_ message: String) {
        toastDismissTask?.cancel()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            toastMessage = message
        }
        toastDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                toastMessage = nil
            }
        }
    }
}

struct DimensionEditorView: View {
    let route: DimensionEditorRoute

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [UserProfile]
    @Query private var dimensions: [Dimension]

    @State private var draft = DimensionEditorDraft()
    @State private var snapshot = DimensionEditorDraft()
    @State private var loaded = false
    @State private var showDiscardAlert = false
    @State private var showSaveFailureAlert = false
    @State private var showLimitAlert = false

    private var profile: UserProfile? { profiles.first }

    private var editingDimension: Dimension? {
        guard case .edit(let dimensionID) = route else { return nil }
        return dimensions.first { $0.id == dimensionID }
    }

    private var isEditing: Bool {
        if case .edit = route { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            previewSection

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: TBSpace.s5) {
                    identitySection
                    formulaSection
                }
                .padding(.horizontal, TBSpace.s5)
                .padding(.top, TBSpace.s4)
                .padding(.bottom, TBSpace.s8)
            }
        }
        .background(Color.tbBg)
        .navigationTitle(isEditing ? "编辑时间账户" : "新建时间账户")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    requestDismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    save()
                }
                .disabled(draft.canSave == false)
            }
        }
        .interactiveDismissDisabled(draft != snapshot)
        .onAppear(perform: loadIfNeeded)
        .alert("还没保存。先这样吗？", isPresented: $showDiscardAlert) {
            Button("继续编辑", role: .cancel) {}
            Button("不保存", role: .destructive) { dismiss() }
        } message: {
            Text("你改的内容会丢。")
        }
        .alert("最多 10 个自定义时间账户", isPresented: $showLimitAlert) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("可以先删除一个不需要的自定义账户。")
        }
        .alert("没保存上。再试一次？", isPresented: $showSaveFailureAlert) {
            Button("取消", role: .cancel) {}
            Button("重试") { save() }
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            Text("预览")
                .font(.tbLabel)
                .foregroundStyle(Color.tbInk3)

            HStack(spacing: TBSpace.s3) {
                ZStack {
                    Circle()
                        .fill(DimensionPalette.soft(forColorKey: draft.colorKey))

                    Image(systemName: draft.iconKey)
                        .font(.tbHeadS)
                        .foregroundStyle(DimensionPalette.color(forColorKey: draft.colorKey))
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: TBSpace.s1) {
                    Text(draft.trimmedName.isEmpty ? "未命名时间账户" : draft.trimmedName)
                        .font(.tbHeadS)
                        .foregroundStyle(Color.tbInk)
                        .lineLimit(1)

                    Text(CustomDimensionAccount.formulaSummary(draft.params))
                        .font(.tbBodySm)
                        .foregroundStyle(Color.tbInk2)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: TBSpace.s1) {
                    Text(previewPrimaryText)
                        .font(.tbHeadS)
                        .foregroundStyle(Color.tbInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(profile == nil ? "保存后看效果" : "约还能")
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbInk3)
                }
            }
            .padding(TBSpace.s4)
            .frame(maxWidth: .infinity)
            .tbThemedSurface(.row)
        }
        .padding(.horizontal, TBSpace.s5)
        .padding(.top, TBSpace.s4)
        .padding(.bottom, TBSpace.s3)
        .background(Color.tbBg)
    }

    private var previewPrimaryText: String {
        guard let profile else { return "0 小时" }
        return Formatter.hoursCompact(
            CustomDimensionAccount.previewHours(params: draft.params, profile: profile)
        )
    }

    private var identitySection: some View {
        editorCard {
            VStack(alignment: .leading, spacing: TBSpace.s4) {
                labeledTextField(
                    title: "名称",
                    placeholder: "例如 读书",
                    text: $draft.name
                )
                .onChange(of: draft.name) { _, _ in
                    draft.clampNameLength()
                }

                Divider()
                    .overlay(Color.tbHair)

                VStack(alignment: .leading, spacing: TBSpace.s3) {
                    Text("图标")
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbInk3)

                    IconPickerView(selection: $draft.iconKey, tintKey: draft.colorKey)
                }

                Divider()
                    .overlay(Color.tbHair)

                VStack(alignment: .leading, spacing: TBSpace.s3) {
                    Text("颜色")
                        .font(.tbLabel)
                        .foregroundStyle(Color.tbInk3)

                    ColorPickerStrip(selection: $draft.colorKey)
                }
            }
        }
    }

    private var formulaSection: some View {
        editorCard {
            VStack(alignment: .leading, spacing: TBSpace.s4) {
                Text("计算方式")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk3)

                Picker("计算方式", selection: $draft.formula) {
                    Text("每周").tag(CustomFormula.weeklyHours)
                    Text("每天").tag(CustomFormula.dailyHours)
                    Text("每年").tag(CustomFormula.occurrenceBased)
                }
                .pickerStyle(.segmented)
                .tint(Color.tbPrimary)

                switch draft.formula {
                case .weeklyHours:
                    sliderRow(title: "每周时长", valueText: Formatter.hoursReadable(draft.weeklyHours)) {
                        Slider(value: $draft.weeklyHours, in: 0...80, step: 0.5)
                            .tint(Color.tbPrimary)
                    }

                case .dailyHours:
                    sliderRow(title: "每天时长", valueText: Formatter.hoursReadable(draft.dailyHours)) {
                        Slider(value: $draft.dailyHours, in: 0...16, step: 0.5)
                            .tint(Color.tbPrimary)
                    }

                case .occurrenceBased:
                    Stepper(value: $draft.annualOccurrences, in: 1...365) {
                        stepperLabel(title: "每年次数", value: "\(draft.annualOccurrences) 次")
                    }

                    Stepper(value: $draft.hoursPerOccurrence, in: 0.5...72, step: 0.5) {
                        stepperLabel(title: "每次时长", value: Formatter.hoursReadable(draft.hoursPerOccurrence))
                    }
                }
            }
        }
    }

    private func editorCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: TBSpace.s4) {
            content()
        }
        .padding(TBSpace.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tbThemedSurface()
    }

    private func labeledTextField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: TBSpace.s2) {
            HStack {
                Text(title)
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk3)

                Spacer()

                Text("\(draft.trimmedName.count)/\(CustomDimensionAccount.maxNameCount)")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk3)
            }

            TextField(placeholder, text: text)
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)
                .textInputAutocapitalization(.never)
        }
    }

    private func sliderRow<Content: View>(
        title: String,
        valueText: String,
        @ViewBuilder control: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: TBSpace.s2) {
            stepperLabel(title: title, value: valueText)
            control()
        }
    }

    private func stepperLabel(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.tbBody)
                .foregroundStyle(Color.tbInk)

            Spacer()

            Text(value)
                .font(.tbBodySm)
                .foregroundStyle(Color.tbPrimary)
        }
    }

    private func loadIfNeeded() {
        guard loaded == false else { return }
        loaded = true

        if let editingDimension {
            draft = DimensionEditorDraft(dimension: editingDimension)
        }
        snapshot = draft
    }

    private func requestDismiss() {
        if draft != snapshot {
            showDiscardAlert = true
        } else {
            dismiss()
        }
    }

    private func save() {
        guard draft.canSave else { return }

        do {
            switch route {
            case .create:
                guard CustomDimensionAccount.canCreateCustomDimension(in: dimensions) else {
                    showLimitAlert = true
                    return
                }

                let dimension = Dimension(
                    id: UUID().uuidString,
                    name: draft.trimmedName,
                    kind: .custom,
                    status: .visible,
                    mode: .normal,
                    iconKey: draft.iconKey,
                    colorKey: draft.colorKey,
                    sortIndex: CustomDimensionAccount.nextSortIndex(in: dimensions),
                    params: Dimension.encodedParams(draft.params)
                )
                modelContext.insert(dimension)

            case .edit:
                guard let editingDimension else { return }
                editingDimension.name = draft.trimmedName
                editingDimension.iconKey = draft.iconKey
                editingDimension.colorKey = draft.colorKey
                editingDimension.setParams(draft.params)
                editingDimension.updatedAt = .now
            }

            try modelContext.save()
            snapshot = draft
            dismiss()
        } catch {
            showSaveFailureAlert = true
        }
    }
}

private struct DimensionManagerRow: View {
    let dimension: Dimension
    let subtitle: String
    let badge: String

    var body: some View {
        HStack(spacing: TBSpace.s3) {
            ZStack {
                Circle()
                    .fill(DimensionPalette.soft(for: dimension))

                Image(systemName: DimensionDetailCopy.iconSystemName(for: dimension))
                    .font(.tbBody)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(DimensionPalette.color(for: dimension))
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: TBSpace.s1) {
                Text(dimension.name)
                    .font(.tbBody)
                    .foregroundStyle(Color.tbInk)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer()

            Text(badge)
                .font(.tbLabel)
                .foregroundStyle(Color.tbInk3)
            .padding(.horizontal, TBSpace.s2)
            .padding(.vertical, TBSpace.s1)
            .background(Color.tbPrimary.opacity(0.10))
            .clipShape(Capsule())
        }
        .padding(TBSpace.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tbThemedSurface(.row)
    }
}

private struct IconPickerView: View {
    @Binding var selection: String
    let tintKey: String

    private var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(44), spacing: TBSpace.s2), count: 6)
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: TBSpace.s2) {
            ForEach(CustomDimensionAccount.iconOptions, id: \.self) { icon in
                Button {
                    selection = icon
                } label: {
                    Image(systemName: icon)
                        .font(.tbBody)
                        .foregroundStyle(selection == icon ? DimensionPalette.color(forColorKey: tintKey) : Color.tbInk2)
                        .frame(width: 44, height: 44)
                        .background(selection == icon ? DimensionPalette.soft(forColorKey: tintKey) : Color.tbBg2)
                        .clipShape(RoundedRectangle(cornerRadius: TBRadius.sm))
                        .overlay {
                            RoundedRectangle(cornerRadius: TBRadius.sm)
                                .stroke(
                                    selection == icon ? DimensionPalette.color(forColorKey: tintKey) : Color.clear,
                                    lineWidth: 1.5
                                )
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(iconAccessibilityLabel(for: icon))
            }
        }
    }

    private func iconAccessibilityLabel(for icon: String) -> String {
        switch icon {
        case "book.fill":
            return "书"
        case "pencil.tip":
            return "写作"
        case "graduationcap.fill":
            return "学习"
        case "paintbrush.pointed.fill":
            return "创作"
        case "music.note":
            return "音乐"
        case "camera.fill":
            return "摄影"
        case "cup.and.saucer.fill":
            return "茶与咖啡"
        case "fork.knife":
            return "吃饭"
        case "bed.double.fill":
            return "休息"
        case "airplane":
            return "旅行"
        case "figure.walk":
            return "散步"
        case "bicycle":
            return "骑行"
        case "person.2.fill":
            return "陪伴"
        case "dog.fill":
            return "宠物"
        case "star.fill":
            return "重要"
        case "heart.fill":
            return "喜欢"
        default:
            return "图标"
        }
    }
}

private struct ColorPickerStrip: View {
    @Binding var selection: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TBSpace.s3) {
                ForEach(CustomDimensionAccount.colorOptions) { preset in
                    Button {
                        selection = preset.key
                    } label: {
                        Circle()
                            .fill(preset.color)
                            .frame(width: 36, height: 36)
                            .overlay {
                                Circle()
                                    .stroke(Color.tbSurface, lineWidth: 3)
                            }
                            .overlay {
                                Circle()
                                    .stroke(selection == preset.key ? Color.tbInk : Color.clear, lineWidth: 2)
                                    .frame(width: 44, height: 44)
                            }
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(preset.name)
                }
            }
            .padding(.vertical, TBSpace.s1)
            .padding(.horizontal, TBSpace.s1)
        }
    }
}

private struct DimensionDeletionRequest: Identifiable {
    let dimensionID: String
    let name: String
    let movedMomentCount: Int
    let message: String

    var id: String { dimensionID }
    var title: String { "删除「\(name)」？" }
}
