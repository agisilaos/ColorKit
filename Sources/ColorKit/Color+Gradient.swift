//
//  Color+Gradient.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 11.03.25.
//
//  Description:
//  Provides utilities for generating and manipulating color gradients.
//
//  Features:
//  - Linear gradient generation between colors
//  - Color interpolation in different color spaces (RGB, HSL, LAB)
//  - Gradient palette generation with customizable steps
//  - Complementary and analogous gradient generation
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// Extension providing gradient generation and color interpolation functionality.
///
/// This extension adds sophisticated gradient generation capabilities to SwiftUI's Color type,
/// supporting multiple color spaces and gradient types:
///
/// - Linear gradients between any two colors
/// - Complementary gradients using color wheel theory
/// - Analogous gradients for harmonious transitions
/// - Triadic gradients for balanced color schemes
/// - Monochromatic gradients for subtle variations
///
/// Example usage:
/// ```swift
/// // Generate a simple linear gradient
/// let colors = Color.blue.linearGradient(to: .purple, steps: 10)
///
/// // Create a complementary gradient
/// let complementary = Color.blue.complementaryGradient(steps: 10)
///
/// // Generate an analogous color scheme
/// let analogous = Color.blue.analogousGradient(steps: 10, angle: 0.1)
/// ```
///
/// All gradient generation methods support:
/// - Custom step counts for granular control
/// - Multiple color spaces (RGB, HSL, LAB)
/// - Caching for performance optimization
public extension Color {
    /// Creates a linear gradient between two colors with a specified number of steps.
    ///
    /// This method generates a smooth transition between two colors by interpolating
    /// in the specified color space. The resulting array includes both the start
    /// and end colors.
    ///
    /// Example:
    /// ```swift
    /// let gradient = Color.blue.linearGradient(
    ///     to: .purple,
    ///     steps: 10,
    ///     in: .hsl
    /// )
    ///
    /// // Use in a SwiftUI view
    /// LinearGradient(
    ///     colors: gradient,
    ///     startPoint: .leading,
    ///     endPoint: .trailing
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - to: The destination color to transition towards.
    ///   - steps: The number of colors to generate (minimum 2).
    ///   - colorSpace: The color space for interpolation (default: .rgb).
    /// - Returns: An array of colors representing the gradient steps.
    func linearGradient(to: Color, steps: Int, in colorSpace: GradientColorSpace = .rgb) -> [Color] {
        guard steps > 1 else { return [self] }

        var colors: [Color] = []

        for step in 0..<steps {
            let amount = CGFloat(step) / CGFloat(steps - 1)
            colors.append(interpolated(with: to, amount: amount, in: colorSpace))
        }

        return colors
    }

    /// Creates a complementary gradient with a specified number of steps.
    ///
    /// Generates a gradient that transitions from the base color to its complement
    /// (opposite on the color wheel). This creates high-contrast, visually striking
    /// gradients that work well for highlighting important content.
    ///
    /// Example:
    /// ```swift
    /// let gradient = Color.blue.complementaryGradient(
    ///     steps: 10,
    ///     in: .hsl
    /// )
    ///
    /// // Use in a SwiftUI view
    /// Rectangle()
    ///     .fill(
    ///         LinearGradient(
    ///             colors: gradient,
    ///             startPoint: .topLeading,
    ///             endPoint: .bottomTrailing
    ///         )
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - steps: The number of colors to generate (minimum 2).
    ///   - colorSpace: The color space for interpolation (default: .hsl).
    /// - Returns: An array of colors from this color to its complement.
    func complementaryGradient(steps: Int, in colorSpace: GradientColorSpace = .hsl) -> [Color] {
        guard let hsl = self.hslComponents(), steps > 1 else { return [self] }

        // Create complementary color (opposite on the color wheel)
        let complementaryHue = fmod(hsl.hue + 0.5, 1.0)
        let complementaryColor = Color(hue: complementaryHue, saturation: hsl.saturation, lightness: hsl.lightness)

        return linearGradient(to: complementaryColor, steps: steps, in: colorSpace)
    }

