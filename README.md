# DesignSystem

Ready-made SwiftUI building blocks for iOS apps (iOS 17+, no dependencies):
buttons, fields, lists, banners, toasts, loading and empty states, and more.
They already follow Apple's Human Interface Guidelines: Dynamic Type, dark
mode, VoiceOver, large tap targets, Reduce Motion.

**One idea to remember:** every colour, font size, spacing, corner radius and
component size comes from a **theme**. You write the theme once from your
project's Figma file, set it at the top of the app, and every component picks
it up. You never restyle a component on a screen.

- [Quick start](#quick-start)
- [Build a screen](#build-a-screen)
- [Match your Figma file](#match-your-figma-file)
- [Extend it for your project](#extend-it-for-your-project)
- [Component list](#component-list)
- [Rules for writing screens](#rules-for-writing-screens)
- [What you get for free, and what you still do](#what-you-get-for-free-and-what-you-still-do)
- [Try everything in the catalog](#try-everything-in-the-catalog)
- [Troubleshooting](#troubleshooting)
- [Versions](#versions)

How screens should behave (navigation, forms, deleting, empty and error
states, permissions, writing) is in [PATTERNS.md](PATTERNS.md).

---

## Quick start

**1. Add the package.** In Xcode: File › Add Package Dependencies › paste the
repository URL › "Up to Next Major Version" from the latest tag. Or in
`Package.swift`:

```swift
.package(url: "<repository URL>", from: "0.1.0")
// in your target:
.product(name: "DesignSystem", package: "mobile-design-system")
```

While developing before the repository is hosted, use a local path:
`.package(path: "../mobile-design-system")`.

**2. Set a theme once, at the top of the app.** Without any setup you already
get `DesignSystem.Theme.system` (iOS colours and San Francisco), so this works
on day one:

```swift
import DesignSystem

ContentView().theme(.system)
```

**3. Write your own theme** when you have the Figma colours. Only the 15
colours are required; everything else is optional and defaults to Apple's
values:

```swift
extension DesignSystem.Theme {
    static let brand = DesignSystem.Theme(
        // Colours: one (light, dark) pair per role, from your Figma colour styles.
        accent: DesignSystem.color(light: 0x0F766E, dark: 0x2DD4BF),
        accentPressed: DesignSystem.color(light: 0x0B5953, dark: 0x5EEAD4),
        onAccent: DesignSystem.color(light: 0xFFFFFF, dark: 0x042F2E),
        background: DesignSystem.color(light: 0xFAF7F2, dark: 0x14110F),
        surface: DesignSystem.color(light: 0xFFFFFF, dark: 0x221E1A),
        surfacePressed: DesignSystem.color(light: 0xEFEAE2, dark: 0x2E2924),
        labelPrimary: DesignSystem.color(light: 0x1C1917, dark: 0xF5F5F4),
        labelSecondary: DesignSystem.color(light: 0x57534E, dark: 0xA8A29E),
        labelTertiary: DesignSystem.color(light: 0x8A847E, dark: 0x78716C),
        border: DesignSystem.color(light: 0xD6D3D1, dark: 0x44403C),
        separator: DesignSystem.color(light: 0xE7E5E4, dark: 0x292524),
        success: DesignSystem.color(light: 0x15803D, dark: 0x4ADE80),
        warning: DesignSystem.color(light: 0xB45309, dark: 0xFBBF24),
        destructive: DesignSystem.color(light: 0xB91C1C, dark: 0xF87171),
        info: DesignSystem.color(light: 0x1D4ED8, dark: 0x60A5FA),

        // Everything below is optional. Leave a line out to keep Apple's default.
        typeface: .init(text: .init(
            regular: "BrandSans-Regular",
            semibold: "BrandSans-SemiBold",
            bold: "BrandSans-Bold"
        )),
        typography: .apple.with {
            $0.title1 = .init(size: 30, lineHeight: 36, weight: .semibold, emphasizedWeight: .bold)
            $0.body = .init(size: 16, lineHeight: 24)
            $0.largeTitle = .init(size: 34, lineHeight: 41, emphasizedWeight: .bold, design: .serif)
        },
        spacing: .standard.with { $0.cardPadding = 20 },
        radius: .standard.with { $0.button = 26; $0.card = 20 },
        size: .standard.with { $0.buttonHeight = 52 },
        components: .standard.with { $0.button.label = .init(.callout, emphasized: true) }
    )
}
```

**4. Set it at the root** (`.brand` is the theme above):

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .theme(.brand)   // set once, at the top of the app
        }
    }
}
```

That's it. Use components and the theme values in your screens.

---

## Build a screen

Read everything visual from the theme, with `@Environment(\.theme)`:

```swift
@Environment(\.theme) private var theme
// theme.spacing.md   theme.labelSecondary   theme.radius.card   theme.size.buttonHeight
```

### A form with a pinned Save button

```swift
struct AddExpenseScreen: View {
    @Environment(\.theme) private var theme
    @State private var title = ""
    @State private var amount = ""
    @FocusState private var titleFocused: Bool
    @FocusState private var amountFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.groupGap) {
                DSTextField("What was it for?", placeholder: "e.g. Dinner",
                            text: $title, isFocused: $titleFocused)
                    .submitLabel(.next)
                    .onSubmit { amountFocused = true }

                DSTextField("Amount", text: $amount, isFocused: $amountFocused,
                            helperMessage: "Split equally unless you change it later.",
                            keyboardType: .decimalPad)
            }
            .screenMargins()
            .padding(.vertical, theme.spacing.groupGap)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(theme.background)
        .dsBottomBar {
            Button("Save expense") { /* save */ }
                .buttonStyle(.ds(.primary))
        }
    }
}
```

What this shows:
- `DSTextField` has a label above the field, helper and error text, and
  handles focus. Move through fields with `.submitLabel(.next)` + `.onSubmit`.
- `.screenMargins()` gives the screen's side margin; `theme.spacing.groupGap`
  is the gap between groups of fields.
- `.dsBottomBar { … }` pins the main action above the home indicator and the
  keyboard. Put the one primary action there.
- `.buttonStyle(.ds(.primary))` is the button. Kinds: `.primary`,
  `.secondary`, `.plain`, `.destructive`. One `.primary` per screen.

### A settings or list screen

```swift
struct SettingsScreen: View {
    @State private var sharesLocation = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        Text("Language")
                    } label: {
                        DSRow("Language", systemImage: "globe") { DSRowValue("English") }
                    }
                    Toggle(isOn: $sharesLocation) {
                        DSRow("Share my location", subtitle: "Only with people in this trip",
                              systemImage: "location.fill")
                    }
                } header: {
                    DSSectionHeader("Trip settings")
                }
                .dsListRows()
            }
            .dsList()
            .navigationTitle("Settings")
        }
    }
}
```

What this shows:
- `DSRow` is the one row: title, optional subtitle, optional leading icon
  (`systemImage:`), optional trailing content (a value, a checkmark).
- A row with a switch is a `Toggle` whose label is the row, so VoiceOver says
  "switch, on" and a tap anywhere on the row flips it.
- `.dsList()` and `.dsListRows()` apply the theme's background, row colour and
  separators to a `List`. Without them a list stays system grey.
- `NavigationLink` adds the chevron; don't add your own.

### Loading, empty, error and offline

Design all four for every screen that loads data:

```swift
enum LoadState {
    case loading
    case loaded([String])
    case failed(String)
    case offline
}

