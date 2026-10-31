//
//  DesignSystem.swift
//
//  Shared foundations for our iOS apps, based on Apple's Human Interface
//  Guidelines and the four principles of The Non-Designer's Design Book
//  (proximity, alignment, repetition, contrast). Brand-neutral: each app
//  supplies a `DesignSystem.Theme` built from its own Figma file.
//
//  Adapting to a Figma file
//  - Every visual value is a token in the theme: colours, fonts, the type
//    scale (size, line height, letter spacing, weights per text style),
//    spacing, corner radii, component sizes, border width and shadow.
//  - The defaults are Apple's values. An app overrides only what its Figma
//    file says differently:
//      DesignSystem.Theme(
//          accent: DesignSystem.color(light: 0x0F766E, dark: 0x2DD4BF), ...,
//          typography: .apple.with { $0.body = .init(size: 16, lineHeight: 24) },
//          spacing: .standard.with { $0.cardPadding = 20 },
//          radius: .standard.with { $0.button = 28 }
//      )
//  - Map each Figma style to the role it plays, not to its name: Figma's
//    "Body/M" becomes `body`, "Surface/Raised" becomes `surface`. Components
//    then pick the design up without changes.
//  - Some things are not tokens, because Apple requires them whatever the
//    design says: a 44 × 44 pt hit area (a smaller button keeps its look and
//    gets an invisible larger hit area), text that scales with Dynamic Type,
//    11 pt as the smallest text size, and continuous corners. If a Figma
//    file breaks one of these, the code keeps the floor and the design
//    should be raised with the designer.
//
//  Proximity: related things sit together
//  - Space grows with distance in meaning, and each level doubles by
//    default: tight 4 (parts of one item: title + subtitle) → stack 8 (items
//    in a group) → group 16 → section 32. Never use the same gap inside a
//    group and between groups.
//  - Group before you add. If a screen has more than five separate visual
//    blocks, merge related ones into a card or a section.
//
//  Alignment: every element lines up with something
//  - Leading-aligned text on every screen. Center only short, standalone
//    content (empty states, onboarding, alerts) and never mix centered and
//    leading text in one block.
//  - One edge: text, icons and dividers share the screen margin and the
//    row's text inset. In one list section, either every row has an icon or
//    none does. Use `.leading`/`.trailing`, never left/right, so
//    right-to-left languages mirror correctly.
//  - Long text is capped at a readable width (`.readableWidth()`) on iPad.
//
//  Repetition: the same thing always looks the same
//  - Same role → same token, component and position on every screen
//    (titles, primary action, navigation, cards, rows).
//  - Components are built once from the theme; screens don't restyle them.
//
//  Contrast: if things are different, make them clearly different
//  - Pair text roles at least two steps apart in size (title3 + subheadline,
//    headline + footnote), or contrast weight and colour together
//    (headline / labelPrimary vs body / labelSecondary). Never pair
//    neighbours like body + callout.
//  - Emphasis jumps from regular to semibold or bold, never to medium.
//  - One primary action per screen. Only it uses the accent fill.
//  - Warm colours (destructive, warning, a warm accent) command attention:
//    keep them to small areas. Cool colours can cover larger areas.
//  - Text meets 4.5:1 against its background, large text and UI parts 3:1,
//    in light, dark and Increase Contrast.
//
//  Typography
//  - Concordant by default: one family for everything (San Francisco when
//    no brand font is set).
//  - A second family is allowed only for titles (`Typeface.display`) and
//    must clearly contrast with the text family in structure, e.g. a serif
//    or slab display face over a sans text face. Never two similar sans
//    faces, never two scripts. Three families: never.
//  - Each custom family supplies a font file per weight. `.weight()` on a
//    single static font file does nothing.
//
//  Accessibility
//  - Every layout works from xSmall to AX5. At accessibility sizes, rows
//    that sit side by side stack vertically
//    (`dynamicTypeSize.isAccessibilitySize`).
//  - Bold Text, Increase Contrast, Reduce Motion and Reduce Transparency are
//    respected: colours carry high-contrast variants, motion falls back to a
//    fade, materials fall back to a solid surface.
//  - Icon-only controls carry an accessibility label. Status is never shown
//    by colour alone; pair it with an icon or text.
//  - Icons are SF Symbols sized by the text role they sit next to, not by
//    a fixed frame, so they scale with Dynamic Type.
//
//  Theming
//  - Three tiers: brand palette (raw Figma colours) → semantic roles
//    (`Theme`, the only colours views use) → components.
//  - Views read everything from `@Environment(\.theme)`. No hex, no
//    `Color("…")` lookups, no raw numbers for spacing, radius or size.
//  - Every colour role has light and dark values (asset catalog colours, or
//    `DesignSystem.color(light:dark:)` from Figma hex). Don't set
//    `UIUserInterfaceStyle` in Info.plist and don't branch on `colorScheme`
//    in views.
//  - One brand = one `Theme` value. Pick it per build target (white-label)
//    or swap it at runtime; set it once at the root with `.theme(_:)`.
//  - The accent is the app's tint: primary actions, selection and links.
//
//  Layout
//  - Corners are always continuous. Pills are `Capsule()` or a radius of
//    half the height.
//  - Cards rely on fill, not shadow. Use the elevation only for content
//    that floats over other content.
//  - Bottom actions go in `.safeAreaInset(edge: .bottom)`.
//

import SwiftUI

/// Brand-neutral foundations and components shared by every app.
public enum DesignSystem {}

// MARK: - Preview

private struct DesignSystemPreview: View {
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.sectionGap) {
                VStack(alignment: .leading, spacing: theme.spacing.stackGap) {
                    ForEach(DesignSystem.TextRole.allCases, id: \.self) { role in
                        Text(String(describing: role))
                            .textRole(role)
                            .foregroundStyle(theme.labelPrimary)
                    }
                }

                VStack(alignment: .leading, spacing: theme.spacing.tightGap) {
                    Text("Card").textRole(.headline).foregroundStyle(theme.labelPrimary)
                    Text("Surface fill, continuous corners, no shadow.")
                        .textRole(.subheadline)
                        .foregroundStyle(theme.labelSecondary)
                }
                .card()

                VStack(alignment: .leading, spacing: theme.spacing.tightGap) {
                    Text("Outlined card").textRole(.headline).foregroundStyle(theme.labelPrimary)
                    Text("1-pt theme border.")
                        .textRole(.subheadline)
                        .foregroundStyle(theme.labelSecondary)
                }
                .card(fill: theme.background, outlined: true)
            }
            .screenMargins()
            .padding(.vertical, theme.spacing.xl)
        }
        .background(theme.background)
    }
}

#Preview("Light") {
    DesignSystemPreview().theme(.system)
}

#Preview("Dark") {
    DesignSystemPreview().theme(.system).preferredColorScheme(.dark)
}
