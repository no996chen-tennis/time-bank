// TimeBank/Features/Onboarding/OnboardingFlowView.swift

import SwiftUI

enum OnboardingStep {
    case welcome
    case birthday
    case relationships
    case details
    case done
}

struct OnboardingFlowView: View {
    @State private var draft = OnboardingDraft()
    @State private var currentStep: OnboardingStep = .welcome

    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: TBSpace.s6) {
            stepContent
        }
        .font(.tbBody)
        .foregroundStyle(Color.tbInk)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(currentStep == .welcome ? 0 : TBSpace.s6)
        .background(Color.tbBg)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .welcome:
            Step0WelcomeView(onNext: goNext)

        case .birthday:
            Step1BirthdayView(
                draft: $draft,
                onNext: goNext,
                onBack: goBack
            )

        case .relationships:
            Step2RelationshipsView(
                draft: $draft,
                onNext: goNext,
                onBack: goBack
            )

        case .details:
            Step3DetailsView(
                draft: $draft,
                onNext: goNext,
                onBack: goBack
            )

        case .done:
            Step4DoneView(
                draft: $draft,
                onNext: onFinish,
                onBack: goBack
            )
        }
    }

    private func goNext() {
        switch currentStep {
        case .welcome:
            currentStep = .birthday
        case .birthday:
            currentStep = .relationships
        case .relationships:
            currentStep = .details
        case .details:
            currentStep = .done
        case .done:
            onFinish()
        }
    }

    private func goBack() {
        switch currentStep {
        case .welcome:
            break
        case .birthday:
            currentStep = .welcome
        case .relationships:
            currentStep = .birthday
        case .details:
            currentStep = .relationships
        case .done:
            currentStep = .details
        }
    }
}
