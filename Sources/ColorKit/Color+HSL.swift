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

public extension Color {
    /// Returns the HSL (Hue, Saturation, Lightness) components of the color.
    ///
    /// - Returns: A tuple containing hue (0.0 - 1.0), saturation (0.0 - 1.0), and lightness (0.0 - 1.0), or `nil` if conversion fails.
    func hslComponents() -> (hue: CGFloat, saturation: CGFloat, lightness: CGFloat)? {
        guard let components = cgColor?.components, components.count >= 3 else { return nil }
        let r = components[0]
        let g = components[1]
        let b = components[2]
        
        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        let delta = maxVal - minVal
        
        var h: CGFloat = 0
        var s: CGFloat = 0
        let l = (maxVal + minVal) / 2
        
        if delta != 0 {
            s = l > 0.5 ? delta / (2.0 - maxVal - minVal) : delta / (maxVal + minVal)
            if maxVal == r {
                h = (g - b) / delta + (g < b ? 6 : 0)
            } else if maxVal == g {
                h = (b - r) / delta + 2
            } else if maxVal == b {
                h = (r - g) / delta + 4
            }
            h /= 6
        }
        
        return (h, s, l)
    }
    
    /// Creates a `Color` from HSL (Hue, Saturation, Lightness) values.
    ///
    /// - Parameters:
    ///   - hue: The hue value (0.0 - 1.0), representing the color's shade on the color wheel.
    ///   - saturation: The saturation value (0.0 - 1.0), representing the intensity of the color.
    ///   - lightness: The lightness value (0.0 - 1.0), representing how bright or dark the color is.
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
    /// - Returns: A string in the format "hsl(h, s%, l%)" representing the color, or nil if conversion fails.
    func hslString() -> String? {
        guard let hsl = hslComponents() else { return nil }
        
        let h = Int(hsl.hue * 360)
        let s = Int(hsl.saturation * 100)
        let l = Int(hsl.lightness * 100)
        
        return "hsl(\(h), \(s)%, \(l)%)"
    }
}
