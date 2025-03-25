//
//  Color+WCAG.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 25.03.25.
//
//  Description:    
//  Extension to get RGBA components of a color.
//
//  License:
//  MIT License. See LICENSE file for details.
// 

import SwiftUI

extension Color {
    /// Get the RGBA components of a color
    func wcagRGBAComponents() -> (red: Double, green: Double, blue: Double, alpha: Double) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        #if canImport(UIKit)
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #elseif canImport(AppKit)
        NSColor(self).usingColorSpace(.sRGB)?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        return (Double(red), Double(green), Double(blue), Double(alpha))
    }

    /// Get suggested colors that would comply with the specified WCAG level when paired with this color
    /// - Parameters:
    ///   - color: The color to improve contrast with
    ///   - level: The WCAG compliance level to achieve (defaults to AA)
    ///   - preserveHue: Whether to try preserving the original hue. If true, will first try to achieve compliance
    ///                  by only adjusting lightness. If false or if lightness adjustment fails, will also adjust saturation.
    /// - Returns: An array of suggested colors that meet the compliance level.
    ///           Returns the original color if it already meets the requirements.
    ///           Falls back to black or white if no other suggestions are found.
    func suggestedAccessibleColors(for color: Color, level: WCAGContrastLevel = .AA, preserveHue: Bool = true) -> [Color] {
        let suggestions = WCAGColorSuggestions(baseColor: self, targetColor: color, targetLevel: level)
        return suggestions.generateSuggestions(preserveHue: preserveHue)
    }
}
