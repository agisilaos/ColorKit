//
//  Color+HSL.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 10.03.25.
//
//  Description:
//  Provides utilities to convert between HSL and RGB color models.
//
//  Features:
//  - Extracts Hue, Saturation, and Lightness (HSL) components from a `Color`.
//  - Creates `Color` instances from HSL values.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// Extension providing HSL (Hue, Saturation, Lightness) color space support for SwiftUI's Color type.
///
/// The HSL color space is a more intuitive way to think about colors than RGB:
/// - Hue: The basic color (0° to 360°, normalized to 0.0-1.0)
/// - Saturation: The intensity or purity (0% to 100%, normalized to 0.0-1.0)
/// - Lightness: The brightness (0% to 100%, normalized to 0.0-1.0)
///
/// HSL is particularly useful for:
/// - Color manipulation and adjustment
/// - Creating color schemes
/// - Generating color variations
/// - User interfaces for color selection
///
/// Example usage:
/// ```swift
/// // Create a color from HSL values
/// let color = Color(
///     hue: 0.6,        // Blue (60% around color wheel)
///     saturation: 0.8, // Quite saturated
///     lightness: 0.5   // Medium brightness
/// )
///
/// // Get HSL components
/// if let hsl = color.hslComponents() {
///     print("Hue: \(hsl.hue * 360)°")
///     print("Saturation: \(hsl.saturation * 100)%")
///     print("Lightness: \(hsl.lightness * 100)%")
/// }
///
/// // Get string representation
/// if let hslStr = color.hslString() {
///     print(hslStr)  // "hsl(216, 80%, 50%)"
/// }
/// ```
public extension Color {
    /// Returns the HSL (Hue, Saturation, Lightness) components of the color.
    ///
    /// This method converts the color from sRGB to HSL color space. The conversion
    /// process involves finding the minimum and maximum RGB components to determine
    /// lightness, then calculating saturation and hue based on their relationships.
    ///
    /// The results are cached for performance in subsequent calls.
    ///
    /// Example:
    /// ```swift
    /// let color = Color.blue
    /// if let hsl = color.hslComponents() {
    ///     // Create a lighter version
    ///     let lighter = Color(
    ///         hue: hsl.hue,
    ///         saturation: hsl.saturation,
    ///         lightness: min(1, hsl.lightness + 0.2)
    ///     )
    ///
    ///     // Create a more saturated version
    ///     let vibrant = Color(
    ///         hue: hsl.hue,
    ///         saturation: min(1, hsl.saturation + 0.3),
    ///         lightness: hsl.lightness
    ///     )
    /// }
    /// ```
    ///
    /// HSL is defined on sRGB, so the color is resolved for the current appearance and a
    /// wider-gamut color is clamped into sRGB. Opacity is not part of HSL.
    ///
    /// - Returns: A tuple containing hue (0.0-1.0), saturation (0.0-1.0),
    ///           and lightness (0.0-1.0), or `nil` when the color cannot be resolved to
    ///           sRGB components at all, as for a pattern color.
    func hslComponents() -> (hue: CGFloat, saturation: CGFloat, lightness: CGFloat)? {
        // Check cache first
        if let cachedComponents = ColorCache.shared.getCachedHSLComponents(for: self) {
            return cachedComponents
        }

        // Resolve through the platform types. Reading raw cgColor components required at
        // least three of them, so named SwiftUI colors and grayscale reported no value and
        // silently made adjustedForMode(isDarkMode:) and adjustedForAccessibility no-ops.
        guard let components = AppearanceResolvedSRGBA.resolve(self) else { return nil }

        // UIKit returns extended sRGB values; HSL requires components in 0-1.
        let hsl = SRGBColorConversion.hsl(
            from: (
                red: min(1, max(0, components.red)),
                green: min(1, max(0, components.green)),
                blue: min(1, max(0, components.blue))
            )
        )
        let h = CGFloat(hsl.hue)
        let s = CGFloat(hsl.saturation)
        let l = CGFloat(hsl.lightness)

        // Cache the result
        ColorCache.shared.cacheHSLComponents(for: self, hue: h, saturation: s, lightness: l)

        return (h, s, l)
    }

