//
//  DSIconButtonStyle.swift
//
//  Icon-only buttons. Always create them with a title and a symbol,
//  `Button("Close", systemImage: "xmark")`: the style hides the title on
//  screen, and VoiceOver reads it.
//

import SwiftUI

public extension DesignSystem {
    /// Icon button look.
    enum IconButtonKind: Sendable {
        /// Accent icon, no background.
        case plain
        /// Icon on a surface circle, for buttons over images or maps.
        case filled
    }
}

/// Icon-only button style with a 44 × 44 hit area at every size.
public struct DSIconButtonStyle: ButtonStyle {
    public var kind: DesignSystem.IconButtonKind

    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init(kind: DesignSystem.IconButtonKind = .plain) {
        self.kind = kind
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .textRole(theme.components.button.iconGlyph)
            .foregroundStyle(foreground)
            .padding(theme.spacing.xs)
            .background {
                if kind == .filled {
                    Circle().fill(configuration.isPressed ? theme.surfacePressed : theme.surface)
                }
            }
            .opacity(kind == .plain && configuration.isPressed ? 0.6 : 1)
            .animation(DesignSystem.Motion.press, value: configuration.isPressed)
            .minTapTarget()
    }

    private var foreground: Color {
        guard isEnabled else { return theme.labelTertiary }
        return kind == .filled ? theme.labelPrimary : theme.accent
    }
}

public extension ButtonStyle where Self == DSIconButtonStyle {
    /// Icon-only button style.
    static func dsIcon(_ kind: DesignSystem.IconButtonKind = .plain) -> DSIconButtonStyle {
        DSIconButtonStyle(kind: kind)
    }
}

/// The standard close button for sheets and covers.
public struct DSCloseButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button("Close", systemImage: "xmark", action: action)
            .buttonStyle(.dsIcon(.filled))
    }
}

#Preview {
    HStack(spacing: DesignSystem.Spacing.standard.md) {
        Button("Share", systemImage: "square.and.arrow.up") {}.buttonStyle(.dsIcon())
        Button("Favourite", systemImage: "heart") {}.buttonStyle(.dsIcon(.filled))
        DSCloseButton {}
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
