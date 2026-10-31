//
//  DSBanner.swift
//
//  Inline banner: icon plus text on a tinted fill, leading-aligned, inside
//  the content (not floating over it). Four standard kinds, each with its own
//  icon shape so status is never colour alone; an optional title, action and
//  dismiss button; VoiceOver reads the kind first ("Warning, …").
//
//  Kinds are open: `extension DSBanner.Kind { static let promo = Self(name:
//  "Offer", systemImage: "tag.fill") { $0.accent } }`.
//

import SwiftUI

/// A message about the current screen, shown in its content.
public struct DSBanner: View {
    /// What the banner is about: its colour, icon and the word VoiceOver
    /// reads first. Give each kind a distinct icon shape.
    public struct Kind: Sendable {
        public let name: String
        public let systemImage: String
        let color: @Sendable (DesignSystem.Theme) -> Color

        public init(
            name: String,
            systemImage: String,
            color: @escaping @Sendable (DesignSystem.Theme) -> Color
        ) {
            self.name = name
            self.systemImage = systemImage
            self.color = color
        }

        public static let info = Kind(name: "Information", systemImage: "info.circle.fill") { $0.info }
        public static let success = Kind(name: "Success", systemImage: "checkmark.circle.fill") { $0.success }
        public static let warning = Kind(name: "Warning", systemImage: "exclamationmark.triangle.fill") {
            $0.warning
        }
        public static let error = Kind(name: "Error", systemImage: "exclamationmark.octagon.fill") {
            $0.destructive
        }
    }

    /// An optional text button under the message.
    public struct Action {
        let title: String
        let handler: () -> Void

        public init(_ title: String, handler: @escaping () -> Void) {
            self.title = title
            self.handler = handler
        }
    }

    private let message: String
    private let kind: Kind
    private let title: String?
    private let action: Action?
    private let onDismiss: (() -> Void)?

    @Environment(\.theme) private var theme

    /// A trailing closure is the dismiss handler and adds a close button:
    /// `DSBanner("Card declined.", kind: .error) { showsBanner = false }`.
    public init(
        _ message: String,
        kind: Kind = .info,
        title: String? = nil,
        action: Action? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.message = message
        self.kind = kind
        self.title = title
        self.action = action
        self.onDismiss = onDismiss
    }

    public var body: some View {
        let shape = DesignSystem.Radius.shape(theme.radius.control)
        HStack(alignment: .firstTextBaseline, spacing: theme.spacing.sm) {
            Image(systemName: iconName)
                .textRole(theme.components.banner.title)
                .foregroundStyle(color)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                VStack(alignment: .leading, spacing: theme.spacing.tightGap) {
                    if let title {
                        Text(title).textRole(theme.components.banner.title)
                    }
                    Text(message).textRole(theme.components.banner.message)
                }
                .foregroundStyle(theme.labelPrimary)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel([kindName, title, message].compactMap { $0 }.joined(separator: ", "))

                if let action {
                    Button(action.title, action: action.handler)
                        .textRole(theme.components.banner.action)
                        .foregroundStyle(theme.accent)
                        .frame(minHeight: DesignSystem.minTapTarget)
                        .contentShape(Rectangle())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let onDismiss {
                Button("Dismiss", systemImage: "xmark", action: onDismiss)
                    .buttonStyle(DSFieldAccessoryStyle())
            }
        }
        .padding(.leading, theme.spacing.md)
        .padding(.trailing, onDismiss == nil ? theme.spacing.md : theme.spacing.xxs)
        .padding(.vertical, theme.spacing.sm)
        .background(color.opacity(theme.tintOpacity), in: shape)
        .overlay {
            shape.strokeBorder(color.opacity(min(1, theme.tintOpacity * 3)), lineWidth: theme.size.borderWidth)
        }
    }

    private var color: Color { kind.color(theme) }
    private var iconName: String { kind.systemImage }
    private var kindName: String { kind.name }
}

#Preview {
    VStack(spacing: DesignSystem.Spacing.standard.groupGap) {
        DSBanner("Renewal is on. You'll be charged on 1 March.")
        DSBanner("Payment received.", kind: .success)
        DSBanner(
            "Two expenses are waiting to sync.",
            kind: .warning,
            title: "You're offline",
            action: .init("Retry now") {}
        )
        DSBanner("Card declined. Use another card.", kind: .error) {}
    }
    .screenMargins()
}
