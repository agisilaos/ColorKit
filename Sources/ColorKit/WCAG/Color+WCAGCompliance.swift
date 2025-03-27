//
//  Color+WCAGCompliance.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 25.03.25.
//
//  Description:    
//  Extension to provide WCAG compliance functionalities for colors, including RGBA components, relative luminance, and contrast ratio calculations.
//
//  License:
//  MIT License. See LICENSE file for details.
// 

import SwiftUI

public extension Color {
    /// Returns the RGBA components of a color
    ///
    /// - Returns: A tuple containing red, green, blue, and alpha components as Double values (0.0-1.0)
    func rgbaComponents() -> (red: Double, green: Double, blue: Double, alpha: Double) {
        return wcagRGBAComponents()
    }

    /// Calculate the relative luminance of a color as defined by WCAG 2.0
    func wcagRelativeLuminance() -> Double {
        // Check cache first
        if let cachedLuminance = ColorCache.shared.getCachedLuminance(for: self) {
            return cachedLuminance
        }

        let rgba = self.rgbaComponents()

        // Convert sRGB to linear RGB
        let r = rgba.red <= 0.03928 ? rgba.red / 12.92 : pow((rgba.red + 0.055) / 1.055, 2.4)
        let g = rgba.green <= 0.03928 ? rgba.green / 12.92 : pow((rgba.green + 0.055) / 1.055, 2.4)
        let b = rgba.blue <= 0.03928 ? rgba.blue / 12.92 : pow((rgba.blue + 0.055) / 1.055, 2.4)

        // Calculate relative luminance
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b

        // Cache the result
        ColorCache.shared.cacheLuminance(for: self, luminance: luminance)

        return luminance
    }

    /// Calculate the contrast ratio between this color and another color
    func wcagContrastRatio(with color: Color) -> Double {
        // Check cache first
        if let cachedRatio = ColorCache.shared.getCachedContrastRatio(for: self, with: color) {
            return cachedRatio
        }

        let luminance1 = self.wcagRelativeLuminance()
        let luminance2 = color.wcagRelativeLuminance()

        let lighter = max(luminance1, luminance2)
        let darker = min(luminance1, luminance2)

        let ratio = (lighter + 0.05) / (darker + 0.05)

        // Cache the result
        ColorCache.shared.cacheContrastRatio(for: self, with: color, ratio: ratio)

        return ratio
    }

    /// Check WCAG compliance between this color and another color
    func wcagCompliance(with color: Color) -> WCAGComplianceResult {
        let ratio = self.wcagContrastRatio(with: color)

        return WCAGComplianceResult(
            contrastRatio: ratio,
            passesAA: ratio >= 4.5,
            passesAALarge: ratio >= 3.0,
            passesAAA: ratio >= 7.0,
            passesAAALarge: ratio >= 4.5
        )
    }

    /// Get a suggested color that would meet the specified WCAG level when paired with this color
    func suggestedColor(for level: WCAGContrastLevel) -> Color {
        let luminance = self.wcagRelativeLuminance()

        // If the color is dark, suggest a lighter color, and vice versa
        if luminance < 0.5 {
            // Suggest a light color
            return .white
        } else {
            // Suggest a dark color
            return .black
        }
    }
}
