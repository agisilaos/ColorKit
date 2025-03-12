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

public extension Color {
    /// Creates a `Color` from a HEX string.
    ///
    /// This initializer supports both 6-character (RGB) and 8-character (RGBA) HEX strings.
    ///
    /// - Parameter hex: A HEX string representation of the color. Supports `#RRGGBB` and `#RRGGBBAA` formats.
    /// - Returns: A `Color` instance if the HEX string is valid; otherwise, `nil`.
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
    
    /// Returns the HEX representation of the color.
    ///
    /// - Returns: A HEX string in the format `#RRGGBBAA` representing the color, or `nil` if conversion fails.
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
    
    /// Returns the HEX representation of the color.
    /// This is an alias for `hexValue()` for API consistency.
    ///
    /// - Returns: A HEX string in the format `#RRGGBBAA` representing the color, or `nil` if conversion fails.
    func hexString() -> String? {
        return hexValue()
    }
    
    /// Returns the RGBA components of the color as hexadecimal values.
    ///
    /// - Returns: A tuple containing the red, green, blue, and alpha components as hexadecimal values,
    ///           or `nil` if conversion fails.
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
