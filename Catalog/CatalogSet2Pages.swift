//
//  CatalogSet2Pages.swift
//
//  Catalog pages for banners, tags, chips, avatars, segmented control and
//  progress, remote images and the sheet toolbar.
//

import SwiftUI

struct BannersPage: View {
    @State private var showsError = true
    @State private var taps: [String: Int] = [:]

    var body: some View {
        CatalogScroll {
            TapLog(taps: taps)
            DSBanner("Renewal is on. You'll be charged on 1 March.")
            DSBanner("Payment received. Your booking is confirmed.", kind: .success)
            DSBanner(
                "Two expenses are waiting to sync.",
                kind: .warning,
                title: "You're offline",
                action: .init("Retry now") { taps["Retry", default: 0] += 1 }
            )
            if showsError {
                DSBanner("Card declined. Use another card.", kind: .error) {
                    showsError = false
                }
            }
        }
    }
}

struct TagsPage: View {
    @Environment(\.theme) private var theme

    var body: some View {
        CatalogScroll {
            DSFlowLayout(spacing: theme.spacing.xs) {
                DSTag("Pickleball", systemImage: "figure.pickleball", tone: .accent)
                DSTag("Settled", systemImage: "checkmark", tone: .success)
                DSTag("Due soon", systemImage: "clock", tone: .warning)
                DSTag("Overdue", tone: .destructive)
                DSTag("Shared", systemImage: "person.2", tone: .info)
                DSTag("Draft")
            }
            HStack(spacing: theme.spacing.md) {
                Image(systemName: "bell")
                    .textRole(.title3)
                    .overlay(alignment: .topTrailing) {
                        DSCountBadge(3, label: "unread notifications").offset(x: 10, y: -8)
                    }
                    .accessibilityHidden(true)
                DSCountBadge(3, label: "unread notifications")
                DSCountBadge(120, label: "messages")
                DSCountBadge(0)
            }
        }
    }
}

struct ChipsPage: View {
    @Environment(\.theme) private var theme
    @State private var selected: Set<String> = ["Padel"]
    private let sports = ["Padel", "Pickleball", "Tennis", "Badminton", "Squash", "Table tennis", "Basketball"]

    var body: some View {
        CatalogScroll {
            DSSectionHeader("Sports")
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
            Text("Selected: " + selected.sorted().joined(separator: ", "))
                .textRole(.footnote)
                .foregroundStyle(theme.labelSecondary)
        }
    }
}

struct AvatarsPage: View {
    @Environment(\.theme) private var theme
    private let people = [
        DSPerson(name: "Dana Cruz", imageURL: URL(string: "https://picsum.photos/id/64/200/200")),
        DSPerson(name: "Leo Santos"),
        DSPerson(name: "Mia Reyes", imageURL: URL(string: "https://picsum.photos/id/91/200/200")),
        DSPerson(name: "Paolo Lim"),
        DSPerson(name: "Bea Tan"),
    ]

    var body: some View {
        CatalogScroll {
            HStack(spacing: theme.spacing.sm) {
                DSAvatar(people[1], size: .small)
                DSAvatar(people[1])
                DSAvatar(people[1], size: .large)
                DSAvatar(people[0], size: .large)
            }
            DSAvatarStack(people)
            DSAvatarStack(Array(people.prefix(2)), size: .regular)
            DSRow("Mia Reyes", subtitle: "Paid ₱2,400 for dinner") {
                DSAvatar(people[2])
            } trailing: {
                EmptyView()
            }
            .card()
        }
    }
}

struct SegmentedPage: View {
    @Environment(\.theme) private var theme
    @State private var tab = "Expenses"
    @State private var step = 2

    var body: some View {
        CatalogScroll {
            DSSegmentedControl(selection: $tab, options: ["Expenses", "Balances", "Map"]) { $0 }
            Text("Showing: \(tab)")
                .textRole(.footnote)
                .foregroundStyle(theme.labelSecondary)
            DSStepIndicator(step: step, of: 4, title: "Split")
            ProgressView(value: 0.6)
            ProgressView()
        }
    }
}

struct ImagesPage: View {
    @Environment(\.theme) private var theme

    var body: some View {
        CatalogScroll {
            DSRemoteImage(url: URL(string: "https://picsum.photos/id/1018/1200/800"), accessibilityLabel: "Mountain lake")
                .frame(height: 200)
                .clipShape(DesignSystem.Radius.shape(theme.radius.card))
            DSRemoteImage(url: URL(string: "https://example.invalid/missing.jpg"))
                .frame(height: 120)
                .clipShape(DesignSystem.Radius.shape(theme.radius.card))
        }
    }
}

struct SheetPage: View {
    @State private var isPresented = ProcessInfo.processInfo.arguments.contains("-open-sheet")
    @State private var name = ""
    @FocusState private var nameFocused: Bool

    var body: some View {
        CatalogScroll {
            Button("Add expense") { isPresented = true }
                .buttonStyle(.ds(.primary))
        }
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                CatalogScroll {
                    DSTextField("What was it for?", placeholder: "e.g. Dinner", text: $name, isFocused: $nameFocused)
                }
                .dsSheetToolbar(
                    "Add expense",
                    cancel: { isPresented = false },
                    confirmTitle: "Save",
                    isConfirmEnabled: !name.isEmpty
                ) {
                    isPresented = false
                }
            }
        }
    }
}
