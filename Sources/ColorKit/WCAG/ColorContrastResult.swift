//
//  ColorContrastResult.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 03.09.25.
//
//  Description:
//  Provides result-bearing WCAG relative luminance and contrast ratio measurements,
//  and the strict measurement shared by every result-bearing accessibility API.
//
//  Features:
//  - Distinguishes a measured contrast ratio from an unavailable measurement
//  - Reports independent per-input reasons for an unavailable measurement
//  - Resolves strictly, so a measurement is reproducible from its inputs alone
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A reason that one input cannot participate in an authoritative WCAG contrast measurement.
public enum ContrastInputIssue: Sendable, Equatable {
    /// The color cannot be resolved to fixed, finite sRGB components.
    case unresolved
    /// The resolved color lies outside the standard sRGB gamut and was not clamped.
    case outOfSRGBGamut
    /// The background is not opaque, so the contrast depends on context not supplied here.
    ///
    /// A translucent foreground is composited over the background instead of reporting
    /// this issue. Only a background can be diagnosed as translucent.
    case translucentBackground
}

/// The independently diagnosed issues for both inputs to a contrast measurement.
public struct ContrastIssues: Sendable, Equatable {
    /// Issues for the color that received `Color.contrastResult(with:)`.
    public let foreground: [ContrastInputIssue]
    /// Issues for the background color passed to `Color.contrastResult(with:)`.
    public let background: [ContrastInputIssue]
}

/// A measured WCAG contrast ratio and the relative luminance values behind it.
public struct ContrastMeasurement: Sendable, Equatable {
    /// The WCAG contrast ratio, from 1 to 21.
    public let ratio: Double
    /// The WCAG relative luminance of the foreground, composited over the background when translucent.
    public let foregroundLuminance: Double
    /// The WCAG relative luminance of the background.
    public let backgroundLuminance: Double

    /// The WCAG contrast levels this ratio meets.
    ///
    /// An empty array means the ratio meets no level, not that measurement failed.
    public var passingLevels: [WCAGContrastLevel] {
        WCAGContrastLevel.allCases.filter { ratio >= $0.minimumRatio }
    }

    init(ratio: Double, foregroundLuminance: Double, backgroundLuminance: Double) {
        self.ratio = ratio
        self.foregroundLuminance = foregroundLuminance
        self.backgroundLuminance = backgroundLuminance
    }
}

/// The result of an atomic WCAG contrast measurement between a foreground and background.
public enum ColorContrastResult: Sendable, Equatable {
    /// The contrast ratio was measured from both inputs.
    case available(ContrastMeasurement)
    /// No contrast ratio is available; the associated value explains why.
    case unavailable(ContrastIssues)

    /// The measured contrast ratio, or `nil` when measurement is unavailable.
    ///
    /// An unavailable measurement is absence, not a ratio of 1.
    public var ratio: Double? {
        guard case .available(let measurement) = self else { return nil }
        return measurement.ratio
    }
}

public extension Color {
    /// Measures the WCAG relative luminance of this color.
    ///
    /// The calculation follows WCAG 2.1: each nonlinear sRGB component is linearized,
    /// then weighted by 0.2126, 0.7152, and 0.0722. Opacity is not part of relative
    /// luminance; composite a translucent color against its background first.
    ///
    /// Example:
    /// ```swift
    /// if let luminance = Color(red: 0.35, green: 0.35, blue: 0.35).relativeLuminanceValue() {
    ///     print("Relative luminance: \(luminance)")
    /// }
    /// ```
    ///
    /// - Returns: The relative luminance from 0 to 1, or `nil` when this color cannot
    ///   be resolved to finite, in-gamut sRGB components.
    func relativeLuminanceValue() -> Double? {
        StrictWCAGContrast.luminance(of: self)
    }

