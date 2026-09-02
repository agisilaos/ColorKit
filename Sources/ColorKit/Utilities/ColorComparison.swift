import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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
            firstColor: comparisonIssues(for: first),
            secondColor: comparisonIssues(for: second)
        )

        guard issues.firstColor.isEmpty,
              issues.secondColor.isEmpty,
              let first,
              let second else { return .unavailable(issues) }
        return .available(ColorComparisonCalculator.difference(first: first, second: second))
    }

    private func comparisonIssues(for resolved: ResolvedSRGBA?) -> [ColorComparisonInputIssue] {
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

    /// Compares this color using the ColorKit 2.x compatibility contract.
    ///
    /// Comparable colors return the same CIEDE2000 result as ``comparisonResult(with:)``.
    /// When an authoritative comparison is unavailable, this method preserves the legacy
    /// platform-defaulting behavior and labels its value as ``PerceptualDifferenceMetric/legacyRGBDistance``.
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
        // Get RGB components
        let thisRGB = self.rgbaComponents()
        let otherRGB = other.rgbaComponents()

        // Calculate RGB differences
        let rgbDiff = (
            red: abs(thisRGB.red - otherRGB.red),
            green: abs(thisRGB.green - otherRGB.green),
            blue: abs(thisRGB.blue - otherRGB.blue)
        )

        // Get HSL components
        let thisHSL = self.hslComponents() ?? (hue: 0, saturation: 0, lightness: 0)
        let otherHSL = other.hslComponents() ?? (hue: 0, saturation: 0, lightness: 0)

        // Calculate HSL differences and convert CGFloat to Double where needed
        let hueDiff = min(abs(thisHSL.hue - otherHSL.hue), 1 - abs(thisHSL.hue - otherHSL.hue)) * 360
        let hslDiff = (
            hue: Double(hueDiff),
            saturation: Double(abs(thisHSL.saturation - otherHSL.saturation) * 100),
            lightness: Double(abs(thisHSL.lightness - otherHSL.lightness) * 100)
        )

        // Preserve the normalized Euclidean RGB fallback used by ColorKit 2.x.
        let perceptualDiff = sqrt(
            pow(rgbDiff.red * 255, 2) +
            pow(rgbDiff.green * 255, 2) +
            pow(rgbDiff.blue * 255, 2)
        ) / sqrt(3)

        // Get contrast ratio and WCAG compliance
        let ratio = self.wcagContrastRatio(with: other)
        let compliance = self.wcagCompliance(with: other)

        return ColorDifference(
            rgbDifference: rgbDiff,
            hslDifference: hslDiff,
            perceptualDifference: perceptualDiff,
            perceptualDifferenceMetric: .legacyRGBDistance,
            contrastRatio: ratio,
            wcagComplianceLevels: compliance.passes
        )
    }
}

