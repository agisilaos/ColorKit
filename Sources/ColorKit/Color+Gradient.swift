//
//  Color+Gradient.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 11.03.25.
//
//  Description:
//  Provides utilities for generating and manipulating color gradients.
//
//  Features:
//  - Linear gradient generation between colors
//  - Color interpolation in different color spaces (RGB, HSL, LAB)
//  - Gradient palette generation with customizable steps
//  - Complementary and analogous gradient generation
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

// MARK: - Gradient Generation
public extension Color {
    /// Creates a linear gradient between two colors with a specified number of steps.
    ///
    /// - Parameters:
    ///   - to: The destination color.
    ///   - steps: The number of color steps to generate (including start and end colors).
    ///   - colorSpace: The color space in which to perform the interpolation.
    /// - Returns: An array of colors representing the gradient.
    func linearGradient(to: Color, steps: Int, in colorSpace: GradientColorSpace = .rgb) -> [Color] {
        guard steps > 1 else { return [self] }
        
        var colors: [Color] = []
        
        for step in 0..<steps {
            let amount = CGFloat(step) / CGFloat(steps - 1)
            colors.append(interpolated(with: to, amount: amount, in: colorSpace))
        }
        
        return colors
    }
    
    /// Creates a complementary gradient with a specified number of steps.
    ///
    /// - Parameters:
    ///   - steps: The number of color steps to generate (including start and complementary colors).
    ///   - colorSpace: The color space in which to perform the interpolation.
    /// - Returns: An array of colors representing the gradient from this color to its complement.
    func complementaryGradient(steps: Int, in colorSpace: GradientColorSpace = .hsl) -> [Color] {
        guard let hsl = self.hslComponents(), steps > 1 else { return [self] }
        
        // Create complementary color (opposite on the color wheel)
        let complementaryHue = fmod(hsl.hue + 0.5, 1.0)
        let complementaryColor = Color(hue: complementaryHue, saturation: hsl.saturation, lightness: hsl.lightness)
        
        return linearGradient(to: complementaryColor, steps: steps, in: colorSpace)
    }
    
    /// Creates an analogous gradient with a specified number of steps.
    ///
    /// - Parameters:
    ///   - steps: The number of color steps to generate.
    ///   - angle: The angle on the color wheel to span (default: 30° or 0.0833 in normalized hue).
    ///   - colorSpace: The color space in which to perform the interpolation.
    /// - Returns: An array of colors representing the analogous gradient.
    func analogousGradient(steps: Int, angle: CGFloat = 0.0833, in colorSpace: GradientColorSpace = .hsl) -> [Color] {
        guard let hsl = self.hslComponents(), steps > 1 else { return [self] }
        
        // Calculate start and end hues for analogous colors
        let startHue = fmod(hsl.hue - angle/2 + 1.0, 1.0)
        let endHue = fmod(hsl.hue + angle/2, 1.0)
        
        let startColor = Color(hue: startHue, saturation: hsl.saturation, lightness: hsl.lightness)
        let endColor = Color(hue: endHue, saturation: hsl.saturation, lightness: hsl.lightness)
        
        return startColor.linearGradient(to: endColor, steps: steps, in: colorSpace)
    }
    
    /// Creates a triadic gradient with a specified number of steps.
    ///
    /// - Parameters:
    ///   - steps: The number of color steps to generate for each segment.
    ///   - colorSpace: The color space in which to perform the interpolation.
    /// - Returns: An array of colors representing the triadic gradient.
    func triadicGradient(steps: Int, in colorSpace: GradientColorSpace = .hsl) -> [Color] {
        guard let hsl = self.hslComponents(), steps > 1 else { return [self] }
        
        // Create triadic colors (120° apart on the color wheel)
        let triad1Hue = fmod(hsl.hue + 1.0/3.0, 1.0)
        let triad2Hue = fmod(hsl.hue + 2.0/3.0, 1.0)
        
        let triad1 = Color(hue: triad1Hue, saturation: hsl.saturation, lightness: hsl.lightness)
        let triad2 = Color(hue: triad2Hue, saturation: hsl.saturation, lightness: hsl.lightness)
        
        // Generate gradients between each pair of triadic colors
        let gradient1 = self.linearGradient(to: triad1, steps: steps, in: colorSpace)
        let gradient2 = triad1.linearGradient(to: triad2, steps: steps, in: colorSpace)
        let gradient3 = triad2.linearGradient(to: self, steps: steps, in: colorSpace)
        
        // Combine gradients, removing duplicates at the connection points
        var result = gradient1
        result.append(contentsOf: gradient2.dropFirst())
        result.append(contentsOf: gradient3.dropFirst())
        
        return result
    }
    
