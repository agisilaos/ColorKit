//
//  Color+WCAG.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 25.03.25.
//
//  Description:
//  Extension to get RGBA components of a color.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// Extension providing core WCAG accessibility functionality for SwiftUI's Color type.
///
/// This extension adds methods for:
/// - Extracting RGBA components in the sRGB color space
/// - Generating accessible color suggestions
///
/// These methods form the foundation for ColorKit's WCAG compliance features.
extension Color {
    /// Gets the RGBA components of a color in the sRGB color space.
    ///
    /// This method provides platform-independent access to a color's components,
    /// handling the differences between UIKit and AppKit color representations.
    ///
    /// Example:
    /// ```swift
    /// let color = Color.blue
    /// let components = color.wcagRGBAComponents()
    /// print("Red: \(components.red)")
    /// print("Green: \(components.green)")
    /// print("Blue: \(components.blue)")
    /// print("Alpha: \(components.alpha)")
    /// ```
    ///
    /// - Returns: A tuple containing normalized (0.0-1.0) RGBA components. A color the
    ///   platform cannot resolve, such as a pattern color, reports all zeros, which is
    ///   indistinguishable from transparent black.
    func wcagRGBAComponents() -> (red: Double, green: Double, blue: Double, alpha: Double) {
        AppearanceResolvedSRGBA.resolve(self) ?? (red: 0, green: 0, blue: 0, alpha: 0)
    }

    /// Gets color candidates that target the specified WCAG level when paired with this color.
    ///
    /// This method generates accessible color alternatives that maintain visual harmony
    /// while meeting WCAG contrast requirements. It provides options for preserving
    /// the original color's characteristics.
    ///
    /// Example:
    /// ```swift
    /// let backgroundColor = Color.blue
    /// let textColor = Color.gray
    ///
    /// // Get accessible alternatives
    /// let suggestions = backgroundColor.suggestedAccessibleColors(
    ///     for: textColor,
    ///     level: .AA,
    ///     preserveHue: true
    /// )
    ///
    /// // Use the first suggestion
    /// if let accessibleColor = suggestions.first {
    ///     Text("Accessible Text")
    ///         .foregroundColor(accessibleColor)
    ///         .background(backgroundColor)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - color: The color to improve contrast with
    ///   - level: The WCAG compliance level to achieve (defaults to AA)
    ///   - preserveHue: Whether to try preserving the original hue. If true, will first try to achieve compliance
    ///                  by only adjusting lightness. If false or if lightness adjustment fails, will also adjust saturation.
    /// - Returns: Suggested color candidates. The result may include a black-or-white
    ///   fallback that does not meet the requested level. Assess a selected candidate
    ///   with ``Color/accessibilityResult(against:targetLevel:)`` before use.
    func suggestedAccessibleColors(for color: Color, level: WCAGContrastLevel = .AA, preserveHue: Bool = true) -> [Color] {
        let suggestions = WCAGColorSuggestions(baseColor: self, targetColor: color, targetLevel: level)
        return suggestions.generateSuggestions(preserveHue: preserveHue)
    }
}
