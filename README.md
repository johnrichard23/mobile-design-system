# DesignSystem

A SwiftUI design system for iOS 17+ apps. It is project-neutral: every app
brings its own Figma design as a theme, and the shared components take on
that design without being copied or forked. The rules behind it come from
Apple's Human Interface Guidelines and the four principles of *The
Non-Designer's Design Book* (proximity, alignment, repetition, contrast);
they are written out at the top of `Sources/DesignSystem/Foundations/DesignSystem.swift`.

No third-party dependencies.

## Adopting it in a project

1. **Add the package as a dependency, pinned to a version**, and
   `import DesignSystem`. In Xcode: File › Add Package Dependencies › the
   repository URL › "Up to Next Major Version" from the latest tag. In
   `Package.swift`:

   ```swift
   .package(url: "<repository URL>", from: "0.1.0")
   // and in the target: .product(name: "DesignSystem", package: "mobile-design-system")
   ```

   Before the repository has a remote, use a local path while developing:
   `.package(path: "../mobile-design-system")`.
2. **Write the theme from the Figma file.** Map each Figma style to the role
   it plays, not to its name. Override only what differs from the defaults.

   ```swift
   extension DesignSystem.Theme {
       static let brand = DesignSystem.Theme(
           accent: DesignSystem.color(light: 0x0F766E, dark: 0x2DD4BF),
           accentPressed: DesignSystem.color(light: 0x0B5953, dark: 0x5EEAD4),
           onAccent: .white,
           background: .Brand.background,          // or asset catalog colours
           // … the other colour roles …
           typeface: .init(text: .init(regular: "BrandSans-Regular",
                                       semibold: "BrandSans-SemiBold",
                                       bold: "BrandSans-Bold")),
           typography: .apple.with { $0.body = .init(size: 16, lineHeight: 24) },
           spacing: .standard.with { $0.cardPadding = 20 },
           radius: .standard.with { $0.button = 26 },
           size: .standard.with { $0.buttonHeight = 52 },
           components: .standard.with { $0.button.label = .init(.callout, emphasized: true) }
       )
   }
   ```
3. **Set it once** at the app root: `ContentView().theme(.brand)`.
4. **Fonts:** list the font files under `UIAppFonts` in Info.plist, or call
   `DesignSystem.registerFonts(_:in:)` at launch. One file per weight.
5. **Screens read from the theme only:** `@Environment(\.theme) var theme`,
   then `theme.spacing.md`, `theme.labelSecondary`, `.textRole(.headline)`,
   `.card()`, `.screenMargins()`. No hex, no raw numbers, no `.font(.system(size:))`.

### Mapping a Figma file

| Figma | Theme |
|---|---|
| Colour styles / variables (light and dark modes) | The 15 colour roles, via `DesignSystem.color(light:dark:)` or asset colours |
| Text styles | `typography` (size, line height, letter spacing, weights) for the 11 roles |
| Font family | `typeface.text`, and optionally `typeface.display` for titles |
| Spacing variables | `spacing` (scale and the named gaps) |
| Corner radii | `radius` (tag, control, field, button, card, chip) |
| Component heights, border width | `size` |
| Drop shadow | `elevation` |
| Per-component text styles ("Button label: Callout Semibold") | `components` |
| Icon set (exported as template images) | `DSIcon.Source.asset(…)`, named once in an extension; outline/filled via `components.icon` |
| Haptics on or off | `hapticsEnabled` |

### What a theme can't change

Apple requires these whatever the design says, so they are constants, not
tokens: a 44 × 44 pt hit area (a smaller button keeps its look and gets an
invisible larger hit area), text that scales with Dynamic Type, 11 pt as the
smallest text, fields at least 44 pt tall, and continuous corners. If a
Figma file breaks one, keep the floor and raise it with the designer.

## Extending without forking

Go down this list and stop at the first level that does the job.

1. **Tokens.** Different colour, size, radius, spacing or type scale: change
   the theme.
2. **Component tokens.** A component uses a different text style or press
   feedback: change `theme.components`.