    /// Creates a monochromatic gradient by varying the lightness.
    ///
    /// - Parameters:
    ///   - steps: The number of color steps to generate.
    ///   - lightnessRange: The range of lightness values to span (default: 0.1 to 0.9).
    /// - Returns: An array of colors representing the monochromatic gradient.
    func monochromaticGradient(steps: Int, lightnessRange: ClosedRange<CGFloat> = 0.1...0.9) -> [Color] {
        guard let hsl = self.hslComponents(), steps > 1 else { return [self] }
        
        var colors: [Color] = []
        
        for step in 0..<steps {
            let amount = CGFloat(step) / CGFloat(steps - 1)
            let lightness = lightnessRange.lowerBound + amount * (lightnessRange.upperBound - lightnessRange.lowerBound)
            colors.append(Color(hue: hsl.hue, saturation: hsl.saturation, lightness: lightness))
        }
        
        return colors
    }
}

// MARK: - Color Interpolation
public extension Color {
    /// Interpolates between this color and another color.
    ///
    /// - Parameters:
    ///   - color: The destination color.
    ///   - amount: The interpolation amount (0.0 = this color, 1.0 = destination color).
    ///   - colorSpace: The color space in which to perform the interpolation.
    /// - Returns: The interpolated color.
    func interpolated(with color: Color, amount: CGFloat, in colorSpace: GradientColorSpace = .rgb) -> Color {
        let clampedAmount = max(0, min(1, amount))
        
        // Check cache first
        if let cachedColor = ColorCache.shared.getCachedInterpolatedColor(
            color1: self, 
            with: color, 
            amount: clampedAmount, 
            colorSpace: String(describing: colorSpace)
        ) {
            return cachedColor
        }
        
        // If not in cache, perform the interpolation
        let result: Color
        switch colorSpace {
        case .rgb:
            result = interpolateRGB(with: color, amount: clampedAmount)
        case .hsl:
            result = interpolateHSL(with: color, amount: clampedAmount)
        case .lab:
            result = interpolateLAB(with: color, amount: clampedAmount)
        }
        
        // Cache the result
        ColorCache.shared.cacheInterpolatedColor(
            color1: self, 
            with: color, 
            amount: clampedAmount, 
            colorSpace: String(describing: colorSpace), 
            result: result
        )
        
        return result
    }
    
    /// Interpolates between this color and another color in RGB space.
    private func interpolateRGB(with color: Color, amount: CGFloat) -> Color {
        guard let components1 = cgColor?.components, components1.count >= 3,
              let components2 = color.cgColor?.components, components2.count >= 3 else {
            return self
        }
        
        let r1 = components1[0]
        let g1 = components1[1]
        let b1 = components1[2]
        let a1 = components1.count >= 4 ? components1[3] : 1.0
        
        let r2 = components2[0]
        let g2 = components2[1]
        let b2 = components2[2]
        let a2 = components2.count >= 4 ? components2[3] : 1.0
        
        let r = r1 + (r2 - r1) * amount
        let g = g1 + (g2 - g1) * amount
        let b = b1 + (b2 - b1) * amount
        let a = a1 + (a2 - a1) * amount
        
        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    /// Interpolates between this color and another color in HSL space.
    private func interpolateHSL(with color: Color, amount: CGFloat) -> Color {
        guard let hsl1 = self.hslComponents(),
              let hsl2 = color.hslComponents() else {
            return interpolateRGB(with: color, amount: amount)
        }
        
        // Handle hue interpolation specially to ensure we go the shortest way around the color wheel
        var hue1 = hsl1.hue
        var hue2 = hsl2.hue
        
        // Ensure we go the shortest way around the color wheel
        if abs(hue2 - hue1) > 0.5 {
            if hue1 > hue2 {
                hue2 += 1.0
            } else {
                hue1 += 1.0
            }
        }
        
        let h = fmod(hue1 + (hue2 - hue1) * amount, 1.0)
        let s = hsl1.saturation + (hsl2.saturation - hsl1.saturation) * amount
        let l = hsl1.lightness + (hsl2.lightness - hsl1.lightness) * amount
        
        return Color(hue: h, saturation: s, lightness: l)
    }
    
    /// Interpolates between this color and another color in LAB space.
    private func interpolateLAB(with color: Color, amount: CGFloat) -> Color {
        guard let lab1 = self.labComponents(),
              let lab2 = color.labComponents() else {
            return interpolateRGB(with: color, amount: amount)
        }
        
        let L = lab1.L + (lab2.L - lab1.L) * amount
        let a = lab1.a + (lab2.a - lab1.a) * amount
        let b = lab1.b + (lab2.b - lab1.b) * amount
        
        return Color(L: L, a: a, b: b)
    }
}

/// Defines the color space to use for gradient interpolation.
public enum GradientColorSpace {
    /// Interpolate in RGB color space (linear).
    case rgb
    
    /// Interpolate in HSL color space (better for hue transitions).
    case hsl
    
    /// Interpolate in LAB color space (perceptually uniform).
    case lab
} 
