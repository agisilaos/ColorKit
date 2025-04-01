//
//  Color+Hex.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 10.03.25.
//
//  Description:
//  Implements HEX <-> RGB conversion for ColorKit.
//
//  Features:
//  - Converts HEX strings (`#RRGGBB` or `#RRGGBBAA`) into `Color` instances.
//  - Converts `Color` instances back to HEX representation.
//
//  License:
//  MIT License. See LICENSE file for details.
//
import SwiftUI

/// Extension providing hexadecimal color support for SwiftUI's Color type.
///
/// Hexadecimal color representation is widely used in web development and design tools.
/// This extension supports both RGB (#RRGGBB) and RGBA (#RRGGBBAA) formats, where:
/// - RR: Red component (00-FF)
/// - GG: Green component (00-FF)
/// - BB: Blue component (00-FF)
/// - AA: Alpha component (00-FF, optional)
///
/// Key features:
/// - Create colors from hex strings
/// - Convert colors to hex strings
/// - Access individual hex components
/// - Support for opacity/alpha channel
///
/// Example usage:
/// ```swift
/// // Create colors from hex strings
/// let blue = Color(hex: "#0000FF")
/// let translucentRed = Color(hex: "#FF000080")
///
/// // Convert color to hex string
/// if let hexString = Color.green.hexString() {
///     print(hexString)  // "#00FF00FF"
/// }
///
/// // Get individual hex components
/// if let components = Color.purple.hexComponents() {
///     print("Red: #\(components.red)")
///     print("Green: #\(components.green)")
///     print("Blue: #\(components.blue)")
///     print("Alpha: #\(components.alpha)")
/// }
/// ```
public extension Color {
    /// Creates a `Color` from a hexadecimal string.
    ///
    /// This initializer supports both 6-character (RGB) and 8-character (RGBA)
    /// hexadecimal strings, with or without the leading '#' character.
    ///
    /// The conversion process:
    /// 1. Sanitizes the input string (removes whitespace and '#')
    /// 2. Validates the string length (must be 6 or 8 characters)
    /// 3. Parses the hex values into RGB(A) components
    /// 4. Creates a new color with the parsed values
    ///
    /// Example:
    /// ```swift
    /// // RGB format (fully opaque)
    /// let red = Color(hex: "#FF0000")
    /// let green = Color(hex: "00FF00")  // # is optional
    ///
    /// // RGBA format (with alpha)
    /// let translucentBlue = Color(hex: "#0000FF80")
    /// let semiTransparentYellow = Color(hex: "FFFF0040")
    ///
    /// // Using in SwiftUI
    /// Text("Colored Text")
    ///     .foregroundColor(Color(hex: "#FF5500"))
    /// ```
    ///
    /// - Parameter hex: A hexadecimal string representation of the color.
    ///                 Supports `#RRGGBB` and `#RRGGBBAA` formats.
    ///
    init?(hex: String) {
        let r, g, b, a: CGFloat

        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var hexNumber: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&hexNumber) else { return nil }

        switch hexSanitized.count {
        case 6:
            r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255
            g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255
            b = CGFloat(hexNumber & 0x0000FF) / 255
            a = 1.0
        case 8:
            r = CGFloat((hexNumber & 0xFF000000) >> 24) / 255
            g = CGFloat((hexNumber & 0x00FF0000) >> 16) / 255
            b = CGFloat((hexNumber & 0x0000FF00) >> 8) / 255
            a = CGFloat(hexNumber & 0x000000FF) / 255
        default:
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }

    /// Returns the hexadecimal representation of the color.
    ///
    /// This method converts the color's RGB(A) components to a hexadecimal string
    /// in the format #RRGGBBAA. The alpha channel is always included for consistency.
    ///
    /// Example:
    /// ```swift
    /// let color = Color.blue
    /// if let hex = color.hexValue() {
    ///     print(hex)  // "#0000FFFF"
    /// }
    ///
    /// // Use for CSS-style colors
    /// let style = """
    ///     background-color: \(color.hexValue() ?? "#000000");
    /// """
    ///
    /// // Store color preferences
    /// UserDefaults.standard.set(
    ///     color.hexValue(),
    ///     forKey: "accentColor"
    /// )
    /// ```
    ///
    /// - Returns: A hexadecimal string in the format `#RRGGBBAA` representing
    ///           the color, or `nil` if conversion fails.
    func hexValue() -> String? {
        guard let components = cgColor?.components, components.count >= 3 else { return nil }
        let r = components[0]
        let g = components[1]
        let b = components[2]
        let a = components.count >= 4 ? components[3] : 1.0

        return String(format: "#%02X%02X%02X%02X",
                      Int(r * 255),
                      Int(g * 255),
                      Int(b * 255),
                      Int(a * 255))
    }

    /// Returns the hexadecimal representation of the color.
    ///
    /// This is an alias for `hexValue()` that provides a more consistent naming
    /// convention with other color space conversions in ColorKit.
    ///
    /// Example:
    /// ```swift
    /// let colors = [Color.red, Color.green, Color.blue]
    ///
    /// // Print all color formats
    /// colors.forEach { color in
    ///     print("HSL: \(color.hslString() ?? "N/A")")
    ///     print("CMYK: \(color.cmykString() ?? "N/A")")
    ///     print("Hex: \(color.hexString() ?? "N/A")")
    /// }
    /// ```
    ///
    /// - Returns: A hexadecimal string in the format `#RRGGBBAA` representing
    ///           the color, or `nil` if conversion fails.
    func hexString() -> String? {
        return hexValue()
    }

    /// Returns the RGBA components of the color as hexadecimal values.
    ///
    /// This method provides access to individual color components in hexadecimal
    /// format, useful for:
    /// - Color manipulation
    /// - Component-wise comparison
    /// - Custom color string formatting
    /// - Debugging color values
    ///
    /// Example:
    /// ```swift
    /// let color = Color.purple
    /// if let hex = color.hexComponents() {
    ///     // Print individual components
    ///     print("R: #\(hex.red)")   // Red component
    ///     print("G: #\(hex.green)") // Green component
    ///     print("B: #\(hex.blue)")  // Blue component
    ///     print("A: #\(hex.alpha)") // Alpha component
    ///
    ///     // Create custom format
    ///     let rgb = "#\(hex.red)\(hex.green)\(hex.blue)"
    ///     print("RGB only: \(rgb)")
    ///
    ///     // Check if color is pure
    ///     let isPureRed = hex.red == "FF" &&
    ///                     hex.green == "00" &&
    ///                     hex.blue == "00"
    /// }
    /// ```
    ///
    /// - Returns: A tuple containing the red, green, blue, and alpha components
    ///           as hexadecimal values, or `nil` if conversion fails.
    func hexComponents() -> (red: String, green: String, blue: String, alpha: String)? {
        guard let components = cgColor?.components, components.count >= 3 else { return nil }
        let r = components[0]
        let g = components[1]
        let b = components[2]
        let a = components.count >= 4 ? components[3] : 1.0

        return (
            red: String(format: "%02X", Int(r * 255)),
            green: String(format: "%02X", Int(g * 255)),
            blue: String(format: "%02X", Int(b * 255)),
            alpha: String(format: "%02X", Int(a * 255))
        )
    }
}
