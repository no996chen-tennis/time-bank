// TimeBank/Features/Onboarding/Components/YearInputField.swift

import SwiftUI

struct YearInputField: View {
    let title: String
    @Binding var year: Int
    let range: ClosedRange<Int>

    init(
        title: String,
        year: Binding<Int>,
        range: ClosedRange<Int>
    ) {
        self.title = title
        self._year = year
        self.range = range
    }

    var body: some View {
        HStack(spacing: TBSpace.s2) {
            Text(title)
                .font(.tbBody)
                .foregroundStyle(Color.tbInk)

            Spacer()

            Picker("年份", selection: clampedYearBinding) {
                ForEach(Array(range).reversed(), id: \.self) { candidate in
                    Text(verbatim: "\(candidate) 年")
                        .tag(candidate)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.tbPrimary)
            .font(.tbBody)
            .padding(.horizontal, TBSpace.s3)
            .padding(.vertical, TBSpace.s2)
            .background(Color.tbSurface)
            .clipShape(RoundedRectangle(cornerRadius: TBRadius.sm))
            .accessibilityLabel("\(title)\(year)年")
        }
        .onAppear {
            year = clamped(year)
        }
    }

    private var clampedYearBinding: Binding<Int> {
        Binding(
            get: { clamped(year) },
            set: { year = clamped($0) }
        )
    }

    private func clamped(_ value: Int) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