    /// Creates an analogous gradient with a specified number of steps.
    ///
    /// Generates a gradient using colors that are adjacent on the color wheel.
    /// Analogous color schemes create harmonious, natural-looking transitions
    /// that are pleasing to the eye.
    ///
    /// Example:
    /// ```swift
    /// let gradient = Color.blue.analogousGradient(
    ///     steps: 10,
    ///     angle: 0.1,  // Wider spread between colors
    ///     in: .hsl
    /// )
    ///
    /// // Create a background with the gradient
    /// Color.clear
    ///     .background(
    ///         LinearGradient(
    ///             colors: gradient,
    ///             startPoint: .leading,
    ///             endPoint: .trailing
    ///         )
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - steps: The number of colors to generate (minimum 2).
    ///   - angle: The angle on the color wheel to span (default: 30° or 0.0833).
    ///   - colorSpace: The color space for interpolation (default: .hsl).
    /// - Returns: An array of analogous colors forming a gradient.
    func analogousGradient(steps: Int, angle: CGFloat = 0.0833, in colorSpace: GradientColorSpace = .hsl) -> [Color] {
        guard let hsl = self.hslComponents(), steps > 1 else { return [self] }

        // Calculate start and end hues for analogous colors
        let startHue = fmod(hsl.hue - angle / 2 + 1.0, 1.0)
        let endHue = fmod(hsl.hue + angle / 2, 1.0)

        let startColor = Color(hue: startHue, saturation: hsl.saturation, lightness: hsl.lightness)
        let endColor = Color(hue: endHue, saturation: hsl.saturation, lightness: hsl.lightness)

        return startColor.linearGradient(to: endColor, steps: steps, in: colorSpace)
    }

    /// Creates a triadic gradient with a specified number of steps.
    ///
    /// Generates a gradient using three colors evenly spaced around the color wheel
    /// (120° apart). Triadic color schemes are vibrant and balanced, even when using
    /// muted hues.
    ///
    /// Example:
    /// ```swift
    /// let gradient = Color.blue.triadicGradient(
    ///     steps: 7,  // Steps per segment
    ///     in: .hsl
    /// )
    ///
    /// // Create a circular gradient
    /// Circle()
    ///     .fill(
    ///         AngularGradient(
    ///             colors: gradient,
    ///             center: .center
    ///         )
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - steps: The number of steps between each triadic color.
    ///   - colorSpace: The color space for interpolation (default: .hsl).
    /// - Returns: An array of colors forming a triadic gradient.
    func triadicGradient(steps: Int, in colorSpace: GradientColorSpace = .hsl) -> [Color] {
        guard let hsl = self.hslComponents(), steps > 1 else { return [self] }

        // Create triadic colors (120° apart on the color wheel)
        let triad1Hue = fmod(hsl.hue + 1.0 / 3.0, 1.0)
        let triad2Hue = fmod(hsl.hue + 2.0 / 3.0, 1.0)

        let triad1 = Color(hue: triad1Hue, saturation: hsl.saturation, lightness: hsl.lightness)
        let triad2 = Color(hue: triad2Hue, saturation: hsl.saturation, lightness: hsl.lightness)

        // Generate gradients between each pair of triadic colors
        let gradient1 = self.linearGradient(to: triad1, steps: steps, in: colorSpace)
        let gradient2 = triad1.linearGradient(to: triad2, steps: steps, in: colorSpace)
        let gradient3 = triad2.linearGradient(to: self, steps: steps, in: colorSpace)

        // Combine gradients, removing duplicates at the connection points
        var result = gradient1
        result.append(contentsOf: gradient2.dropFirst())
        result.append(contentsOf: gradient3.dropFirst())

        return result
    }

    /// Creates a monochromatic gradient by varying the lightness.
    ///
    /// Generates a gradient by keeping the hue and saturation constant while varying
    /// the lightness. This creates subtle, professional-looking gradients perfect
    /// for backgrounds and non-distracting UI elements.
    ///
    /// Example:
    /// ```swift
    /// let gradient = Color.blue.monochromaticGradient(
    ///     steps: 8,
    ///     lightnessRange: 0.3...0.7  // More mid-tones
    /// )
    ///
    /// // Create a subtle background
    /// Rectangle()
    ///     .fill(
    ///         LinearGradient(
    ///             colors: gradient,
    ///             startPoint: .top,
    ///             endPoint: .bottom
    ///         )
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - steps: The number of colors to generate.
    ///   - lightnessRange: The range of lightness values (default: 0.1...0.9).
    /// - Returns: An array of colors forming a monochromatic gradient.
    func monochromaticGradient(steps: Int, lightnessRange: ClosedRange<CGFloat> = 0.1...0.9) -> [Color] {
        guard let hsl = self.hslComponents(), steps > 1 else { return [self] }

        var colors: [Color] = []
        let lightnessStep = (lightnessRange.upperBound - lightnessRange.lowerBound) / CGFloat(steps - 1)

        for step in 0..<steps {
            let lightness = lightnessRange.lowerBound + lightnessStep * CGFloat(step)
            colors.append(Color(hue: hsl.hue, saturation: hsl.saturation, lightness: lightness))
        }

        return colors
    }

