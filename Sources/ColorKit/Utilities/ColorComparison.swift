import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public extension Color {
    /// Compare this color with another color and get detailed information about their differences
    /// - Parameter other: The color to compare with
    /// - Returns: A ColorDifference object containing detailed comparison information
    func compare(with other: Color) -> ColorDifference {
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

        // Calculate perceptual difference (simplified CIEDE2000)
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
            contrastRatio: ratio,
            wcagComplianceLevels: compliance.passes
        )
    }
}

/// A view that displays a comparison between two colors
public struct ColorComparisonView: View {
    private let color1: Color
    private let color2: Color
    private let difference: ColorDifference

    public init(color1: Color, color2: Color) {
        self.color1 = color1
        self.color2 = color2
        self.difference = color1.compare(with: color2)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                ColorSwatch(color: color1, label: "Color 1")
                ColorSwatch(color: color2, label: "Color 2")
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("RGB Difference")
                    .font(.headline)

                HStack {
                    DifferenceBar(value: difference.rgbDifference.red, label: "R")
                    DifferenceBar(value: difference.rgbDifference.green, label: "G")
                    DifferenceBar(value: difference.rgbDifference.blue, label: "B")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("HSL Difference")
                    .font(.headline)

                HStack {
                    DifferenceBar(value: difference.hslDifference.hue / 360, label: "H")
                    DifferenceBar(value: difference.hslDifference.saturation / 100, label: "S")
                    DifferenceBar(value: difference.hslDifference.lightness / 100, label: "L")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Perceptual Difference")
                    .font(.headline)

                DifferenceBar(value: difference.perceptualDifference / 255, label: "ΔE")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Contrast Ratio: \(String(format: "%.2f", difference.contrastRatio)):1")
                    .font(.headline)

                HStack {
                    ForEach(WCAGContrastLevel.allCases) { level in
                        let passes = difference.wcagComplianceLevels.contains(level)
                        WCAGBadge(level: level, passes: passes)
                    }
                }
            }
        }
        .padding()
        .background(backgroundColorView)
        .cornerRadius(12)
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
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))

                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * value)
                }
            }
            .frame(height: 8)
            .cornerRadius(4)

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
            .cornerRadius(4)
    }
}
