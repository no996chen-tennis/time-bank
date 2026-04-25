// TimeBank/Features/Onboarding/Components/YearInputField.swift

import SwiftUI

struct YearInputField: View {
    let title: String
    @Binding var year: Int
    let range: ClosedRange<Int>

    @State private var text: String
    @FocusState private var isFocused: Bool

    init(
        title: String,
        year: Binding<Int>,
        range: ClosedRange<Int>
    ) {
        self.title = title
        self._year = year
        self.range = range
        self._text = State(initialValue: "\(year.wrappedValue)")
    }

    var body: some View {
        HStack(spacing: TBSpace.s2) {
            Text(title)
                .font(.tbBody)
                .foregroundStyle(Color.tbInk)

            Spacer()

            TextField("年份", text: $text)
                .font(.tbBody)
                .foregroundStyle(Color.tbInk)
                .multilineTextAlignment(.trailing)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .frame(width: 72)
                .padding(.horizontal, TBSpace.s3)
                .padding(.vertical, TBSpace.s2)
                .background(Color.tbSurface)
                .clipShape(RoundedRectangle(cornerRadius: TBRadius.sm))
                .onChange(of: text) { _, newValue in
                    updateYear(from: newValue)
                }
                .onChange(of: year) { _, newValue in
                    guard !isFocused else { return }
                    text = "\(clamped(newValue))"
                }
                .onChange(of: isFocused) { _, focused in
                    if !focused {
                        commitText()
                    }
                }

            Text("年")
                .font(.tbBody)
                .foregroundStyle(Color.tbInk2)
        }
        .onAppear(perform: commitCurrentYear)
    }

    private func updateYear(from value: String) {
        let digits = value.filter { $0.isNumber }

        if digits != value {
            text = digits
            return
        }

        guard let parsed = Int(digits) else {
            return
        }

        if parsed > range.upperBound {
            year = range.upperBound
            text = "\(range.upperBound)"
            return
        }

        if digits.count >= 4, parsed < range.lowerBound {
            year = range.lowerBound
            text = "\(range.lowerBound)"
            return
        }

        if range.contains(parsed) {
            year = parsed
        }
    }

    private func commitText() {
        let digits = text.filter { $0.isNumber }

        guard let parsed = Int(digits) else {
            let validYear = clamped(year)
            year = validYear
            text = "\(validYear)"
            return
        }

        let validYear = clamped(parsed)
        year = validYear
        text = "\(validYear)"
    }

    private func commitCurrentYear() {
        let validYear = clamped(year)
        year = validYear
        text = "\(validYear)"
    }

    private func clamped(_ value: Int) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
