//
//  ComponentTokens.swift
//
//  The component tier: which text style each part of each component uses,
//  and how far a pressed button shrinks. Colours, spacing, radii and sizes
//  come from the other token sets; this covers what a project's Figma file
//  typically specifies per component ("button label: Callout Semibold",
//  "field label: Footnote"). The defaults reproduce the standard look.
//
//      theme.components = .standard.with {
//          $0.button.label = .init(.callout, emphasized: true)
//          $0.field.label = .init(.footnote)
//      }
//

import SwiftUI

public extension DesignSystem {
    /// A text role plus whether it is the emphasized weight.
    struct TextStyleRef: Sendable, Equatable {
        public var role: TextRole
        public var emphasized: Bool

        public init(_ role: TextRole, emphasized: Bool = false) {
            self.role = role
            self.emphasized = emphasized
        }
    }

    /// Per-component text styles and press feedback.
    struct ComponentTokens: TokenSet, Equatable {
        public struct Button: Sendable, Equatable {
            public var label = TextStyleRef(.headline)
            /// Icon-only buttons: the glyph's text style.
            public var iconGlyph = TextStyleRef(.body, emphasized: true)
            /// How far buttons and tappable cards shrink when pressed (1 = not
            /// at all). Ignored under Reduce Motion.
            public var pressedScale: CGFloat = 0.97
        }

        public struct Field: Sendable, Equatable {
            public var label = TextStyleRef(.subheadline, emphasized: true)
            public var text = TextStyleRef(.body)
            /// Helper and error messages under the field.
            public var message = TextStyleRef(.footnote)
        }

        public struct Row: Sendable, Equatable {
            public var title = TextStyleRef(.body)
            public var subtitle = TextStyleRef(.subheadline)
            public var value = TextStyleRef(.body)
        }

        public struct SectionHeader: Sendable, Equatable {
            public var title = TextStyleRef(.headline)
            public var action = TextStyleRef(.subheadline, emphasized: true)
        }

        public struct Banner: Sendable, Equatable {
            public var title = TextStyleRef(.subheadline, emphasized: true)
            public var message = TextStyleRef(.subheadline)
            public var action = TextStyleRef(.subheadline, emphasized: true)
        }

        public struct Tag: Sendable, Equatable {
            public var label = TextStyleRef(.caption1, emphasized: true)
            public var countBadge = TextStyleRef(.caption2, emphasized: true)
        }

        public struct Selection: Sendable, Equatable {
            /// Chip labels.
            public var chip = TextStyleRef(.subheadline, emphasized: true)
            /// Segmented control labels.
            public var segment = TextStyleRef(.subheadline, emphasized: true)
        }

        public struct Feedback: Sendable, Equatable {
            public var toast = TextStyleRef(.subheadline)
            /// Full-screen empty, error and offline states.
            public var stateTitle = TextStyleRef(.title3, emphasized: true)
            public var stateMessage = TextStyleRef(.body)
            /// Inline (card) empty states.
            public var inlineStateTitle = TextStyleRef(.headline)
            public var inlineStateMessage = TextStyleRef(.subheadline)
            /// "Step 2 of 4".
            public var stepLabel = TextStyleRef(.footnote, emphasized: true)
        }

        public struct Icon: Sendable, Equatable {
            /// Outline or filled SF Symbols, to match the project's icon set.
            public var symbolStyle: SymbolStyle = .outline
            /// Brand (asset) icon size relative to its text role's font size.
            /// 1.2 matches an SF Symbol at the same text style.
            public var assetScale: CGFloat = 1.2
        }

        /// SF Symbol drawing style.
        public enum SymbolStyle: Sendable, Equatable {
            case outline, filled
        }

        public var button = Button()
        public var icon = Icon()
        public var field = Field()
        public var row = Row()
        public var sectionHeader = SectionHeader()
        public var banner = Banner()
        public var tag = Tag()
        public var selection = Selection()
        public var feedback = Feedback()

        public init() {}

        /// The standard component look.
        public static let standard = ComponentTokens()
    }
}

public extension View {
    /// Applies a text role referenced from the component tokens.
    func textRole(_ style: DesignSystem.TextStyleRef) -> some View {
        textRole(style.role, emphasized: style.emphasized)
    }
}