    /// Creates a `Color` from HSL (Hue, Saturation, Lightness) values.
    ///
    /// This initializer converts HSL values to sRGB color space. The conversion
    /// process:
    /// 1. Clamps input values to valid ranges
    /// 2. Calculates chroma and intermediate values
    /// 3. Converts to RGB based on hue sector
    /// 4. Adjusts for lightness
    ///
    /// Example:
    /// ```swift
    /// // Create a pastel blue
    /// let pastelBlue = Color(
    ///     hue: 0.6,        // Blue
    ///     saturation: 0.4, // Less saturated
    ///     lightness: 0.8   // Bright
    /// )
    ///
    /// // Create a deep purple
    /// let deepPurple = Color(
    ///     hue: 0.75,       // Purple
    ///     saturation: 0.8, // Highly saturated
    ///     lightness: 0.3   // Dark
    /// )
    ///
    /// // Create a pure gray (saturation = 0)
    /// let gray = Color(
    ///     hue: 0,          // Hue doesn't matter
    ///     saturation: 0,   // No color
    ///     lightness: 0.5   // Medium brightness
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - hue: The hue value (0.0-1.0), representing the color's shade on the color wheel
    ///   - saturation: The saturation value (0.0-1.0), representing the intensity of the color
    ///   - lightness: The lightness value (0.0-1.0), representing how bright or dark the color is
    init(hue: CGFloat, saturation: CGFloat, lightness: CGFloat) {
        // Clamp values to valid ranges
        let clampedHue = fmod(max(0, hue), 1.0)
        let clampedSaturation = max(0, min(1, saturation))
        let clampedLightness = max(0, min(1, lightness))

        let c = (1 - abs(2 * clampedLightness - 1)) * clampedSaturation
        let x = c * (1 - abs(fmod(clampedHue * 6, 2) - 1))
        let m = clampedLightness - c / 2

        let (r, g, b): (CGFloat, CGFloat, CGFloat)
        switch clampedHue * 6 {
        case 0..<1: (r, g, b) = (c, x, 0)
        case 1..<2: (r, g, b) = (x, c, 0)
        case 2..<3: (r, g, b) = (0, c, x)
        case 3..<4: (r, g, b) = (0, x, c)
        case 4..<5: (r, g, b) = (x, 0, c)
        case 5..<6: (r, g, b) = (c, 0, x)
        default: (r, g, b) = (0, 0, 0)
        }

        self.init(red: r + m, green: g + m, blue: b + m)
    }

    /// Returns a string representation of the color in HSL format.
    ///
    /// This method provides a standardized string format for HSL colors,
    /// converting the normalized values (0.0-1.0) to their conventional
    /// ranges (hue: 0-360, saturation/lightness: 0-100%).
    ///
    /// Example:
    /// ```swift
    /// let color = Color(
    ///     hue: 0.33,       // 120° (Green)
    ///     saturation: 0.5, // 50%
    ///     lightness: 0.75  // 75%
    /// )
    ///
    /// if let hslStr = color.hslString() {
    ///     print(hslStr)  // Prints: "hsl(120, 50%, 75%)"
    /// }
    ///
    /// // Use for debugging color schemes
    /// let colors = [
    ///     Color(hue: 0.0, saturation: 0.8, lightness: 0.5),
    ///     Color(hue: 0.33, saturation: 0.8, lightness: 0.5),
    ///     Color(hue: 0.66, saturation: 0.8, lightness: 0.5)
    /// ]
    ///
    /// colors.forEach { color in
    ///     print(color.hslString() ?? "unknown")
    /// }
    /// ```
    ///
    /// - Returns: A string in the format "hsl(h, s%, l%)" representing the color,
    ///           or nil if conversion fails.
    func hslString() -> String? {
        guard let hsl = hslComponents() else { return nil }

        let h = Int(hsl.hue * 360)
        let s = Int(hsl.saturation * 100)
        let l = Int(hsl.lightness * 100)

        return "hsl(\(h), \(s)%, \(l)%)"
    }
}
