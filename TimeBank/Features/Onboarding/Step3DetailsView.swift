// TimeBank/Features/Onboarding/Step3DetailsView.swift

import SwiftUI

struct Step3DetailsView: View {
    @Binding var draft: OnboardingDraft
    @State private var frequencyUnit: FrequencyUnit
    @State private var frequencyValue: Int
    @State private var frequencyText: String

    let onNext: () -> Void
    let onBack: () -> Void

    init(
        draft: Binding<OnboardingDraft>,
        onNext: @escaping () -> Void,
        onBack: @escaping () -> Void
    ) {
        let visitsPerYear = max(1, draft.wrappedValue.parents?.visitsPerYear ?? 4)

        self._draft = draft
        self._frequencyUnit = State(initialValue: .perYear)
        self._frequencyValue = State(initialValue: visitsPerYear)
        self._frequencyText = State(initialValue: "\(visitsPerYear)")
        self.onNext = onNext
        self.onBack = onBack
    }

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
        .onAppear {
            ensureSelectedDefaults()
            syncParentsVisitsPerYear()
        }
        .onChange(of: draft.selectedRelationships) { _, _ in
            ensureSelectedDefaults()
            syncParentsVisitsPerYear()
        }
        .onChange(of: frequencyUnit) { oldUnit, newUnit in
            convertFrequencyValue(from: oldUnit, to: newUnit)
        }
        .onChange(of: frequencyText) { _, newValue in
            updateFrequencyValue(from: newValue)
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

            parentFrequencyRow

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
            YearInputField(
                title: "伴侣出生于",
                year: partnerBirthYear,
                range: 1920...(currentYear - 18)
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
            YearInputField(
                title: "孩子 \(index + 1) 生于",
                year: childBirthYearBinding(index: index),
                range: 1920...currentYear
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
                YearInputField(
                    title: "生于",
                    year: birthYear,
                    range: 1920...(currentYear - 18)
                )
            }
        }
    }

    private var parentFrequencyRow: some View {
        VStack(alignment: .leading, spacing: TBSpace.s2) {
            HStack(spacing: TBSpace.s3) {
                Text("见面频率")
                    .font(.tbBody)
                    .foregroundStyle(Color.tbInk)

                Spacer()

                Picker("见面频率单位", selection: $frequencyUnit) {
                    ForEach(FrequencyUnit.allCases, id: \.self) { unit in
                        Text(unit.title)
                            .tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 176)
            }

            HStack(spacing: TBSpace.s2) {
                TextField("次数", text: $frequencyText)
                    .font(.tbBody)
                    .foregroundStyle(Color.tbInk)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, TBSpace.s3)
                    .padding(.vertical, TBSpace.s2)
                    .background(Color.tbSurface)
                    .clipShape(RoundedRectangle(cornerRadius: TBRadius.sm))

                Text("次")
                    .font(.tbBody)
                    .foregroundStyle(Color.tbInk2)
            }

            Text("大约\(frequencyUnit.title)见 \(frequencyValue) 次")
                .font(.tbBodySm)
                .foregroundStyle(Color.tbInk3)
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

    private func convertFrequencyValue(
        from oldUnit: FrequencyUnit,
        to newUnit: FrequencyUnit
    ) {
        let visitsPerYear = oldUnit.visitsPerYear(from: frequencyValue)
        setFrequencyValue(newUnit.value(fromVisitsPerYear: visitsPerYear))
    }

    private func updateFrequencyValue(from value: String) {
        let digits = value.filter { $0.isNumber }

        if digits != value {
            frequencyText = digits
            return
        }

        guard let parsed = Int(digits) else {
            setFrequencyValue(10_000)
            return
        }

        setFrequencyValue(parsed)
    }

    private func setFrequencyValue(_ value: Int) {
        let clampedValue = min(max(1, value), 10_000)
        frequencyValue = clampedValue

        if frequencyText != "\(clampedValue)" {
            frequencyText = "\(clampedValue)"
        }

        syncParentsVisitsPerYear()
    }

    private func syncParentsVisitsPerYear() {
        guard isSelected(.parents) else { return }

        var parents = draft.parents ?? ParentsInfo()
        parents.visitsPerYear = frequencyUnit.visitsPerYear(from: frequencyValue)
        draft.parents = parents
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
