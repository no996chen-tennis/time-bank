// TimeBank/Utility/KeyboardDismiss.swift

import SwiftUI
import UIKit

extension View {
    func timeBankKeyboardDismissBehavior() -> some View {
        modifier(TimeBankKeyboardDismissModifier())
    }
}

private struct TimeBankKeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(
                TapGesture().onEnded {
                    dismissKeyboard()
                }
            )
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        dismissKeyboard()
                    }
                    .foregroundStyle(Color.tbPrimary)
                }
            }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
