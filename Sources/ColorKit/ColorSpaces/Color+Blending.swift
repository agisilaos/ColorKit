//
//  Color+Blending.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 11.03.25.
//
//  Description:
//  Provides color blending operations similar to those found in graphic design software.
//
//  Features:
//  - Standard blending modes: Normal, Multiply, Screen, Overlay, etc.
//  - Alpha-aware blending
//  - Supports all color blending operations as SwiftUI Color extensions
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// Extension providing professional-grade color blending operations for SwiftUI's Color type.
///
/// This extension implements color blending modes commonly found in professional design
/// software like Adobe Photoshop, Sketch, and Figma. It supports:
///
/// - 12 standard blending modes (Normal, Multiply, Screen, etc.)
/// - Variable opacity blending with amount parameter
/// - Performance optimization through caching
/// - Alpha channel awareness
///
/// Key features:
/// - Professional-grade blending algorithms
/// - Cached results for better performance
/// - Full alpha channel support
/// - Photoshop-style blend modes
///
/// Example usage:
/// ```swift
/// let background = Color.blue
/// let foreground = Color.red
///
/// // Simple blending
/// let overlaid = background.overlay(with: foreground)
///
/// // Partial opacity blend
/// let subtle = background.multiply(with: foreground, amount: 0.5)
///
/// // Complex effects
/// let effect = background
///     .screen(with: .yellow, amount: 0.7)
///     .overlay(with: .purple.opacity(0.3))
///     .softLight(with: .gray)
/// ```
public extension Color {
    /// Blends this color with another color using a specific blending mode.
    ///
    /// This method provides the foundation for all blending operations in ColorKit.
    /// It handles:
    /// - Proper color component extraction
    /// - Alpha channel calculations
    /// - Result caching for performance
    /// - Amount/opacity control
    ///
    /// Example:
    /// ```swift
    /// let base = Color.blue
    /// let blend = Color.red
    ///
    /// // Full strength multiply blend
    /// let result1 = base.blended(
    ///     with: blend,
    ///     mode: .multiply
    /// )
    ///
    /// // Partial overlay blend
    /// let result2 = base.blended(
    ///     with: blend,
    ///     mode: .overlay,
    ///     amount: 0.5
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color
    ///   - mode: The ``BlendMode`` determining how colors are combined
    ///   - amount: The opacity of the blend, from 0.0 (no effect) to 1.0 (full effect)
    /// - Returns: The resulting blended color
    func blended(with color: Color, mode: BlendMode, amount: CGFloat = 1.0) -> Color {
        // If amount is 0, return the original color (no blending)
        if amount <= 0 {
            return self
        }

        // If amount is 1.0, check the cache for the full blend
        if amount >= 1.0 {
            if let cachedColor = ColorCache.shared.getCachedBlendedColor(color1: self, with: color, blendMode: String(describing: mode)) {
                return cachedColor
            }
        }

        // Extract RGB components from both colors
        guard let components1 = cgColor?.components, components1.count >= 3,
              let components2 = color.cgColor?.components, components2.count >= 3 else {
            return self
        }

        let r1 = components1[0]
        let g1 = components1[1]
        let b1 = components1[2]
        let a1 = components1.count >= 4 ? components1[3] : 1.0

        let r2 = components2[0]
        let g2 = components2[1]
        let b2 = components2[2]
        let a2 = components2.count >= 4 ? components2[3] : 1.0

        // Apply the blending function with amount
        let blendResult = mode.blend(base: (r1, g1, b1), blend: (r2, g2, b2))

        // Apply the amount blending
        let clampedAmount = max(0, min(1, amount))
        let r = r1 + (blendResult.r - r1) * clampedAmount * a2
        let g = g1 + (blendResult.g - g1) * clampedAmount * a2
        let b = b1 + (blendResult.b - b1) * clampedAmount * a2

        // Create the result color
        let resultColor = Color(.sRGB, red: r, green: g, blue: b, opacity: a1)

        // Cache the result if amount is 1.0 (full blend)
        if amount >= 1.0 {
            ColorCache.shared.cacheBlendedColor(color1: self, with: color, blendMode: String(describing: mode), result: resultColor)
        }

        return resultColor
    }

