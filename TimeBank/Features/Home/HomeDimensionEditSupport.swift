// TimeBank/Features/Home/HomeDimensionEditSupport.swift

import SwiftUI
import UniformTypeIdentifiers

enum HomeDimensionEditMode: Equatable {
    case inactive
    case editing

    var isEditing: Bool { self == .editing }
}

struct HomeDimensionJiggleEffect: ViewModifier {
    let isActive: Bool
    let phaseDelay: Double

    @State private var angle: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isActive ? angle : 0))
            .onAppear {
                updateAnimation()
            }
            .onChange(of: isActive) { _, _ in
                updateAnimation()
            }
    }

    private func updateAnimation() {
        guard isActive else {
            withAnimation(.easeOut(duration: 0.14)) {
                angle = 0
            }
            return
        }

        let target = Double.random(in: 1.0...1.5) * (Bool.random() ? 1 : -1)
        DispatchQueue.main.asyncAfter(deadline: .now() + phaseDelay) {
            guard isActive else { return }
            angle = target
            withAnimation(.easeInOut(duration: 0.30).repeatForever(autoreverses: true)) {
                angle = -target
            }
        }
    }
}

struct HomeDimensionDeleteBadge: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "minus")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.tbSurface)
                .frame(width: 26, height: 26)
                .background(Color.tbInk)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Color.tbSurface, lineWidth: 2)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("删除自定义时间账户")
    }
}

struct HomeDimensionAddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("添加自定义时间账户", systemImage: "plus")
                .font(.tbBody)
                .foregroundStyle(Color.tbPrimary)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(Color.tbPrimary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: actionRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: actionRadius, style: .continuous)
                        .stroke(
                            Color.tbPrimary.opacity(0.42),
                            style: StrokeStyle(lineWidth: 1.2, dash: [6, 6])
                        )
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("添加自定义时间账户")
    }

    private var actionRadius: CGFloat {
        switch TimeBankTheme.current.kind {
        case .gallery, .localRemoteEditorial:
            return 0
        default:
            return TBRadius.pill
        }
    }
}

struct HomeHeaderActionButtonStyle: ButtonStyle {
    enum Role {
        case primary
        case secondary
        case accent
    }

    let role: Role

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundColor)
            .frame(minWidth: 44, minHeight: 44)
            .padding(.horizontal, TBSpace.s3)
            .background(backgroundColor.opacity(configuration.isPressed ? pressedBackgroundOpacity : backgroundOpacity))
            .clipShape(RoundedRectangle(cornerRadius: TBRadius.pill, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: TBRadius.pill, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
    }

    private var foregroundColor: Color {
        switch role {
        case .primary:
            return Color.tbSurface
        case .secondary:
            return Color.tbInk2
        case .accent:
            return Color.tbPrimary
        }
    }

    private var backgroundColor: Color {
        switch role {
        case .primary:
            return Color.tbPrimary
        case .secondary:
            return Color.tbInk2
        case .accent:
            return Color.tbPrimary
        }
    }

    private var backgroundOpacity: Double {
        switch role {
        case .primary:
            return 1
        case .secondary:
            return 0.08
        case .accent:
            return 0.10
        }
    }

    private var pressedBackgroundOpacity: Double {
        switch role {
        case .primary:
            return 0.78
        case .secondary, .accent:
            return 0.18
        }
    }
}

struct HomeDimensionDropDelegate: DropDelegate {
    let targetID: String
    @Binding var orderedIDs: [String]
    @Binding var draggingID: String?

    func dropEntered(info: DropInfo) {
        guard let draggingID,
              draggingID != targetID,
              let fromIndex = orderedIDs.firstIndex(of: draggingID),
              let toIndex = orderedIDs.firstIndex(of: targetID)
        else {
            return
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            let movedID = orderedIDs.remove(at: fromIndex)
            orderedIDs.insert(movedID, at: toIndex)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingID = nil
        return true
    }
}
