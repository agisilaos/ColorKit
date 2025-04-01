//
//  Color+CMYK.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 11.03.25.
//
//  Description:
//  Provides utilities to convert between CMYK and RGB color models.
//
//  Features:
//  - Extracts Cyan, Magenta, Yellow, and Key (Black) components from a `Color`.
//  - Creates `Color` instances from CMYK values.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// Extension providing CMYK (Cyan, Magenta, Yellow, Key) color space support for SwiftUI's Color type.
///
/// The CMYK color space is primarily used in printing and physical color reproduction:
/// - Cyan: Cyan ink amount (0-100%, normalized to 0.0-1.0)
/// - Magenta: Magenta ink amount (0-100%, normalized to 0.0-1.0)
/// - Yellow: Yellow ink amount (0-100%, normalized to 0.0-1.0)
/// - Key (Black): Black ink amount (0-100%, normalized to 0.0-1.0)
///
/// CMYK is essential for:
/// - Print design and production
/// - Color separations
/// - Professional printing workflows
/// - Print preview and soft proofing
///
/// Example usage:
/// ```swift
/// // Create a color from CMYK values
/// let color = Color(
///     cyan: 1.0,    // 100% cyan
///     magenta: 0.0, // 0% magenta
///     yellow: 0.0,  // 0% yellow
///     key: 0.0      // 0% black
/// )
///
/// // Get CMYK components
/// if let cmyk = color.cmykComponents() {
///     print("Cyan: \(cmyk.cyan * 100)%")
///     print("Magenta: \(cmyk.magenta * 100)%")
///     print("Yellow: \(cmyk.yellow * 100)%")
///     print("Black: \(cmyk.key * 100)%")
/// }
///
/// // Get string representation
/// if let cmykStr = color.cmykString() {
///     print(cmykStr)  // "cmyk(100%, 0%, 0%, 0%)"
/// }
/// ```
public extension Color {
    /// Returns the CMYK (Cyan, Magenta, Yellow, Key/Black) components of the color.
    ///
    /// This method converts the color from sRGB to CMYK color space. The conversion
    /// process:
    /// 1. Determines the black (Key) component from RGB values
    /// 2. Calculates CMY values accounting for the black component
    /// 3. Handles special cases like pure black
    ///
    /// Example:
    /// ```swift
    /// let color = Color.blue
    /// if let cmyk = color.cmykComponents() {
    ///     // Check if it's a pure process color
    ///     if cmyk.key == 0 {
    ///         print("Pure process color")
    ///     }
    ///
    ///     // Calculate ink coverage
    ///     let totalInk = cmyk.cyan + cmyk.magenta +
    ///                    cmyk.yellow + cmyk.key
    ///     print("Total ink coverage: \(totalInk * 100)%")
    ///
    ///     // Create a richer black
    ///     let richBlack = Color(
    ///         cyan: 0.6,
    ///         magenta: 0.5,
    ///         yellow: 0.5,
    ///         key: 1.0
    ///     )
    /// }
    /// ```
    ///
    /// - Returns: A tuple containing cyan (0.0-1.0), magenta (0.0-1.0),
    ///           yellow (0.0-1.0), and key/black (0.0-1.0), or `nil` if
    ///           conversion fails.
    func cmykComponents() -> (cyan: CGFloat, magenta: CGFloat, yellow: CGFloat, key: CGFloat)? {
        guard let components = cgColor?.components, components.count >= 3 else { return nil }
        let r = components[0]
        let g = components[1]
        let b = components[2]

        let k = 1 - max(r, g, b)

        // Avoid division by zero
        if k == 1 {
            return (0, 0, 0, 1)
        }

        let c = (1 - r - k) / (1 - k)
        let m = (1 - g - k) / (1 - k)
        let y = (1 - b - k) / (1 - k)

        return (c, m, y, k)
    }

    /// Creates a `Color` from CMYK (Cyan, Magenta, Yellow, Key/Black) values.
    ///
    /// This initializer converts CMYK values to sRGB color space. The conversion
    /// process:
    /// 1. Clamps all input values to valid ranges (0.0-1.0)
    /// 2. Calculates RGB values accounting for black component
    /// 3. Creates a new color in the sRGB color space
    ///
    /// Example:
    /// ```swift
    /// // Create process colors
    /// let processCyan = Color(
    ///     cyan: 1.0,
    ///     magenta: 0.0,
    ///     yellow: 0.0,
    ///     key: 0.0
    /// )
    ///
    /// // Create rich black (better for printing)
    /// let richBlack = Color(
    ///     cyan: 0.6,
    ///     magenta: 0.5,
    ///     yellow: 0.5,
    ///     key: 1.0
    /// )
    ///
    /// // Create a muted color
    /// let muted = Color(
    ///     cyan: 0.2,
    ///     magenta: 0.4,
    ///     yellow: 0.3,
    ///     key: 0.1
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - cyan: The cyan value (0.0-1.0)
    ///   - magenta: The magenta value (0.0-1.0)
    ///   - yellow: The yellow value (0.0-1.0)
    ///   - key: The key (black) value (0.0-1.0)
    init(cyan: CGFloat, magenta: CGFloat, yellow: CGFloat, key: CGFloat) {
        // Clamp values to valid ranges
        let clampedCyan = max(0, min(1, cyan))
        let clampedMagenta = max(0, min(1, magenta))
        let clampedYellow = max(0, min(1, yellow))
        let clampedKey = max(0, min(1, key))

        let r = (1 - clampedCyan) * (1 - clampedKey)
        let g = (1 - clampedMagenta) * (1 - clampedKey)
        let b = (1 - clampedYellow) * (1 - clampedKey)

        self.init(red: r, green: g, blue: b)
    }

    /// Returns a string representation of the color in CMYK format.
    ///
    /// This method provides a standardized string format for CMYK colors,
    /// converting the normalized values (0.0-1.0) to percentages (0-100%).
    /// Useful for:
    /// - Print specifications
    /// - Color communication with print providers
    /// - Debugging print-related color issues
    ///
    /// Example:
    /// ```swift
    /// // Create and display process colors
    /// let processColors = [
    ///     Color(cyan: 1.0, magenta: 0, yellow: 0, key: 0),
    ///     Color(cyan: 0, magenta: 1.0, yellow: 0, key: 0),
    ///     Color(cyan: 0, magenta: 0, yellow: 1.0, key: 0)
    /// ]
    ///
    /// processColors.forEach { color in
    ///     print(color.cmykString() ?? "unknown")
    /// }
    ///
    /// // Print specifications
    /// let brandColor = Color(cyan: 0.85, magenta: 0.21,
    ///                       yellow: 0, key: 0)
    /// print("Brand color spec: \(brandColor.cmykString() ?? "N/A")")
    /// ```
    ///
    /// - Returns: A string in the format "cmyk(c%, m%, y%, k%)" representing
    ///           the color, or nil if conversion fails.
    func cmykString() -> String? {
        guard let cmyk = cmykComponents() else { return nil }

        let c = Int(cmyk.cyan * 100)
        let m = Int(cmyk.magenta * 100)
        let y = Int(cmyk.yellow * 100)
        let k = Int(cmyk.key * 100)

        return "cmyk(\(c)%, \(m)%, \(y)%, \(k)%)"
    }
}
