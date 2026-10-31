//
//  DSBottomBar.swift
//
//  A screen's main actions pinned to the bottom, above the home indicator.
//  It sits in the bottom safe-area inset, so scrolling content passes behind
//  it and its last item can still scroll clear of the bar, and it rises with
//  the keyboard. A material background and a hairline separate it from the
//  content; under Reduce Transparency the background is solid.
//

import SwiftUI

private struct BottomBarModifier<Bar: View>: ViewModifier {
    let bar: Bar
    @Environment(\.theme) private var theme
    @Environment(\.displayScale) private var displayScale

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: theme.spacing.xs) {
                bar
            }
            .screenMargins()
            .padding(.vertical, theme.spacing.sm)
            .frame(maxWidth: .infinity)
            .dsMaterial(.regular)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(theme.separator)
                    .frame(height: DesignSystem.Size.hairline(displayScale: displayScale))
            }
        }
    }
}

public extension View {
    /// Pins the screen's main actions to the bottom. Put the primary action
    /// first; a secondary action, if any, goes under it.
    func dsBottomBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        modifier(BottomBarModifier(bar: bar()))
    }
}

#Preview {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.standard.groupGap) {
            ForEach(0..<20, id: \.self) { index in
                Text("Item \(index + 1)").frame(maxWidth: .infinity, alignment: .leading).card()
            }
        }
        .screenMargins()
    }
    .dsBottomBar {
        Button("Continue") {}.buttonStyle(.ds(.primary))
    }
}
