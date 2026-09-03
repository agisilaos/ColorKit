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

/// Extension providing WCAG (Web Content Accessibility Guidelines) compliance checking
/// and color analysis functionality for SwiftUI's Color type.
///
/// This extension adds methods for:
/// - Calculating color components (RGBA)
/// - Computing relative luminance according to WCAG 2.0
/// - Determining contrast ratios between colors
/// - Checking WCAG compliance levels
/// - Suggesting accessible color alternatives
///
/// Example usage:
/// ```swift
/// let textColor = Color.blue
/// let backgroundColor = Color.white
///
/// // Check contrast ratio
/// let ratio = textColor.wcagContrastRatio(with: backgroundColor)
/// print("Contrast ratio: \(ratio):1")
///
/// // Check compliance
/// let compliance = textColor.wcagCompliance(with: backgroundColor)
/// if compliance.passesAA {
///     print("Safe for normal text")
/// }
///
/// // Get suggested accessible color
/// let accessibleColor = backgroundColor.suggestedColor(for: .AA)
/// ```
public extension Color {
    /// Returns the RGBA components of a color.
    ///
    /// This method provides access to the raw color components in the sRGB color space.
    /// Values are normalized to the range 0.0-1.0.
    ///
    /// Example:
    /// ```swift
    /// let color = Color.blue
    /// let components = color.rgbaComponents()
    /// print("Red: \(components.red)")
    /// print("Green: \(components.green)")
    /// print("Blue: \(components.blue)")
    /// print("Alpha: \(components.alpha)")
    /// ```
    ///
    /// - Returns: A tuple containing red, green, blue, and alpha components as Double values (0.0-1.0)
    func rgbaComponents() -> (red: Double, green: Double, blue: Double, alpha: Double) {
        return wcagRGBAComponents()
    }

    /// Calculates the relative luminance of a color as defined by WCAG 2.0.
    ///
    /// Relative luminance represents the perceived brightness of a color, taking into
    /// account human vision's different sensitivities to red, green, and blue light.
    ///
    /// The calculation follows the WCAG 2.0 specification:
    /// 1. Convert sRGB values to linear RGB
    /// 2. Apply luminance coefficients (0.2126R + 0.7152G + 0.0722B)
    ///
    /// Example:
    /// ```swift
    /// let color = Color.blue
    /// let luminance = color.wcagRelativeLuminance()
    /// print("Relative luminance: \(luminance)")
    /// ```
    ///
    /// Opacity is not part of relative luminance. Composite a translucent color over its
    /// background before measuring it.
    ///
    /// - Returns: The relative luminance value between 0 (darkest) and 1 (brightest)
    func wcagRelativeLuminance() -> Double {
        // Check cache first
        if let cachedLuminance = ColorCache.shared.getCachedLuminance(for: self) {
            return cachedLuminance
        }

        let rgba = self.rgbaComponents()
        let luminance = SRGBColorConversion.wcagRelativeLuminance(
            (red: rgba.red, green: rgba.green, blue: rgba.blue)
        )

        // Cache the result
        ColorCache.shared.cacheLuminance(for: self, luminance: luminance)

        return luminance
    }

    /// Calculates the contrast ratio between this color and another color.
    ///
    /// The contrast ratio is calculated according to WCAG 2.0 formula:
    /// (L1 + 0.05) / (L2 + 0.05), where L1 is the lighter color's luminance
    /// and L2 is the darker color's luminance.
    ///
    /// The ratio ranges from 1:1 (no contrast) to 21:1 (black on white).
    ///
    /// Example:
    /// ```swift
    /// let textColor = Color.blue
    /// let backgroundColor = Color.white
    /// let ratio = textColor.wcagContrastRatio(with: backgroundColor)
    /// print("Contrast ratio: \(ratio):1")
    /// ```
    ///
    /// Both colors must be opaque. A translucent color's contrast depends on what shows
    /// through it, which this method is never given, so a translucent input produces a
    /// **declined contrast measurement**: the pair is not measured at all.
    ///
    /// A declined measurement is reported as `1` because this method cannot express
    /// absence in its return type. That `1` is a compatibility sentinel, not a measured
    /// 1:1 ratio, and it is indistinguishable from the genuine ratio of a color against
    /// an identical one. It satisfies no WCAG level, so `wcagCompliance(with:)` reports
    /// no passing levels for a translucent input.
    ///
    /// Use `contrastResult(with:)` or `accessibilityResult(against:targetLevel:)` to tell
    /// the two apart. Both composite a translucent foreground over an explicit opaque
    /// background and return an available measurement. They report an unavailable result
    /// when either input is unresolved or out of the sRGB gamut, or the background is translucent.
    ///
    /// - Parameter color: The color to compare against
    /// - Returns: The contrast ratio between the two colors, or the sentinel `1` when
    ///   either color is translucent.
    func wcagContrastRatio(with color: Color) -> Double {
        // Check cache first
        if let cachedRatio = ColorCache.shared.getCachedContrastRatio(for: self, with: color) {
            return cachedRatio
        }

        let first = self.rgbaComponents()
        let second = color.rgbaComponents()

        // Decline rather than measure. Treating a translucent color as opaque reported a
        // faint overlay as fully saturated: black at ten percent opacity on white
        // measured 21:1, and passed AAA, against its true composited 1.25:1. This method
        // has no background to composite over and no way to return absence, so it
        // reports the sentinel instead.
        guard first.alpha >= 1, second.alpha >= 1 else { return 1 }

        let ratio = SRGBColorConversion.wcagContrastRatio(
            between: (red: first.red, green: first.green, blue: first.blue),
            and: (red: second.red, green: second.green, blue: second.blue)
        )

        // Cache the result
        ColorCache.shared.cacheContrastRatio(for: self, with: color, ratio: ratio)

        return ratio
    }

    /// Checks WCAG compliance between this color and another color.
    ///
    /// This method evaluates the contrast ratio between two colors and determines
    /// which WCAG compliance levels they satisfy. It checks for:
    /// - Level AA (normal text)
    /// - Level AA (large text)
    /// - Level AAA (normal text)
    /// - Level AAA (large text)
    ///
    /// Example:
    /// ```swift
    /// let textColor = Color.blue
    /// let backgroundColor = Color.white
    /// let compliance = textColor.wcagCompliance(with: backgroundColor)
    ///
    /// if compliance.passesAA {
    ///     print("Safe for body text")
    /// } else if compliance.passesAALarge {
    ///     print("Safe for headlines only")
    /// }
    /// ```
    ///
    /// - Parameter color: The color to check compliance against
    /// - Returns: A ``WCAGComplianceResult`` containing detailed compliance information
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

    /// Suggests a black-or-white color to pair with this color.
    ///
    /// This method provides a simple suggestion for an accessible color by recommending
    /// either black or white based on the current color's luminance. For more
    /// sophisticated color suggestions that preserve brand identity, use
    /// ``AccessibilityEnhancer``.
    ///
    /// Example:
    /// ```swift
    /// let backgroundColor = Color.blue
    /// let textColor = backgroundColor.suggestedColor(for: .AA)
    /// Text("Accessible Text")
    ///     .foregroundColor(textColor)
    ///     .background(backgroundColor)
    /// ```
    ///
    /// - Parameter level: The WCAG compliance level to target
    /// - Returns: A black-or-white candidate selected from this color's legacy luminance.
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