    /// Measures the WCAG contrast ratio between this foreground color and a background.
    ///
    /// Both colors must resolve to finite, in-gamut sRGB values, and the background
    /// must be opaque. A translucent foreground is composited over the background
    /// before measurement. Dynamic colors, wider-gamut colors, and translucent
    /// backgrounds produce an unavailable result rather than an invented ratio.
    ///
    /// Example:
    /// ```swift
    /// switch Color(red: 0.35, green: 0.35, blue: 0.35).contrastResult(with: .white) {
    /// case .available(let measurement):
    ///     print("Contrast ratio: \(measurement.ratio):1")
    /// case .unavailable(let issues):
    ///     print("Unavailable: \(issues.foreground), \(issues.background)")
    /// }
    /// ```
    ///
    /// - Parameter backgroundColor: The background behind this foreground color.
    /// - Returns: A result that distinguishes a measured ratio from an unavailable measurement.
    func contrastResult(with backgroundColor: Color) -> ColorContrastResult {
        StrictWCAGContrast.measure(foreground: self, background: backgroundColor)
    }
}

/// The strict WCAG contrast measurement shared by the result-bearing APIs.
///
/// Strict resolution never consults appearance. A color participates only when it has
/// fixed, finite, in-gamut sRGB components, which is what lets these measurements be
/// reproduced from the inputs alone.
enum StrictWCAGContrast {
    /// The relative luminance of one strictly resolved color.
    ///
    /// - Returns: The luminance, or `nil` when the color does not resolve strictly.
    static func luminance(of color: Color) -> Double? {
        guard let resolved = ResolvedSRGBA.resolve(color), resolved.isInSRGBGamut else { return nil }
        return SRGBColorConversion.wcagRelativeLuminance(components(of: resolved))
    }

    /// Measures a foreground against a background, or diagnoses both inputs.
    ///
    /// A translucent foreground is composited over the background, which supplies the
    /// context its contrast depends on. A translucent background has no such context.
    static func measure(foreground: Color, background: Color) -> ColorContrastResult {
        let resolvedForeground = ResolvedSRGBA.resolve(foreground)
        let resolvedBackground = ResolvedSRGBA.resolve(background)
        let foregroundIssues = issues(for: resolvedForeground, asBackground: false)
        let backgroundIssues = issues(for: resolvedBackground, asBackground: true)

        guard foregroundIssues.isEmpty,
              backgroundIssues.isEmpty,
              let resolvedForeground,
              let resolvedBackground else {
            return .unavailable(
                ContrastIssues(foreground: foregroundIssues, background: backgroundIssues)
            )
        }

        let backgroundComponents = components(of: resolvedBackground)
        let compositedComponents = composite(resolvedForeground, over: resolvedBackground)

        return .available(
            ContrastMeasurement(
                ratio: SRGBColorConversion.wcagContrastRatio(
                    between: compositedComponents,
                    and: backgroundComponents
                ),
                foregroundLuminance: SRGBColorConversion.wcagRelativeLuminance(compositedComponents),
                backgroundLuminance: SRGBColorConversion.wcagRelativeLuminance(backgroundComponents)
            )
        )
    }

    /// The reasons one resolved input cannot participate, in the role it was supplied in.
    private static func issues(for resolved: ResolvedSRGBA?, asBackground: Bool) -> [ContrastInputIssue] {
        guard let resolved else { return [.unresolved] }

        var issues: [ContrastInputIssue] = []
        if !resolved.isInSRGBGamut { issues.append(.outOfSRGBGamut) }
        if asBackground, resolved.alpha != 1 { issues.append(.translucentBackground) }
        return issues
    }

    /// Composites a foreground over an opaque background so its opacity is measured.
    private static func composite(
        _ foreground: ResolvedSRGBA,
        over background: ResolvedSRGBA
    ) -> (red: Double, green: Double, blue: Double) {
        let inverseAlpha = 1 - foreground.alpha
        return (
            red: Double(foreground.red * foreground.alpha + background.red * inverseAlpha),
            green: Double(foreground.green * foreground.alpha + background.green * inverseAlpha),
            blue: Double(foreground.blue * foreground.alpha + background.blue * inverseAlpha)
        )
    }

    private static func components(of resolved: ResolvedSRGBA) -> (red: Double, green: Double, blue: Double) {
        (red: Double(resolved.red), green: Double(resolved.green), blue: Double(resolved.blue))
    }
}