    /// Performs normal blending (standard alpha composition).
    ///
    /// Normal blending simply places the blend color over the base color,
    /// taking into account the blend color's opacity and the amount parameter.
    ///
    /// Example:
    /// ```swift
    /// let background = Color.blue
    /// let foreground = Color.red.opacity(0.5)
    ///
    /// // Full strength blend
    /// let result1 = background.normal(with: foreground)
    ///
    /// // Partial blend
    /// let result2 = background.normal(
    ///     with: foreground,
    ///     amount: 0.7
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - color: The color to blend on top of this color
    ///   - amount: The opacity of the blend (0.0 to 1.0)
    /// - Returns: The blended color
    func normal(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .normal, amount: amount)
    }

    /// Performs multiply blending, which darkens the image by multiplying color values.
    ///
    /// Multiply blending multiplies each color component, resulting in a darker color.
    /// White has no effect, and black results in black.
    ///
    /// Example:
    /// ```swift
    /// let background = Color.blue
    /// let shadow = Color.black
    ///
    /// // Create a shadow effect
    /// let darkened = background.multiply(
    ///     with: shadow,
    ///     amount: 0.5
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color
    ///   - amount: The opacity of the blend (0.0 to 1.0)
    /// - Returns: The blended color
    func multiply(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .multiply, amount: amount)
    }

    /// Performs screen blending, which lightens by multiplying inverse values.
    ///
    /// Screen blending is the opposite of multiply - it multiplies the complements
    /// of the colors, resulting in a brighter color. Black has no effect, and
    /// white results in white.
    ///
    /// Example:
    /// ```swift
    /// let background = Color.blue
    /// let highlight = Color.white
    ///
    /// // Create a highlight effect
    /// let lightened = background.screen(
    ///     with: highlight,
    ///     amount: 0.7
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color
    ///   - amount: The opacity of the blend (0.0 to 1.0)
    /// - Returns: The blended color
    func screen(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .screen, amount: amount)
    }

    /// Performs overlay blending, which combines multiply and screen effects.
    ///
    /// Overlay blending combines multiply and screen modes. Light base colors become
    /// lighter, and dark base colors become darker. This creates high contrast while
    /// preserving highlights and shadows.
    ///
    /// Example:
    /// ```swift
    /// let photo = Color.gray
    /// let contrast = Color.white
    ///
    /// // Enhance contrast
    /// let enhanced = photo.overlay(
    ///     with: contrast,
    ///     amount: 0.3
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color
    ///   - amount: The opacity of the blend (0.0 to 1.0)
    /// - Returns: The blended color
    func overlay(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .overlay, amount: amount)
    }

    /// Performs darken blending, which keeps the darker value for each channel.
    ///
    /// Darken blending compares each component of the base and blend colors,
    /// keeping whichever is darker. White has no effect.
    ///
    /// Example:
    /// ```swift
    /// let image = Color.blue
    /// let shadow = Color.black
    ///
    /// // Add shadows
    /// let darkened = image.darken(
    ///     with: shadow,
    ///     amount: 0.6
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color
    ///   - amount: The opacity of the blend (0.0 to 1.0)
    /// - Returns: The blended color
    func darken(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .darken, amount: amount)
    }

    /// Performs lighten blending, which keeps the lighter value for each channel.
    ///
    /// Lighten blending compares each component of the base and blend colors,
    /// keeping whichever is lighter. Black has no effect.
    ///
    /// Example:
    /// ```swift
    /// let image = Color.blue
    /// let highlight = Color.white
    ///
    /// // Add highlights
    /// let lightened = image.lighten(
    ///     with: highlight,
    ///     amount: 0.4
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color
    ///   - amount: The opacity of the blend (0.0 to 1.0)
    /// - Returns: The blended color
    func lighten(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .lighten, amount: amount)
    }

    /// Performs color dodge blending, which brightens the base color by decreasing contrast.
    ///
    /// Color dodge divides the base color by the inverse of the blend color.
    /// This brightens the base color while preserving blacks. The effect is
    /// similar to photographically "dodging" an image.
    ///
    /// Example:
    /// ```swift
    /// let photo = Color.gray
    /// let light = Color.white
    ///
    /// // Brighten highlights
    /// let dodged = photo.colorDodge(
    ///     with: light,
    ///     amount: 0.5
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color
    ///   - amount: The opacity of the blend (0.0 to 1.0)
    /// - Returns: The blended color
    func colorDodge(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .colorDodge, amount: amount)
    }

    /// Performs color burn blending, which darkens the base color by increasing contrast.
    ///
    /// Color burn inverts the base color, divides by the blend color, and inverts
    /// the result. This darkens the base color while preserving whites. The effect
    /// is similar to photographically "burning" an image.
    ///
    /// Example:
    /// ```swift
    /// let photo = Color.gray
    /// let dark = Color.black
    ///
    /// // Deepen shadows
    /// let burned = photo.colorBurn(
    ///     with: dark,
    ///     amount: 0.6
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color
    ///   - amount: The opacity of the blend (0.0 to 1.0)
    /// - Returns: The blended color
    func colorBurn(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .colorBurn, amount: amount)
    }

    /// Performs hard light blending, similar to overlay but with the layers swapped.
    ///
    /// Hard light is similar to overlay, but with the blend and base colors swapped.
    /// Light blend colors make the result lighter, dark blend colors make it darker.
    /// The effect is similar to shining a harsh spotlight on the base color.
    ///
    /// Example:
    /// ```swift
    /// let image = Color.blue
    /// let light = Color.white
    ///
    /// // Add harsh lighting
    /// let lit = image.hardLight(
    ///     with: light,
    ///     amount: 0.7
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color
    ///   - amount: The opacity of the blend (0.0 to 1.0)
    /// - Returns: The blended color
    func hardLight(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .hardLight, amount: amount)
    }

    /// Performs soft light blending, a softer version of hard light.
    ///
    /// Soft light is similar to hard light but produces a more subtle effect.
    /// The result is similar to shining a diffused spotlight on the base color.
    /// It's useful for gentle lighting adjustments.
    ///
    /// Example:
    /// ```swift
    /// let image = Color.blue
    /// let light = Color.white
    ///
    /// // Add soft lighting
    /// let lit = image.softLight(
    ///     with: light,
    ///     amount: 0.4
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color
    ///   - amount: The opacity of the blend (0.0 to 1.0)
    /// - Returns: The blended color
    func softLight(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .softLight, amount: amount)
    }

    /// Performs difference blending, which subtracts the darker from the lighter value.
    ///
    /// Difference blending subtracts the blend color from the base color (or vice versa)
    /// and takes the absolute value. Blending with white inverts the base color,
    /// while blending with black has no effect.
    ///
    /// Example:
    /// ```swift
    /// let color1 = Color.blue
    /// let color2 = Color.red
    ///
    /// // Create abstract effect
    /// let diff = color1.difference(
    ///     with: color2,
    ///     amount: 0.8
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color
    ///   - amount: The opacity of the blend (0.0 to 1.0)
    /// - Returns: The blended color
    func difference(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .difference, amount: amount)
    }

    /// Performs exclusion blending, similar to difference but with lower contrast.
    ///
    /// Exclusion is similar to difference but produces a lower contrast result.
    /// Like difference, blending with white inverts the base color, and blending
    /// with black has no effect.
    ///
    /// Example:
    /// ```swift
    /// let color1 = Color.blue
    /// let color2 = Color.red
    ///
    /// // Create subtle effect
    /// let excluded = color1.exclusion(
    ///     with: color2,
    ///     amount: 0.5
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color
    ///   - amount: The opacity of the blend (0.0 to 1.0)
    /// - Returns: The blended color
    func exclusion(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .exclusion, amount: amount)
    }
}

