import SwiftUI
import Testing

@testable import ColorKit

struct ColorComparisonResultTests {
    @Test("Returns a complete CIEDE2000 comparison for comparable colors")
    func returnsAvailableComparison() {
        let white = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
        let black = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)

        guard case let .available(difference) = white.comparisonResult(with: black) else {
            Issue.record("Expected an available comparison")
            return
        }

        #expect(difference.perceptualDifferenceMetric == .ciede2000)
        #expect(abs(difference.perceptualDifference - 100) <= 0.0001)
        #expect(difference.rgbDifference.red == 1)
        #expect(difference.rgbDifference.green == 1)
        #expect(difference.rgbDifference.blue == 1)
        #expect(difference.hslDifference.hue == 0)
        #expect(difference.hslDifference.saturation == 0)
        #expect(difference.hslDifference.lightness == 100)
        #expect(abs(difference.contrastRatio - 21) <= 0.0001)
        #expect(difference.wcagComplianceLevels.count == WCAGContrastLevel.allCases.count)
        #expect(difference.wcagComplianceLevels.contains(.AALarge))
        #expect(difference.wcagComplianceLevels.contains(.AA))
        #expect(difference.wcagComplianceLevels.contains(.AAALarge))
        #expect(difference.wcagComplianceLevels.contains(.AAA))
    }

    @Test("Compares resolved grayscale colors using the achromatic HSL convention")
    func comparesGrayscaleColors() throws {
        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.genericGrayGamma2_2))
        let firstSource = try #require(CGColor(colorSpace: colorSpace, components: [0.25, 1]))
        let secondSource = try #require(CGColor(colorSpace: colorSpace, components: [0.75, 1]))

        guard case let .available(difference) = Color(firstSource).comparisonResult(with: Color(secondSource)) else {
            Issue.record("Expected an available comparison")
            return
        }

        #expect(difference.hslDifference.hue == 0)
        #expect(difference.hslDifference.saturation == 0)
        #expect(difference.perceptualDifferenceMetric == .ciede2000)
        #expect(difference.perceptualDifference > 0)
    }

    @Test("Rejects a translucent color without fabricating measurements")
    func rejectsTranslucentColor() {
        let translucent = Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 0.5)
        let opaque = Color(.sRGB, red: 0, green: 0, blue: 1, opacity: 1)

        guard case let .unavailable(issues) = translucent.comparisonResult(with: opaque) else {
            Issue.record("Expected an unavailable comparison")
            return
        }

        #expect(issues.firstColor == [.translucent])
        #expect(issues.secondColor.isEmpty)
    }

    @Test("Rejects an out-of-gamut color without clamping")
    func rejectsOutOfGamutColor() throws {
        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.extendedSRGB))
        let source = try #require(
            CGColor(colorSpace: colorSpace, components: [1.2, 0.2, 0.3, 1])
        )
        let outOfGamut = Color(source)
        let inGamut = Color(.sRGB, red: 0.2, green: 0.3, blue: 0.4, opacity: 1)

        guard case let .unavailable(issues) = outOfGamut.comparisonResult(with: inGamut) else {
            Issue.record("Expected an unavailable comparison")
            return
        }

        #expect(issues.firstColor == [.outOfSRGBGamut])
        #expect(issues.secondColor.isEmpty)
    }

    @Test("Reports every provable issue for both colors")
    func reportsAllInputIssues() throws {
        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.extendedSRGB))
        let source = try #require(
            CGColor(colorSpace: colorSpace, components: [1.2, 0.2, 0.3, 0.5])
        )
        let translucentOutOfGamut = Color(source)

        #if canImport(AppKit)
        let unresolved = Color(NSColor(name: nil) { _ in .blue })
        #else
        let unresolved = Color(UIColor { _ in .blue })
        #endif

        guard case let .unavailable(issues) = translucentOutOfGamut.comparisonResult(with: unresolved) else {
            Issue.record("Expected an unavailable comparison")
            return
        }

        #expect(issues.firstColor == [.translucent, .outOfSRGBGamut])
        #expect(issues.secondColor == [.unresolved])
    }

    @Test("Deprecated adapter identifies genuine and legacy calculations")
    @available(*, deprecated)
    func deprecatedAdapterIdentifiesMetric() {
        let white = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
        let black = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
        let translucentWhite = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.5)

        let genuine = white.compare(with: black)
        let fallback = translucentWhite.compare(with: black)

        #expect(genuine.perceptualDifferenceMetric == .ciede2000)
        #expect(abs(genuine.perceptualDifference - 100) <= 0.0001)
        #expect(fallback.perceptualDifferenceMetric == .legacyRGBDistance)
    }
}
