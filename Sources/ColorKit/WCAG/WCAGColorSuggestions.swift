//
//  WCAGColorSuggestions.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 25.03.25.
//
//  Description:
//  Provides advanced color suggestions to achieve WCAG compliance.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A utility for generating accessible color suggestions that meet WCAG contrast requirements.
///
/// `WCAGColorSuggestions` provides sophisticated algorithms for adjusting colors to meet
/// accessibility guidelines while attempting to maintain the original color's character.
/// It uses a two-step approach:
///
/// 1. Lightness adjustments (preserving hue and saturation)
/// 2. Saturation adjustments (if lightness adjustments alone aren't sufficient)
///
/// Example usage:
/// ```swift
/// let backgroundColor = Color.blue
/// let textColor = Color.gray
///
/// // Create suggestions generator
/// let suggestions = WCAGColorSuggestions(
///     baseColor: backgroundColor,
///     targetColor: textColor,
///     targetLevel: .AA
/// )
///
/// // Get accessible color suggestions
/// let accessibleColors = suggestions.generateSuggestions()
///
/// // Use the first suggestion
/// if let accessibleColor = accessibleColors.first {
///     Text("Accessible Text")
///         .foregroundColor(accessibleColor)
///         .background(backgroundColor)
/// }
/// ```
public struct WCAGColorSuggestions {
    /// Default number of steps to use when adjusting lightness.
    ///
    /// A higher number of steps provides more granular adjustments but may impact performance.
    private static let defaultLightnessSteps = 10

    /// Starting saturation factor for adjustments.
    ///
    /// The initial saturation multiplier when attempting to achieve compliance
    /// through saturation adjustments. Value of 0.8 means starting at 80% of
    /// the original saturation.
    private static let initialSaturationFactor: CGFloat = 0.8

    /// Step size for reducing saturation.
    ///
    /// The amount by which saturation is reduced in each iteration when
    /// searching for a compliant color. Value of 0.2 means reducing
    /// saturation by 20% each step.
    private static let saturationStepSize: CGFloat = 0.2

    /// The base color that will remain unchanged (typically the background).
    private let baseColor: Color

    /// The color that needs to be adjusted to meet accessibility requirements.
    private let targetColor: Color

    /// The WCAG compliance level to achieve.
    private let targetLevel: WCAGContrastLevel

    /// Creates a new WCAG color suggestions generator.
    ///
    /// This initializer sets up the generator with the necessary context for
    /// generating accessible color suggestions.
    ///
    /// Example:
    /// ```swift
    /// let generator = WCAGColorSuggestions(
    ///     baseColor: .white,      // Background color
    ///     targetColor: .gray,     // Text color to adjust
    ///     targetLevel: .AAA       // Highest compliance level
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - baseColor: The base color that won't be changed (typically background)
    ///   - targetColor: The color that needs to be adjusted for compliance
    ///   - targetLevel: The WCAG compliance level to aim for (defaults to AA)
    public init(baseColor: Color, targetColor: Color, targetLevel: WCAGContrastLevel = .AA) {
        self.baseColor = baseColor
        self.targetColor = targetColor
        self.targetLevel = targetLevel
    }

