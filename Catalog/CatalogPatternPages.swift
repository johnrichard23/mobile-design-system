//
//  CatalogPatternPages.swift
//
//  Icons and materials, plus reference screens for the patterns in
//  PATTERNS.md: a form, delete with undo or confirm, and a permission request.
//

import SwiftUI

// MARK: - Icons

extension DSIcon.Source {
    /// A brand icon shipped with the catalog, standing in for a Figma icon set.
    static let brandBag = DSIcon.Source.asset("brand-bag")
}

struct IconsPage: View {
    @Environment(\.theme) private var theme

    var body: some View {
        CatalogScroll {
            DSSectionHeader("SF Symbols, sized by text role")
            HStack(alignment: .firstTextBaseline, spacing: theme.spacing.md) {
                ForEach([DesignSystem.TextRole.caption1, .footnote, .body, .title3, .title1], id: \.self) { role in
                    DSIcon(.system("suitcase"), role: role)
                }
            }
            .foregroundStyle(theme.accent)
            DSSectionHeader("Brand icon from the asset catalog, same sizes")
            HStack(alignment: .firstTextBaseline, spacing: theme.spacing.md) {
                ForEach([DesignSystem.TextRole.caption1, .footnote, .body, .title3, .title1], id: \.self) { role in
                    DSIcon(.brandBag, role: role)
                }
            }
            .foregroundStyle(theme.accent)
            DSSectionHeader("Next to text")
            HStack(spacing: theme.spacing.xs) {
                DSIcon(.brandBag, role: .body)
                Text("2 bags included").textRole(.body)
            }
            .foregroundStyle(theme.labelPrimary)
            HStack(spacing: theme.spacing.xs) {
                DSIcon(.system("bell"), role: .body, label: "Notifications on")
                Text("Reminders").textRole(.body)
            }
            .foregroundStyle(theme.labelPrimary)
        }
    }
}

// MARK: - Materials

struct MaterialsPage: View {
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.groupGap) {
                DSRemoteImage(url: URL(string: "https://picsum.photos/id/1015/1200/900"), accessibilityLabel: "River valley")
                    .frame(height: 320)
                    .clipShape(DesignSystem.Radius.shape(theme.radius.card))
                    .overlay(alignment: .bottomLeading) {
                        Text("Floating label on a photo")
                            .textRole(.subheadline, emphasized: true)
                            .foregroundStyle(theme.labelPrimary)
                            .padding(.horizontal, theme.spacing.sm)
                            .padding(.vertical, theme.spacing.xs)
                            .dsMaterial(.regular, in: Capsule())
                            .padding(theme.spacing.sm)
                    }
                ForEach(1...6, id: \.self) { index in
                    Text("Content row \(index) scrolls behind the bar")
                        .textRole(.body)
                        .foregroundStyle(theme.labelPrimary)
                        .card()
                }
            }
            .screenMargins()
            .padding(.vertical, theme.spacing.groupGap)
        }
        .background(theme.background)
        .dsBottomBar {
            Button("Book now") {}.buttonStyle(.ds(.primary))
        }
    }
}

// MARK: - Pattern: form

struct FormPatternPage: View {
    @Environment(\.theme) private var theme
    @State private var name = ""
    @State private var email = ""
    @State private var amount = ""
    @State private var touched: Set<String> = []
    @State private var submitted = false
    @State private var failedSubmits = 0
    @State private var toast: DSToast?
    @FocusState private var nameFocused: Bool
    @FocusState private var emailFocused: Bool
    @FocusState private var amountFocused: Bool

    private var nameError: String? {
        name.trimmingCharacters(in: .whitespaces).isEmpty ? "Enter a name for this expense." : nil
    }

    private var emailError: String? {
        email.contains("@") && email.contains(".") ? nil : "Enter a full email address, like name@example.com."
    }

    private var amountError: String? {
        Double(amount).map { $0 > 0 } == true ? nil : "Enter an amount above 0."
    }

