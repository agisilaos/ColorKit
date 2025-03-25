//
//  ColorComponents.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 25.03.25.
//
//  Description:
//  Provides a structure to represent color components in various color spaces.
//
//  Features:
//  - RGB color components
//  - HSL color components
//  - HSB color components
//  - CMYK color components
//  - LAB color components
//  - XYZ color components
//
//  License:
//  MIT License. See LICENSE file for details.

/// A structure that represents color components in various color spaces
public struct ColorComponents: Sendable {
    /// RGB color components
    public let rgb: (red: Double, green: Double, blue: Double, alpha: Double)
    /// HSL color components
    public let hsl: (hue: Double, saturation: Double, lightness: Double)
    /// HSB color components
    public let hsb: (hue: Double, saturation: Double, brightness: Double)
    /// CMYK color components
    public let cmyk: (cyan: Double, magenta: Double, yellow: Double, key: Double)
    /// LAB color components
    public let lab: (l: Double, a: Double, b: Double)
    /// XYZ color components
    public let xyz: (x: Double, y: Double, z: Double)

    /// A human-readable description of the color components
    public var description: String {
        """
        RGB:
        - Red: \(String(format: "%.2f", rgb.red * 255)) (\(String(format: "%.2f", rgb.red)))
        - Green: \(String(format: "%.2f", rgb.green * 255)) (\(String(format: "%.2f", rgb.green)))
        - Blue: \(String(format: "%.2f", rgb.blue * 255)) (\(String(format: "%.2f", rgb.blue)))
        - Alpha: \(String(format: "%.2f", rgb.alpha))

        HSL:
        - Hue: \(String(format: "%.2f", hsl.hue * 360))°
        - Saturation: \(String(format: "%.2f", hsl.saturation * 100))%
        - Lightness: \(String(format: "%.2f", hsl.lightness * 100))%

        HSB:
        - Hue: \(String(format: "%.2f", hsb.hue * 360))°
        - Saturation: \(String(format: "%.2f", hsb.saturation * 100))%
        - Brightness: \(String(format: "%.2f", hsb.brightness * 100))%

        CMYK:
        - Cyan: \(String(format: "%.2f", cmyk.cyan * 100))%
        - Magenta: \(String(format: "%.2f", cmyk.magenta * 100))%
        - Yellow: \(String(format: "%.2f", cmyk.yellow * 100))%
        - Key: \(String(format: "%.2f", cmyk.key * 100))%

        LAB:
        - L: \(String(format: "%.2f", lab.l))
        - a: \(String(format: "%.2f", lab.a))
        - b: \(String(format: "%.2f", lab.b))

        XYZ:
        - X: \(String(format: "%.2f", xyz.x))
        - Y: \(String(format: "%.2f", xyz.y))
        - Z: \(String(format: "%.2f", xyz.z))
        """
    }
}