struct TripsScreen: View {
    @Environment(\.theme) private var theme
    @State private var state = LoadState.loading

    var body: some View {
        ScrollView {
            switch state {
            case .loading:
                // The real layout with sample data, redacted and shimmering.
                VStack(spacing: theme.spacing.groupGap) {
                    DSSkeletonCard()
                    DSSkeletonCard()
                }
                .screenMargins()
            case let .loaded(trips) where trips.isEmpty:
                DSStateView("No trips yet", message: "Create one to start planning.",
                            systemImage: "suitcase", actionTitle: "New trip", action: { /* create */ })
            case let .loaded(trips):
                VStack(spacing: theme.spacing.groupGap) {
                    ForEach(trips, id: \.self) { Text($0).card() }
                }
                .screenMargins()
            case let .failed(message):
                DSStateView.error(message: message) { /* reload */ }
            case .offline:
                DSStateView.offline { /* reload */ }
            }
        }
        .background(theme.background)
    }
}
```

- `.dsLoading(true)` turns any layout into a placeholder; `DSSkeletonCard` is
  a ready-made one.
- `DSStateView` has two placements: full screen (`placement: .fullScreen`,
  the default, centred) and inside a card (`placement: .inline`).

### A toast with Undo, and a red swipe action

```swift
struct ExpensesScreen: View {
    @Environment(\.theme) private var theme
    @State private var items = ["Dinner", "Boat tour", "Groceries"]
    @State private var toast: DSToast?

    var body: some View {
        List {
            ForEach(items, id: \.self) { item in
                DSRow(item)
                    .swipeActions {
                        Button("Delete", role: .destructive) { delete(item) }
                            .tint(theme.destructive)   // keeps the swipe red
                    }
            }
            .dsListRows()
        }
        .dsList()
        .dsToast($toast)
    }

