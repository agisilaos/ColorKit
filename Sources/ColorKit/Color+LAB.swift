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

public extension Color {
    /// Returns the LAB (L*, a*, b*) components of the color.
    ///
    /// - Returns: A tuple containing L* (0-100), a* (-128-127), and b* (-128-127), or `nil` if conversion fails.
    func labComponents() -> (L: CGFloat, a: CGFloat, b: CGFloat)? {
        guard let components = cgColor?.components, components.count >= 3 else { return nil }
        let r = components[0]
        let g = components[1]
        let b = components[2]
        
        // Convert RGB to XYZ
        func linearize(_ v: CGFloat) -> CGFloat {
            v > 0.04045 ? pow((v + 0.055) / 1.055, 2.4) : v / 12.92
        }
        
        let rl = linearize(r)
        let gl = linearize(g)
        let bl = linearize(b)
        
        // Using D65 illuminant
        let x = rl * 0.4124564 + gl * 0.3575761 + bl * 0.1804375
        let y = rl * 0.2126729 + gl * 0.7151522 + bl * 0.0721750
        let z = rl * 0.0193339 + gl * 0.1191920 + bl * 0.9503041
        
        // Convert XYZ to LAB
        func f(_ t: CGFloat) -> CGFloat {
            t > 0.008856 ? pow(t, 1.0/3.0) : (7.787 * t) + (16.0/116.0)
        }
        
        // Reference values for D65 illuminant
        let xn: CGFloat = 0.95047
        let yn: CGFloat = 1.0
        let zn: CGFloat = 1.08883
        
        let fx = f(x/xn)
        let fy = f(y/yn)
        let fz = f(z/zn)
        
        let L = (116.0 * fy) - 16
        let a = 500 * (fx - fy)
        let bValue = 200 * (fy - fz)
        
        return (L, a, bValue)
    }
    
    /// Creates a `Color` from LAB (L*, a*, b*) values.
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
            return t3 > 0.008856 ? t3 : (t - 16.0/116.0) / 7.787
        }
        
        // Reference values for D65 illuminant
        let xn: CGFloat = 0.95047
        let yn: CGFloat = 1.0
        let zn: CGFloat = 1.08883
        
        let x = xn * finv(fx)
        let y = yn * finv(fy)
        let z = zn * finv(fz)
        
        // XYZ to RGB
        let r =  3.2404542 * x - 1.5371385 * y - 0.4985314 * z
        let g = -0.9692660 * x + 1.8760108 * y + 0.0415560 * z
        let b =  0.0556434 * x - 0.2040259 * y + 1.0572252 * z
        
        // Linearized RGB to sRGB
        func delinearize(_ v: CGFloat) -> CGFloat {
            v > 0.0031308 ? 1.055 * pow(v, 1/2.4) - 0.055 : 12.92 * v
        }
        
        let rc = max(0, min(1, delinearize(r)))
        let gc = max(0, min(1, delinearize(g)))
        let bc = max(0, min(1, delinearize(b)))
        
        self.init(red: rc, green: gc, blue: bc)
    }
    
    /// Returns a string representation of the color in LAB format.
    ///
    /// - Returns: A string in the format "lab(L, a, b)" representing the color, or nil if conversion fails.
    func labString() -> String? {
        guard let lab = labComponents() else { return nil }
        
        return String(format: "lab(%.1f, %.1f, %.1f)", lab.L, lab.a, lab.b)
    }
} 