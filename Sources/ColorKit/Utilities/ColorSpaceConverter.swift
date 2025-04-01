//
//  ColorSpaceConverter.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 25.03.25.
//
//  Description:
//  A utility for converting colors between different color spaces.
//
//  Features:
//  - Convert colors between RGB, HSL, HSB, CMYK, LAB, and XYZ color spaces
//
//  License:
//  MIT License. See LICENSE file for details.

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A utility for converting colors between different color spaces.
///
/// `ColorSpaceConverter` provides methods to convert colors between various color spaces including:
/// - RGB (Red, Green, Blue)
/// - HSL (Hue, Saturation, Lightness)
/// - HSB (Hue, Saturation, Brightness)
/// - CMYK (Cyan, Magenta, Yellow, Key)
/// - LAB (Lightness, a*, b*)
/// - XYZ (CIE XYZ)
///
/// Example usage:
/// ```swift
/// let color = Color.red
/// let converter = ColorSpaceConverter(color: color)
/// let components = converter.getAllColorComponents()
///
/// // Access different color space representations
/// let lab = components.lab
/// print("L: \(lab.l), a: \(lab.a), b: \(lab.b)")
/// ```
public struct ColorSpaceConverter {
    private let color: Color

    /// Creates a new color space converter for a specific color.
    /// - Parameter color: The color to convert between different color spaces.
    public init(color: Color) {
        self.color = color
    }

    /// Get all color components in various color spaces.
    ///
    /// This method converts the color to all supported color spaces and returns their components
    /// in a single structure. This is useful when you need to analyze or compare a color across
    /// different color spaces.
    ///
    /// Example:
    /// ```swift
    /// let converter = ColorSpaceConverter(color: .blue)
    /// let components = converter.getAllColorComponents()
    ///
    /// // Access RGB components
    /// print("R: \(components.rgb.red), G: \(components.rgb.green), B: \(components.rgb.blue)")
    ///
    /// // Access LAB components
    /// print("L: \(components.lab.l), a: \(components.lab.a), b: \(components.lab.b)")
    /// ```
    ///
    /// - Returns: A ``ColorComponents`` structure containing all color space representations
    public func getAllColorComponents() -> ColorComponents {
        let rgb = color.rgbaComponents()

        // Get HSL
        let hsl = color.hslComponents() ?? (hue: 0, saturation: 0, lightness: 0)

        // Get HSB
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        #if canImport(UIKit)
        UIColor(self.color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        #elseif canImport(AppKit)
        let nsColor = NSColor(self.color)
        // Convert to RGB colorspace first to avoid NSInvalidArgumentException
        if let rgbColor = nsColor.usingColorSpace(.sRGB) {
            rgbColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        }
        #endif

        let hsb = (hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness))

        // Get CMYK
        let cmykComponents = color.cmykComponents() ?? (cyan: 0, magenta: 0, yellow: 0, key: 0)
        let cmyk = (
            cyan: Double(cmykComponents.cyan),
            magenta: Double(cmykComponents.magenta),
            yellow: Double(cmykComponents.yellow),
            key: Double(cmykComponents.key)
        )

        // Get LAB
        let lab = calculateLAB(from: rgb)

        // Get XYZ
        let xyz = calculateXYZ(from: rgb)

        return ColorComponents(
            rgb: rgb,
            hsl: (Double(hsl.hue), Double(hsl.saturation), Double(hsl.lightness)),
            hsb: hsb,
            cmyk: cmyk,
            lab: lab,
            xyz: xyz
        )
    }

    /// Calculate LAB color components from RGB values.
    ///
    /// This method implements the conversion from RGB to LAB color space using the D65 white point.
    /// The conversion happens in two steps:
    /// 1. RGB to XYZ
    /// 2. XYZ to LAB
    ///
    /// - Parameter rgb: A tuple containing the red, green, blue, and alpha components
    /// - Returns: A tuple containing the LAB components (L, a, b)
    private func calculateLAB(from rgb: (red: Double, green: Double, blue: Double, alpha: Double)) -> (l: Double, a: Double, b: Double) {
        // First convert RGB to XYZ
        let xyz = calculateXYZ(from: rgb)

        // XYZ to LAB
        // Using D65 reference white
        let refX: Double = 95.047
        let refY: Double = 100.0
        let refZ: Double = 108.883

        let x = xyz.x / refX
        let y = xyz.y / refY
        let z = xyz.z / refZ

        let fx = x > 0.008856 ? pow(x, 1 / 3) : (7.787 * x) + (16 / 116)
        let fy = y > 0.008856 ? pow(y, 1 / 3) : (7.787 * y) + (16 / 116)
        let fz = z > 0.008856 ? pow(z, 1 / 3) : (7.787 * z) + (16 / 116)

        let l = (116 * fy) - 16
        let a = 500 * (fx - fy)
        let b = 200 * (fy - fz)

        return (l, a, b)
    }

    /// Calculate XYZ color components from RGB values.
    ///
    /// This method converts RGB values to CIE XYZ color space. The conversion process:
    /// 1. Converts RGB to linear RGB
    /// 2. Applies the RGB to XYZ transformation matrix
    ///
    /// - Parameter rgb: A tuple containing the red, green, blue, and alpha components
    /// - Returns: A tuple containing the XYZ components (x, y, z)
    private func calculateXYZ(from rgb: (red: Double, green: Double, blue: Double, alpha: Double)) -> (x: Double, y: Double, z: Double) {
        // Convert RGB to linear RGB
        let r = rgb.red <= 0.04045 ? rgb.red / 12.92 : pow((rgb.red + 0.055) / 1.055, 2.4)
        let g = rgb.green <= 0.04045 ? rgb.green / 12.92 : pow((rgb.green + 0.055) / 1.055, 2.4)
        let b = rgb.blue <= 0.04045 ? rgb.blue / 12.92 : pow((rgb.blue + 0.055) / 1.055, 2.4)

        // Convert linear RGB to XYZ
        let x = r * 0.4124 + g * 0.3576 + b * 0.1805
        let y = r * 0.2126 + g * 0.7152 + b * 0.0722
        let z = r * 0.0193 + g * 0.1192 + b * 0.9505

        return (x * 100, y * 100, z * 100)
    }
}
