//
//  DSSegmentedControl.swift
//
//  Segmented control. Use the system `Picker(...).pickerStyle(.segmented)`
//  when the system look is fine; use this when the design needs the theme's
//  colours, which the system control can't take without a global appearance
//  override. Theme tokens, a 44-pt hit area per segment, VoiceOver marks the
//  selected segment, the slide becomes a fade under Reduce Motion, and the
//  options stack vertically at accessibility text sizes.
//

import SwiftUI

/// Picks one of a few mutually exclusive options.
public struct DSSegmentedControl<Option: Hashable>: View {
    @Binding private var selection: Option
    private let options: [Option]
    private let title: (Option) -> String

    @Namespace private var namespace
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(selection: Binding<Option>, options: [Option], title: @escaping (Option) -> String) {
        _selection = selection
        self.options = options
        self.title = title
    }

    public var body: some View {
        // Each segment's hit area is the full 44-pt height; the selected pill
        // is drawn inset inside it. At accessibility text sizes the options
        // stack vertically instead of squeezing words onto broken lines.
        let isStacked = dynamicTypeSize.isAccessibilitySize
        let layout = isStacked ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 0))
        layout {
            ForEach(options, id: \.self) { option in
                segment(option)
            }
        }
        .padding(isStacked ? .all : .horizontal, theme.spacing.xxs)
        .background(
            theme.surfacePressed,
            in: DesignSystem.Radius.shape(isStacked ? theme.radius.card : theme.radius.chip)
        )
        .dsHaptic(.selection, trigger: selection)
    }

    private func segment(_ option: Option) -> some View {
        let isSelected = option == selection
        return Button {
            guard !isSelected else { return }
            withAnimation(reduceMotion ? nil : DesignSystem.Motion.enter) {
                selection = option
            }
        } label: {
            Text(title(option))
                .textRole(theme.components.selection.segment)
                .foregroundStyle(isSelected ? theme.labelPrimary : theme.labelSecondary)
                .padding(.horizontal, theme.spacing.xs)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.xxs)
                .frame(minHeight: DesignSystem.minTapTarget)
                .contentShape(Rectangle())
                .background {
                    if isSelected {
                        DesignSystem.Radius.shape(theme.radius.chip)
                            .fill(theme.surface)
                            .shadow(color: theme.elevation.color, radius: 2, y: 1)
                            .padding(.vertical, theme.spacing.xxs)
                            .matchedGeometryEffect(id: "selection", in: namespace)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct DSSegmentedControlPreview: View {
    @State private var tab = "Expenses"

    var body: some View {
        DSSegmentedControl(selection: $tab, options: ["Expenses", "Balances", "Map"]) { $0 }
            .screenMargins()
    }
}

#Preview {
    DSSegmentedControlPreview()
}
