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
}
