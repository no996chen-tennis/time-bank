// TimeBank/Features/Onboarding/Components/SelectableChip.swift

import SwiftUI

struct SelectableChip: View {
    let title: String
    let iconSystemName: String?
    let isSelected: Bool
    let action: () -> Void

    init(
        title: String,
        iconSystemName: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconSystemName = iconSystemName
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: TBSpace.s2) {
                if let iconSystemName {
                    Image(systemName: iconSystemName)
                        .imageScale(.small)
                }

                Text(title)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
        }
        .buttonStyle(SelectableChipButtonStyle(isSelected: isSelected))
        .animation(TBAnimation.microPress, value: isSelected)
    }
}

private struct SelectableChipButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.tbBody)
            .foregroundStyle(isSelected ? Color.tbPrimary : Color.tbInk)
            .padding(.horizontal, TBSpace.s5)
            .padding(.vertical, TBSpace.s3)
            .background(isSelected ? Color.tbPrimary.opacity(0.15) : Color.tbBg2)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.tbPrimary : Color.tbHair,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(TBAnimation.microPress, value: configuration.isPressed)
    }
}
