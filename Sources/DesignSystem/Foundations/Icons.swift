//
//  Icons.swift
//
//  One way to draw icons, whether they are SF Symbols or the project's own
//  icon set from Figma (exported to the asset catalog as template images).
//  Either way the icon is sized by the text role it sits next to, so it
//  scales with Dynamic Type, takes the surrounding text colour, and is
//  hidden from VoiceOver unless it carries meaning of its own.
//
//  Name a project's icons once, so screens never type asset strings:
//
//      extension DSIcon.Source {
//          static let luggage = Self.asset("icons/luggage")
//          static let seat = Self.asset("icons/seat")
//      }
//      DSIcon(.luggage, role: .subheadline)
//
//  Rules
//  - One icon family per app: SF Symbols or the brand set, not a mix in one
//    screen. Outline vs filled is a theme choice
//    (`theme.components.icon.symbolStyle`); use the filled form only for a
//    selected state if the set is outline.
//  - Icons that stand alone as a button get an accessibility label (use
//    `Button("Share", systemImage:)` with `.dsIcon()`, or pass `label:`).
//

import SwiftUI
import UIKit

/// An SF Symbol or brand icon, sized by a text role.
public struct DSIcon: View {
    /// Where the icon comes from.
    public enum Source: Sendable, Hashable {
        /// An SF Symbol name.
        case system(String)
        /// A template image in an asset catalog. `bundle` defaults to the app's.
        case asset(String, bundle: Bundle? = nil)
    }

    private let source: Source
    private let role: DesignSystem.TextRole
    private let label: String?

    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// `label` is read by VoiceOver; leave it `nil` for decorative icons.
    public init(_ source: Source, role: DesignSystem.TextRole = .body, label: String? = nil) {
        self.source = source
        self.role = role
        self.label = label
    }

    public var body: some View {
        icon
            .accessibilityHidden(label == nil)
            .accessibilityLabel(label ?? "")
    }

    @ViewBuilder
    private var icon: some View {
        switch source {
        case let .system(name):
            Image(systemName: name)
                .symbolVariant(theme.components.icon.symbolStyle == .filled ? .fill : .none)
                .textRole(role)
        case let .asset(name, bundle):
            let side = role.scaled(
                theme.typography[role].size * theme.components.icon.assetScale,
                at: dynamicTypeSize
            )
            // UIImage finds both asset-catalog images and loose image files.
            if let image = UIImage(named: name, in: bundle, compatibleWith: nil) {
                Image(uiImage: image)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: side, height: side)
            } else {
                Color.clear.frame(width: side, height: side)
            }
        }
    }
}

#Preview {
    HStack(spacing: DesignSystem.Spacing.standard.md) {
        DSIcon(.system("heart"))
        DSIcon(.system("airplane"), role: .title2)
        DSIcon(.system("bell"), role: .footnote, label: "Notifications")
    }
}
