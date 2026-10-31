//
//  DSAvatar.swift
//
//  Avatars (new: none of the three apps had a shared one). A photo when
//  there is one, the person's initials otherwise and while it loads. Sizes
//  come from the theme and grow with Dynamic Type up to 1.6×. VoiceOver
//  reads the person's name.
//

import SwiftUI

/// A person shown in an avatar.
public struct DSPerson: Hashable, Sendable {
    public var name: String
    public var imageURL: URL?

    public init(name: String, imageURL: URL? = nil) {
        self.name = name
        self.imageURL = imageURL
    }

    /// Up to two initials: first and last word ("Dana Cruz" → "DC").
    public var initials: String {
        let words = name.split(separator: " ")
        let letters = [words.first, words.count > 1 ? words.last : nil]
            .compactMap { $0?.first }
        return String(letters).uppercased()
    }
}

public extension DesignSystem {
    /// Avatar diameter, from the theme's size tokens.
    enum AvatarSize: Sendable {
        case small, regular, large

        func diameter(in size: DesignSystem.Size) -> CGFloat {
            switch self {
            case .small: size.avatarSmall
            case .regular: size.avatar
            case .large: size.avatarLarge
            }
        }
    }
}

/// One person's avatar.
public struct DSAvatar: View {
    private let person: DSPerson
    private let size: DesignSystem.AvatarSize

    @Environment(\.theme) private var theme
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1

    public init(_ person: DSPerson, size: DesignSystem.AvatarSize = .regular) {
        self.person = person
        self.size = size
    }

    public var body: some View {
        let diameter = size.diameter(in: theme.size) * min(textScale, 1.6)
        ZStack {
            initials(diameter: diameter)
            if let url = person.imageURL {
                DSRemoteImage(url: url) { initials(diameter: diameter) }
            }
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(person.name)
        .accessibilityAddTraits(.isImage)
    }

    private func initials(diameter: CGFloat) -> some View {
        // Initials are drawn as part of the graphic, so they size with the
        // circle rather than with a text role.
        Text(person.initials)
            .font(.system(size: diameter * 0.4, weight: .semibold))
            .foregroundStyle(theme.labelSecondary)
            .frame(width: diameter, height: diameter)
            .background(theme.surfacePressed)
    }
}

/// Overlapping avatars for a group, with "+N" for the rest.
public struct DSAvatarStack: View {
    private let people: [DSPerson]
    private let maxVisible: Int
    private let size: DesignSystem.AvatarSize

    @Environment(\.theme) private var theme
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1

    public init(_ people: [DSPerson], maxVisible: Int = 3, size: DesignSystem.AvatarSize = .small) {
        self.people = people
        self.maxVisible = maxVisible
        self.size = size
    }

    public var body: some View {
        let diameter = size.diameter(in: theme.size) * min(textScale, 1.6)
        let visible = Array(people.prefix(maxVisible))
        let rest = people.count - visible.count
        HStack(spacing: -diameter * 0.25) {
            ForEach(visible, id: \.self) { person in
                DSAvatar(person, size: size)
                    .overlay(Circle().strokeBorder(theme.background, lineWidth: 2))
            }
            if rest > 0 {
                Text("+\(rest)")
                    .font(.system(size: diameter * 0.38, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(theme.labelSecondary)
                    .frame(width: diameter, height: diameter)
                    .background(theme.surfacePressed, in: Circle())
                    .overlay(Circle().strokeBorder(theme.background, lineWidth: 2))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(summary)
    }

    /// "Dana, Leo and Mia" or "Dana, Leo, Mia and 2 others".
    private var summary: String {
        let names = people.prefix(maxVisible).map(\.name)
        let rest = people.count - names.count
        if rest > 0 {
            return names.joined(separator: ", ") + " and \(rest) other" + (rest == 1 ? "" : "s")
        }
        guard names.count > 1 else { return names.first ?? "" }
        return names.dropLast().joined(separator: ", ") + " and " + (names.last ?? "")
    }
}

#Preview {
    let people = ["Dana Cruz", "Leo Santos", "Mia Reyes", "Paolo Lim", "Bea Tan"].map { DSPerson(name: $0) }
    VStack(spacing: DesignSystem.Spacing.standard.groupGap) {
        HStack(spacing: DesignSystem.Spacing.standard.sm) {
            DSAvatar(people[0], size: .small)
            DSAvatar(people[1])
            DSAvatar(people[2], size: .large)
        }
        DSAvatarStack(people)
    }
}
