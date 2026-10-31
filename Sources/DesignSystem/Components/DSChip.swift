//
//  DSChip.swift
//
//  Filter chips, plus the wrapping layout chips sit in. A ToggleStyle, so a
//  chip is a real on/off control: `Toggle("Padel", isOn: $on).toggleStyle(.dsChip)`.
//  A selected chip shows a checkmark (not colour alone), VoiceOver reads it as
//  a switch that is on or off, and its hit area is at least 44 pt tall.
//

import SwiftUI

/// Pill-shaped toggle for filters and multi-select options.
public struct DSChipStyle: ToggleStyle {
    @Environment(\.theme) private var theme

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        let isOn = configuration.isOn
        let shape = DesignSystem.Radius.shape(theme.radius.chip)
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: theme.spacing.xxs) {
                if isOn {
                    Image(systemName: "checkmark").accessibilityHidden(true)
                }
                configuration.label
            }
            .textRole(theme.components.selection.chip)
            .foregroundStyle(isOn ? theme.onAccent : theme.labelPrimary)
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.xs)
            .background(isOn ? theme.accent : theme.surface, in: shape)
            .overlay {
                if !isOn {
                    shape.strokeBorder(theme.border, lineWidth: theme.size.borderWidth)
                }
            }
            .frame(minHeight: DesignSystem.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(DesignSystem.Motion.press, value: isOn)
        .dsHaptic(.selection, trigger: isOn)
    }
}

public extension ToggleStyle where Self == DSChipStyle {
    /// Pill-shaped filter chip.
    static var dsChip: DSChipStyle { DSChipStyle() }
}

/// Lays children out left to right, wrapping onto new lines, like words in
/// a paragraph. Pass the theme's spacing: `DSFlowLayout(spacing: theme.spacing.xs)`.
public struct DSFlowLayout: Layout {
    private let spacing: CGFloat
    private let lineSpacing: CGFloat

    public init(spacing: CGFloat, lineSpacing: CGFloat? = nil) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing ?? spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let rows = rows(for: subviews, maxWidth: proposal.width ?? .infinity)
        let height = rows.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) {
        var y = bounds.minY
        for row in rows(for: subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

private struct DSChipPreview: View {
    @State private var selected: Set<String> = ["Padel"]
    private let sports = ["Padel", "Pickleball", "Tennis", "Badminton", "Squash", "Table tennis"]

    var body: some View {
        DSFlowLayout(spacing: DesignSystem.Spacing.standard.xs) {
            ForEach(sports, id: \.self) { sport in
                Toggle(sport, isOn: Binding(
                    get: { selected.contains(sport) },
                    set: { isOn in
                        if isOn { selected.insert(sport) } else { selected.remove(sport) }
                    }
                ))
                .toggleStyle(.dsChip)
            }
        }
        .screenMargins()
    }
}

#Preview {
    DSChipPreview()
}
