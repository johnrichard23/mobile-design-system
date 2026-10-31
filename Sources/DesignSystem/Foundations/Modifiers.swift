//
//  Modifiers.swift
//
//  The view modifiers screens use to apply the theme: text roles, cards,
//  margins, readable width and the minimum hit area.
//

import SwiftUI

private struct TextRoleModifier: ViewModifier {
    let role: DesignSystem.TextRole
    let emphasized: Bool
    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.legibilityWeight) private var legibilityWeight

    func body(content: Content) -> some View {
        let spec = theme.typography[role]
        let family = theme.typeface.family(for: role)
        if family == nil, spec == DesignSystem.Typography.apple[role] {
            // Apple's own text style: exact system metrics, Bold Text included.
            content.font(.system(role.textStyle).weight(emphasized ? spec.emphasizedWeight : spec.weight))
        } else {
            let resolved = role.resolve(
                spec,
                family: family,
                emphasized: emphasized,
                boldText: legibilityWeight == .bold,
                dynamicTypeSize: dynamicTypeSize
            )
            if let tracking = resolved.tracking {
                content
                    .font(resolved.font)
                    .lineSpacing(resolved.lineSpacing)
                    .tracking(tracking)
            } else {
                content
                    .font(resolved.font)
                    .lineSpacing(resolved.lineSpacing)
            }
        }
    }
}

private struct CardModifier: ViewModifier {
    let fill: Color?
    let outlined: Bool
    let elevated: Bool
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        let shape = DesignSystem.Radius.shape(theme.radius.card)
        content
            .padding(theme.spacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill ?? theme.surface, in: shape)
            .overlay {
                if outlined {
                    shape.strokeBorder(theme.border, lineWidth: theme.size.borderWidth)
                }
            }
            .shadow(
                color: elevated ? theme.elevation.color : .clear,
                radius: theme.elevation.radius,
                y: theme.elevation.offsetY
            )
    }
}

private struct ScreenMarginModifier: ViewModifier {
    @Environment(\.theme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass

    func body(content: Content) -> some View {
        content.padding(.horizontal, theme.spacing.screenMargin(for: sizeClass))
    }
}

private struct ListThemeModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(theme.background)
    }
}

private struct ListRowsThemeModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .listRowBackground(theme.surface)
            .listRowSeparatorTint(theme.separator)
    }
}

private struct ReadableWidthModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: theme.size.readableWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
    }
}

public extension View {
    /// Sets the theme for this view tree and tints controls with its accent.
    func theme(_ theme: DesignSystem.Theme) -> some View {
        environment(\.theme, theme).tint(theme.accent)
    }

    /// Applies a text role from the theme's type scale and typeface.
    func textRole(_ role: DesignSystem.TextRole, emphasized: Bool = false) -> some View {
        modifier(TextRoleModifier(role: role, emphasized: emphasized))
    }

    /// Card container: the theme's card padding, card radius and surface
    /// (or `fill`), an optional theme border and the theme's elevation.
    func card(fill: Color? = nil, outlined: Bool = false, elevated: Bool = false) -> some View {
        modifier(CardModifier(fill: fill, outlined: outlined, elevated: elevated))
    }

    /// Grows the hit area to at least 44 × 44 without changing the visual size.
    func minTapTarget() -> some View {
        frame(minWidth: DesignSystem.minTapTarget, minHeight: DesignSystem.minTapTarget)
            .contentShape(Rectangle())
    }

    /// The theme's horizontal screen margin for the current size class.
    func screenMargins() -> some View {
        modifier(ScreenMarginModifier())
    }

    /// Themes a `List`: the theme's background behind it instead of the
    /// system grey. Pair with `.dsListRows()` on each `Section`.
    func dsList() -> some View {
        modifier(ListThemeModifier())
    }

    /// Themes the rows of a `List` section: surface fill and separator colour.
    /// Apply to a `Section` (or `ForEach`) inside a list styled with `.dsList()`.
    func dsListRows() -> some View {
        modifier(ListRowsThemeModifier())
    }

    /// Caps running text at the theme's readable width, centred on wide
    /// screens, with the text itself still leading-aligned.
    func readableWidth() -> some View {
        modifier(ReadableWidthModifier())
    }
}