/// Defines the available color blending modes in ColorKit.
///
/// `BlendMode` provides a comprehensive set of blending operations similar to
/// those found in professional design software. Each mode defines how colors
/// are combined mathematically.
///
/// The available modes are:
/// - `normal`: Standard alpha composition
/// - `multiply`: Darkens by multiplying values
/// - `screen`: Lightens by multiplying inverse values
/// - `overlay`: Combines multiply and screen
/// - `darken`: Keeps darker values
/// - `lighten`: Keeps lighter values
/// - `colorDodge`: Brightens by decreasing contrast
/// - `colorBurn`: Darkens by increasing contrast
/// - `hardLight`: Similar to overlay but with layers swapped
/// - `softLight`: Softer version of hard light
/// - `difference`: Subtracts darker from lighter
/// - `exclusion`: Similar to difference but lower contrast
///
/// Example usage:
/// ```swift
/// let background = Color.blue
/// let foreground = Color.red
///
/// // Using with blended method
/// let result = background.blended(
///     with: foreground,
///     mode: .overlay
/// )
///
/// // Creating effects
/// let effects = [
///     BlendMode.multiply,
///     BlendMode.screen,
///     BlendMode.overlay
/// ]
///
/// effects.forEach { mode in
///     let blended = background.blended(
///         with: foreground,
///         mode: mode
///     )
///     // Use blended color
/// }
/// ```
public enum BlendMode {
    /// Normal blending (standard alpha composition).
    case normal

    /// Multiply blending (darkens by multiplying values).
    case multiply

    /// Screen blending (lightens by multiplying inverse values).
    case screen

    /// Overlay blending (combines multiply and screen).
    case overlay

    /// Darken blending (keeps the darker value for each channel).
    case darken

    /// Lighten blending (keeps the lighter value for each channel).
    case lighten

    /// Color dodge blending (brightens by decreasing contrast).
    case colorDodge

    /// Color burn blending (darkens by increasing contrast).
    case colorBurn

    /// Hard light blending (similar to overlay but with layers swapped).
    case hardLight

    /// Soft light blending (softer version of hard light).
    case softLight

    /// Difference blending (subtracts darker from lighter).
    case difference

    /// Exclusion blending (similar to difference but with lower contrast).
    case exclusion

