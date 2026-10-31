//
//  Typography.swift
//
//  Text roles, the type scale and fonts. The scale is a token: a Figma file
//  can set its own size, line height, letter spacing and weights per role.
//  Each role stays tied to one of Apple's text styles, so whatever the sizes,
//  text scales with Dynamic Type.
//

import CoreText
import SwiftUI
import UIKit

// MARK: - Roles

public extension DesignSystem {
    /// What a piece of text is. Views pick a role; the theme decides its look.
    enum TextRole: CaseIterable, Sendable {
        case largeTitle, title1, title2, title3, headline, body
        case callout, subheadline, footnote, caption1, caption2

        /// The Dynamic Type style this role scales with.
        public var textStyle: Font.TextStyle {
            switch self {
            case .largeTitle: .largeTitle
            case .title1: .title
            case .title2: .title2
            case .title3: .title3
            case .headline: .headline
            case .body: .body
            case .callout: .callout
            case .subheadline: .subheadline
            case .footnote: .footnote
            case .caption1: .caption
            case .caption2: .caption2
            }
        }

        var uiTextStyle: UIFont.TextStyle {
            switch self {
            case .largeTitle: .largeTitle
            case .title1: .title1
            case .title2: .title2
            case .title3: .title3
            case .headline: .headline
            case .body: .body
            case .callout: .callout
            case .subheadline: .subheadline
            case .footnote: .footnote
            case .caption1: .caption1
            case .caption2: .caption2
            }
        }

        /// Titles, which may use the display family.
        public var isDisplay: Bool {
            switch self {
            case .largeTitle, .title1, .title2, .title3: true
            default: false
            }
        }
    }
}

// MARK: - Type scale

public extension DesignSystem {
    /// One role's look at the default Dynamic Type size, as a Figma text
    /// style gives it.
    struct TextSpec: Sendable, Equatable {
        /// Font size in points.
        public var size: CGFloat
        /// Line height in points.
        public var lineHeight: CGFloat
        /// Letter spacing in points. `nil` keeps the font's own spacing
        /// (San Francisco adjusts its spacing by size).
        public var tracking: CGFloat?
        /// Regular weight.
        public var weight: Font.Weight
        /// Emphasized weight. Emphasis changes weight, never size.
        public var emphasizedWeight: Font.Weight

        public init(
            size: CGFloat,
            lineHeight: CGFloat,
            tracking: CGFloat? = nil,
            weight: Font.Weight = .regular,
            emphasizedWeight: Font.Weight = .semibold
        ) {
            self.size = size
            self.lineHeight = lineHeight
            self.tracking = tracking
            self.weight = weight
            self.emphasizedWeight = emphasizedWeight
        }

        /// The weight to draw, one step heavier when the user turns on Bold Text.
        public func resolvedWeight(emphasized: Bool, boldText: Bool) -> Font.Weight {
            let base = emphasized ? emphasizedWeight : weight
            guard boldText else { return base }
            return base == .regular ? .semibold : .bold
        }
    }

    /// The type scale: one `TextSpec` per role.
    struct Typography: TokenSet, Equatable {
        public var largeTitle = TextSpec(size: 34, lineHeight: 41, emphasizedWeight: .bold)
        public var title1 = TextSpec(size: 28, lineHeight: 34, emphasizedWeight: .bold)
        public var title2 = TextSpec(size: 22, lineHeight: 28, emphasizedWeight: .bold)
        public var title3 = TextSpec(size: 20, lineHeight: 25, emphasizedWeight: .bold)
        public var headline = TextSpec(
            size: 17,
            lineHeight: 22,
            weight: .semibold,
            emphasizedWeight: .bold
        )
        public var body = TextSpec(size: 17, lineHeight: 22)
        public var callout = TextSpec(size: 16, lineHeight: 21)
        public var subheadline = TextSpec(size: 15, lineHeight: 20)
        public var footnote = TextSpec(size: 13, lineHeight: 18)
        public var caption1 = TextSpec(size: 12, lineHeight: 16)
        public var caption2 = TextSpec(size: 11, lineHeight: 13)

        public init() {}

        /// Apple's text styles.
        public static let apple = Typography()