    private func delete(_ item: String) {
        guard let index = items.firstIndex(of: item) else { return }
        items.remove(at: index)
        toast = DSToast("Deleted \u{201C}\(item)\u{201D}.", action: .init("Undo") {
            items.insert(item, at: min(index, items.count))
        })
    }
}
```

`DSToast` shows one message at a time, closes itself, and can be swiped up to
dismiss. Use `.success`, `.error` or `.info`. For something easy to reverse,
do it at once and offer Undo; for something that can't be undone, ask first
with a confirmation dialog (see [PATTERNS.md](PATTERNS.md)).

### A sheet

```swift
struct HomeScreen: View {
    @State private var showsAdd = false

    var body: some View {
        NavigationStack {
            Button("Add expense") { showsAdd = true }
                .buttonStyle(.ds(.primary))
                .padding()
                .sheet(isPresented: $showsAdd) {
                    NavigationStack {
                        AddExpenseScreen()
                            .dsSheetToolbar("Add expense", cancel: { showsAdd = false },
                                            confirmTitle: "Save") { showsAdd = false }
                    }
                }
        }
    }
}
```

`.dsSheetToolbar` gives the system look: title in the middle, Cancel on the
left, Save on the right (and it can be disabled with `isConfirmEnabled:`).

### Chips (filters)

```swift
struct SportFilter: View {
    @Environment(\.theme) private var theme
    @State private var selected: Set<String> = ["Padel"]
    private let sports = ["Padel", "Tennis", "Squash", "Badminton"]

    var body: some View {
        DSFlowLayout(spacing: theme.spacing.xs) {
            ForEach(sports, id: \.self) { sport in
                Toggle(sport, isOn: Binding(
                    get: { selected.contains(sport) },
                    set: { isOn in
                        if isOn { selected.insert(sport) } else { selected.remove(sport) }
                    }
                ))
                .toggleStyle(.dsChip)
            }
        }
    }
}
```

### Icons

```swift
extension DSIcon.Source {
    // Name each brand icon once; screens never type asset strings.
    static let luggage = DSIcon.Source.asset("icons/luggage")
    static let seat = DSIcon.Source.asset("icons/seat")
}

struct IconExamples: View {
    var body: some View {
        HStack {
            DSIcon(.system("heart"), role: .body)                  // SF Symbol
            DSIcon(.luggage, role: .title3)                        // brand icon
            DSIcon(.system("bell"), role: .body, label: "Alerts")  // spoken by VoiceOver
        }
    }
}
```

An icon is sized by the text style next to it, so it grows with Dynamic Type
and takes the surrounding text colour. Use one icon family per screen. Icons
that carry meaning on their own need a `label:`. For icon-only buttons use
`Button("Share", systemImage: "square.and.arrow.up") {}` with
`.buttonStyle(.dsIcon())` so VoiceOver has a name.

---

## Match your Figma file

Map each Figma style to the role it plays, not to its name ("Body/M" becomes
`body`; "Surface/Raised" becomes `surface`). Override only what differs from
the defaults.

| In Figma | In the theme |
|---|---|
| Colour styles or variables (light and dark modes) | The 15 colour roles, with `DesignSystem.color(light:dark:)` or colours from your asset catalog |
| Text styles (size, line height, letter spacing, weight) | `typography`: one entry for each of the 11 text roles |
| Font family | `typeface.text`; optionally `typeface.display` for titles |
| Spacing variables | `spacing`: the scale, screen margins, the named gaps, card padding |
| Corner radii | `radius`: tag, control, field, button, card, chip |
| Component heights, border width, icon sizes | `size` |
| Drop shadow | `elevation` |
| "Button label uses Callout Semibold" and similar | `components` |
| Icon set exported as template images | name them in an extension (see Icons above); outline or filled via `components.icon` |
| Haptics on or off | `hapticsEnabled` |

The 11 text roles are Apple's: `largeTitle`, `title1`, `title2`, `title3`,
`headline`, `body`, `callout`, `subheadline`, `footnote`, `caption1`,
`caption2`. Use them with `.textRole(.headline)` (add `emphasized: true` for
the heavier weight).

**Fonts.** Add the font files to the app and list them under `UIAppFonts` in
Info.plist (or call `DesignSystem.registerFonts(_:in:)` at launch). You need
**one file per weight** (regular, semibold, bold), because asking for bold on
a single regular file does nothing. Use the font's PostScript name in
`typeface`.

### What a theme can't change

Apple requires these whatever the design says, so they are fixed:

- tappable things have at least a **44 × 44 pt** hit area (a button designed
  36 pt tall keeps its look and gets an invisible bigger tap area)
- text **scales with Dynamic Type**
- the smallest text is **11 pt**
- fields are at least **44 pt** tall
- corners are **continuous** (Apple's smooth rounding)

If a Figma file breaks one of these, the code keeps the minimum; raise it with
the designer.

---

## Extend it for your project

Go down this list and stop at the first level that does the job. Don't copy a
component into your app to change it.

1. **Tokens.** A different colour, size, radius, spacing or type scale: change
   the theme.
2. **Component tokens.** A component uses a different text style or press
   feedback: change `theme.components`.
3. **New variants.** Button kinds, banner kinds, tag tones and toast kinds are
   open lists. Add one, defined from your theme:

```swift
extension DesignSystem.ButtonKind {
    /// A button kind only this project needs, defined from its theme.
    static let outlineAccent = DesignSystem.ButtonKind { theme in
        .init(fill: .clear, pressedFill: theme.surfacePressed,
              foreground: theme.accent, border: theme.accent)
    }
}