    /// Applies the blend mode to a base color and a blend color.
    ///
    /// This method implements the mathematical operations for each blend mode.
    /// It works with individual RGB components to create the blended result.
    ///
    /// Example:
    /// ```swift
    /// let mode = BlendMode.overlay
    /// let base = (r: 0.5, g: 0.2, b: 0.8)
    /// let blend = (r: 0.3, g: 0.9, b: 0.1)
    ///
    /// let result = mode.blend(base: base, blend: blend)
    /// print("R: \(result.r), G: \(result.g), B: \(result.b)")
    /// ```
    ///
    /// - Parameters:
    ///   - base: A tuple containing the base color's RGB components
    ///   - blend: A tuple containing the blend color's RGB components
    /// - Returns: A tuple containing the resulting RGB components
    func blend(base: (r: CGFloat, g: CGFloat, b: CGFloat), blend: (r: CGFloat, g: CGFloat, b: CGFloat)) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch self {
        case .normal:
            return blend

        case .multiply:
            return (
                r: base.r * blend.r,
                g: base.g * blend.g,
                b: base.b * blend.b
            )

        case .screen:
            return (
                r: 1 - (1 - base.r) * (1 - blend.r),
                g: 1 - (1 - base.g) * (1 - blend.g),
                b: 1 - (1 - base.b) * (1 - blend.b)
            )

        case .overlay:
            return (
                r: overlayComponent(base: base.r, blend: blend.r),
                g: overlayComponent(base: base.g, blend: blend.g),
                b: overlayComponent(base: base.b, blend: blend.b)
            )

        case .darken:
            return (
                r: min(base.r, blend.r),
                g: min(base.g, blend.g),
                b: min(base.b, blend.b)
            )

        case .lighten:
            return (
                r: max(base.r, blend.r),
                g: max(base.g, blend.g),
                b: max(base.b, blend.b)
            )

        case .colorDodge:
            return (
                r: colorDodgeComponent(base: base.r, blend: blend.r),
                g: colorDodgeComponent(base: base.g, blend: blend.g),
                b: colorDodgeComponent(base: base.b, blend: blend.b)
            )

        case .colorBurn:
            return (
                r: colorBurnComponent(base: base.r, blend: blend.r),
                g: colorBurnComponent(base: base.g, blend: blend.g),
                b: colorBurnComponent(base: base.b, blend: blend.b)
            )

        case .hardLight:
            return (
                r: hardLightComponent(base: base.r, blend: blend.r),
                g: hardLightComponent(base: base.g, blend: blend.g),
                b: hardLightComponent(base: base.b, blend: blend.b)
            )

        case .softLight:
            return (
                r: softLightComponent(base: base.r, blend: blend.r),
                g: softLightComponent(base: base.g, blend: blend.g),
                b: softLightComponent(base: base.b, blend: blend.b)
            )

        case .difference:
            return (
                r: abs(base.r - blend.r),
                g: abs(base.g - blend.g),
                b: abs(base.b - blend.b)
            )

        case .exclusion:
            return (
                r: base.r + blend.r - 2 * base.r * blend.r,
                g: base.g + blend.g - 2 * base.g * blend.g,
                b: base.b + blend.b - 2 * base.b * blend.b
            )
        }
    }

    // MARK: - Helper Functions

    /// Helper function for overlay and hard light blending
    private func overlayComponent(base: CGFloat, blend: CGFloat) -> CGFloat {
        if base < 0.5 {
            return 2 * base * blend
        } else {
            return 1 - 2 * (1 - base) * (1 - blend)
        }
    }

    /// Helper function for hard light blending
    private func hardLightComponent(base: CGFloat, blend: CGFloat) -> CGFloat {
        return overlayComponent(base: blend, blend: base)
    }

    /// Helper function for soft light blending
    private func softLightComponent(base: CGFloat, blend: CGFloat) -> CGFloat {
        if blend < 0.5 {
            return base - (1 - 2 * blend) * base * (1 - base)
        } else {
            let d = base <= 0.25 ? ((16 * base - 12) * base + 4) * base : sqrt(base)
            return base + (2 * blend - 1) * (d - base)
        }
    }

    /// Helper function for color dodge blending
    private func colorDodgeComponent(base: CGFloat, blend: CGFloat) -> CGFloat {
        if blend >= 1 {
            return 1
        } else if blend <= 0 {
            return base
        } else {
            return min(1, base / (1 - blend))
        }
    }

    /// Helper function for color burn blending
    private func colorBurnComponent(base: CGFloat, blend: CGFloat) -> CGFloat {
        if blend <= 0 {
            return 0
        } else if blend >= 1 {
            return base
        } else {
            return 1 - min(1, (1 - base) / blend)
        }
    }
}