        public subscript(role: TextRole) -> TextSpec {
            get {
                switch role {
                case .largeTitle: largeTitle
                case .title1: title1
                case .title2: title2
                case .title3: title3
                case .headline: headline
                case .body: body
                case .callout: callout
                case .subheadline: subheadline
                case .footnote: footnote
                case .caption1: caption1
                case .caption2: caption2
                }
            }
            set {
                switch role {
                case .largeTitle: largeTitle = newValue
                case .title1: title1 = newValue
                case .title2: title2 = newValue
                case .title3: title3 = newValue
                case .headline: headline = newValue
                case .body: body = newValue
                case .callout: callout = newValue
                case .subheadline: subheadline = newValue
                case .footnote: footnote = newValue
                case .caption1: caption1 = newValue
                case .caption2: caption2 = newValue
                }
            }
        }
    }
}

// MARK: - Fonts

public extension DesignSystem {
    /// A custom font family: the PostScript name of each weight's font file.
    struct FontFamily: Sendable, Equatable {
        public var regular: String
        public var medium: String
        public var semibold: String
        public var bold: String

        /// `medium` defaults to `regular` for families without a medium file.
        public init(regular: String, medium: String? = nil, semibold: String, bold: String) {
            self.regular = regular
            self.medium = medium ?? regular
            self.semibold = semibold
            self.bold = bold
        }

        /// The font file for a weight. Lighter weights use regular.
        public func name(for weight: Font.Weight) -> String {
            if weight == .medium { return medium }
            if weight == .semibold { return semibold }
            if weight == .bold || weight == .heavy || weight == .black { return bold }
            return regular
        }
    }

    /// The families an app uses. `nil` means San Francisco.
    struct Typeface: Sendable, Equatable {
        /// Family for every role, unless `display` overrides titles.
        public var text: FontFamily?
        /// Optional family for largeTitle to title3. Must contrast with `text`
        /// in structure (e.g. serif over sans), never resemble it.
        public var display: FontFamily?

        public init(text: FontFamily? = nil, display: FontFamily? = nil) {
            self.text = text
            self.display = display
        }

        /// San Francisco for everything.
        public static let system = Typeface()

        /// The family a role draws with, or `nil` for San Francisco.
        public func family(for role: TextRole) -> FontFamily? {
            role.isDisplay ? (display ?? text) : text
        }
    }

    /// Registers font files shipped as resources (for example in a Swift package)
    /// so `Font.custom` can find them. Call once at launch. Apps that list their
    /// fonts under `UIAppFonts` in Info.plist don't need this.
    /// Returns the file names that failed to register.
    @discardableResult
    static func registerFonts(_ fileNames: [String], in bundle: Bundle) -> [String] {
        fileNames.filter { fileName in
            guard let url = bundle.url(forResource: fileName, withExtension: nil) else {
                return true
            }
            return !CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

// MARK: - Resolving

/// A role's font, line spacing and letter spacing at one Dynamic Type size.
struct ResolvedText {
    let font: Font
    let lineSpacing: CGFloat
    let tracking: CGFloat?
}

extension DesignSystem.TextRole {
    /// `value` scaled the way this role's text scales at `dynamicTypeSize`.
    func scaled(_ value: CGFloat, at dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        let traits = UITraitCollection(
            preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize)
        )
        return UIFontMetrics(forTextStyle: uiTextStyle).scaledValue(for: value, compatibleWith: traits)
    }

    /// Draws `spec` scaled to `dynamicTypeSize`. Sizes below the 11-pt floor
    /// are raised to it.
    func resolve(
        _ spec: DesignSystem.TextSpec,
        family: DesignSystem.FontFamily?,
        emphasized: Bool,
        boldText: Bool,
        dynamicTypeSize: DynamicTypeSize
    ) -> ResolvedText {
        let weight = spec.resolvedWeight(emphasized: emphasized, boldText: boldText)
        let size = max(spec.size, DesignSystem.minTextSize)
        let traits = UITraitCollection(
            preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize)
        )
        let metrics = UIFontMetrics(forTextStyle: uiTextStyle)
        let scaledSize = metrics.scaledValue(for: size, compatibleWith: traits)
        let scaledLineHeight = metrics.scaledValue(
            for: max(spec.lineHeight, size),
            compatibleWith: traits
        )

        let font: Font
        let naturalLineHeight: CGFloat
        if let family {
            let fontName = family.name(for: weight)
            font = .custom(fontName, size: size, relativeTo: textStyle)
            naturalLineHeight = UIFont(name: fontName, size: scaledSize)?.lineHeight
                ?? scaledSize * 1.2
        } else {
            font = .system(size: scaledSize, weight: weight)
            naturalLineHeight = UIFont.systemFont(ofSize: scaledSize).lineHeight
        }
        return ResolvedText(
            font: font,
            lineSpacing: max(0, scaledLineHeight - naturalLineHeight),
            tracking: spec.tracking
        )
    }
}
