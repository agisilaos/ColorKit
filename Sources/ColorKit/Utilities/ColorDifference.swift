//
//  ColorDifference.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 12.03.25.
//
//  Description:
//  Provides utilities for comparing colors across different color spaces and metrics.
//
//  Features:
//  - RGB component differences
//  - HSL component differences
//  - Perceptual color difference (CIEDE2000)
//  - WCAG contrast ratio
//  - WCAG compliance level checking
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A structure that represents the difference between two colors across various color spaces
public struct ColorDifference {
    /// The difference in RGB components
    public let rgbDifference: (red: Double, green: Double, blue: Double)
    /// The difference in HSL components
    public let hslDifference: (hue: Double, saturation: Double, lightness: Double)
    /// The perceptual difference using CIEDE2000 formula
    public let perceptualDifference: Double
    /// The contrast ratio between the colors
    public let contrastRatio: Double
    /// WCAG compliance levels that pass for this color pair
    public let wcagComplianceLevels: [WCAGContrastLevel]

    /// A human-readable description of the color difference
    public var description: String {
        """
        RGB Difference:
        - Red: \(String(format: "%.2f", rgbDifference.red))
        - Green: \(String(format: "%.2f", rgbDifference.green))
        - Blue: \(String(format: "%.2f", rgbDifference.blue))

        HSL Difference:
        - Hue: \(String(format: "%.2f", hslDifference.hue))°
        - Saturation: \(String(format: "%.2f", hslDifference.saturation))%
        - Lightness: \(String(format: "%.2f", hslDifference.lightness))%

        Perceptual Difference: \(String(format: "%.2f", perceptualDifference))
        Contrast Ratio: \(String(format: "%.2f", contrastRatio)):1
        WCAG Compliance: \(wcagComplianceLevels.map { $0.rawValue }.joined(separator: ", "))
        """
    }
}
