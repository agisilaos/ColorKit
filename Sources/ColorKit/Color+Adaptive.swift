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

/// Extension providing adaptive color functionality for SwiftUI's Color type.
///
/// This extension adds capabilities for:
/// - Automatic light/dark mode color adaptation
/// - WCAG contrast ratio calculations and adjustments
/// - Accessibility-focused color adjustments
/// - Luminance and brightness calculations
///
/// Example usage:
/// ```swift
/// // Create an adaptive color that works in both light and dark mode
/// Text("Hello, World!")
///     .foregroundColor(Color.blue.adjustedForMode(isDarkMode: colorScheme == .dark))
///
/// // Ensure text meets WCAG AA contrast requirements
/// Text("Accessible Text")
///     .foregroundColor(textColor.adjustedForAccessibility(with: backgroundColor, minimumRatio: 4.5))
/// ```
public extension Color {
    /// Computes the relative luminance of a color based on WCAG standards.
    ///
    /// Relative luminance represents the perceived brightness of a color, calculated
    /// according to the WCAG 2.1 specification: each nonlinear sRGB component is
    /// linearized, then weighted by 0.2126 (red), 0.7152 (green), and 0.0722 (blue).
    ///
    /// Opacity is not part of relative luminance. Composite a translucent color over
    /// its background before measuring it.
    ///
    /// Example:
    /// ```swift
    /// let color = Color.blue
    /// let luminance = color.relativeLuminance()
    /// print("Relative luminance: \(luminance)") // Value between 0 and 1
    /// ```
    ///
    /// - Returns: A `CGFloat` representing the relative luminance, ranging from 0 (darkest)
    ///   to 1 (brightest). Returns 0 when the color cannot be resolved to finite, in-gamut
    ///   sRGB components; use ``relativeLuminanceValue()`` to distinguish that case from
    ///   a measured black.
    func relativeLuminance() -> CGFloat {
        guard let luminance = relativeLuminanceValue() else { return 0 }
        return CGFloat(luminance)
    }

    /// Determines if the color is better suited for a light or dark mode background.
    ///
    /// This method analyzes the color's perceived brightness to determine if it would
    /// be more appropriate for a light or dark context. The determination is based on
    /// the color's relative luminance value.
    ///
    /// Example:
    /// ```swift
    /// let color = Color.purple
    /// if color.isDarkColor() {
    ///     // Use light text for contrast
    ///     Text("Light Text")
    ///         .foregroundColor(.white)
    /// } else {
    ///     // Use dark text for contrast
    ///     Text("Dark Text")
    ///         .foregroundColor(.black)
    /// }
    /// ```
    ///
    /// - Returns: `true` when white contrasts better than black against this color,
    ///   `false` otherwise. An unresolvable color reports `true`, matching the luminance
    ///   fallback of ``relativeLuminance()``.
    func isDarkColor() -> Bool {
        return relativeLuminance() < Color.whitePreferenceLuminanceThreshold
    }

    /// Adjusts color brightness to ensure it contrasts well with Light/Dark mode backgrounds.
    ///
    /// This method modifies the color's brightness to maintain visual hierarchy and readability
    /// when switching between light and dark modes.
    ///
    /// Example:
    /// ```swift
    /// struct AdaptiveView: View {
    ///     @Environment(\.colorScheme) var colorScheme
    ///
    ///     var body: some View {
    ///         Text("Adaptive Text")
    ///             .foregroundColor(Color.blue.adjustedForMode(isDarkMode: colorScheme == .dark))
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter isDarkMode: A Boolean indicating whether the current mode is dark.
    /// - Returns: A new `Color` instance with adjusted brightness for the specified mode.
    func adjustedForMode(isDarkMode: Bool) -> Color {
        let adjustment: CGFloat = isDarkMode ? 0.3 : -0.3
        return self.adjustBrightness(by: adjustment)
    }

    /// Computes the contrast ratio between two colors based on WCAG guidelines.
    ///
    /// The contrast ratio is calculated according to WCAG 2.1 specifications using
    /// the relative luminance values of both colors. The ratio ranges from 1:1 (no contrast)
    /// to 21:1 (maximum contrast).
    ///
    /// Opacity is ignored. This method compares two colors rather than compositing a
    /// foreground over a background; use ``contrastResult(with:)`` to measure a
    /// translucent foreground against an opaque background.
    ///
    /// Example:
    /// ```swift
    /// let textColor = Color.blue
    /// let backgroundColor = Color.white
    /// let ratio = textColor.contrastRatio(with: backgroundColor)
    /// print("Contrast ratio: \(ratio):1")
    /// ```
    ///
    /// - Parameter other: The color to compare contrast against.
    /// - Returns: A `CGFloat` representing the contrast ratio (from 1 to 21). An
    ///   unresolvable color contributes the luminance fallback of ``relativeLuminance()``;
    ///   use ``contrastResult(with:)`` to distinguish that case from a measured ratio.
    func contrastRatio(with other: Color) -> CGFloat {
        let l1 = self.relativeLuminance() + 0.05
        let l2 = other.relativeLuminance() + 0.05
        return max(l1, l2) / min(l1, l2)
    }

    /// Preserves a color that already meets the requested contrast, or attempts to adjust it.
    ///
    /// Uses the WCAG `contrastRatio(with:)` calculation. If the initial ratio meets or
    /// exceeds the minimum, the original color is returned unchanged, including its opacity.
    /// Otherwise, the existing greedy search adjusts HSL lightness in steps of 0.05.
    /// If adjustment is unsuccessful, the fallback is white for a background classified
    /// as dark by `isDarkColor()`, or black otherwise. That is always the stronger
    /// contrasting endpoint, but it may still fall short of the requested minimum.
    /// If the foreground cannot be converted to HSL, the original color is returned.
    /// A NaN minimum retains the fallback behavior when foreground conversion succeeds.
    ///
    /// Example:
    /// ```swift
    /// struct AccessibleText: View {
    ///     let textColor: Color
    ///     let backgroundColor: Color
    ///
    ///     var body: some View {
    ///         Text("Accessible Text")
    ///             .foregroundColor(textColor.adjustedForAccessibility(
    ///                 with: backgroundColor,
    ///                 minimumRatio: 4.5
    ///             ))
    ///             .background(backgroundColor)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - background: The background color against which contrast should be checked.
    ///   - minimumRatio: The requested minimum WCAG contrast ratio.
    /// - Returns: The original color on initial success or HSL conversion failure,
    ///   the first successful adjustment, or the existing black/white fallback.
    func adjustedForAccessibility(with background: Color, minimumRatio: CGFloat) -> Color {
        guard let foregroundHSL = self.hslComponents() else { return self }

        var adjustedLightness = foregroundHSL.lightness
        var contrastRatio = self.contrastRatio(with: background)

        if contrastRatio >= minimumRatio {
            return self
        }

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

        // Preserve the existing fallback when adjustment does not produce a successful result.
        return background.isDarkColor() ? .white : .black
    }
}

// MARK: - Internal Constants
extension Color {
    /// The relative luminance at which black and white contrast equally against a color.
    ///
    /// Below this value white is the stronger contrasting endpoint, and above it black is.
    /// It is the solution to `(L + 0.05) / 0.05 == 1.05 / (L + 0.05)`.
    static let whitePreferenceLuminanceThreshold: CGFloat = 0.1791287847
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