    /// Creates a split-complementary gradient.
    ///
    /// Generates a gradient using a base color and two colors adjacent to its
    /// complement. This creates a high-contrast, vibrant scheme that's more
    /// balanced than a pure complementary gradient.
    ///
    /// Example:
    /// ```swift
    /// let gradient = Color.blue.splitComplementaryGradient(
    ///     steps: 8,
    ///     angle: 0.1  // Adjust split angle
    /// )
    ///
    /// // Create a dynamic background
    /// Rectangle()
    ///     .fill(
    ///         AngularGradient(
    ///             colors: gradient,
    ///             center: .center
    ///         )
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - steps: The number of steps between each color.
    ///   - angle: The angle of separation from the complement (default: 0.0833 or 30°).
    ///   - colorSpace: The color space for interpolation (default: .hsl).
    /// - Returns: An array of colors forming a split-complementary gradient.
    func splitComplementaryGradient(steps: Int, angle: CGFloat = 0.0833, in colorSpace: GradientColorSpace = .hsl) -> [Color] {
        guard let hsl = self.hslComponents(), steps > 1 else { return [self] }

        // Calculate the complement and its adjacent colors
        let complementHue = fmod(hsl.hue + 0.5, 1.0)
        let split1Hue = fmod(complementHue - angle + 1.0, 1.0)
        let split2Hue = fmod(complementHue + angle, 1.0)

        let split1 = Color(hue: split1Hue, saturation: hsl.saturation, lightness: hsl.lightness)
        let split2 = Color(hue: split2Hue, saturation: hsl.saturation, lightness: hsl.lightness)

        // Generate gradients between colors
        let gradient1 = self.linearGradient(to: split1, steps: steps, in: colorSpace)
        let gradient2 = split1.linearGradient(to: split2, steps: steps, in: colorSpace)
        let gradient3 = split2.linearGradient(to: self, steps: steps, in: colorSpace)

        // Combine gradients
        var result = gradient1
        result.append(contentsOf: gradient2.dropFirst())
        result.append(contentsOf: gradient3.dropFirst())

        return result
    }

    /// Creates a tetradic (double complementary) gradient.
    ///
    /// Generates a gradient using four colors arranged in two complementary
    /// pairs. This creates a rich, balanced color scheme with maximum contrast
    /// and variety.
    ///
    /// Example:
    /// ```swift
    /// let gradient = Color.blue.tetradicGradient(
    ///     steps: 6,
    ///     angle: 0.25  // 90° between pairs
    /// )
    ///
    /// // Create a complex gradient background
    /// Circle()
    ///     .fill(
    ///         AngularGradient(
    ///             colors: gradient,
    ///             center: .center,
    ///             startAngle: .degrees(0),
    ///             endAngle: .degrees(360)
    ///         )
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - steps: The number of steps between each color.
    ///   - angle: The angle between complementary pairs (default: 0.25 or 90°).
    ///   - colorSpace: The color space for interpolation (default: .hsl).
    /// - Returns: An array of colors forming a tetradic gradient.
    func tetradicGradient(steps: Int, angle: CGFloat = 0.25, in colorSpace: GradientColorSpace = .hsl) -> [Color] {
        guard let hsl = self.hslComponents(), steps > 1 else { return [self] }

        // Calculate the four tetradic colors
        let hue2 = fmod(hsl.hue + angle, 1.0)
        let hue3 = fmod(hsl.hue + 0.5, 1.0)
        let hue4 = fmod(hue2 + 0.5, 1.0)

        let color2 = Color(hue: hue2, saturation: hsl.saturation, lightness: hsl.lightness)
        let color3 = Color(hue: hue3, saturation: hsl.saturation, lightness: hsl.lightness)
        let color4 = Color(hue: hue4, saturation: hsl.saturation, lightness: hsl.lightness)

        // Generate gradients between each pair of colors
        let gradient1 = self.linearGradient(to: color2, steps: steps, in: colorSpace)
        let gradient2 = color2.linearGradient(to: color3, steps: steps, in: colorSpace)
        let gradient3 = color3.linearGradient(to: color4, steps: steps, in: colorSpace)
        let gradient4 = color4.linearGradient(to: self, steps: steps, in: colorSpace)

        // Combine gradients
        var result = gradient1
        result.append(contentsOf: gradient2.dropFirst())
        result.append(contentsOf: gradient3.dropFirst())
        result.append(contentsOf: gradient4.dropFirst())

        return result
    }
}