extension DSBanner.Kind {
    static let promo = DSBanner.Kind(name: "Offer", systemImage: "tag.fill") { $0.accent }
}

extension DSTag.Tone {
    static let premium = DSTag.Tone { $0.warning }
}

struct Examples: View {
    var body: some View {
        VStack {
            Button("Learn more") {}.buttonStyle(.ds(.outlineAccent))
            DSBanner("Members save 20% this week.", kind: .promo, title: "Weekend offer")
            DSTag("Members only", systemImage: "crown.fill", tone: .premium)
        }
    }
}
```

4. **A new kind of field** built on the shared layout, so it behaves like the
   others (focus, error, read-only, VoiceOver, big text):

```swift
struct AmountField: View {
    @Binding var amount: String
    @FocusState private var isFocused: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        DSFieldLayout(label: "Amount", isFocused: isFocused) {
            HStack(spacing: theme.spacing.xs) {
                Text("$").foregroundStyle(theme.labelSecondary)
                TextField("0.00", text: $amount)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .accessibilityLabel("Amount")   // the visible label is hidden from VoiceOver
            }
        } trailing: {
            EmptyView()
        }
    }
}
```

5. **A component only your project needs.** Write it in your app, reading only
   from the theme, and follow the checklist below. If a second project needs
   it, move it into this package.

If you think a component should change for everyone, change it in this
repository and release a new version (see [Versions](#versions)).

### Checklist for a new component

- Reads every visual value from the theme; nothing hard-coded.
- Works in light, dark and Increase Contrast.
- Works from the smallest text size to the largest; side-by-side content
  stacks at accessibility sizes.
- Every tappable part has a 44 × 44 pt hit area.
- VoiceOver: a label, the right traits, decorative images hidden, one element
  where the content is one thing.
- Status is never colour alone (add an icon or text).
- Respects Reduce Motion.
- Has a page in the catalog.

---

## Component list

| Need | Use |
|---|---|
| Buttons | `.buttonStyle(.ds(.primary))` (also `.secondary`, `.plain`, `.destructive`, or your own); `size: .regular` for inline; `isLoading:` shows a spinner and blocks double taps |
| Icon-only button | `Button("Share", systemImage: "square.and.arrow.up") {}.buttonStyle(.dsIcon())`; `DSCloseButton` |
| Tappable card | `Button { … } label: { … }.buttonStyle(.dsCard())` |
| Plain card | `.card()` (add `outlined: true` for a border) |
| Text field, password field | `DSTextField`, `DSSecureField` (`textContentType: .newPassword` on sign-up) |
| Your own field | `DSFieldLayout` |
| List row, header | `DSRow`, `DSRowIcon`, `DSRowValue`, `DSSectionHeader`, `.dsList()`, `.dsListRows()` |
| Filter chips | `.toggleStyle(.dsChip)` inside `DSFlowLayout` |
| Choose one of a few | `DSSegmentedControl` (or the system segmented `Picker` when its look is fine) |
| Message on a screen | `DSBanner` (`.info`, `.success`, `.warning`, `.error`; optional title, action, dismiss) |
| Status label, count | `DSTag`, `DSCountBadge` |
| Steps in a flow | `DSStepIndicator` |
| Empty, error, offline | `DSStateView`, `DSStateView.error(…)`, `DSStateView.offline(…)` |
| Loading | `.dsLoading(true)`, `DSSkeletonCard` |
| Short confirmation | `.dsToast($toast)` with `DSToast.success / .error / .info` |
| People, images | `DSAvatar`, `DSAvatarStack` (with `DSPerson`), `DSRemoteImage` |
| Sheets | `.dsSheetToolbar(…)` |
| Pinned actions | `.dsBottomBar { … }` |
| Text | `.textRole(.body)`; icons `DSIcon` |
| Margins, width | `.screenMargins()`, `.readableWidth()` |
| Haptics, materials | `.dsHaptic(.success, trigger: …)`, `.dsMaterial(.regular)` |

For anything else, use the system control (navigation bar, tab bar, alert,
confirmation dialog, menu, picker, toggle, search, `ProgressView`). They
already follow the theme's tint.

---

## Rules for writing screens

Do:
- Read values from the theme. `theme.spacing.md`, not `16`.
- Use `.textRole(…)` for every piece of text.
- Use one `.primary` button per screen.
- Group related things closely and separate groups clearly: 4 pt inside one
  item, 8 between items, 16 between groups, 32 between sections.
- Keep text leading-aligned; centre only short standalone content (empty
  states, onboarding).
- Test every screen at the largest text size and in dark mode.

Don't:
- No hex colours or `Color("name")` in screens, and no
  `.font(.system(size: …))`. Colours come from the theme, text from roles.
- Don't cap text size with `.dynamicTypeSize(…)`.
- Don't rebuild a system control (navigation bar, sheet header, search bar).
- Don't colour-code status without an icon or text.

---

## What you get for free, and what you still do

**Free:** light and dark colours; Increase Contrast; text from the smallest
size to the largest (rows, headers and segmented controls re-stack
automatically); Bold Text; Reduce Motion (no shimmer, no slide, no press
shrink); Reduce Transparency (materials turn solid); VoiceOver names and
traits for the components (toasts and field errors are also announced); 44 pt
hit areas.

**Still on you:**
- Give every image a description with `accessibilityLabel`, or leave it
  decorative.
- Give icon-only controls a name (use the `Button("Name", systemImage:)` form).
- Write good copy: say what a button does ("Save expense"), and what to do
  when something fails.
- Check a screen with the largest text size and VoiceOver before shipping.

---

## Try everything in the catalog

The `Catalog` folder is a small app with a page per component and reference
screens for the patterns. With a simulator booted:

```bash
Catalog/run.sh                  # the list of pages
Catalog/run.sh buttons          # open one page
THEME=sample Catalog/run.sh     # everything under a second, very different theme
```

Pages: `typography`, `colors`, `buttons`, `icon-buttons`, `fields`, `rows`,
`headers-cards`, `offline`, `error`, `inline-states`, `loading`, `toast`,
`banners`, `tags`, `chips`, `avatars`, `segmented`, `images`, `sheet`,
`extending`, `icons`, `materials`, `pattern-form`, `pattern-delete`,
`pattern-permission`.

The `-dump-a11y` launch argument writes what VoiceOver would read to the app's
Documents folder, since the simulator can't run VoiceOver.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Everything is system blue and grey | The theme isn't set. Add `.theme(.brand)` once at the app root. |
| A `List` has a grey background | Add `.dsList()` to the list and `.dsListRows()` to its sections. |
| A swipe "Delete" is the accent colour, not red | Add `.tint(theme.destructive)` to that button. |
| The brand font doesn't show | List the font files in `UIAppFonts`, use the PostScript name, and include a file for each weight. |
| Bold text looks the same as regular | Same cause: only one weight file was added. |
| A brand icon is blank | The asset name doesn't match, or it isn't a template image in the asset catalog. |
| A button looks too small | That's your Figma size. It's drawn at that size and still tappable at 44 pt. |
| A toast doesn't appear | Add `.dsToast($toast)` to a screen that is on screen, then set `toast = .success("…")`. |

---

## Versions

One shared repository, so a fix made here reaches every app when it updates.
Apps pin a version and update on purpose.

- Versions are `MAJOR.MINOR.PATCH` git tags.
  - **Patch:** a fix; nothing in the public API changes.
  - **Minor:** something new, backwards compatible. A new token must have a
    default so existing themes keep working.
  - **Major:** something an app has to change.
- Every release is listed in [CHANGELOG.md](CHANGELOG.md), with what an app
  must do for a major one.
- Before tagging: the package builds for iOS, every catalog page was checked in
  light, dark and the largest text size, and the VoiceOver dump (`-dump-a11y`)
  reads correctly for anything touched.
- The repository stays project-neutral: no project names, brand fonts or
  project copy in code, comments or sample data.
