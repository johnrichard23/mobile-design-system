//
//  DSStateView.swift
//
//  Empty, error and offline states, in two placements: inline (a
//  leading-aligned card inside a screen) and full screen (centred, the one
//  place centred text is allowed, with Retry and Open Settings). Error is the
//  same view with a custom message.
//
//  Default copy is English; pass your own strings to localise.
//

import SwiftUI
import UIKit

/// A screen or section with nothing to show: empty, failed, or offline.
public struct DSStateView: View {
    /// Where the state sits.
    public enum Placement: Sendable {
        /// Replaces the whole screen's content. Centred.
        case fullScreen
        /// A card inside a screen, e.g. an empty section. Leading-aligned.
        case inline
    }

    private let title: String
    private let message: String?
    private let systemImage: String?
    private let placement: Placement
    private let actionTitle: String?
    private let isActionLoading: Bool
    private let action: (@MainActor () -> Void)?
    private let secondaryActionTitle: String?
    private let secondaryAction: (@MainActor () -> Void)?

    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        _ title: String,
        message: String? = nil,
        systemImage: String? = nil,
        placement: Placement = .fullScreen,
        actionTitle: String? = nil,
        isActionLoading: Bool = false,
        action: (@MainActor () -> Void)? = nil,
        secondaryActionTitle: String? = nil,
        secondaryAction: (@MainActor () -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.placement = placement
        self.actionTitle = actionTitle
        self.isActionLoading = isActionLoading
        self.action = action
        self.secondaryActionTitle = secondaryActionTitle
        self.secondaryAction = secondaryAction
    }

    /// No connection and nothing cached to show. Retry plus Open Settings.
    public static func offline(
        isRetrying: Bool = false,
        title: String = "No internet connection",
        message: String = "Check your connection and try again.",
        retryTitle: String = "Try again",
        settingsTitle: String = "Open Settings",
        retry: @escaping @MainActor () -> Void
    ) -> DSStateView {
        DSStateView(
            title,
            message: message,
            systemImage: "wifi.slash",
            actionTitle: retryTitle,
            isActionLoading: isRetrying,
            action: retry,
            secondaryActionTitle: settingsTitle,
            secondaryAction: {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
        )
    }

    /// A load failed. Say what happened and what to do, never an error code.
    public static func error(
        message: String,
        isRetrying: Bool = false,
        title: String = "Something went wrong",
        retryTitle: String = "Try again",
        retry: @escaping @MainActor () -> Void
    ) -> DSStateView {
        DSStateView(
            title,
            message: message,
            systemImage: "exclamationmark.triangle",
            actionTitle: retryTitle,
            isActionLoading: isRetrying,
            action: retry
        )
    }

    public var body: some View {
        switch placement {
        case .fullScreen: fullScreen
        case .inline: inline
        }
    }

    // MARK: - Full screen

    private var fullScreen: some View {
        VStack(spacing: theme.spacing.xl) {
            VStack(spacing: theme.spacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.largeTitle)
                        .foregroundStyle(theme.labelSecondary)
                        .padding(.bottom, theme.spacing.xs)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .textRole(theme.components.feedback.stateTitle)
                    .foregroundStyle(theme.labelPrimary)
                    .accessibilityAddTraits(.isHeader)
                if let message {
                    Text(message)
                        .textRole(theme.components.feedback.stateMessage)
                        .foregroundStyle(theme.labelSecondary)
                }
            }
            .multilineTextAlignment(.center)

            VStack(spacing: theme.spacing.sm) {
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .buttonStyle(.ds(.primary, isLoading: isActionLoading))
                }
                if let secondaryActionTitle, let secondaryAction {
                    Button(secondaryActionTitle, action: secondaryAction)
                        .buttonStyle(.ds(.plain))
                }
            }
        }
        .frame(maxWidth: theme.size.readableWidth)
        .screenMargins()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Inline

    private var inline: some View {
        // Icon beside the text, or above it at accessibility text sizes.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: theme.spacing.xs))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: theme.spacing.sm))
        return VStack(alignment: .leading, spacing: theme.spacing.groupGap) {
            layout {
                if let systemImage {
                    DSRowIcon(systemImage, tint: theme.labelSecondary)
                }
                VStack(alignment: .leading, spacing: theme.spacing.tightGap) {
                    Text(title)
                        .textRole(theme.components.feedback.inlineStateTitle)
                        .foregroundStyle(theme.labelPrimary)
                    if let message {
                        Text(message)
                            .textRole(theme.components.feedback.inlineStateMessage)
                            .foregroundStyle(theme.labelSecondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.ds(.secondary, size: .regular, isLoading: isActionLoading, expandsWidth: false))
            }
        }
        .card()
    }
}

#Preview("Full screen") {
    DSStateView.offline {}
        .background(Color(.systemGroupedBackground))
}

#Preview("Inline") {
    VStack(spacing: DesignSystem.Spacing.standard.groupGap) {
        DSStateView(
            "No expenses yet",
            message: "Add the first one to get started.",
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
    .screenMargins()
    .frame(maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
}
