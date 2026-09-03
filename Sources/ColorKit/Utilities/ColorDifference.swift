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

/// The calculation represented by ``ColorDifference/perceptualDifference``.
public enum PerceptualDifferenceMetric: Sendable, Equatable {
    /// CIEDE2000 over D65 LAB values with `kL`, `kC`, and `kH` set to one.
    case ciede2000
    /// ColorKit's deprecated normalized Euclidean RGB calculation.
    ///
    /// Only the deprecated `Color.compare(with:)` compatibility adapter produces this metric.
    case legacyRGBDistance
}

extension PerceptualDifferenceMetric {
    var displayLabel: String {
        switch self {
        case .ciede2000:
            "CIEDE2000 Difference (ΔE00)"
        case .legacyRGBDistance:
            "Legacy RGB Distance"
        }
    }
}

/// A reason that one input cannot participate in an authoritative color comparison.
public enum ColorComparisonInputIssue: Sendable, Equatable {
    /// The color cannot be resolved to fixed, finite components.
    case unresolved
    /// The color is not opaque and no backing color was supplied for compositing.
    case translucent
    /// The resolved color lies outside the standard sRGB gamut and was not clamped.
    case outOfSRGBGamut
}

/// The independently diagnosed issues for both inputs to a color comparison.
public struct ColorComparisonIssues: Sendable {
    /// Issues for the color that received `comparisonResult(with:)`.
    public let firstColor: [ColorComparisonInputIssue]
    /// Issues for the color passed to `comparisonResult(with:)`.
    public let secondColor: [ColorComparisonInputIssue]
}

/// The result of an atomic comparison between two colors.
public enum ColorComparisonResult: Sendable {
    /// Every advertised comparison metric is available.
    case available(ColorDifference)
    /// No comparison metrics are available; the associated value explains why.
    case unavailable(ColorComparisonIssues)
}

/// A complete set of component, perceptual, contrast, and WCAG measurements for two colors.
///
/// Instances returned by `Color.comparisonResult(with:)` describe fixed, opaque,
/// in-gamut sRGB inputs. RGB and HSL values are component-coordinate differences;
/// only ``perceptualDifference`` with ``PerceptualDifferenceMetric/ciede2000`` is a
/// perceptual color-difference measurement.
public struct ColorDifference: Sendable {
    /// Absolute differences between normalized nonlinear sRGB components.
    public let rgbDifference: (red: Double, green: Double, blue: Double)
    /// Absolute HSL coordinate differences in degrees and percentage points.
    ///
    /// Achromatic colors use a canonical hue coordinate of zero.
    public let hslDifference: (hue: Double, saturation: Double, lightness: Double)
    /// The difference produced by ``perceptualDifferenceMetric``.
    ///
    /// Authoritative comparison results use CIEDE2000. The deprecated `compare(with:)`
    /// adapter can return the legacy RGB distance when its inputs cannot be compared.
    public let perceptualDifference: Double
    /// The calculation used for ``perceptualDifference``.
    public let perceptualDifferenceMetric: PerceptualDifferenceMetric
    /// The WCAG contrast ratio between the colors.
    public let contrastRatio: Double
    /// WCAG compliance levels that pass for this color pair.
    public let wcagComplianceLevels: [WCAGContrastLevel]

    /// A human-readable description of the color difference.
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

        \(perceptualDifferenceMetric.displayLabel): \(String(format: "%.2f", perceptualDifference))
        Contrast Ratio: \(String(format: "%.2f", contrastRatio)):1
        WCAG Compliance: \(wcagComplianceLevels.map { $0.rawValue }.joined(separator: ", "))
        """
    }
}
