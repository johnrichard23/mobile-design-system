//
//  Haptics.swift
//
//  Haptics are punctuation: one per user action, on the same frame as the
//  visual change, never the only feedback, never on scroll. Selection when a
//  value steps (chip, segment, picker), success/warning/error for outcomes,
//  impacts only when something physically snaps into place.
//
//  A project can turn component haptics off with `theme.hapticsEnabled`. The
//  system's own setting (Settings › Sounds & Haptics) always wins.
//

import SwiftUI
import UIKit

public extension DesignSystem {
    /// The haptics components use.
    enum Haptic: Sendable {
        /// A value stepped: chip toggled, segment changed.
        case selection
        /// Something worked.
        case success
        /// Something needs attention.
        case warning
        /// Something failed.
        case error
        /// Something snapped into place (a sheet detent, a drag landing).
        case impact

        var feedback: SensoryFeedback {
            switch self {
            case .selection: .selection
            case .success: .success
            case .warning: .warning
            case .error: .error
            case .impact: .impact(weight: .light)
            }
        }

        /// Plays the haptic now, for code outside a view (e.g. after a
        /// network call). Inside views prefer `.dsHaptic(_:trigger:)`.
        @MainActor
        public func play(in theme: Theme) {
            guard theme.hapticsEnabled else { return }
            switch self {
            case .selection: UISelectionFeedbackGenerator().selectionChanged()
            case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .warning: UINotificationFeedbackGenerator().notificationOccurred(.warning)
            case .error: UINotificationFeedbackGenerator().notificationOccurred(.error)
            case .impact: UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
}

private struct HapticModifier<Trigger: Equatable>: ViewModifier {
    let haptic: DesignSystem.Haptic
    let trigger: Trigger
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content.sensoryFeedback(trigger: trigger) { _, _ in
            theme.hapticsEnabled ? haptic.feedback : nil
        }
    }
}

public extension View {
    /// Plays `haptic` whenever `trigger` changes, if the theme allows haptics.
    func dsHaptic<Trigger: Equatable>(_ haptic: DesignSystem.Haptic, trigger: Trigger) -> some View {
        modifier(HapticModifier(haptic: haptic, trigger: trigger))
    }
}
