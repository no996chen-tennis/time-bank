// TimeBank/Features/SettingsUI/ProfileEditor/ProfileEditorView.swift

import SwiftData
import SwiftUI

struct ProfileEditorView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Query private var dimensions: [Dimension]

    @State private var editorRoute: ProfileEditorRoute?
    @State private var actionTarget: RelationActionTarget?
    @State private var removalRequest: RelationRemovalRequest?
    @State private var recoveryRequest: RelationRecoveryRequest?
    @State private var toastMessage: String?

    private var currentYear: Int {
        Calendar(identifier: .gregorian).component(.year, from: .now)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: TBSpace.s5) {
                selfSection
                parentsSection
                childrenSection
                partnerSection
            }
            .padding(.horizontal, TBSpace.s5)
            .padding(.top, TBSpace.s4)
            .padding(.bottom, TBSpace.s8)
        }
        .background(Color.tbBg)
        .navigationTitle("个人信息")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editorRoute) { route in
            RelationshipEditorSheet(route: route) { savedRoute in
                save(route: savedRoute)
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            actionTarget?.title ?? "",
            isPresented: Binding(
                get: { actionTarget != nil },
                set: { if $0 == false { actionTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let target = actionTarget {
                Button("编辑信息") {
                    editorRoute = target.editorRoute
                    actionTarget = nil
                }

                Button("标记\(target.relationName)已故") {
                    actionTarget = nil
                }

                Button(target.removalTitle, role: .destructive) {
                    prepareRemoval(for: target)
                    actionTarget = nil
                }

                Button("取消", role: .cancel) {
                    actionTarget = nil
                }
            }
        }
        .alert(removalRequest?.title ?? "", isPresented: Binding(
            get: { removalRequest != nil },
            set: { if $0 == false { removalRequest = nil } }
        )) {
            Button("取消", role: .cancel) {
                removalRequest = nil
            }

            Button("移除", role: .destructive) {
                confirmRemoval()
            }
        } message: {
            Text(removalRequest?.message ?? "")
        }
        .alert(recoveryRequest?.title ?? "", isPresented: Binding(
            get: { recoveryRequest != nil },
            set: { if $0 == false { recoveryRequest = nil } }
        )) {
            Button("保留在其他", role: .cancel) {
                recoveryRequest = nil
            }

            Button("收回来") {
                confirmRecovery()
            }
        } message: {
            Text(recoveryRequest?.message ?? "")
        }
        .overlay(alignment: .bottom) {
            if let toastMessage {
                Text(toastMessage)
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbSurface)
                    .padding(.horizontal, TBSpace.s4)
                    .padding(.vertical, TBSpace.s3)
                    .background(Color.tbInk.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(.bottom, TBSpace.s5)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private var selfSection: some View {
        ProfileSection(title: "我自己") {
            DatePicker("生日", selection: birthdayBinding, displayedComponents: .date)
                .datePickerStyle(.compact)

            Picker("性别", selection: genderBinding) {
                Text("男").tag(Gender.male)
                Text("女").tag(Gender.female)
                Text("不愿透露").tag(Gender.undisclosed)
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: TBSpace.s2) {
                HStack {
                    Text("预期寿命")
                        .font(.tbBody)
                        .foregroundStyle(Color.tbInk)

                    Spacer()

                    Text("\(profile.expectedLifespanYears) 岁")
                        .font(.tbBodySm)
                        .foregroundStyle(Color.tbPrimary)
                }

                Slider(value: expectedLifespanBinding, in: 60...100, step: 1)
                    .tint(Color.tbPrimary)
            }
        }
    }

    private var parentsSection: some View {
        ProfileSection(title: "父母") {
            if let parents = profile.parents {
                Button {
                    editorRoute = .parents(parents)
                } label: {
                    RelationInfoCard(lines: parentLines(parents))
                }
                .buttonStyle(.plain)
                .onLongPressGesture {
                    actionTarget = .parents(parents)
                }
            } else {
                EmptyRelationRow(text: "还没填父母信息。", buttonTitle: "添加父母") {
                    editorRoute = .parents(nil)
                }
            }
        }
    }

    private var childrenSection: some View {
        ProfileSection(title: "孩子") {
            if profile.children.isEmpty {
                EmptyRelationRow(text: "还没填孩子信息。", buttonTitle: "添加孩子") {
                    editorRoute = .child(nil)
                }
            } else {
                ForEach(profile.children, id: \.id) { child in
                    Button {
                        editorRoute = .child(child)
                    } label: {
                        RelationInfoCard(lines: [childLine(child)])
                    }
                    .buttonStyle(.plain)
                    .onLongPressGesture {
                        actionTarget = .child(child, totalCount: profile.children.count)
                    }
                }

                Button {
                    editorRoute = .child(nil)
                } label: {
                    Label("添加孩子", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ProfileSecondaryButtonStyle())
            }
        }
    }

    private var partnerSection: some View {
        ProfileSection(title: "伴侣") {
            if let partner = profile.partner {
                Button {
                    editorRoute = .partner(partner)
                } label: {
                    RelationInfoCard(lines: [partnerLine(partner)])
                }
                .buttonStyle(.plain)
                .onLongPressGesture {
                    actionTarget = .partner(partner)
                }
            } else {
                EmptyRelationRow(text: "还没填伴侣信息。", buttonTitle: "添加伴侣") {
                    editorRoute = .partner(nil)
                }
            }
        }
    }

    private var birthdayBinding: Binding<Date> {
        Binding(
            get: { profile.birthday },
            set: { newValue in
                profile.birthday = newValue
                persistProfile()
            }
        )
    }

    private var genderBinding: Binding<Gender> {
        Binding(
            get: { profile.gender },
            set: { newValue in
                profile.gender = newValue
                persistProfile()
            }
        )
    }

    private var expectedLifespanBinding: Binding<Double> {
        Binding(
            get: { Double(profile.expectedLifespanYears) },
            set: { newValue in
                profile.expectedLifespanYears = Int(newValue.rounded())
                persistProfile()
            }
        )
    }

    private func save(route: SavedProfileRoute) {
        do {
            let store = DimensionDemotionStore(modelContext: modelContext)
            let recoverableDimensionID: String?
            let successMessage: String

            switch route {
            case .parents(let parents):
                let isAdding = profile.parents == nil
                profile.parents = parents
                profile.updatedAt = .now
                try store.markDimensionVisible(DimensionReservedID.parents.rawValue)
                recoverableDimensionID = isAdding ? DimensionReservedID.parents.rawValue : nil
                successMessage = isAdding ? "已添加父母" : "已更新"

            case .child(let child):
                let isAdding = profile.children.contains(where: { $0.id == child.id }) == false
                if let index = profile.children.firstIndex(where: { $0.id == child.id }) {
                    profile.children[index] = child
                } else {
                    profile.children.append(child)
                }
                profile.updatedAt = .now
                try store.markDimensionVisible(DimensionReservedID.kids.rawValue)
                recoverableDimensionID = isAdding ? DimensionReservedID.kids.rawValue : nil
                successMessage = isAdding ? "已添加孩子" : "已更新"

            case .partner(let partner):
                let isAdding = profile.partner == nil
                profile.partner = partner
                profile.updatedAt = .now
                try store.markDimensionVisible(DimensionReservedID.partner.rawValue)
                recoverableDimensionID = isAdding ? DimensionReservedID.partner.rawValue : nil
                successMessage = isAdding ? "已添加伴侣" : "已更新"
            }

            try modelContext.save()
            editorRoute = nil
            showToast(successMessage)

            if let recoverableDimensionID {
                prepareRecoveryIfNeeded(for: recoverableDimensionID)
            }
        } catch {
            showToast("已更新")
        }
    }

    private func prepareRemoval(for target: RelationActionTarget) {
        do {
            let store = DimensionDemotionStore(modelContext: modelContext)
            let request: RelationRemovalRequest

            switch target {
            case .parents:
                let count = try store.sourceMomentCount(for: DimensionReservedID.parents.rawValue)
                let message = count > 0
                    ? "你存入父母的 \(Formatter.momentsCount(count))会被收纳到「其他」时间账户，不会消失。\n重新添加父母时可以收回。"
                    : "你还没存过和父母相关的瞬间。\n移除后任何时候可以重新添加。"
                request = RelationRemovalRequest(kind: .parents, title: "确定要把父母从时间银行里移除吗？", message: message, count: count)

            case .child(let child, let totalCount):
                if totalCount > 1 {
                    request = RelationRemovalRequest(
                        kind: .child(child, isLast: false),
                        title: "移除这个孩子吗？",
                        message: "这条孩子信息会从你的时间银行删除，但你已存入\"陪孩子\"的瞬间不受影响。",
                        count: 0
                    )
                } else {
                    let count = try store.sourceMomentCount(for: DimensionReservedID.kids.rawValue)
                    let message = count > 0
                        ? "你存入孩子的 \(Formatter.momentsCount(count))会被收纳到「其他」时间账户。\n重新添加孩子时可以收回。"
                        : "你还没存过和孩子相关的瞬间。\n移除后任何时候可以重新添加。"
                    request = RelationRemovalRequest(kind: .child(child, isLast: true), title: "确定要移除最后一个孩子吗？", message: message, count: count)
                }

            case .partner:
                let count = try store.sourceMomentCount(for: DimensionReservedID.partner.rawValue)
                let message = count > 0
                    ? "你存入伴侣的 \(Formatter.momentsCount(count))不会消失，会被收纳到「其他」时间账户。\n任何时候你重新添加伴侣，都可以选择把它们收回来。"
                    : "你还没存过和伴侣相关的瞬间。\n移除后任何时候可以重新添加。"
                request = RelationRemovalRequest(kind: .partner, title: "确定要从时间银行里把伴侣移除吗？", message: message, count: count)
            }

            removalRequest = request
        } catch {
            showToast("已移除")
        }
    }

    private func confirmRemoval() {
        guard let request = removalRequest else { return }
        removalRequest = nil

        do {
            let store = DimensionDemotionStore(modelContext: modelContext)
            let movedCount: Int

            switch request.kind {
            case .parents:
                movedCount = try store.removeParents(from: profile)
            case .child(let child, _):
                movedCount = try store.removeChild(child.id, from: profile)
            case .partner:
                movedCount = try store.removePartner(from: profile)
            }

            showToast(movedCount > 0 ? "已移除 · \(Formatter.momentsCount(movedCount))收到了「其他」" : "已移除")
        } catch {
            showToast("已移除")
        }
    }

    private func prepareRecoveryIfNeeded(for dimensionID: String) {
        do {
            let store = DimensionDemotionStore(modelContext: modelContext)
            let count = try store.recoverableMomentCount(for: dimensionID)
            guard count > 0 else { return }

            recoveryRequest = RelationRecoveryRequest(
                dimensionID: dimensionID,
                count: count,
                message: "我们在「其他」里看到 \(Formatter.momentsCount(count))原本属于\(recoveryRelationName(for: dimensionID))。"
            )
        } catch {
            recoveryRequest = nil
        }
    }

    private func confirmRecovery() {
        guard let request = recoveryRequest else { return }
        recoveryRequest = nil

        do {
            let count = try DimensionDemotionStore(modelContext: modelContext).restore(dimensionID: request.dimensionID)
            showToast("收回了 \(Formatter.momentsCount(count))")
        } catch {
            showToast("已更新")
        }
    }

    private func persistProfile() {
        profile.updatedAt = .now
        try? modelContext.save()
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

    private func parentLines(_ parents: ParentsInfo) -> [String] {
        var lines: [String] = []
        if let father = parents.father {
            lines.append(parentLine(title: "父亲", member: father))
        }
        if let mother = parents.mother {
            lines.append(parentLine(title: "母亲", member: mother))
        }
        return lines.isEmpty ? ["父母"] : lines
    }

    private func parentLine(title: String, member: FamilyMember) -> String {
        "\(title) · 生于 \(member.birthYear) 年 · \(age(fromBirthYear: member.birthYear)) 岁\(member.deceased ? " · 已离开" : "")"
    }

    private func childLine(_ child: ChildInfo) -> String {
        "孩子 · 生于 \(child.birthYear) 年 · \(age(fromBirthYear: child.birthYear)) 岁\(child.deceased ? " · 已离开" : "")"
    }

    private func partnerLine(_ partner: PartnerInfo) -> String {
        "伴侣 · 生于 \(partner.birthYear) 年 · \(age(fromBirthYear: partner.birthYear)) 岁\(partner.deceased ? " · 已离开" : "")"
    }

    private func age(fromBirthYear birthYear: Int) -> Int {
        max(0, currentYear - birthYear)
    }

    private func recoveryRelationName(for dimensionID: String) -> String {
        switch dimensionID {
        case DimensionReservedID.parents.rawValue:
            return "陪父母"
        case DimensionReservedID.kids.rawValue:
            return "陪孩子"
        case DimensionReservedID.partner.rawValue:
            return "陪伴侣"
        default:
            return "这个时间账户"
        }
    }
}

private struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            Text(title)
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)

            VStack(alignment: .leading, spacing: TBSpace.s3) {
                content()
            }
            .padding(TBSpace.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.tbBg2)
            .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg))
        }
    }
}

private struct EmptyRelationRow: View {
    let text: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            Text(text)
                .font(.tbBodySm)
                .foregroundStyle(Color.tbInk2)

            Button(action: action) {
                Label(buttonTitle, systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ProfileSecondaryButtonStyle())
        }
    }
}

