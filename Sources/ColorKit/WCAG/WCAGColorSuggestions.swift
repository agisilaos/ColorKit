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
    private let baseColor: Color
    private let targetColor: Color
    private let targetLevel: WCAGContrastLevel

    /// Creates a new WCAG color suggestions generator
    /// - Parameters:
    ///   - baseColor: The base color that won't be changed
    ///   - targetColor: The color that needs to be adjusted for compliance
    ///   - targetLevel: The WCAG compliance level to aim for
    public init(baseColor: Color, targetColor: Color, targetLevel: WCAGContrastLevel = .AA) {
        self.baseColor = baseColor
        self.targetColor = targetColor
        self.targetLevel = targetLevel
    }

    /// Generates a set of color suggestions that meet WCAG compliance
    /// - Parameter preserveHue: Whether to preserve the original hue when generating suggestions
    /// - Returns: An array of suggested colors that meet the required contrast level
    public func generateSuggestions(preserveHue: Bool = true) -> [Color] {
        let currentCompliance = baseColor.wcagCompliance(with: targetColor)

        // If already compliant, return the original color
        if currentCompliance.passes.contains(targetLevel) {
            return [targetColor]
        }

        var suggestions: [Color] = []

        // Get target color components
        guard let hsl = targetColor.hslComponents() else {
            return [targetColor]
        }

        let baseLuminance = baseColor.wcagRelativeLuminance()

        // Determine if we need to lighten or darken
        let needsDarkening = baseLuminance > 0.5

        // Generate a lighter/darker version maintaining hue and saturation
        if preserveHue {
            // Adjust lightness in increments
            let steps = 10
            for i in 1...steps {
                let adjustedLightness = needsDarkening
                    ? max(0.0, hsl.lightness - (Double(i) / Double(steps)) * hsl.lightness)
                    : min(1.0, hsl.lightness + (Double(i) / Double(steps)) * (1.0 - hsl.lightness))

                if let adjustedColor = Color.fromHSL(hue: hsl.hue, saturation: hsl.saturation, lightness: CGFloat(adjustedLightness)) {
                    let compliance = baseColor.wcagCompliance(with: adjustedColor)
                    if compliance.passes.contains(targetLevel) {
                        suggestions.append(adjustedColor)
                        break
                    }
                }
            }
        }

        // If we couldn't find a suitable color by adjusting lightness alone,
        // try adjusting saturation as well
        if suggestions.isEmpty {
            for saturationFactor in stride(from: 0.8, to: 0.0, by: -0.2) {
                let adjustedSaturation = hsl.saturation * saturationFactor

                let adjustedLightness = needsDarkening ? 0.0 : 1.0

                if let adjustedColor = Color.fromHSL(hue: hsl.hue, saturation: adjustedSaturation, lightness: CGFloat(adjustedLightness)) {
                    let compliance = baseColor.wcagCompliance(with: adjustedColor)
                    if compliance.passes.contains(targetLevel) {
                        suggestions.append(adjustedColor)
                        break
                    }
                }
            }
        }

        // If still no suggestions, add fallback colors
        if suggestions.isEmpty {
            suggestions.append(needsDarkening ? .black : .white)
        }

        return suggestions
    }
}