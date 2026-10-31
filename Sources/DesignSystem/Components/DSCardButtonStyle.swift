//
//  DSCardButtonStyle.swift
//
//  A whole card that is tappable. Same look as `.card()`, with a pressed fill.
//

import SwiftUI

/// Makes a Button's label a tappable card.
public struct DSCardButtonStyle: ButtonStyle {
    public var outlined: Bool
    public var elevated: Bool

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(outlined: Bool = false, elevated: Bool = false) {
        self.outlined = outlined
        self.elevated = elevated
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(theme.labelPrimary)
            .multilineTextAlignment(.leading)
            .card(
                fill: configuration.isPressed ? theme.surfacePressed : nil,
                outlined: outlined,
                elevated: elevated
            )
            .contentShape(DesignSystem.Radius.shape(theme.radius.card))
            .scaleEffect(configuration.isPressed && !reduceMotion ? theme.components.button.pressedScale : 1)
            .animation(DesignSystem.Motion.press, value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == DSCardButtonStyle {
    /// Tappable card style.
    static func dsCard(outlined: Bool = false, elevated: Bool = false) -> DSCardButtonStyle {
        DSCardButtonStyle(outlined: outlined, elevated: elevated)
    }
}

#Preview {
    Button {} label: {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard.tightGap) {
            Text("Siargao, 12–18 March").textRole(.headline)
            Text("6 travellers · ₱42,300 spent").textRole(.subheadline)
        }
    }
    .buttonStyle(.dsCard())
    .screenMargins()
    .frame(maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
}
