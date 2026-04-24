// TimeBank/Features/Onboarding/Step3DetailsView.swift

import SwiftUI

struct Step3DetailsView: View {
    @Binding var draft: OnboardingDraft

    let onNext: () -> Void
    let onBack: () -> Void

    private var currentYear: Int {
        Calendar.current.component(.year, from: .now)
    }

    private var canGoNext: Bool {
        !isSelected(.children) || !draft.children.isEmpty
    }

    var body: some View {
        VStack(spacing: TBSpace.s6) {
            ScrollView {
                VStack(alignment: .leading, spacing: TBSpace.s5) {
                    header

                    if hasSelectedRelationships {
                        selectedForms
                    } else {
                        emptyState
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, TBSpace.s5)
            }

            navigationButtons
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: ensureSelectedDefaults)
        .onChange(of: draft.selectedRelationships) { _, _ in
            ensureSelectedDefaults()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            Text("不用太准，估个数就好。")
                .font(.tbHeadM)
                .foregroundStyle(Color.tbInk)

            Text("随时可以改。")
                .font(.tbBody)
                .foregroundStyle(Color.tbInk2)
        }
    }

    @ViewBuilder
    private var selectedForms: some View {
        if isSelected(.parents) {
            parentsForm
        }

        if isSelected(.children) {
            childrenForm
        }

        if isSelected(.partner) {
            partnerForm
        }

        if isSelected(.solo) {
            soloAcknowledgement
        }
    }

    private var parentsForm: some View {
        DetailCard(title: "父母") {
            optionalParentRow(
                title: "父亲",
                member: draft.parents?.father,
                setMember: { updateParent(\.father, member: $0) },
                birthYear: parentBirthYearBinding(\.father, defaultOffset: 60)
            )

            optionalParentRow(
                title: "母亲",
                member: draft.parents?.mother,
                setMember: { updateParent(\.mother, member: $0) },
                birthYear: parentBirthYearBinding(\.mother, defaultOffset: 58)
            )

            Stepper(
                "每年见 \(parentsBinding.visitsPerYear.wrappedValue) 次",
                value: parentsBinding.visitsPerYear,
                in: 1...52
            )

            sliderRow(
                title: "每次见面大约",
                valueText: "\(formatHalfHour(parentsBinding.hoursPerVisit.wrappedValue)) 小时"
            ) {
                Slider(value: parentsBinding.hoursPerVisit, in: 0.5...24, step: 0.5)
                    .tint(Color.tbPrimary)
            }

            sliderRow(
                title: "父母预期寿命",
                valueText: "\(parentsBinding.expectedLifespan.wrappedValue) 岁"
            ) {
                Slider(
                    value: parentsExpectedLifespanSlider,
                    in: 60...110,
                    step: 1
                )
                .tint(Color.tbPrimary)
            }
        }
    }

    private var childrenForm: some View {
        DetailCard(title: "孩子") {
            if draft.children.isEmpty {
                Text("至少添加一个孩子后，就可以继续。")
                    .font(.tbBody)
                    .foregroundStyle(Color.tbInk2)
            }

            ForEach(draft.children.indices, id: \.self) { index in
                childRow(index: index)
            }

            Button {
                draft.children.append(ChildInfo(birthYear: currentYear - 1))
            } label: {
                Label("添加孩子", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(OnboardingSecondaryButtonStyle())
        }
    }

    private var partnerForm: some View {
        DetailCard(title: "伴侣") {
            Stepper(
                "伴侣出生于 \(partnerBirthYear.wrappedValue) 年",
                value: partnerBirthYear,
                in: 1920...(currentYear - 18)
            )

            sliderRow(
                title: "平均每天共处",
                valueText: "\(formatHalfHour(partnerHoursPerDay.wrappedValue)) 小时"
            ) {
                Slider(value: partnerHoursPerDay, in: 0...16, step: 0.5)
                    .tint(Color.tbPrimary)
            }
        }
    }

    private var soloAcknowledgement: some View {
        DetailCard(title: "独处") {
            Text("独处也是一种时间。这份时间我们也会帮你记下来。")
                .font(.tbBody)
                .foregroundStyle(Color.tbInk2)
        }
    }

    private var emptyState: some View {
        DetailCard(title: "之后再补") {
            Text("你可以直接继续。家人信息随时能在设置里补上。")
                .font(.tbBody)
                .foregroundStyle(Color.tbInk2)
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: TBSpace.s5) {
            Button("上一步", action: onBack)
                .buttonStyle(OnboardingSecondaryButtonStyle())

            Button("下一步", action: onNext)
                .buttonStyle(OnboardingNavigationButtonStyle())
                .disabled(!canGoNext)
                .opacity(canGoNext ? 1 : 0.5)
        }
    }

    private func childRow(index: Int) -> some View {
        HStack(spacing: TBSpace.s3) {
            Stepper(
                "孩子 \(index + 1) 生于 \(draft.children[index].birthYear) 年",
                value: childBirthYearBinding(index: index),
                in: 1920...currentYear
            )

            Button {
                draft.children.remove(at: index)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Color.tbDanger)
                    .frame(width: TBSpace.s8, height: TBSpace.s8)
            }
        }
    }

    private func optionalParentRow(
        title: String,
        member: FamilyMember?,
        setMember: @escaping (FamilyMember?) -> Void,
        birthYear: Binding<Int>
    ) -> some View {
        VStack(alignment: .leading, spacing: TBSpace.s2) {
            HStack {
                Text(title)
                    .font(.tbBody)
                    .foregroundStyle(Color.tbInk)

                Spacer()

                Button(member == nil ? "填写" : "清除") {
                    if member == nil {
                        setMember(FamilyMember(birthYear: birthYear.wrappedValue))
                    } else {
                        setMember(nil)
                    }
                }
                .font(.tbBodySm)
                .foregroundStyle(member == nil ? Color.tbPrimary : Color.tbInk2)
            }

            if member != nil {
                Stepper(
                    "生于 \(birthYear.wrappedValue) 年",
                    value: birthYear,
                    in: 1920...(currentYear - 18)
                )
            }
        }
    }

    private func sliderRow<Content: View>(
        title: String,
        valueText: String,
        @ViewBuilder control: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: TBSpace.s2) {
            HStack {
                Text(title)
                    .font(.tbBody)
                    .foregroundStyle(Color.tbInk)

                Spacer()

                Text(valueText)
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbPrimary)
            }

            control()
        }
    }

