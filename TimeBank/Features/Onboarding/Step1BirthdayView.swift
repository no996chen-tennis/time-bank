// TimeBank/Features/Onboarding/Step1BirthdayView.swift

import SwiftUI

struct Step1BirthdayView: View {
    @Binding var draft: OnboardingDraft

    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TBSpace.s6) {
            Spacer(minLength: TBSpace.s5)

            header
            birthdayPicker
            genderPicker
            lifespanSlider

            Spacer(minLength: TBSpace.s5)

            Button("下一步", action: onNext)
                .buttonStyle(OnboardingNavigationButtonStyle())
                .disabled(!isBirthdayValid)
                .opacity(isBirthdayValid ? 1 : 0.5)
                .frame(maxWidth: .infinity)

            Spacer(minLength: TBSpace.s5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            Text("先从你开始。")
                .font(.tbHeadM)
                .foregroundStyle(Color.tbInk)

            Text("这些只会存在你的手机里。")
                .font(.tbBody)
                .foregroundStyle(Color.tbInk2)
        }
    }

    private var birthdayPicker: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            Text("生日")
                .font(.tbLabel)
                .foregroundStyle(Color.tbInk2)

            DatePicker(
                "生日",
                selection: $draft.birthday,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .background(Color.tbBg2)
            .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg))
        }
    }

    private var genderPicker: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            Text("性别")
                .font(.tbLabel)
                .foregroundStyle(Color.tbInk2)

            HStack(spacing: TBSpace.s3) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    SelectableChip(
                        title: label(for: gender),
                        isSelected: draft.gender == gender
                    ) {
                        draft.gender = gender
                    }
                }
            }
        }
    }

    private var lifespanSlider: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            HStack {
                Text("预期寿命")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk2)

                Spacer()

                Text("预期 \(draft.expectedLifespanYears) 岁")
                    .font(.tbBody)
                    .foregroundStyle(Color.tbPrimary)
            }

            Slider(
                value: Binding(
                    get: { Double(draft.expectedLifespanYears) },
                    set: { draft.expectedLifespanYears = Int($0.rounded()) }
                ),
                in: 60...120,
                step: 1
            )
            .tint(Color.tbPrimary)
        }
    }

    private var isBirthdayValid: Bool {
        draft.birthday <= Date.now
    }

    private func label(for gender: Gender) -> String {
        switch gender {
        case .male:
            "男"
        case .female:
            "女"
        case .other:
            "其他"
        case .undisclosed:
            "不想说"
        }
    }
}
