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

public extension Color {
    /// Returns the CMYK (Cyan, Magenta, Yellow, Key/Black) components of the color.
    ///
    /// - Returns: A tuple containing cyan (0.0 - 1.0), magenta (0.0 - 1.0), yellow (0.0 - 1.0), and key/black (0.0 - 1.0),
    ///           or `nil` if conversion fails.
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
    /// - Parameters:
    ///   - cyan: The cyan value (0.0 - 1.0)
    ///   - magenta: The magenta value (0.0 - 1.0)
    ///   - yellow: The yellow value (0.0 - 1.0)
    ///   - key: The key (black) value (0.0 - 1.0)
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
    /// - Returns: A string in the format "cmyk(c%, m%, y%, k%)" representing the color, or nil if conversion fails.
    func cmykString() -> String? {
        guard let cmyk = cmykComponents() else { return nil }
        
        let c = Int(cmyk.cyan * 100)
        let m = Int(cmyk.magenta * 100)
        let y = Int(cmyk.yellow * 100)
        let k = Int(cmyk.key * 100)
        
        return "cmyk(\(c)%, \(m)%, \(y)%, \(k)%)"
    }
} 