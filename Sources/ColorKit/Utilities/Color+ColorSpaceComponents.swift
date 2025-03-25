//
//  Color+ColorSpaceComponents.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 25.03.25.
//
//  Description:
//  Provides an extension to the Color structure to retrieve color components in various color spaces.
//
//  Features:
//  - Retrieve color components in RGB, HSL, HSB, CMYK, LAB, and XYZ color spaces
//
//  License:
//  MIT License. See LICENSE file for details.


import SwiftUI

public extension Color {
    /// Get color components in all available color spaces
    /// - Returns: A ColorComponents structure with all color space representations
    func colorSpaceComponents() -> ColorComponents {
        let converter = ColorSpaceConverter(color: self)
        return converter.getAllColorComponents()
    }
}