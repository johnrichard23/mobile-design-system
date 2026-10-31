//
//  CatalogApp.swift
//
//  A small app that shows every design system component, for checking them
//  on a simulator or device in light, dark, every text size and with
//  accessibility settings on. Build and launch it with `Catalog/run.sh`.
//
//  Launch with `-page <name>` to open one page directly, e.g. `-page buttons`,
//  and with `-theme sample` to see every component under a different design.
//

import SwiftUI

@main
struct CatalogApp: App {
    private let theme: DesignSystem.Theme = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-theme"),
              index + 1 < arguments.count,
              arguments[index + 1] == "sample"
        else { return .system }
        return .figmaSample
    }()

    var body: some Scene {
        WindowGroup {
            CatalogRoot()
                .theme(theme)
                .task { AccessibilityDump.start() }
        }
    }
}

extension DesignSystem.Theme {
    /// Stands in for a real Figma file: its own colours, type scale, spacing,
    /// radii and sizes, all mapped onto the same roles. The compact button is
    /// 36 pt tall to show the 44-pt hit-area floor at work.
    static let figmaSample = DesignSystem.Theme(
        accent: DesignSystem.color(light: 0x0F766E, dark: 0x2DD4BF, lightHighContrast: 0x0B5953),
        accentPressed: DesignSystem.color(light: 0x0B5953, dark: 0x5EEAD4),
        onAccent: DesignSystem.color(light: 0xFFFFFF, dark: 0x042F2E),
        background: DesignSystem.color(light: 0xFAF7F2, dark: 0x14110F),
        surface: DesignSystem.color(light: 0xFFFFFF, dark: 0x221E1A),
        surfacePressed: DesignSystem.color(light: 0xEFEAE2, dark: 0x2E2924),
        labelPrimary: DesignSystem.color(light: 0x1C1917, dark: 0xF5F5F4),
        labelSecondary: DesignSystem.color(light: 0x57534E, dark: 0xA8A29E, lightHighContrast: 0x3F3B37),
        labelTertiary: DesignSystem.color(light: 0x8A847E, dark: 0x78716C),
        border: DesignSystem.color(light: 0xD6D3D1, dark: 0x44403C, lightHighContrast: 0x78716C),
        separator: DesignSystem.color(light: 0xE7E5E4, dark: 0x292524),
        success: DesignSystem.color(light: 0x15803D, dark: 0x4ADE80),
        warning: DesignSystem.color(light: 0xB45309, dark: 0xFBBF24),
        destructive: DesignSystem.color(light: 0xB91C1C, dark: 0xF87171),
        info: DesignSystem.color(light: 0x1D4ED8, dark: 0x60A5FA),
        typography: .apple.with {
            $0.title1 = .init(size: 30, lineHeight: 36, tracking: -0.4, weight: .semibold, emphasizedWeight: .bold)
            $0.title3 = .init(size: 22, lineHeight: 28, tracking: -0.2, weight: .semibold, emphasizedWeight: .bold)
            $0.headline = .init(size: 16, lineHeight: 24, weight: .semibold, emphasizedWeight: .bold)
            $0.body = .init(size: 16, lineHeight: 24)
            $0.subheadline = .init(size: 14, lineHeight: 20)
            $0.footnote = .init(size: 12, lineHeight: 16)
        },
        spacing: .standard.with {
            $0.screenMarginCompact = 20
            $0.cardPadding = 20
            $0.stackGap = 12
            $0.groupGap = 20
        },
        radius: .standard.with {
            $0.button = 26
            $0.field = 10
            $0.card = 20
        },
        size: .standard.with {
            $0.buttonHeight = 52
            $0.compactButtonHeight = 36
            $0.fieldHeight = 52
        },
        components: .standard.with {
            $0.button.label = .init(.callout, emphasized: true)
            $0.field.label = .init(.footnote, emphasized: true)
        }
    )
}

