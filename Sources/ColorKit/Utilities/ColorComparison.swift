import SwiftUI

// MARK: - Public API

public extension Color {
    /// Compares two fixed, opaque, in-gamut sRGB colors.
    ///
    /// The available result derives every metric from the same resolved color snapshots and
    /// calculates perceptual difference using CIEDE2000. If either input cannot be compared,
    /// the unavailable result reports issues for both inputs without fabricating measurements.
    ///
    /// ```swift
    /// switch firstColor.comparisonResult(with: secondColor) {
    /// case .available(let difference):
    ///     print(difference.perceptualDifference)
    /// case .unavailable(let issues):
    ///     print(issues.firstColor, issues.secondColor)
    /// }
    /// ```
    ///
    /// - Parameter other: The second color in the comparison.
    /// - Returns: A complete color difference or the issues that prevent measurement.
    func comparisonResult(with other: Color) -> ColorComparisonResult {
        let first = ResolvedSRGBA.resolve(self)
        let second = ResolvedSRGBA.resolve(other)
        let issues = ColorComparisonIssues(
            firstColor: Self.comparisonIssues(for: first),
            secondColor: Self.comparisonIssues(for: second)
        )

        guard issues.firstColor.isEmpty,
              issues.secondColor.isEmpty,
              let first,
              let second else { return .unavailable(issues) }
        return .available(ColorComparisonCalculator.difference(first: first, second: second))
    }

    private static func comparisonIssues(for resolved: ResolvedSRGBA?) -> [ColorComparisonInputIssue] {
        guard let resolved else { return [.unresolved] }

        var issues: [ColorComparisonInputIssue] = []
        if resolved.alpha != 1 {
            issues.append(.translucent)
        }
        if !resolved.isInSRGBGamut {
            issues.append(.outOfSRGBGamut)
        }
        return issues
    }

    /// Retains the legacy comparison call shape, but not its numeric results.
    ///
    /// Comparable colors return the same CIEDE2000 result as ``comparisonResult(with:)``.
    /// When an authoritative comparison is unavailable, this method preserves the legacy
    /// RGB-distance fallback and labels its value as ``PerceptualDifferenceMetric/legacyRGBDistance``.
    /// Use ``comparisonResult(with:)`` to handle failures without fabricated components.
    ///
    /// - Parameter other: The second color in the comparison.
    /// - Returns: A CIEDE2000 difference or an explicitly identified legacy fallback.
    @available(*, deprecated, message: "Use comparisonResult(with:) to handle unavailable colors explicitly.")
    func compare(with other: Color) -> ColorDifference {
        if case let .available(difference) = comparisonResult(with: other) {
            return difference
        }

        return legacyComparison(with: other)
    }

    private func legacyComparison(with other: Color) -> ColorDifference {
        let firstRGB = rgbaComponents()
        let secondRGB = other.rgbaComponents()
        let rgbDifference = (
            red: abs(firstRGB.red - secondRGB.red),
            green: abs(firstRGB.green - secondRGB.green),
            blue: abs(firstRGB.blue - secondRGB.blue)
        )

        let firstHSL = hslComponents() ?? (hue: 0, saturation: 0, lightness: 0)
        let secondHSL = other.hslComponents() ?? (hue: 0, saturation: 0, lightness: 0)
        let hueDifference = abs(firstHSL.hue - secondHSL.hue)
        let hslDifference = (
            hue: Double(min(hueDifference, 1 - hueDifference) * 360),
            saturation: Double(abs(firstHSL.saturation - secondHSL.saturation) * 100),
            lightness: Double(abs(firstHSL.lightness - secondHSL.lightness) * 100)
        )

        // Preserve the normalized Euclidean RGB fallback used by ColorKit 2.x.
        let legacyRGBDistance = sqrt(
            pow(rgbDifference.red * 255, 2) +
            pow(rgbDifference.green * 255, 2) +
            pow(rgbDifference.blue * 255, 2)
        ) / sqrt(3)

        let contrastRatio = wcagContrastRatio(with: other)
        let compliance = wcagCompliance(with: other)

        return ColorDifference(
            rgbDifference: rgbDifference,
            hslDifference: hslDifference,
            perceptualDifference: legacyRGBDistance,
            perceptualDifferenceMetric: .legacyRGBDistance,
            contrastRatio: contrastRatio,
            wcagComplianceLevels: compliance.passes
        )
    }
}

// MARK: - Authoritative Calculation

private enum ColorComparisonCalculator {
    static func difference(first: ResolvedSRGBA, second: ResolvedSRGBA) -> ColorDifference {
        let firstRGB = rgb(first)
        let secondRGB = rgb(second)
        let firstHSL = SRGBColorConversion.hsl(from: firstRGB)
        let secondHSL = SRGBColorConversion.hsl(from: secondRGB)
        let firstLAB = lab(firstRGB)
        let secondLAB = lab(secondRGB)
        let contrastRatio = SRGBColorConversion.wcagContrastRatio(
            between: firstRGB,
            and: secondRGB
        )

        let hueDistance = abs(firstHSL.hue - secondHSL.hue)
        return ColorDifference(
            rgbDifference: (
                red: abs(firstRGB.red - secondRGB.red),
                green: abs(firstRGB.green - secondRGB.green),
                blue: abs(firstRGB.blue - secondRGB.blue)
            ),
            hslDifference: (
                hue: min(hueDistance, 1 - hueDistance) * 360,
                saturation: abs(firstHSL.saturation - secondHSL.saturation) * 100,
                lightness: abs(firstHSL.lightness - secondHSL.lightness) * 100
            ),
            perceptualDifference: CIEDE2000.difference(between: firstLAB, and: secondLAB),
            perceptualDifferenceMetric: .ciede2000,
            contrastRatio: contrastRatio,
            wcagComplianceLevels: WCAGContrastLevel.allCases.filter {
                contrastRatio >= $0.minimumRatio
            }
        )
    }

    private static func rgb(
        _ resolved: ResolvedSRGBA
    ) -> (red: Double, green: Double, blue: Double) {
        (Double(resolved.red), Double(resolved.green), Double(resolved.blue))
    }

    private static func lab(
        _ rgb: (red: Double, green: Double, blue: Double)
    ) -> LABColor {
        let components = SRGBColorConversion.lab(from: SRGBColorConversion.xyz(from: rgb))
        return LABColor(lightness: components.l, a: components.a, b: components.b)
    }
}
