//
//  DSSectionHeader.swift
//
//  Section title with an optional trailing action ("See all"). Marked as a
//  heading so VoiceOver users can jump between sections.
//

import SwiftUI

/// A section title, optionally with one trailing action.
public struct DSSectionHeader: View {
    private let title: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: theme.spacing.xxs))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: theme.spacing.sm))
        layout {
            Text(title)
                .textRole(theme.components.sectionHeader.title)
                .foregroundStyle(theme.labelPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .textRole(theme.components.sectionHeader.action)
                    .foregroundStyle(theme.accent)
                    .frame(minHeight: DesignSystem.minTapTarget)
                    .contentShape(Rectangle())
            }
        }
    }
}

#Preview {
    VStack(spacing: DesignSystem.Spacing.standard.sectionGap) {
        DSSectionHeader("Upcoming trips", actionTitle: "See all") {}
        DSSectionHeader("Balances")
    }
    .screenMargins()
}