    /// Generates a set of color suggestions that meet WCAG compliance requirements.
    ///
    /// This method attempts to find accessible colors through a series of adjustments:
    /// 1. First checks if the original color is already compliant
    /// 2. If preserving hue, tries adjusting lightness only
    /// 3. If needed, attempts saturation adjustments
    /// 4. Falls back to black or white as a last resort
    ///
    /// Example:
    /// ```swift
    /// let suggestions = WCAGColorSuggestions(
    ///     baseColor: .white,
    ///     targetColor: .gray
    /// )
    ///
    /// // Get suggestions preserving hue
    /// let preservingHue = suggestions.generateSuggestions(preserveHue: true)
    ///
    /// // Get suggestions allowing hue changes
    /// let anyHue = suggestions.generateSuggestions(preserveHue: false)
    /// ```
    ///
    /// - Parameter preserveHue: Whether to preserve the original hue when generating suggestions.
    ///                         If true, will first try to achieve compliance by only adjusting lightness.
    ///                         If false or if lightness adjustment fails, will also adjust saturation.
    /// - Returns: An array of suggested colors that meet the required contrast level.
    ///           Returns the original color if it already meets the requirements.
    ///           Falls back to black or white if no other suggestions are found.
    public func generateSuggestions(preserveHue: Bool = true) -> [Color] {
        // Return original if already compliant
        if isColorCompliant(targetColor) {
            return [targetColor]
        }

        // Get target color components
        guard let hsl = targetColor.hslComponents() else {
            return [targetColor]
        }

        var suggestions: [Color] = []
        let needsDarkening = shouldDarkenColor()

        // Try adjusting lightness first if preserving hue
        if preserveHue {
            suggestions = generateLightnessAdjustedSuggestions(
                from: hsl,
                needsDarkening: needsDarkening
            )
        }

        // If no suggestions found, try adjusting saturation
        if suggestions.isEmpty {
            suggestions = generateSaturationAdjustedSuggestions(
                from: hsl,
                needsDarkening: needsDarkening
            )
        }

        // Fallback to black or white if needed
        if suggestions.isEmpty {
            suggestions.append(needsDarkening ? .black : .white)
        }

        return suggestions
    }

    // MARK: - Private Helper Methods

    /// Checks if a color meets the target WCAG compliance level.
    private func isColorCompliant(_ color: Color) -> Bool {
        baseColor.wcagCompliance(with: color).passes.contains(targetLevel)
    }

    /// Determines if the color needs to be darkened based on the base color's luminance.
    private func shouldDarkenColor() -> Bool {
        baseColor.wcagRelativeLuminance() > 0.5
    }

    /// Generates suggestions by adjusting the lightness while preserving hue and saturation.
    ///
    /// This method attempts to find a compliant color by incrementally adjusting
    /// the lightness value in the HSL color space.
    private func generateLightnessAdjustedSuggestions(
        from hsl: (hue: CGFloat, saturation: CGFloat, lightness: CGFloat),
        needsDarkening: Bool
    ) -> [Color] {
        for i in 1...Self.defaultLightnessSteps {
            let progress = Double(i) / Double(Self.defaultLightnessSteps)
            let adjustedLightness = needsDarkening
                ? max(0.0, hsl.lightness - progress * hsl.lightness)
                : min(1.0, hsl.lightness + progress * (1.0 - hsl.lightness))

            let adjustedColor = Color(
                hue: hsl.hue,
                saturation: hsl.saturation,
                lightness: CGFloat(adjustedLightness)
            )

            if isColorCompliant(adjustedColor) {
                return [adjustedColor]
            }
        }
        return []
    }

    /// Generates suggestions by adjusting both saturation and lightness.
    ///
    /// This method is used when lightness adjustments alone cannot achieve
    /// the required contrast ratio. It progressively reduces saturation
    /// while setting lightness to either minimum or maximum.
    private func generateSaturationAdjustedSuggestions(
        from hsl: (hue: CGFloat, saturation: CGFloat, lightness: CGFloat),
        needsDarkening: Bool
    ) -> [Color] {
        var saturationFactor = Self.initialSaturationFactor
        while saturationFactor > 0 {
            let adjustedSaturation = hsl.saturation * saturationFactor
            let adjustedLightness = needsDarkening ? 0.0 : 1.0

            let adjustedColor = Color(
                hue: hsl.hue,
                saturation: adjustedSaturation,
                lightness: CGFloat(adjustedLightness)
            )

            if isColorCompliant(adjustedColor) {
                return [adjustedColor]
            }

            saturationFactor -= Self.saturationStepSize
        }
        return []
    }
}
