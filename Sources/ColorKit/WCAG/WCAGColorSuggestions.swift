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

/// Provides advanced color suggestions to achieve WCAG compliance
public struct WCAGColorSuggestions {
    /// Default number of steps to use when adjusting lightness
    private static let defaultLightnessSteps = 10
    /// Starting saturation factor for adjustments
    private static let initialSaturationFactor: CGFloat = 0.8
    /// Step size for reducing saturation
    private static let saturationStepSize: CGFloat = 0.2

    private let baseColor: Color
    private let targetColor: Color
    private let targetLevel: WCAGContrastLevel

    /// Creates a new WCAG color suggestions generator
    /// - Parameters:
    ///   - baseColor: The base color that won't be changed
    ///   - targetColor: The color that needs to be adjusted for compliance
    ///   - targetLevel: The WCAG compliance level to aim for (defaults to AA)
    public init(baseColor: Color, targetColor: Color, targetLevel: WCAGContrastLevel = .AA) {
        self.baseColor = baseColor
        self.targetColor = targetColor
        self.targetLevel = targetLevel
    }

    /// Generates a set of color suggestions that meet WCAG compliance
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

    private func isColorCompliant(_ color: Color) -> Bool {
        baseColor.wcagCompliance(with: color).passes.contains(targetLevel)
    }

    private func shouldDarkenColor() -> Bool {
        baseColor.wcagRelativeLuminance() > 0.5
    }

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
