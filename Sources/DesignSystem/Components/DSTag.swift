//
//  DSTag.swift
//
//  Tags and count badges. A tag is an optional icon and a short label on a
//  tinted fill; the icon scales with the text, tones come from the theme, and
//  VoiceOver reads the tag as one element.
//
//  Tones are open: `extension DSTag.Tone { static let premium = Self { $0.warning } }`.
//

import SwiftUI

/// A short label that classifies something: a status, a category, a level.
public struct DSTag: View {
    /// Tag colour from the theme, or `nil` for the neutral grey. Keep warm
    /// tones (warning, destructive) for real status.
    public struct Tone: Sendable {
        let color: @Sendable (DesignSystem.Theme) -> Color?

        public init(color: @escaping @Sendable (DesignSystem.Theme) -> Color?) {
            self.color = color
        }

        public static let neutral = Tone { _ in nil }
        public static let accent = Tone { $0.accent }
        public static let success = Tone { $0.success }
        public static let warning = Tone { $0.warning }
        public static let destructive = Tone { $0.destructive }
        public static let info = Tone { $0.info }
    }

    private let text: String
    private let systemImage: String?
    private let tone: Tone

    @Environment(\.theme) private var theme

    public init(_ text: String, systemImage: String? = nil, tone: Tone = .neutral) {
        self.text = text
        self.systemImage = systemImage
        self.tone = tone
    }

    public var body: some View {
        HStack(spacing: theme.spacing.xxs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(iconColor)
                    .accessibilityHidden(true)
            }
            Text(text).foregroundStyle(theme.labelPrimary)
        }
        .textRole(theme.components.tag.label)
        .padding(.horizontal, theme.spacing.xs)
        .padding(.vertical, theme.spacing.xxs)
        .background(fill, in: DesignSystem.Radius.shape(theme.radius.tag))
        .accessibilityElement(children: .combine)
    }

    private var toneColor: Color? { tone.color(theme) }

    private var fill: Color {
        toneColor.map { $0.opacity(theme.tintOpacity) } ?? theme.surfacePressed
    }

    private var iconColor: Color {
        toneColor ?? theme.labelSecondary
    }
}

/// A small count on an icon or row, e.g. unread notifications. Hidden at 0;
/// shows "99+" above 99.
public struct DSCountBadge: View {
    private let count: Int
    private let label: String

    @Environment(\.theme) private var theme

    /// `label` is what is being counted, for VoiceOver: "3 unread messages".
    public init(_ count: Int, label: String = "") {
        self.count = count
        self.label = label
    }

    public var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .textRole(theme.components.tag.countBadge)
                .monospacedDigit()
                .foregroundStyle(theme.onAccent)
                .padding(.horizontal, theme.spacing.xxs * 1.5)
                .padding(.vertical, theme.spacing.xxs / 2)
                .background(theme.destructive, in: Capsule())
                .accessibilityLabel(label.isEmpty ? "\(count)" : "\(count) \(label)")
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard.sm) {
        HStack {
            DSTag("Pickleball", systemImage: "figure.pickleball", tone: .accent)
            DSTag("Settled", systemImage: "checkmark", tone: .success)
            DSTag("Draft")
        }
        HStack {
            DSCountBadge(3, label: "unread messages")
            DSCountBadge(120)
        }
    }
    .screenMargins()
}
