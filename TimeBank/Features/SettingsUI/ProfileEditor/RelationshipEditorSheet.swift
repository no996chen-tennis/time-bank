// TimeBank/Features/SettingsUI/ProfileEditor/RelationshipEditorSheet.swift

import SwiftUI

struct RelationshipEditorSheet: View {
    let route: ProfileEditorRoute
    let onSave: (SavedProfileRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var fatherEnabled: Bool
    @State private var fatherYear: Int
    @State private var motherEnabled: Bool
    @State private var motherYear: Int
    @State private var child: ChildInfo
    @State private var partner: PartnerInfo

    private var currentYear: Int {
        Calendar(identifier: .gregorian).component(.year, from: .now)
    }

    init(
        route: ProfileEditorRoute,
        onSave: @escaping (SavedProfileRoute) -> Void
    ) {
        self.route = route
        self.onSave = onSave

        switch route {
        case .parents(let parents):
            let father = parents?.father
            let mother = parents?.mother
            self._fatherEnabled = State(initialValue: father != nil || parents == nil)
            self._fatherYear = State(initialValue: father?.birthYear ?? Calendar.current.component(.year, from: .now) - 60)
            self._motherEnabled = State(initialValue: mother != nil || parents == nil)
            self._motherYear = State(initialValue: mother?.birthYear ?? Calendar.current.component(.year, from: .now) - 58)
            self._child = State(initialValue: ChildInfo())
            self._partner = State(initialValue: PartnerInfo())

        case .child(let child):
            self._fatherEnabled = State(initialValue: false)
            self._fatherYear = State(initialValue: Calendar.current.component(.year, from: .now) - 60)
            self._motherEnabled = State(initialValue: false)
            self._motherYear = State(initialValue: Calendar.current.component(.year, from: .now) - 58)
            self._child = State(initialValue: child ?? ChildInfo(birthYear: Calendar.current.component(.year, from: .now) - 1))
            self._partner = State(initialValue: PartnerInfo())

        case .partner(let partner):
            self._fatherEnabled = State(initialValue: false)
            self._fatherYear = State(initialValue: Calendar.current.component(.year, from: .now) - 60)
            self._motherEnabled = State(initialValue: false)
            self._motherYear = State(initialValue: Calendar.current.component(.year, from: .now) - 58)
            self._child = State(initialValue: ChildInfo())
            self._partner = State(initialValue: partner ?? PartnerInfo())
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: TBSpace.s5) {
                    content
                }
                .padding(TBSpace.s5)
            }
            .background(Color.tbBg)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch route {
        case .parents:
            Toggle("父亲", isOn: $fatherEnabled)
                .font(.tbBody)
                .foregroundStyle(Color.tbInk)
            if fatherEnabled {
                YearInputField(
                    title: "生于",
                    year: $fatherYear,
                    range: 1920...(currentYear - 18)
                )
                .padding(.bottom, TBSpace.s2)
            }

            Toggle("母亲", isOn: $motherEnabled)
                .font(.tbBody)
                .foregroundStyle(Color.tbInk)
            if motherEnabled {
                YearInputField(
                    title: "生于",
                    year: $motherYear,
                    range: 1920...(currentYear - 18)
                )
            }

        case .child:
            YearInputField(
                title: "生于",
                year: Binding(
                    get: { child.birthYear },
                    set: { child.birthYear = $0 }
                ),
                range: 1920...currentYear
            )

        case .partner:
            YearInputField(
                title: "出生于",
                year: Binding(
                    get: { partner.birthYear },
                    set: { partner.birthYear = $0 }
                ),
                range: 1920...(currentYear - 18)
            )

            VStack(alignment: .leading, spacing: TBSpace.s2) {
                HStack {
                    Text("每天共处时长")
                        .font(.tbBody)
                        .foregroundStyle(Color.tbInk)

                    Spacer()

                    Text("\(formatHalfHour(partner.hoursPerDay)) 小时")
                        .font(.tbBodySm)
                        .foregroundStyle(Color.tbPrimary)
                }

                Slider(
                    value: Binding(
                        get: { partner.hoursPerDay },
                        set: { partner.hoursPerDay = $0 }
                    ),
                    in: 0...16,
                    step: 0.5
                )
                .tint(Color.tbPrimary)
            }
        }
    }

    private var title: String {
        switch route {
        case .parents(let parents):
            return parents == nil ? "添加父母" : "编辑父母"
        case .child(let child):
            return child == nil ? "添加孩子" : "编辑孩子"
        case .partner(let partner):
            return partner == nil ? "添加伴侣" : "编辑伴侣"
        }
    }

    private var canSave: Bool {
        switch route {
        case .parents:
            return fatherEnabled || motherEnabled
        case .child, .partner:
            return true
        }
    }

    private func save() {
        switch route {
        case .parents(let original):
            let parents = ParentsInfo(
                father: fatherEnabled ? FamilyMember(birthYear: fatherYear, deceased: original?.father?.deceased ?? false, deceasedAt: original?.father?.deceasedAt) : nil,
                mother: motherEnabled ? FamilyMember(birthYear: motherYear, deceased: original?.mother?.deceased ?? false, deceasedAt: original?.mother?.deceasedAt) : nil,
                visitsPerYear: original?.visitsPerYear ?? 4,
                hoursPerVisit: original?.hoursPerVisit ?? 6,
                expectedLifespan: original?.expectedLifespan ?? 82
            )
            onSave(.parents(parents))

        case .child:
            onSave(.child(child))

        case .partner:
            onSave(.partner(partner))
        }
    }

    private func formatHalfHour(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}
