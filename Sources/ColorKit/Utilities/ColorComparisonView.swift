import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Presentation

struct ColorComparisonPresentation {
    static let rgbDifferenceTitle = "RGB Component Difference"
    static let hslDifferenceTitle = "HSL Component Difference"
    static let perceptualDifferenceTitle = PerceptualDifferenceMetric.ciede2000.displayLabel
    static let unavailableTitle = "Comparison unavailable"

    let result: ColorComparisonResult

    var issueMessages: [String] {
        guard case let .unavailable(issues) = result else { return [] }
        return Self.messages(for: issues.firstColor, colorNumber: 1)
            + Self.messages(for: issues.secondColor, colorNumber: 2)
    }

    static func perceptualDifferenceValue(for difference: ColorDifference) -> String {
        String(format: "%.2f", difference.perceptualDifference)
    }

    private static func messages(
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

// MARK: - Comparison View

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

// MARK: - Supporting Views

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
