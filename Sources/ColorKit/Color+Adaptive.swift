//
//  Color+Adaptive.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 10.03.25.
//
//  Description:
//  Implements adaptive color adjustments for Light/Dark mode and accessibility contrast.
//
//  Features:
//  - Detects if a color is more suited for dark or light mode.
//  - Adjusts brightness dynamically for improved accessibility.
//  - Ensures colors meet WCAG contrast ratio guidelines.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

// MARK: - Public Interface
public extension Color {
    /// Computes the relative luminance of a color based on WCAG standards.
    /// Luminance is calculated as a weighted sum of the RGB components.
    ///
    /// - Returns: A `CGFloat` representing the relative luminance of the color.
    func relativeLuminance() -> CGFloat {
        guard let components = cgColor?.components, components.count >= 3 else { return 0 }
        return 0.2126 * components[0] + 0.7152 * components[1] + 0.0722 * components[2]
    }

    /// Determines if the color is better suited for a light or dark mode background.
    /// Uses perceived luminance to detect brightness.
    ///
    /// - Returns: `true` if the color is dark, `false` if it is light.
    func isDarkColor() -> Bool {
        return relativeLuminance() < 0.5
    }

    /// Adjusts color brightness to ensure it contrasts well with Light/Dark mode backgrounds.
    ///
    /// - Parameter isDarkMode: A Boolean indicating whether the current mode is dark.
    /// - Returns: A new `Color` instance adjusted for the mode.
    func adjustedForMode(isDarkMode: Bool) -> Color {
        let adjustment: CGFloat = isDarkMode ? 0.3 : -0.3
        return self.adjustBrightness(by: adjustment)
    }

    /// Computes the contrast ratio between two colors based on WCAG guidelines.
    /// Contrast ratio is calculated using relative luminance values.
    ///
    /// - Parameter other: The color to compare contrast against.
    /// - Returns: A `CGFloat` representing the contrast ratio.
    func contrastRatio(with other: Color) -> CGFloat {
        let l1 = self.relativeLuminance() + 0.05
        let l2 = other.relativeLuminance() + 0.05
        return max(l1, l2) / min(l1, l2)
    }

    /// Returns an improved color that meets a minimum contrast ratio requirement.
    /// Adjusts the color brightness to ensure accessibility compliance.
    ///
    /// - Parameters:
    ///   - with: The background color against which contrast should be checked.
    ///   - minimumRatio: The minimum contrast ratio required.
    /// - Returns: A `Color` adjusted to meet the contrast ratio requirement.
    func adjustedForAccessibility(with background: Color, minimumRatio: CGFloat) -> Color {
        guard let foregroundHSL = self.hslComponents() else { return self }

        var adjustedLightness = foregroundHSL.lightness
        var contrastRatio = self.contrastRatio(with: background)

        while contrastRatio < minimumRatio {
            // Try adjusting in both directions and pick the better one
            let lightenAttempt = min(1.0, adjustedLightness + 0.05)
            let darkenAttempt = max(0.0, adjustedLightness - 0.05)

            let lightenColor = Color(hue: foregroundHSL.hue, saturation: foregroundHSL.saturation, lightness: lightenAttempt)
            let darkenColor = Color(hue: foregroundHSL.hue, saturation: foregroundHSL.saturation, lightness: darkenAttempt)

            let lightenContrast = lightenColor.contrastRatio(with: background)
            let darkenContrast = darkenColor.contrastRatio(with: background)

            if lightenContrast >= minimumRatio {
                return lightenColor
            } else if darkenContrast >= minimumRatio {
                return darkenColor
            }

            // Pick the direction that increases contrast the most
            if lightenContrast > darkenContrast {
                adjustedLightness = lightenAttempt
                contrastRatio = lightenContrast
            } else {
                adjustedLightness = darkenAttempt
                contrastRatio = darkenContrast
            }

            // Stop if no improvement possible
            if adjustedLightness == 0.0 || adjustedLightness == 1.0 {
                break
            }
        }

        // if contrast is still too low, return a guaranteed high-contrast color
        return background.isDarkColor() ? .white : .black
    }
}

// MARK: - Private Helpers
private extension Color {
    /// Adjusts the brightness of a color by a given percentage.
    ///
    /// - Parameter amount: The brightness adjustment amount.
    /// - Returns: A new `Color` with adjusted brightness.
    func adjustBrightness(by amount: CGFloat) -> Color {
        guard let hsl = self.hslComponents() else { return self }
        let newLightness = max(0, min(1, hsl.lightness + amount))
        return Color(hue: hsl.hue, saturation: hsl.saturation, lightness: newLightness)
    }

    /// Converts a given luminance value to an HSL lightness value.
    ///
    /// - Parameter luminance: The luminance value to convert.
    /// - Returns: The corresponding lightness value in HSL format.
    func convertLuminanceToLightness(_ luminance: CGFloat) -> CGFloat {
        if luminance <= 0.008856 {
            return luminance * 12.92
        } else {
            return pow(luminance, 1.0 / 2.4) * 1.055 - 0.055
        }
    }
}