    private var hasSelectedRelationships: Bool {
        !draft.selectedRelationships.isEmpty
    }

    private func isSelected(_ relationship: OnboardingRelationship) -> Bool {
        draft.selectedRelationships.contains(relationship)
    }

    private func ensureSelectedDefaults() {
        if isSelected(.parents), draft.parents == nil {
            draft.parents = ParentsInfo()
        }

        if isSelected(.partner), draft.partner == nil {
            draft.partner = PartnerInfo()
        }
    }

    private var parentsBinding: Binding<ParentsInfo> {
        Binding(
            get: { draft.parents ?? ParentsInfo() },
            set: { draft.parents = $0 }
        )
    }

    private var partnerBinding: Binding<PartnerInfo> {
        Binding(
            get: { draft.partner ?? PartnerInfo() },
            set: { draft.partner = $0 }
        )
    }

    private var parentsExpectedLifespanSlider: Binding<Double> {
        Binding(
            get: { Double(parentsBinding.expectedLifespan.wrappedValue) },
            set: { parentsBinding.expectedLifespan.wrappedValue = Int($0.rounded()) }
        )
    }

    private var partnerBirthYear: Binding<Int> {
        partnerBinding.birthYear
    }

    private var partnerHoursPerDay: Binding<Double> {
        partnerBinding.hoursPerDay
    }

    private func parentBirthYearBinding(
        _ keyPath: WritableKeyPath<ParentsInfo, FamilyMember?>,
        defaultOffset: Int
    ) -> Binding<Int> {
        Binding(
            get: {
                draft.parents?[keyPath: keyPath]?.birthYear ?? currentYear - defaultOffset
            },
            set: { year in
                updateParent(keyPath, member: FamilyMember(birthYear: year))
            }
        )
    }

    private func updateParent(
        _ keyPath: WritableKeyPath<ParentsInfo, FamilyMember?>,
        member: FamilyMember?
    ) {
        var parents = draft.parents ?? ParentsInfo()
        parents[keyPath: keyPath] = member
        draft.parents = parents
    }

    private func childBirthYearBinding(index: Int) -> Binding<Int> {
        Binding(
            get: { draft.children[index].birthYear },
            set: { draft.children[index].birthYear = $0 }
        )
    }

    private func formatHalfHour(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}

private struct DetailCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: TBSpace.s4) {
            Text(title)
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TBSpace.s5)
        .background(Color.tbBg2)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg))
    }
}