enum CatalogPage: String, CaseIterable, Identifiable, Hashable {
    case typography
    case colors
    case buttons
    case iconButtons = "icon-buttons"
    case fields
    case rows
    case headersAndCards = "headers-cards"
    case offline
    case error
    case inlineStates = "inline-states"
    case loading
    case toast
    case banners
    case tags
    case chips
    case avatars
    case segmented
    case images
    case sheet
    case extending
    case icons
    case materials
    case patternForm = "pattern-form"
    case patternDelete = "pattern-delete"
    case patternPermission = "pattern-permission"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .typography: "Typography"
        case .colors: "Colours"
        case .buttons: "Buttons"
        case .iconButtons: "Icon buttons"
        case .fields: "Text fields"
        case .rows: "Rows"
        case .headersAndCards: "Headers and cards"
        case .offline: "Offline state"
        case .error: "Error state"
        case .inlineStates: "Inline states"
        case .loading: "Loading"
        case .toast: "Toast"
        case .banners: "Banners"
        case .tags: "Tags and badges"
        case .chips: "Chips"
        case .avatars: "Avatars"
        case .segmented: "Segmented and progress"
        case .images: "Remote images"
        case .sheet: "Sheet"
        case .extending: "Extending"
        case .icons: "Icons"
        case .materials: "Materials and bottom bar"
        case .patternForm: "Pattern: form"
        case .patternDelete: "Pattern: delete"
        case .patternPermission: "Pattern: permission"
        }
    }
}

struct CatalogRoot: View {
    @State private var path: [CatalogPage] = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-page"),
              index + 1 < arguments.count,
              let page = CatalogPage(rawValue: arguments[index + 1])
        else { return [] }
        return [page]
    }()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(CatalogPage.allCases) { page in
                    NavigationLink(value: page) {
                        DSRow(page.title)
                    }
                }
                .dsListRows()
            }
            .dsList()
            .navigationTitle("Design System")
            .navigationDestination(for: CatalogPage.self) { page in
                CatalogPageView(page: page)
                    .navigationTitle(page.title)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct CatalogPageView: View {
    let page: CatalogPage
    @Environment(\.theme) private var theme

    var body: some View {
        switch page {
        case .typography: TypographyPage()
        case .colors: ColorsPage()
        case .buttons: ButtonsPage()
        case .iconButtons: IconButtonsPage()
        case .fields: FieldsPage()
        case .rows: RowsPage()
        case .headersAndCards: HeadersAndCardsPage()
        case .offline: DSStateView.offline {}.background(theme.background)
        case .error:
            DSStateView.error(message: "We couldn't load this trip. Try again in a moment.") {}
                .background(theme.background)
        case .inlineStates: InlineStatesPage()
        case .loading: LoadingPage()
        case .toast: ToastPage()
        case .banners: BannersPage()
        case .tags: TagsPage()
        case .chips: ChipsPage()
        case .avatars: AvatarsPage()
        case .segmented: SegmentedPage()
        case .images: ImagesPage()
        case .sheet: SheetPage()
        case .extending: ExtendingPage()
        case .icons: IconsPage()
        case .materials: MaterialsPage()
        case .patternForm: FormPatternPage()
        case .patternDelete: DeletePatternPage()
        case .patternPermission: PermissionPatternPage()
        }
    }
}

/// Scrolling page on the grouped background with screen margins.
struct CatalogScroll<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.groupGap) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .screenMargins()
            .padding(.vertical, theme.spacing.groupGap)
        }
        .background(theme.background)
    }
}

// MARK: - Foundations

struct TypographyPage: View {
    @Environment(\.theme) private var theme

    var body: some View {
        CatalogScroll {
            ForEach(DesignSystem.TextRole.allCases, id: \.self) { role in
                VStack(alignment: .leading, spacing: theme.spacing.tightGap) {
                    Text(String(describing: role)).textRole(role)
                    Text(String(describing: role) + " emphasized").textRole(role, emphasized: true)
                }
                .foregroundStyle(theme.labelPrimary)
            }
        }
    }
}

struct ColorsPage: View {
    @Environment(\.theme) private var theme

    private var swatches: [(String, Color)] {
        [
            ("accent", theme.accent), ("accentPressed", theme.accentPressed),
            ("onAccent", theme.onAccent), ("background", theme.background),
            ("surface", theme.surface), ("surfacePressed", theme.surfacePressed),
            ("labelPrimary", theme.labelPrimary), ("labelSecondary", theme.labelSecondary),
            ("labelTertiary", theme.labelTertiary), ("border", theme.border),
            ("separator", theme.separator), ("success", theme.success),
            ("warning", theme.warning), ("destructive", theme.destructive), ("info", theme.info),
        ]
    }

