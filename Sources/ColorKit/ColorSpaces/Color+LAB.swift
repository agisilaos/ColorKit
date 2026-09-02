//
//  Color+LAB.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 11.03.25.
//
//  Description:
//  Provides utilities to convert between CIE L*a*b* and RGB color models.
//
//  Features:
//  - Extracts L* (Lightness), a* (green-red), and b* (blue-yellow) components from a `Color`.
//  - Creates `Color` instances from LAB values.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// Extension providing CIE L*a*b* color space support for SwiftUI's Color type.
///
/// The CIE L*a*b* color space is designed to be perceptually uniform, meaning that
/// a change of the same amount in a color value should produce a change of about
/// the same visual importance. This makes it ideal for:
///
/// - Measuring color differences
/// - Color matching
/// - Color space transformations
/// - Accessibility calculations
///
/// The components are:
/// - L*: Lightness (0-100)
/// - a*: Green to red axis (-128 to +127)
/// - b*: Blue to yellow axis (-128 to +127)
///
/// Example usage:
/// ```swift
/// // Create a color from LAB values
/// let color = Color(L: 50, a: 30, b: -20)
///
/// // Get LAB components
/// if let lab = color.labComponents() {
///     print("L*: \(lab.L)")  // Lightness
///     print("a*: \(lab.a)")  // Green-Red
///     print("b*: \(lab.b)")  // Blue-Yellow
/// }
///
/// // Get string representation
/// if let labStr = color.labString() {
///     print(labStr)  // "lab(50.0, 30.0, -20.0)"
/// }
/// ```
public extension Color {
    /// Returns the LAB (L*, a*, b*) components of the color.
    ///
    /// This method converts the color from sRGB to the CIE L*a*b* color space
    /// using the D65 illuminant as the white point. The conversion process:
    ///
    /// 1. Converts sRGB to linear RGB
    /// 2. Converts linear RGB to CIE XYZ
    /// 3. Converts CIE XYZ to CIE L*a*b*
    ///
    /// Fixed RGB and grayscale colors are first resolved to nonlinear sRGB. Finite
    /// extended-range channels are preserved without gamut mapping, so LAB can describe
    /// colors outside the sRGB gamut. Alpha does not affect the LAB coordinates.
    /// Dynamic colors must be resolved for a specific appearance before conversion.
    ///
    /// The results are cached for performance in subsequent calls.
    ///
    /// Example:
    /// ```swift
    /// let color = Color.blue
    /// if let lab = color.labComponents() {
    ///     // Use L* for lightness-based decisions
    ///     if lab.L > 50 {
    ///         print("Light color")
    ///     }
    ///
    ///     // Use a* and b* for color adjustments
    ///     let redder = Color(
    ///         L: lab.L,
    ///         a: lab.a + 20,  // More red
    ///         b: lab.b
    ///     )
    /// }
    /// ```
    ///
    /// - Returns: A tuple containing L*, a*, and b*, or `nil` if the color cannot be
    ///            resolved or conversion does not produce finite coordinates.
    func labComponents() -> (L: CGFloat, a: CGFloat, b: CGFloat)? {
        if let cachedComponents = ColorCache.shared.getCachedLABComponents(for: self) {
            return cachedComponents
        }

        guard let resolved = ResolvedSRGBA.resolve(self) else { return nil }
        let xyz = SRGBColorConversion.xyz(
            from: (Double(resolved.red), Double(resolved.green), Double(resolved.blue))
        )
        let lab = SRGBColorConversion.lab(from: xyz)
        guard lab.l.isFinite, lab.a.isFinite, lab.b.isFinite else { return nil }
        let result = (L: CGFloat(lab.l), a: CGFloat(lab.a), b: CGFloat(lab.b))

        ColorCache.shared.cacheLABComponents(for: self, L: result.L, a: result.a, b: result.b)

        return result
    }

    /// Creates a `Color` from LAB (L*, a*, b*) values.
    ///
    /// This initializer converts CIE L*a*b* values to sRGB color space using
    /// the D65 illuminant as the white point. The conversion process:
    ///
    /// 1. Clamps input values to valid ranges
    /// 2. Converts L*a*b* to CIE XYZ
    /// 3. Converts CIE XYZ to linear RGB
    /// 4. Converts linear RGB to sRGB
    ///
    /// Example:
    /// ```swift
    /// // Create a light reddish color
    /// let color = Color(
    ///     L: 70,  // Light
    ///     a: 40,  // Towards red
    ///     b: 0    // Neutral on blue-yellow axis
    /// )
    ///
    /// // Create a dark bluish color
    /// let darkBlue = Color(
    ///     L: 30,  // Dark
    ///     a: 0,   // Neutral on green-red axis
    ///     b: -40  // Towards blue
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - L: The lightness value (0-100)
    ///   - a: The a* value (-128-127), representing green to red
    ///   - b: The b* value (-128-127), representing blue to yellow
    init(L: CGFloat, a: CGFloat, b: CGFloat) {
        // Clamp values to valid ranges
        let clampedL = max(0, min(100, L))
        let clampedA = max(-128, min(127, a))
        let clampedB = max(-128, min(127, b))

        // LAB to XYZ
        let fy = (clampedL + 16) / 116
        let fx = clampedA / 500 + fy
        let fz = fy - clampedB / 200

        func finv(_ t: CGFloat) -> CGFloat {
            let t3 = pow(t, 3.0)
            return t3 > 0.008856 ? t3 : (t - 16.0 / 116.0) / 7.787
        }

        // Reference values for D65 illuminant
        let xn: CGFloat = 0.95047
        let yn: CGFloat = 1.0
        let zn: CGFloat = 1.08883

        let x = xn * finv(fx)
        let y = yn * finv(fy)
        let z = zn * finv(fz)

        // XYZ to RGB
        let r = 3.2404542 * x - 1.5371385 * y - 0.4985314 * z
        let g = -0.9692660 * x + 1.8760108 * y + 0.0415560 * z
        let b = 0.0556434 * x - 0.2040259 * y + 1.0572252 * z

        // Linearized RGB to sRGB
        func delinearize(_ v: CGFloat) -> CGFloat {
            v > 0.0031308 ? 1.055 * pow(v, 1 / 2.4) - 0.055 : 12.92 * v
        }

        let rc = max(0, min(1, delinearize(r)))
        let gc = max(0, min(1, delinearize(g)))
        let bc = max(0, min(1, delinearize(b)))

        self.init(red: rc, green: gc, blue: bc)
    }

    /// Returns a string representation of the color in LAB format.
    ///
    /// This method provides a standardized string format for LAB colors,
    /// useful for debugging, logging, or displaying color information.
    ///
    /// Example:
    /// ```swift
    /// let color = Color(L: 50, a: 30, b: -20)
    /// if let labStr = color.labString() {
    ///     print(labStr)  // Prints: "lab(50.0, 30.0, -20.0)"
    /// }
    ///
    /// // Use for color debugging
    /// Text("Sample")
    ///     .foregroundColor(color)
    ///     .onAppear {
    ///         print("Text color: \(color.labString() ?? "unknown")")
    ///     }
    /// ```
    ///
    /// - Returns: A string in the format "lab(L, a, b)" representing the color,
    ///           or nil if conversion fails.
    func labString() -> String? {
        guard let lab = labComponents() else { return nil }

        return String(format: "lab(%.1f, %.1f, %.1f)", lab.L, lab.a, lab.b)
    }
}
