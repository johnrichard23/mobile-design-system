//
//  DSStepIndicator.swift
//
//  Progress through a multi-step flow ("Step 2 of 4"). For plain progress use
//  the system `ProgressView(value:)` (it takes the theme's tint), and for
//  spinners the system `ProgressView()`. This covers the one case the system
//  lacks.
//

import SwiftUI

/// "Step 2 of 4" with a segmented bar.
public struct DSStepIndicator: View {
    private let current: Int
    private let total: Int
    private let title: String?

    @Environment(\.theme) private var theme

    /// `current` counts from 1. `title` names the current step.
    public init(step current: Int, of total: Int, title: String? = nil) {
        self.current = min(max(current, 1), max(total, 1))
        self.total = max(total, 1)
        self.title = title
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: theme.spacing.xs) {
                Text("Step \(current) of \(total)")
                    .textRole(theme.components.feedback.stepLabel)
                    .foregroundStyle(theme.labelSecondary)
                if let title {
                    Text(title)
                        .textRole(theme.components.feedback.stepLabel.role)
                        .foregroundStyle(theme.labelSecondary)
                }
            }
            HStack(spacing: theme.spacing.xxs) {
                ForEach(1...total, id: \.self) { step in
                    Capsule()
                        .fill(step <= current ? theme.accent : theme.surfacePressed)
                        .frame(height: theme.spacing.xxs)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(["Step \(current) of \(total)", title].compactMap { $0 }.joined(separator: ", "))
    }
}

#Preview {
    VStack(spacing: DesignSystem.Spacing.standard.sectionGap) {
        DSStepIndicator(step: 2, of: 4, title: "Split")
        ProgressView(value: 0.6)
    }
    .screenMargins()
}