private struct RelationInfoCard: View {
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: TBSpace.s2) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.tbBody)
                    .foregroundStyle(Color.tbInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(TBSpace.s4)
        .background(Color.tbSurface)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.md))
    }
}

private struct ProfileSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.tbBody)
            .foregroundStyle(Color.tbPrimary)
            .padding(.vertical, TBSpace.s3)
            .padding(.horizontal, TBSpace.s4)
            .background(Color.tbSurface.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(RoundedRectangle(cornerRadius: TBRadius.md))
    }
}

enum ProfileEditorRoute: Identifiable {
    case parents(ParentsInfo?)
    case child(ChildInfo?)
    case partner(PartnerInfo?)

    var id: String {
        switch self {
        case .parents:
            return "parents"
        case .child(let child):
            return "child-\(child?.id.uuidString ?? "new")"
        case .partner:
            return "partner"
        }
    }
}

enum SavedProfileRoute {
    case parents(ParentsInfo)
    case child(ChildInfo)
    case partner(PartnerInfo)
}

private enum RelationActionTarget {
    case parents(ParentsInfo)
    case child(ChildInfo, totalCount: Int)
    case partner(PartnerInfo)

    var title: String {
        switch self {
        case .parents:
            return "父母"
        case .child:
            return "孩子"
        case .partner:
            return "伴侣"
        }
    }

    var relationName: String {
        switch self {
        case .parents:
            return "父母"
        case .child:
            return "孩子"
        case .partner:
            return "伴侣"
        }
    }

    var editorRoute: ProfileEditorRoute {
        switch self {
        case .parents(let parents):
            return .parents(parents)
        case .child(let child, _):
            return .child(child)
        case .partner(let partner):
            return .partner(partner)
        }
    }

    var removalTitle: String {
        switch self {
        case .parents:
            return "把这个父母从时间银行移除"
        case .child:
            return "把这个孩子从时间银行移除"
        case .partner:
            return "我已不和伴侣在一起了"
        }
    }
}

private struct RelationRemovalRequest {
    enum Kind {
        case parents
        case child(ChildInfo, isLast: Bool)
        case partner
    }

    let kind: Kind
    let title: String
    let message: String
    let count: Int
}

private struct RelationRecoveryRequest {
    let dimensionID: String
    let count: Int
    let message: String

    var title: String { "要把它们收回来吗？" }
}
