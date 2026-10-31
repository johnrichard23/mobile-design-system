//
//  DSLoading.swift
//
//  Loading placeholders: the real layout with sample data, redacted by
//  SwiftUI, so placeholders match the final layout and scale with Dynamic
//  Type; a shimmer that stops under Reduce Motion; and VoiceOver hears one
//  "Loading" instead of placeholder text.
//

import SwiftUI

public extension View {
    /// Shows this view as a loading placeholder: redacted text and images,
    /// a shimmer, no taps, and a single "Loading" element for VoiceOver.
    /// Render the real layout with sample data and pass `true` while loading.
    func dsLoading(_ isLoading: Bool) -> some View {
        modifier(LoadingModifier(isLoading: isLoading))
    }
}

private struct LoadingModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        if isLoading {
            // The VoiceOver element wraps the content only, so the shimmer
            // (wider than the content while it sweeps) doesn't widen the
            // focus box.
            content
                .redacted(reason: .placeholder)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Loading")
                .modifier(ShimmerModifier())
                .allowsHitTesting(false)
        } else {
            content
        }
    }
}

private struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .overlay(
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [.white.opacity(0), .white.opacity(0.6), .white.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: proxy.size.width * 1.5)
                        .offset(x: phase * proxy.size.width * 1.5)
                        .blendMode(.softLight)
                    }
                    .mask(content)
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        }
    }
}

/// A card-shaped placeholder for a list of cards that hasn't loaded yet.
public struct DSSkeletonCard: View {
    private let lines: Int

    @Environment(\.theme) private var theme

    public init(lines: Int = 2) {
        self.lines = lines
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.tightGap) {
            Text("Placeholder title").textRole(.headline)
            ForEach(0..<lines, id: \.self) { index in
                Text(index == lines - 1 ? "A shorter line" : "A longer placeholder line of text")
                    .textRole(.subheadline)
            }
        }
        .card()
        .dsLoading(true)
    }
}

#Preview {
    VStack(spacing: DesignSystem.Spacing.standard.groupGap) {
        DSSkeletonCard()
        DSSkeletonCard(lines: 3)
        DSRow("Dana Cruz", subtitle: "Owes you ₱1,250", systemImage: "person.circle")
            .card()
            .dsLoading(true)
    }
    .screenMargins()
    .frame(maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
}
