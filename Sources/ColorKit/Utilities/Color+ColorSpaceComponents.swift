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
    /// Returns aggregate components without per-conversion availability.
    ///
    /// See ``ColorSpaceConverter/getAllColorComponents()`` for appearance resolution
    /// and failure substitutions; zero components do not establish conversion success.
    func colorSpaceComponents() -> ColorComponents {
        let converter = ColorSpaceConverter(color: self)
        return converter.getAllColorComponents()
    }
}