    var body: some View {
        CatalogScroll {
            ForEach(swatches, id: \.0) { name, color in
                HStack(spacing: theme.spacing.sm) {
                    DesignSystem.Radius.shape(theme.radius.control)
                        .fill(color)
                        .overlay {
                            DesignSystem.Radius.shape(theme.radius.control)
                                .strokeBorder(theme.separator, lineWidth: theme.size.borderWidth)
                        }
                        .frame(width: DesignSystem.minTapTarget, height: DesignSystem.minTapTarget)
                    Text(name).textRole(.body).foregroundStyle(theme.labelPrimary)
                }
            }
        }
    }
}

// MARK: - Components

/// Counts taps per button, shown on the page, so tests can check which taps
/// registered.
struct TapLog: View {
    let taps: [String: Int]
    @Environment(\.theme) private var theme

    var body: some View {
        Text(taps.isEmpty ? "Taps: none" : "Taps: " + taps.sorted { $0.key < $1.key }
            .map { "\($0.key) \($0.value)" }
            .joined(separator: ", "))
            .textRole(.footnote)
            .foregroundStyle(theme.labelSecondary)
    }
}

struct ButtonsPage: View {
    @Environment(\.theme) private var theme
    @State private var isSaving = false
    @State private var taps: [String: Int] = [:]

    var body: some View {
        CatalogScroll {
            TapLog(taps: taps)
            Button("Continue") { taps["Continue", default: 0] += 1 }.buttonStyle(.ds(.primary))
            Button("Save") {
                taps["Save", default: 0] += 1
                isSaving = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    isSaving = false
                }
            }
            .buttonStyle(.ds(.primary, isLoading: isSaving))
            Button("Saving") {}.buttonStyle(.ds(.primary, isLoading: true))
            Button("Add to trip", systemImage: "plus") {}.buttonStyle(.ds(.secondary))
            Button("Skip for now") {}.buttonStyle(.ds(.plain))
            Button("Delete trip") {}.buttonStyle(.ds(.destructive))
            Button("Unavailable") { taps["Unavailable", default: 0] += 1 }
                .buttonStyle(.ds(.primary))
                .disabled(true)
            Button("Unavailable") {}.buttonStyle(.ds(.secondary)).disabled(true)
            HStack(spacing: theme.spacing.sm) {
                Button("Decline") { taps["Decline", default: 0] += 1 }
                    .buttonStyle(.ds(.secondary, size: .regular))
                Button("Accept") { taps["Accept", default: 0] += 1 }
                    .buttonStyle(.ds(.primary, size: .regular))
            }
        }
    }
}

struct IconButtonsPage: View {
    @Environment(\.theme) private var theme
    @State private var taps: [String: Int] = [:]

    var body: some View {
        CatalogScroll {
            TapLog(taps: taps)
            HStack(spacing: theme.spacing.md) {
                Button("Share", systemImage: "square.and.arrow.up") { taps["Share", default: 0] += 1 }
                    .buttonStyle(.dsIcon())
                Button("Favourite", systemImage: "heart") { taps["Favourite", default: 0] += 1 }
                    .buttonStyle(.dsIcon(.filled))
                DSCloseButton { taps["Close", default: 0] += 1 }
                Button("More", systemImage: "ellipsis") { taps["More", default: 0] += 1 }
                    .buttonStyle(.dsIcon())
                    .disabled(true)
            }
        }
    }
}

struct FieldsPage: View {
    @State private var name = ""
    @State private var destination = "Siargao"
    @State private var email = "dana@"
    @State private var code = "RMR-4821"
    @State private var password = "hunter22"
    @FocusState private var nameFocused: Bool
    @FocusState private var destinationFocused: Bool
    @FocusState private var emailFocused: Bool
    @FocusState private var codeFocused: Bool
    @FocusState private var passwordFocused: Bool

    var body: some View {
        CatalogScroll {
            DSTextField(
                "Trip name",
                placeholder: "e.g. Siargao with the barkada",
                text: $name,
                isFocused: $nameFocused,
                helperMessage: "Everyone in the trip sees this."
            )
            DSTextField("Destination", text: $destination, isFocused: $destinationFocused)
            DSTextField(
                "Email",
                text: $email,
                isFocused: $emailFocused,
                errorMessage: "Enter a full email address, like name@example.com.",
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: .never,
                autocorrectionDisabled: true
            )
            DSTextField("Invite code", text: $code, isFocused: $codeFocused, isReadOnly: true)
            DSSecureField(
                "Password",
                text: $password,
                isFocused: $passwordFocused,
                helperMessage: "At least 8 characters.",
                textContentType: .newPassword
            )
        }
    }
}

