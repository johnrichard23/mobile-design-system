//
//  DSButtonStyle.swift
//
//  Buttons: a few named kinds, loading that keeps the button's size, and
//  disabled drawn as inactive. A ButtonStyle, so it has real pressed states
//  and works with any Button label (text, a Label with an icon, or a custom
//  row such as title + price).
//
//  Kinds are open: a project adds its own from its theme, without changing
//  this file:
//
//      extension DesignSystem.ButtonKind {
//          static let social = DesignSystem.ButtonKind { theme in
//              .init(fill: theme.surface, pressedFill: theme.surfacePressed,
//                    foreground: theme.labelPrimary, border: theme.border)
//          }
//      }
//      Button("Continue with Apple", systemImage: "apple.logo") {}.buttonStyle(.ds(.social))
//

import SwiftUI

public extension DesignSystem {
    /// The colours of one button kind.
    struct ButtonColors {
        public var fill: Color
        public var pressedFill: Color
        public var foreground: Color
        /// A border, or `nil` for none.
        public var border: Color?
        /// Fill when disabled. `nil` uses the theme's inactive fill.
        public var disabledFill: Color?

        public init(
            fill: Color,
            pressedFill: Color,
            foreground: Color,
            border: Color? = nil,
            disabledFill: Color? = nil
        ) {
            self.fill = fill
            self.pressedFill = pressedFill
            self.foreground = foreground
            self.border = border
            self.disabledFill = disabledFill
        }
    }

    /// What a button does, as its colours from the theme. One `.primary` per
    /// screen. Add project kinds as static members (see the file header).
    struct ButtonKind: Sendable {
        let colors: @Sendable (Theme) -> ButtonColors

        public init(colors: @escaping @Sendable (Theme) -> ButtonColors) {
            self.colors = colors
        }

        /// The screen's main action. Accent fill.
        public static let primary = ButtonKind { theme in
            ButtonColors(fill: theme.accent, pressedFill: theme.accentPressed, foreground: theme.onAccent)
        }

        /// Other actions. Surface fill with a border.
        public static let secondary = ButtonKind { theme in
            ButtonColors(
                fill: theme.surface,
                pressedFill: theme.surfacePressed,
                foreground: theme.labelPrimary,
                border: theme.border
            )
        }

        /// Low-emphasis actions. Accent text, no fill.
        public static let plain = ButtonKind { theme in
            ButtonColors(
                fill: .clear,
                pressedFill: theme.surfacePressed,
                foreground: theme.accent,
                disabledFill: .clear
            )
        }

        /// Irreversible actions. Destructive fill.
        public static let destructive = ButtonKind { theme in
            ButtonColors(
                fill: theme.destructive,
                pressedFill: theme.destructive.opacity(0.8),
                foreground: theme.onAccent
            )
        }
    }

    /// Button height, from the theme. Both grow with Dynamic Type.
    enum ButtonSize: Sendable {
        /// `size.buttonHeight`. Screen-level actions.
        case large
        /// `size.compactButtonHeight`. Inline actions.
        case regular

        func height(in size: DesignSystem.Size) -> CGFloat {
            self == .large ? size.buttonHeight : size.compactButtonHeight
        }
    }
}

/// The shared button style. Apply with `.buttonStyle(.ds(.primary))`.
///
/// While `isLoading` the label is hidden but keeps its space, a spinner shows
/// and taps are ignored, so the action can't run twice. A disabled button
/// draws as inactive whatever its kind.
public struct DSButtonStyle: ButtonStyle {
    public var kind: DesignSystem.ButtonKind
    public var size: DesignSystem.ButtonSize
    public var isLoading: Bool
    public var expandsWidth: Bool

    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        kind: DesignSystem.ButtonKind = .primary,
        size: DesignSystem.ButtonSize = .large,
        isLoading: Bool = false,
        expandsWidth: Bool = true
    ) {
        self.kind = kind
        self.size = size
        self.isLoading = isLoading
        self.expandsWidth = expandsWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
        let colors = kind.colors(theme)
        let shape = DesignSystem.Radius.shape(theme.radius.button)
        let isPressed = configuration.isPressed && !isLoading
        let height = size.height(in: theme.size)
        let foreground = isEnabled ? colors.foreground : theme.labelTertiary
        let fill = isEnabled
            ? (isPressed ? colors.pressedFill : colors.fill)
            : (colors.disabledFill ?? theme.surfacePressed)
        // A design shorter than 44 pt keeps its look; the hit area grows instead.
        let hitAreaPadding = max(0, (DesignSystem.minTapTarget - height) / 2)
        ZStack {
            // While loading, the label turns clear rather than transparent:
            // it keeps its space and VoiceOver still reads the button's name.
            configuration.label
                .textRole(theme.components.button.label)
                .multilineTextAlignment(.center)
                .foregroundStyle(isLoading ? Color.clear : foreground)
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(foreground)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, theme.spacing.xl)
        .padding(.vertical, theme.spacing.xs)
        .frame(maxWidth: expandsWidth ? .infinity : nil, minHeight: height)
        .background(fill, in: shape)
        .overlay {
            if let border = colors.border, isEnabled {
                shape.strokeBorder(border, lineWidth: theme.size.borderWidth)
            }
        }
        .padding(.vertical, hitAreaPadding)
        .contentShape(Rectangle())
        .scaleEffect(isPressed && !reduceMotion ? theme.components.button.pressedScale : 1)
        .animation(DesignSystem.Motion.press, value: isPressed)
        .animation(DesignSystem.Motion.enter, value: isEnabled)
        .allowsHitTesting(!isLoading)
        .accessibilityValue(isLoading ? "Loading" : "")
    }
}

public extension ButtonStyle where Self == DSButtonStyle {
    /// The shared button style.
    static func ds(
        _ kind: DesignSystem.ButtonKind = .primary,
        size: DesignSystem.ButtonSize = .large,
        isLoading: Bool = false,
        expandsWidth: Bool = true
    ) -> DSButtonStyle {
        DSButtonStyle(kind: kind, size: size, isLoading: isLoading, expandsWidth: expandsWidth)
    }
}

#Preview {
    VStack(spacing: DesignSystem.Spacing.standard.sm) {
        Button("Continue") {}.buttonStyle(.ds(.primary))
        Button("Saving") {}.buttonStyle(.ds(.primary, isLoading: true))
        Button("Add item", systemImage: "plus") {}.buttonStyle(.ds(.secondary))
        Button("Skip for now") {}.buttonStyle(.ds(.plain))
        Button("Delete") {}.buttonStyle(.ds(.destructive))
        Button("Unavailable") {}.buttonStyle(.ds(.primary)).disabled(true)
        Button("Inline") {}.buttonStyle(.ds(.secondary, size: .regular, expandsWidth: false))
    }
    .screenMargins()
}