    private func shown(_ error: String?, for field: String) -> String? {
        submitted || touched.contains(field) ? error : nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.groupGap) {
                DSTextField(
                    "What was it for?",
                    placeholder: "e.g. Dinner",
                    text: $name,
                    isFocused: $nameFocused,
                    errorMessage: shown(nameError, for: "name")
                )
                .submitLabel(.next)
                .onSubmit { emailFocused = true }

                DSTextField(
                    "Who paid? (email)",
                    text: $email,
                    isFocused: $emailFocused,
                    errorMessage: shown(emailError, for: "email"),
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    autocapitalization: .never,
                    autocorrectionDisabled: true
                )
                .submitLabel(.next)
                .onSubmit { amountFocused = true }

                DSTextField(
                    "Amount",
                    placeholder: "0.00",
                    text: $amount,
                    isFocused: $amountFocused,
                    helperMessage: "Split equally unless you change it later.",
                    errorMessage: shown(amountError, for: "amount"),
                    keyboardType: .decimalPad
                )
            }
            .screenMargins()
            .padding(.vertical, theme.spacing.groupGap)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(theme.background)
        // Validate a field when the user leaves it, never while typing.
        .onChange(of: nameFocused) { _, focused in if !focused { touched.insert("name") } }
        .onChange(of: emailFocused) { _, focused in if !focused { touched.insert("email") } }
        .onChange(of: amountFocused) { _, focused in if !focused { touched.insert("amount") } }
        .dsBottomBar {
            Button("Save expense", action: save).buttonStyle(.ds(.primary))
        }
        .dsHaptic(.error, trigger: failedSubmits)
        .dsToast($toast)
    }

    private func save() {
        submitted = true
        if nameError != nil {
            nameFocused = true
        } else if emailError != nil {
            emailFocused = true
        } else if amountError != nil {
            amountFocused = true
        } else {
            toast = .success("Expense saved.")
            return
        }
        failedSubmits += 1
    }
}

// MARK: - Pattern: delete

struct DeletePatternPage: View {
    @Environment(\.theme) private var theme
    @State private var items = ["Dinner at the pier", "Boat tour", "Island hopping", "Groceries"]
    @State private var toast: DSToast?
    @State private var confirmsDeleteAll = false

    var body: some View {
        List {
            Section {
                ForEach(items, id: \.self) { item in
                    DSRow(item, subtitle: "Swipe left to delete")
                        .swipeActions {
                            // The theme tints the whole app with its accent, which would
                            // also colour this destructive action; give it back its red.
                            Button("Delete", role: .destructive) { delete(item) }
                                .tint(theme.destructive)
                        }
                }
            } header: {
                DSSectionHeader("Undo for one item")
            }
            .dsListRows()
        }
        .dsList()
        .overlay {
            if items.isEmpty {
                DSStateView("No expenses", message: "Deleted expenses can't be recovered.", systemImage: "tray")
            }
        }
        .dsBottomBar {
            Button("Delete all") { confirmsDeleteAll = true }
                .buttonStyle(.ds(.destructive))
                .disabled(items.isEmpty)
        }
        .confirmationDialog(
            "Delete all \(items.count) expenses?",
            isPresented: $confirmsDeleteAll,
            titleVisibility: .visible
        ) {
            Button("Delete \(items.count) expenses", role: .destructive) { items.removeAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
        .dsToast($toast)
    }

    private func delete(_ item: String) {
        guard let index = items.firstIndex(of: item) else { return }
        withAnimation { _ = items.remove(at: index) }
        toast = DSToast("Deleted \u{201C}\(item)\u{201D}.", action: .init("Undo") {
            withAnimation { items.insert(item, at: min(index, items.count)) }
        })
    }
}

// MARK: - Pattern: permission

struct PermissionPatternPage: View {
    private enum Status { case notAsked, denied, granted }

    @Environment(\.theme) private var theme
    @State private var status = Status.notAsked

    var body: some View {
        switch status {
        case .notAsked:
            DSStateView(
                "Share your location with your group",
                message: "Your group sees where you are during the trip, so it's easy to meet up. You can stop any time.",
                systemImage: "location.circle",
                actionTitle: "Continue",
                action: { status = .granted },
                secondaryActionTitle: "Not now",
                secondaryAction: { status = .denied }
            )
            .background(theme.background)
        case .denied:
            CatalogScroll {
                DSBanner(
                    "Location sharing is off, so your group can't see you on the map.",
                    kind: .warning,
                    action: .init("Open Settings") { status = .notAsked }
                )
                Text("The rest of the trip still works.")
                    .textRole(.subheadline)
                    .foregroundStyle(theme.labelSecondary)
            }
        case .granted:
            CatalogScroll {
                Text("In an app, Continue shows the system prompt here.")
                    .textRole(.subheadline)
                    .foregroundStyle(theme.labelSecondary)
                DSBanner("Location sharing is on.", kind: .success) { status = .notAsked }
            }
        }
    }
}
