//
//  Theme.swift
//
//  One brand's whole design: colour roles plus every token. Build one per
//  Figma file; set it once at the app root with `.theme(_:)`.
//

import SwiftUI
import UIKit

public extension DesignSystem {
    /// A brand's colours, fonts, type scale, spacing, radii, sizes and shadow.
    /// Views and components read only from this.
    ///
    /// ```
    /// extension DesignSystem.Theme {
    ///     static let brand = DesignSystem.Theme(
    ///         accent: .Brand.accent,                     // asset catalog colour
    ///         accentPressed: DesignSystem.color(light: 0x0B5E58, dark: 0x5EEAD4),
    ///         ...,
    ///         typeface: .init(text: .init(
    ///             regular: "BrandSans-Regular", semibold: "BrandSans-SemiBold", bold: "BrandSans-Bold"
    ///         )),
    ///         typography: .apple.with { $0.body = .init(size: 16, lineHeight: 24) },
    ///         radius: .standard.with { $0.button = 28 },
    ///         components: .standard.with { $0.button.label = .init(.callout, emphasized: true) }
    ///     )
    /// }
    /// ```
    struct Theme: TokenSet {
        /// Primary actions, selection, links. Also the app's tint.
        public var accent: Color
        /// Accent while pressed.
        public var accentPressed: Color
        /// Text and icons on an accent fill.
        public var onAccent: Color
        /// Screen background.
        public var background: Color
        /// Cards, rows and grouped containers on the background.
        public var surface: Color
        /// Surface while pressed or selected.
        public var surfacePressed: Color
        /// Main text.
        public var labelPrimary: Color
        /// Supporting text.
        public var labelSecondary: Color
        /// Placeholders and disabled text.
        public var labelTertiary: Color
        /// Field and outlined-card borders.
        public var border: Color
        /// Hairline dividers between rows.
        public var separator: Color
        /// Positive status.
        public var success: Color
        /// Caution status.
        public var warning: Color
        /// Errors and destructive actions.
        public var destructive: Color
        /// Neutral information.
        public var info: Color

        /// Brand fonts. `.system` uses San Francisco.
        public var typeface: Typeface
        /// Size, line height, letter spacing and weights per text role.
        public var typography: Typography
        /// Spacing scale and gaps.
        public var spacing: Spacing
        /// Corner radii.
        public var radius: Radius
        /// Component sizes.
        public var size: Size
        /// The floating shadow.
        public var elevation: Elevation
        /// How strongly a status colour tints a background (banners, tags).
        public var tintOpacity: Double
        /// Per-component text styles and press feedback.
        public var components: ComponentTokens
        /// Whether components play haptics. The system setting always wins.
        public var hapticsEnabled: Bool

        public init(
            accent: Color,
            accentPressed: Color,
            onAccent: Color,
            background: Color,
            surface: Color,
            surfacePressed: Color,
            labelPrimary: Color,
            labelSecondary: Color,
            labelTertiary: Color,
            border: Color,
            separator: Color,
            success: Color,
            warning: Color,
            destructive: Color,
            info: Color,
            typeface: Typeface = .system,
            typography: Typography = .apple,
            spacing: Spacing = .standard,
            radius: Radius = .standard,
            size: Size = .standard,
            elevation: Elevation = .standard,
            tintOpacity: Double = 0.12,
            components: ComponentTokens = .standard,
            hapticsEnabled: Bool = true
        ) {
            self.accent = accent
            self.accentPressed = accentPressed
            self.onAccent = onAccent
            self.background = background
            self.surface = surface
            self.surfacePressed = surfacePressed
            self.labelPrimary = labelPrimary
            self.labelSecondary = labelSecondary
            self.labelTertiary = labelTertiary
            self.border = border
            self.separator = separator
            self.success = success
            self.warning = warning
            self.destructive = destructive
            self.info = info
            self.typeface = typeface
            self.typography = typography
            self.spacing = spacing
            self.radius = radius
            self.size = size
            self.elevation = elevation
            self.tintOpacity = tintOpacity
            self.components = components
            self.hapticsEnabled = hapticsEnabled
        }

        /// iOS system colours, San Francisco and Apple's values for every token.
        /// Adapts to light, dark and Increase Contrast. The default until an
        /// app sets its own theme.
        public static let system = Theme(
            accent: .accentColor,
            accentPressed: .accentColor.opacity(0.8),
            onAccent: .white,
            background: Color(.systemGroupedBackground),
            surface: Color(.secondarySystemGroupedBackground),
            surfacePressed: Color(.tertiarySystemFill),
            labelPrimary: Color(.label),
            labelSecondary: Color(.secondaryLabel),
            labelTertiary: Color(.tertiaryLabel),
            border: Color(.opaqueSeparator),
            separator: Color(.separator),
            success: Color(.systemGreen),
            warning: Color(.systemOrange),
            destructive: Color(.systemRed),
            info: Color(.systemBlue)
        )
    }

    /// A colour from Figma hex values (`0xRRGGBB`) that switches between light
    /// and dark, and to the high-contrast values when Increase Contrast is on.
    /// Use it in a theme definition, never in a view.
    static func color(
        light: UInt32,
        dark: UInt32,
        lightHighContrast: UInt32? = nil,
        darkHighContrast: UInt32? = nil,
        opacity: Double = 1
    ) -> Color {
        Color(UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            let isHighContrast = traits.accessibilityContrast == .high
            let hex: UInt32 = switch (isDark, isHighContrast) {
            case (false, false): light
            case (false, true): lightHighContrast ?? light
            case (true, false): dark
            case (true, true): darkHighContrast ?? dark
            }
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: opacity
            )
        })
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = DesignSystem.Theme.system
}

public extension EnvironmentValues {
    /// The current theme. Set once at the app root with `.theme(_:)`.
    var theme: DesignSystem.Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
