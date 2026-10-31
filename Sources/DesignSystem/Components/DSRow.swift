//
//  DSRow.swift
//
//  The one list row. None of the three apps had a shared row (about 40
//  one-off *Row types), so this is built on SwiftUI's own layout and stacks
//  vertically at accessibility text sizes.
//
//  The row adds no padding or height of its own: inside a `List` the system
//  row sets the standard 44-pt height and insets; elsewhere put it in a
//  `.card()` (or pad it) so a tappable row still reaches 44 pt.
//
//  Inside a NavigationLink the system adds the chevron; don't add one.
//
//  A row with a switch is a Toggle whose label is the row, not a row with a
//  Toggle inside it. That way VoiceOver reads "Share my location, switch,
//  on" and a tap anywhere on the row flips it:
//  `Toggle(isOn: $on) { DSRow("Share my location", systemImage: "location") }`
//

import SwiftUI

/// A row: optional leading icon, title with optional subtitle, optional
/// trailing content (a value or a checkmark; not a control — see above).
/// VoiceOver reads the whole row as one element.
///
/// ```
/// DSRow("Dana Cruz", subtitle: "Owes you ₱1,250")
/// DSRow("Currency", systemImage: "pesosign.circle") { DSRowValue("PHP") }
/// Toggle(isOn: $on) { DSRow("Notifications", systemImage: "bell") }
/// DSRow("Dana Cruz") { Avatar(...) } trailing: { ... }   // custom leading view
/// ```
/// A single trailing closure is always the trailing content.
public struct DSRow<Leading: View, Trailing: View>: View {
    private let title: String
    private let subtitle: String?
    private let leading: Leading
    private let trailing: Trailing

    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: theme.spacing.xs))
            : AnyLayout(HStackLayout(alignment: .center, spacing: theme.spacing.sm))
        layout {
            // The leading icon or avatar repeats what the title says, so
            // VoiceOver skips it.
            leading.accessibilityHidden(true)
            VStack(alignment: .leading, spacing: theme.spacing.tightGap) {
                Text(title)
                    .textRole(theme.components.row.title)
                    .foregroundStyle(theme.labelPrimary)
                if let subtitle {
                    Text(subtitle)
                        .textRole(theme.components.row.subtitle)
                        .foregroundStyle(theme.labelSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

public extension DSRow where Leading == EmptyView {
    /// A row with trailing content only.
    init(_ title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.init(title, subtitle: subtitle, leading: { EmptyView() }, trailing: trailing)
    }
}

public extension DSRow where Leading == DSRowIcon {
    /// A row with a leading SF Symbol and trailing content.
    init(
        _ title: String,
        subtitle: String? = nil,
        systemImage: String,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(title, subtitle: subtitle, leading: { DSRowIcon(systemImage) }, trailing: trailing)
    }
}

public extension DSRow where Leading == DSRowIcon, Trailing == EmptyView {
    /// A row with a leading SF Symbol only.
    init(_ title: String, subtitle: String? = nil, systemImage: String) {
        self.init(
            title,
            subtitle: subtitle,
            leading: { DSRowIcon(systemImage) },
            trailing: { EmptyView() }
        )
    }
}

public extension DSRow where Leading == EmptyView, Trailing == EmptyView {
    /// A text-only row.
    init(_ title: String, subtitle: String? = nil) {
        self.init(title, subtitle: subtitle, leading: { EmptyView() }, trailing: { EmptyView() })
    }
}

/// Leading row icon. Scales with the row text; decorative for VoiceOver.
public struct DSRowIcon: View {
    private let systemName: String
    private let tint: Color?

    @Environment(\.theme) private var theme

    public init(_ systemName: String, tint: Color? = nil) {
        self.systemName = systemName
        self.tint = tint
    }

    public var body: some View {
        Image(systemName: systemName)
            .textRole(theme.components.row.title)
            .imageScale(.large)
            .foregroundStyle(tint ?? theme.accent)
            .frame(minWidth: theme.size.icon)
            .accessibilityHidden(true)
    }
}

/// Trailing row value, e.g. the current setting.
public struct DSRowValue: View {
    private let value: String

    @Environment(\.theme) private var theme

    public init(_ value: String) {
        self.value = value
    }

    public var body: some View {
        Text(value)
            .textRole(theme.components.row.value)
            .foregroundStyle(theme.labelSecondary)
    }
}

private struct DSRowPreview: View {
    @State private var sharesLocation = true

    var body: some View {
        NavigationStack {
            List {
                NavigationLink(value: 1) {
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
            }
            .navigationTitle("Trip settings")
        }
    }
}

#Preview {
    DSRowPreview()
}