// MARK: - Color Interpolation
public extension Color {
    /// Interpolates between this color and another color.
    ///
    /// This method performs smooth color interpolation in the specified color space.
    /// Results are cached for performance when the same interpolation is requested multiple times.
    ///
    /// Example:
    /// ```swift
    /// let start = Color.blue
    /// let end = Color.purple
    ///
    /// // Get color 30% of the way from blue to purple
    /// let interpolated = start.interpolated(
    ///     with: end,
    ///     amount: 0.3,
    ///     in: .hsl
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - color: The destination color to interpolate towards.
    ///   - amount: The interpolation amount (0.0 = this color, 1.0 = destination).
    ///   - colorSpace: The color space for interpolation (default: .rgb).
    /// - Returns: The interpolated color.
    func interpolated(with color: Color, amount: CGFloat, in colorSpace: GradientColorSpace = .rgb) -> Color {
        let clampedAmount = max(0, min(1, amount))

        // Check cache first
        if let cachedColor = ColorCache.shared.getCachedInterpolatedColor(
            color1: self,
            with: color,
            amount: clampedAmount,
            colorSpace: String(describing: colorSpace)
        ) {
            return cachedColor
        }

        // If not in cache, perform the interpolation
        let result: Color
        switch colorSpace {
        case .rgb:
            result = interpolateRGB(with: color, amount: clampedAmount)
        case .hsl:
            result = interpolateHSL(with: color, amount: clampedAmount)
        case .lab:
            result = interpolateLAB(with: color, amount: clampedAmount)
        }

        // Cache the result
        ColorCache.shared.cacheInterpolatedColor(
            color1: self,
            with: color,
            amount: clampedAmount,
            colorSpace: String(describing: colorSpace),
            result: result
        )

        return result
    }

    /// Interpolates between this color and another color in RGB space.
    private func interpolateRGB(with color: Color, amount: CGFloat) -> Color {
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

        let r = r1 + (r2 - r1) * amount
        let g = g1 + (g2 - g1) * amount
        let b = b1 + (b2 - b1) * amount
        let a = a1 + (a2 - a1) * amount

        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Interpolates between this color and another color in HSL space.
    private func interpolateHSL(with color: Color, amount: CGFloat) -> Color {
        guard let hsl1 = self.hslComponents(),
              let hsl2 = color.hslComponents() else {
            return interpolateRGB(with: color, amount: amount)
        }

        // Handle hue interpolation specially to ensure we go the shortest way around the color wheel
        var hue1 = hsl1.hue
        var hue2 = hsl2.hue

        // Ensure we go the shortest way around the color wheel
        if abs(hue2 - hue1) > 0.5 {
            if hue1 > hue2 {
                hue2 += 1.0
            } else {
                hue1 += 1.0
            }
        }

        let h = fmod(hue1 + (hue2 - hue1) * amount, 1.0)
        let s = hsl1.saturation + (hsl2.saturation - hsl1.saturation) * amount
        let l = hsl1.lightness + (hsl2.lightness - hsl1.lightness) * amount

        return Color(hue: h, saturation: s, lightness: l)
    }

    /// Interpolates between this color and another color in LAB space.
    private func interpolateLAB(with color: Color, amount: CGFloat) -> Color {
        guard let lab1 = self.labComponents(),
              let lab2 = color.labComponents() else {
            return interpolateRGB(with: color, amount: amount)
        }

        let L = lab1.L + (lab2.L - lab1.L) * amount
        let a = lab1.a + (lab2.a - lab1.a) * amount
        let b = lab1.b + (lab2.b - lab1.b) * amount

        return Color(L: L, a: a, b: b)
    }
}

/// Defines the color spaces available for gradient interpolation.
///
/// Different color spaces can produce significantly different results when
/// creating gradients:
///
/// - `rgb`: Linear RGB interpolation. Best for technical accuracy and performance.
/// - `hsl`: Interpolation in Hue, Saturation, Lightness space. Creates more
///   natural-looking transitions, especially for hue changes.
/// - `lab`: Interpolation in CIE L*a*b* space. Produces perceptually uniform
///   gradients but is more computationally intensive.
///
/// Example:
/// ```swift
/// // Compare different color spaces
/// let rgbGradient = color1.linearGradient(
///     to: color2,
///     steps: 10,
///     in: .rgb
/// )
///
/// let hslGradient = color1.linearGradient(
///     to: color2,
///     steps: 10,
///     in: .hsl
/// )
///
/// let labGradient = color1.linearGradient(
///     to: color2,
///     steps: 10,
///     in: .lab
/// )
/// ```
public enum GradientColorSpace {
    /// Linear RGB color space interpolation
    case rgb

    /// HSL (Hue, Saturation, Lightness) color space interpolation
    case hsl

    /// CIE L*a*b* color space interpolation
    case lab
}
