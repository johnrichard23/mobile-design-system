//
//  CatalogExtendingPage.swift
//
//  Shows how a project extends the design system without changing it: its
//  own button kind, banner kind and tag tone defined from the theme, and a
//  new kind of field built on the shared field layout.
//

import SwiftUI

// MARK: - A project's own variants

extension DesignSystem.ButtonKind {
    /// Third-party sign-in: neutral surface, strong border.
    static let social = DesignSystem.ButtonKind { theme in
        .init(
            fill: theme.surface,
            pressedFill: theme.surfacePressed,
            foreground: theme.labelPrimary,
            border: theme.labelPrimary
        )
    }
}

extension DSBanner.Kind {
    /// A limited-time offer.
    static let promo = DSBanner.Kind(name: "Offer", systemImage: "tag.fill") { $0.accent }
}

extension DSTag.Tone {
    /// Members-only items.
    static let premium = DSTag.Tone { $0.warning }
}

// MARK: - A project's own field, built on the shared layout

/// Phone number field: country code menu plus number, in the standard field frame.
struct PhoneField: View {
    let label: String
    @Binding var countryCode: String
    @Binding var number: String
    var errorMessage: String?
    @FocusState private var isFocused: Bool
    @Environment(\.theme) private var theme

    private let codes = ["+63", "+1", "+44", "+61"]

    var body: some View {
        DSFieldLayout(label: label, errorMessage: errorMessage, isFocused: isFocused) {
            HStack(spacing: theme.spacing.xs) {
                Menu {
                    ForEach(codes, id: \.self) { code in
                        Button(code) { countryCode = code }
                    }
                } label: {
                    HStack(spacing: theme.spacing.xxs) {
                        Text(countryCode)
                        Image(systemName: "chevron.down").imageScale(.small)
                    }
                    .foregroundStyle(theme.labelPrimary)
                    .frame(minHeight: DesignSystem.minTapTarget)
                }
                .accessibilityLabel("Country code, \(countryCode)")
                Rectangle()
                    .fill(theme.separator)
                    .frame(width: theme.size.borderWidth)
                    .padding(.vertical, theme.spacing.xs)
                TextField("Phone number", text: $number, prompt: Text("912 345 6789").foregroundStyle(theme.labelTertiary))
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .focused($isFocused)
                    .accessibilityLabel(label)
            }
        } trailing: {
            EmptyView()
        }
    }
}

struct ExtendingPage: View {
    @Environment(\.theme) private var theme
    @State private var countryCode = "+63"
    @State private var number = ""

    var body: some View {
        CatalogScroll {
            DSSectionHeader("Custom button kind")
            Button("Continue with Apple", systemImage: "apple.logo") {}
                .buttonStyle(.ds(.social))
            DSSectionHeader("Custom banner kind and tag tone")
            DSBanner("Members save 20% on court bookings this week.", kind: .promo, title: "Weekend offer")
            DSTag("Members only", systemImage: "crown.fill", tone: .premium)
            DSSectionHeader("Custom field on the shared layout")
            PhoneField(label: "Mobile number", countryCode: $countryCode, number: $number)
            PhoneField(
                label: "Mobile number",
                countryCode: $countryCode,
                number: .constant("12"),
                errorMessage: "Enter all 10 digits."
            )
        }
    }
}