3. **New variants.** Button kinds, banner kinds, tag tones and toast kinds
   are open. Add one as a static member, defined from the theme:

   ```swift
   extension DesignSystem.ButtonKind {
       static let social = DesignSystem.ButtonKind { theme in
           .init(fill: theme.surface, pressedFill: theme.surfacePressed,
                 foreground: theme.labelPrimary, border: theme.labelPrimary)
       }
   }
   Button("Continue with Apple", systemImage: "apple.logo") {}.buttonStyle(.ds(.social))
   ```
4. **New components from the building blocks.** `DSFieldLayout` and
   `DSFieldAccessoryStyle` let a project build its own field (phone number,
   dropdown, amount) that matches the others in focus, error, read-only,
   VoiceOver and Dynamic Type behaviour. `.card()`, `DSRow`, `DSFlowLayout`,
   `.textRole(_:)` and the theme cover most layouts.
5. **A project-only component.** Write it in the app, reading only from the
   theme, and follow the checklist below. If a second project needs it,
   move it into this package.

Don't copy a component into an app to change it. If the change is generally
useful, change it here; if it's project-specific, one of the levels above
covers it.

## Components

| | |
|---|---|
| Buttons | `.buttonStyle(.ds(.primary))` (primary, secondary, plain, destructive, or your own), `.dsIcon()`, `DSCloseButton`, `.dsCard()` |
| Fields | `DSTextField`, `DSSecureField`, `DSFieldLayout` |
| Lists | `DSRow`, `DSRowIcon`, `DSRowValue`, `DSSectionHeader`, `.dsList()`, `.dsListRows()` |
| Selection | `.toggleStyle(.dsChip)`, `DSFlowLayout`, `DSSegmentedControl` |
| Status | `DSBanner`, `DSTag`, `DSCountBadge`, `DSStepIndicator` |
| States | `DSStateView` (empty, error, offline; inline or full screen), `.dsLoading(_:)`, `DSSkeletonCard` |
| Feedback | `.dsToast(_:)` |
| People and media | `DSAvatar`, `DSAvatarStack`, `DSRemoteImage` |
| Sheets | `.dsSheetToolbar(…)` |
| Screen actions | `.dsBottomBar { … }` |
| Foundations | `DSIcon` (SF Symbols or brand icons), `.dsHaptic(_:trigger:)`, `.dsMaterial(_:)`, `DesignSystem.Motion` |

How screens behave (navigation, forms, destructive actions, states,
feedback, permissions, keyboard, writing) is in [PATTERNS.md](PATTERNS.md),
with reference screens in the catalog.

For everything else use the system control (navigation bar, tab bar, alert,
confirmation dialog, menu, picker, toggle, search, progress); it already
follows the theme's tint.

## Checklist for a new component

- Reads every visual value from the theme; nothing hard-coded.
- Works in light, dark and Increase Contrast.
- Works from the smallest text size to AX5; side-by-side content stacks at
  accessibility sizes.
- Every tappable part has a 44 × 44 pt hit area.
- VoiceOver: a label, the right traits, decorative images hidden, one
  element where the content is one thing.
- Status is never colour alone.
- Respects Reduce Motion.
- Has a catalog page.

## Versions and changes

One shared repository, so a fix or improvement made here reaches every app
when it moves to the new version. Apps pin a version and update on purpose.

- Versions are `MAJOR.MINOR.PATCH` git tags.
  - **Patch:** a fix, nothing in the public API changes.
  - **Minor:** something new (a component, a token with a default), backwards
    compatible. A new token must have a default, so existing themes still work.
  - **Major:** something an app has to change (a renamed or removed API, or a
    default that changes how existing screens look).
- Every release is listed in `CHANGELOG.md`, with what an app must do for a
  major one.
- Changes go in this repository, not in a project's copy. A project-only need
  is met with its theme or an extension (see above), not an edit here.
- Before tagging: the package builds for iOS, every catalog page was checked
  in light, dark and the largest text size, and the catalog dump
  (`-dump-a11y`) reads correctly for anything touched.
- The repository must stay project-neutral: no project names, brand fonts or
  project copy in code, comments or sample data.

## Catalog

`Catalog/run.sh` builds a small app with a page per component and launches it
on the booted simulator. `Catalog/run.sh buttons` opens one page;
`THEME=sample Catalog/run.sh` shows everything under a second, very
different theme, to prove components follow the theme. The `-dump-a11y`
launch argument writes what VoiceOver would read to the app's Documents
folder.