struct RowsPage: View {
    @State private var sharesLocation = true

    var body: some View {
        List {
            Section {
                NavigationLink(value: CatalogPage.typography) {
                    DSRow("Currency", systemImage: "pesosign.circle") { DSRowValue("PHP") }
                }
                Toggle(isOn: $sharesLocation) {
                    DSRow(
                        "Share my location",
                        subtitle: "Only with people in this trip",
                        systemImage: "location.fill"
                    )
                }
                DSRow("Dana Cruz", subtitle: "Owes you ₱1,250")
                DSRow("Notifications") { DSRowValue("On") }
            } header: {
                DSSectionHeader("Trip settings")
            }
            .dsListRows()
        }
        .dsList()
    }
}

struct HeadersAndCardsPage: View {
    @Environment(\.theme) private var theme

    var body: some View {
        // Proximity: a header sits 8 from its own cards, sections sit 32 apart.
        CatalogScroll {
            VStack(alignment: .leading, spacing: theme.spacing.sectionGap) {
                VStack(alignment: .leading, spacing: theme.spacing.stackGap) {
                    DSSectionHeader("Upcoming trips", actionTitle: "See all") {}
                    Button {} label: {
                        VStack(alignment: .leading, spacing: theme.spacing.tightGap) {
                            Text("Siargao, 12–18 March").textRole(.headline)
                            Text("6 travellers · ₱42,300 spent")
                                .textRole(.subheadline)
                                .foregroundStyle(theme.labelSecondary)
                        }
                    }
                    .buttonStyle(.dsCard())
                    VStack(alignment: .leading, spacing: theme.spacing.tightGap) {
                        Text("Outlined card").textRole(.headline).foregroundStyle(theme.labelPrimary)
                        Text("1-pt theme border.")
                            .textRole(.subheadline)
                            .foregroundStyle(theme.labelSecondary)
                    }
                    .card(fill: theme.background, outlined: true)
                }
                VStack(alignment: .leading, spacing: theme.spacing.stackGap) {
                    DSSectionHeader("Balances")
                    VStack(alignment: .leading, spacing: theme.spacing.tightGap) {
                        Text("You're owed ₱3,450").textRole(.headline).foregroundStyle(theme.labelPrimary)
                        Text("From 3 people").textRole(.subheadline).foregroundStyle(theme.labelSecondary)
                    }
                    .card()
                }
            }
        }
    }
}

struct InlineStatesPage: View {
    var body: some View {
        CatalogScroll {
            DSStateView(
                "No expenses yet",
                message: "Add the first one and it's split for everyone.",
                systemImage: "receipt",
                placement: .inline,
                actionTitle: "Add expense",
                action: {}
            )
            DSStateView(
                "You're all settled",
                message: "Nobody owes anything on this trip.",
                systemImage: "checkmark.circle",
                placement: .inline
            )
        }
    }
}

struct LoadingPage: View {
    var body: some View {
        CatalogScroll {
            DSSkeletonCard()
            DSSkeletonCard(lines: 3)
            DSRow("Dana Cruz", subtitle: "Owes you ₱1,250", systemImage: "person.circle")
                .card()
                .dsLoading(true)
        }
    }
}

struct ToastPage: View {
    @State private var toast: DSToast?

    var body: some View {
        CatalogScroll {
            Button("Show success") { toast = .success("Expense added. Everyone's share is updated.") }
                .buttonStyle(.ds(.secondary))
            Button("Show error") { toast = .error("Couldn't save. Check your connection and try again.") }
                .buttonStyle(.ds(.secondary))
            Button("Show info") { toast = .info("Dana joined the trip") }
                .buttonStyle(.ds(.secondary))
        }
        .dsToast($toast)
        .task {
            // Show one straight away so a screenshot catches it.
            try? await Task.sleep(for: .milliseconds(600))
            toast = .success("Expense added. Everyone's share is updated.")
        }
    }
}