private enum ColorComparisonCalculator {
    static func difference(first: ResolvedSRGBA, second: ResolvedSRGBA) -> ColorDifference {
        let firstRGB = rgb(first)
        let secondRGB = rgb(second)
        let firstHSL = hsl(firstRGB)
        let secondHSL = hsl(secondRGB)
        let firstLAB = lab(firstRGB)
        let secondLAB = lab(secondRGB)
        let contrastRatio = contrastRatio(firstRGB, secondRGB)

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

    private static func hsl(
        _ rgb: (red: Double, green: Double, blue: Double)
    ) -> (hue: Double, saturation: Double, lightness: Double) {
        let maximum = max(rgb.red, rgb.green, rgb.blue)
        let minimum = min(rgb.red, rgb.green, rgb.blue)
        let chroma = maximum - minimum
        let lightness = (maximum + minimum) / 2

        guard chroma != 0 else { return (hue: 0, saturation: 0, lightness: lightness) }

        let saturation = lightness > 0.5
            ? chroma / (2 - maximum - minimum)
            : chroma / (maximum + minimum)
        let hue: Double
        if maximum == rgb.red {
            hue = ((rgb.green - rgb.blue) / chroma + (rgb.green < rgb.blue ? 6 : 0)) / 6
        } else if maximum == rgb.green {
            hue = ((rgb.blue - rgb.red) / chroma + 2) / 6
        } else {
            hue = ((rgb.red - rgb.green) / chroma + 4) / 6
        }

        return (hue: hue, saturation: saturation, lightness: lightness)
    }

    private static func contrastRatio(
        _ first: (red: Double, green: Double, blue: Double),
        _ second: (red: Double, green: Double, blue: Double)
    ) -> Double {
        let firstLuminance = relativeLuminance(first)
        let secondLuminance = relativeLuminance(second)
        let lighter = max(firstLuminance, secondLuminance)
        let darker = min(firstLuminance, secondLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func relativeLuminance(
        _ rgb: (red: Double, green: Double, blue: Double)
    ) -> Double {
        0.2126 * linearized(rgb.red)
            + 0.7152 * linearized(rgb.green)
            + 0.0722 * linearized(rgb.blue)
    }

    private static func linearized(_ component: Double) -> Double {
        component <= 0.03928
            ? component / 12.92
            : pow((component + 0.055) / 1.055, 2.4)
    }
}

struct ColorComparisonPresentation {
    static let rgbDifferenceTitle = "RGB Component Difference"
    static let hslDifferenceTitle = "HSL Component Difference"
    static let perceptualDifferenceTitle = "CIEDE2000 Difference (ΔE00)"
    static let unavailableTitle = "Comparison unavailable"

    let result: ColorComparisonResult

    static func perceptualDifferenceValue(for difference: ColorDifference) -> String {
        String(format: "%.2f", difference.perceptualDifference)
    }

    var issueMessages: [String] {
        guard case let .unavailable(issues) = result else { return [] }
        return messages(for: issues.firstColor, colorNumber: 1)
            + messages(for: issues.secondColor, colorNumber: 2)
    }

    private func messages(
        for issues: [ColorComparisonInputIssue],
        colorNumber: Int
    ) -> [String] {
        issues.map { issue in
            switch issue {
            case .unresolved:
                "Color \(colorNumber) could not be resolved."
            case .translucent:
                "Color \(colorNumber) is translucent and needs an explicit backing color."
            case .outOfSRGBGamut:
                "Color \(colorNumber) is outside the sRGB gamut."
            }
        }
    }
}

/// A view that displays a comparison between two colors.
public struct ColorComparisonView: View {
    private let color1: Color
    private let color2: Color
    private let presentation: ColorComparisonPresentation

    /// Creates a comparison view for two colors.
    ///
    /// - Parameters:
    ///   - color1: The first comparison input.
    ///   - color2: The second comparison input.
    public init(color1: Color, color2: Color) {
        self.color1 = color1
        self.color2 = color2
        self.presentation = ColorComparisonPresentation(
            result: color1.comparisonResult(with: color2)
        )
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                ColorSwatch(color: color1, label: "Color 1")
                ColorSwatch(color: color2, label: "Color 2")
            }

            Divider()

            switch presentation.result {
            case let .available(difference):
                AvailableColorComparisonView(difference: difference)
            case .unavailable:
                UnavailableColorComparisonView(messages: presentation.issueMessages)
            }
        }
        .padding()
        .background(backgroundColorView)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }

    private var backgroundColorView: some View {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #elseif canImport(AppKit)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.white
        #endif
    }
}

private struct AvailableColorComparisonView: View {
    let difference: ColorDifference

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RGBDifferenceView(difference: difference.rgbDifference)
            HSLDifferenceView(difference: difference.hslDifference)

            VStack(alignment: .leading, spacing: 4) {
                Text(ColorComparisonPresentation.perceptualDifferenceTitle)
                    .font(.headline)
                Text(ColorComparisonPresentation.perceptualDifferenceValue(for: difference))
                    .font(.title3.monospacedDigit())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Contrast Ratio: \(String(format: "%.2f", difference.contrastRatio)):1")
                    .font(.headline)

                HStack {
                    ForEach(WCAGContrastLevel.allCases) { level in
                        WCAGBadge(
                            level: level,
                            passes: difference.wcagComplianceLevels.contains(level)
                        )
                    }
                }
            }
        }
    }
}

private struct RGBDifferenceView: View {
    let difference: (red: Double, green: Double, blue: Double)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ColorComparisonPresentation.rgbDifferenceTitle)
                .font(.headline)

            HStack {
                DifferenceBar(value: difference.red, label: "R")
                DifferenceBar(value: difference.green, label: "G")
                DifferenceBar(value: difference.blue, label: "B")
            }
        }
    }
}

private struct HSLDifferenceView: View {
    let difference: (hue: Double, saturation: Double, lightness: Double)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ColorComparisonPresentation.hslDifferenceTitle)
                .font(.headline)

            HStack {
                DifferenceBar(value: difference.hue / 360, label: "H")
                DifferenceBar(value: difference.saturation / 100, label: "S")
                DifferenceBar(value: difference.lightness / 100, label: "L")
            }
        }
    }
}

private struct UnavailableColorComparisonView: View {
    let messages: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                ColorComparisonPresentation.unavailableTitle,
                systemImage: "exclamationmark.triangle"
            )
                .font(.headline)

            ForEach(messages, id: \.self) { message in
                Text(message)
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ColorSwatch: View {
    let color: Color
    let label: String

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 60, height: 60)
                .shadow(radius: 2)

            Text(label)
                .font(.caption)
        }
    }
}

private struct DifferenceBar: View {
    let value: Double
    let label: String

    var body: some View {
        let boundedValue = min(max(value, 0), 1)

        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))

                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * boundedValue)
                }
            }
            .frame(height: 8)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(String(format: "%.1f%%", value * 100))
                .font(.caption2)
        }
    }
}

private struct WCAGBadge: View {
    let level: WCAGContrastLevel
    let passes: Bool

    var body: some View {
        Text(level.rawValue)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(passes ? Color.green : Color.red)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
