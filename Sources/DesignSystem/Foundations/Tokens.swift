//
//  Tokens.swift
//
//  Spacing, corner radius, size and elevation tokens. Each is a value an app
//  can override from its Figma file; the defaults follow Apple's guidelines.
//  Apple's floors (hit area, smallest text) are constants, not tokens.
//

import SwiftUI

public extension DesignSystem {
    /// Apple's minimum hit area for anything tappable. Not a token: no theme
    /// can lower it.
    static let minTapTarget: CGFloat = 44
    /// Smallest text size at the default Dynamic Type size. Not a token.
    static let minTextSize: CGFloat = 11
}

/// A group of design values an app can override from its Figma file.
public protocol TokenSet: Sendable {}

public extension TokenSet {
    /// A copy with some values changed, e.g.
    /// `DesignSystem.Spacing.standard.with { $0.cardPadding = 20 }`.
    func with(_ change: (inout Self) -> Void) -> Self {
        var copy = self
        change(&copy)
        return copy
    }
}

// MARK: - Spacing

public extension DesignSystem {
    /// The spacing scale and the gaps built from it. Default: a 4-pt scale.
    struct Spacing: TokenSet, Equatable {
        public var xxs: CGFloat = 4
        public var xs: CGFloat = 8
        public var sm: CGFloat = 12
        public var md: CGFloat = 16
        public var lg: CGFloat = 20
        public var xl: CGFloat = 24
        public var xxl: CGFloat = 32
        public var xxxl: CGFloat = 48

        /// Side margin on compact width (iPhone portrait).
        public var screenMarginCompact: CGFloat = 16
        /// Side margin on regular width (iPad, large iPhones in landscape).
        public var screenMarginRegular: CGFloat = 20
        /// Gap between parts of one item, e.g. a title and its subtitle.
        public var tightGap: CGFloat = 4
        /// Gap between items inside one group.
        public var stackGap: CGFloat = 8
        /// Gap between related groups on a screen.
        public var groupGap: CGFloat = 16
        /// Gap between sections of a screen.
        public var sectionGap: CGFloat = 32
        /// Inner padding of a card.
        public var cardPadding: CGFloat = 16

        public init() {}

        /// Apple-based defaults.
        public static let standard = Spacing()

        /// The side margin for a horizontal size class.
        public func screenMargin(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? screenMarginRegular : screenMarginCompact
        }
    }
}

// MARK: - Corner radius

public extension DesignSystem {
    /// Corner radii, always drawn as continuous corners via `shape(_:)`.
    /// For a pill, use a radius of at least half the component's height.
    struct Radius: TokenSet, Equatable {
        /// Tags and small badges.
        public var tag: CGFloat = 4
        /// Small controls and thumbnails.
        public var control: CGFloat = 8
        /// Text fields.
        public var field: CGFloat = 12
        /// Buttons.
        public var button: CGFloat = 12
        /// Cards, toasts and grouped containers.
        public var card: CGFloat = 16
        /// Chips and segmented controls. The default is a pill.
        public var chip: CGFloat = 999

        public init() {}

        /// Apple-based defaults.
        public static let standard = Radius()

        /// A continuous rounded rectangle for clipping, backgrounds and borders.
        public static func shape(_ radius: CGFloat) -> RoundedRectangle {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
        }
    }
}

// MARK: - Sizes

public extension DesignSystem {
    /// Component sizes. Heights are minimums: they grow with Dynamic Type.
    struct Size: TokenSet, Equatable {
        /// Large button height. Below 44 the button keeps this look and gets
        /// an invisible 44-pt hit area.
        public var buttonHeight: CGFloat = 56
        /// Compact (inline) button height. Same 44-pt rule.
        public var compactButtonHeight: CGFloat = 44
        /// Text field height. Never below 44.
        public var fieldHeight: CGFloat = 56
        /// Standard icon frame.
        public var icon: CGFloat = 24
        /// Inline icon frame, next to footnote or caption text.
        public var iconSmall: CGFloat = 16
        /// Avatar diameters. They grow with Dynamic Type, up to 1.6×.
        public var avatarSmall: CGFloat = 24
        public var avatar: CGFloat = 40
        public var avatarLarge: CGFloat = 64
        /// Border on fields and outlined cards.
        public var borderWidth: CGFloat = 1
        /// Maximum width of a column of running text (iPad, landscape).
        public var readableWidth: CGFloat = 672

        public init() {}

        /// Apple-based defaults.
        public static let standard = Size()

        /// One physical pixel, for separators. Pass `@Environment(\.displayScale)`.
        public static func hairline(displayScale: CGFloat) -> CGFloat {
            1 / max(displayScale, 1)
        }
    }
}

// MARK: - Elevation

public extension DesignSystem {
    /// The single shadow, for content that floats over other content.
    struct Elevation: TokenSet {
        public var color: Color = .black.opacity(0.1)
        public var radius: CGFloat = 6
        public var offsetY: CGFloat = 2

        public init() {}

        /// Apple-based defaults.
        public static let standard = Elevation()
    }
}

// MARK: - Motion

public extension DesignSystem {
    /// The only animations components use. Not a token: timing is part of
    /// how the platform feels. Under Reduce Motion, components drop movement
    /// and scale and keep fades.
    enum Motion {
        /// Press feedback on buttons and cards.
        public static let press = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.12)
        /// Something appearing or changing state.
        public static let enter = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.25)
        /// Something leaving. Faster than it arrived.
        public static let exit = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.18)
        /// A dragged element settling back into place.
        public static let settle = Animation.spring(duration: 0.4, bounce: 0)
    }
}
