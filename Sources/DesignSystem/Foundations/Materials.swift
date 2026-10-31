//
//  Materials.swift
//
//  Translucent backgrounds for content that floats over other content: bottom
//  action bars, overlays on photos and maps. Never for cards or rows on a
//  plain background; those use the theme's surface. Under Reduce Transparency
//  the material becomes the solid surface colour.
//

import SwiftUI

public extension DesignSystem {
    /// How much of the content behind shows through.
    enum MaterialThickness: Sendable {
        case thin, regular, thick

        var material: Material {
            switch self {
            case .thin: .thinMaterial
            case .regular: .regularMaterial
            case .thick: .thickMaterial
            }
        }
    }
}

private struct MaterialBackground<S: Shape>: ViewModifier {
    let thickness: DesignSystem.MaterialThickness
    let shape: S
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(theme.surface, in: shape)
        } else {
            content.background(thickness.material, in: shape)
        }
    }
}

public extension View {
    /// A translucent background for floating content; solid under Reduce
    /// Transparency.
    func dsMaterial<S: Shape>(_ thickness: DesignSystem.MaterialThickness = .regular, in shape: S) -> some View {
        modifier(MaterialBackground(thickness: thickness, shape: shape))
    }

    /// A translucent rectangular background for floating content.
    func dsMaterial(_ thickness: DesignSystem.MaterialThickness = .regular) -> some View {
        modifier(MaterialBackground(thickness: thickness, shape: Rectangle()))
    }
}
