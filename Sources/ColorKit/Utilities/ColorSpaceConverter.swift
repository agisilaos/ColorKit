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
    /// LAB and XYZ share the D65 conversion used by `Color.labComponents()`.
    /// XYZ uses a relative scale where the reference white has Y = 100.
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

        let xyz = SRGBColorConversion.xyz(from: (rgb.red, rgb.green, rgb.blue))
        let lab = SRGBColorConversion.lab(from: xyz)

        return ColorComponents(
            rgb: rgb,
            hsl: (Double(hsl.hue), Double(hsl.saturation), Double(hsl.lightness)),
            hsb: hsb,
            cmyk: cmyk,
            lab: lab,
            xyz: (x: xyz.x * 100, y: xyz.y * 100, z: xyz.z * 100)
        )
    }
}

/// Pure sRGB/D65 conversions. Internal XYZ uses reference-white Y = 1.
enum SRGBColorConversion {
    static func xyz(from rgb: (red: Double, green: Double, blue: Double)) -> (x: Double, y: Double, z: Double) {
        func linearize(_ value: Double) -> Double {
            value > 0.04045 ? pow((value + 0.055) / 1.055, 2.4) : value / 12.92
        }

        let r = linearize(rgb.red)
        let g = linearize(rgb.green)
        let b = linearize(rgb.blue)

        return (
            x: r * 0.4124564 + g * 0.3575761 + b * 0.1804375,
            y: r * 0.2126729 + g * 0.7151522 + b * 0.0721750,
            z: r * 0.0193339 + g * 0.1191920 + b * 0.9503041
        )
    }

    static func lab(from xyz: (x: Double, y: Double, z: Double)) -> (l: Double, a: Double, b: Double) {
        // Keep the existing LAB threshold and slope, also used by the inverse.
        func transform(_ value: Double) -> Double {
            value > 0.008856 ? pow(value, 1.0 / 3.0) : 7.787 * value + 16.0 / 116.0
        }

        let fx = transform(xyz.x / 0.95047)
        let fy = transform(xyz.y)
        let fz = transform(xyz.z / 1.08883)

        return (l: 116 * fy - 16, a: 500 * (fx - fy), b: 200 * (fy - fz))
    }
}
