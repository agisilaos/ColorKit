import SwiftUI
import XCTest

@testable import ColorKit

final class ColorAccessibilityResultTests: XCTestCase {
    func testOpaqueColorsReportPassingAndBestEffortResults() throws {
        let passing = Color.black.accessibilityResult(against: .white, targetLevel: .AAA)
        XCTAssertEqual(passing.status, .meetsTarget)
        XCTAssertTrue(passing.meetsTarget)
        XCTAssertEqual(try XCTUnwrap(passing.contrastRatio), 21, accuracy: 0.0001)

        let gray = try fixedTestColor(components: [0.5, 0.5, 0.5, 1])
        let bestEffort = Color.black.accessibilityResult(against: gray, targetLevel: .AAA)
        XCTAssertEqual(bestEffort.status, .bestEffort)
        XCTAssertFalse(bestEffort.meetsTarget)
        XCTAssertLessThan(try XCTUnwrap(bestEffort.contrastRatio), WCAGContrastLevel.AAA.minimumRatio)
    }

    func testTranslucentForegroundIsCompositedOverOpaqueBackground() throws {
        let foreground = try fixedTestColor(components: [0, 0, 0, 0.5])
        let result = foreground.accessibilityResult(against: .white, targetLevel: .AA)

        XCTAssertEqual(result.status, .bestEffort)
        XCTAssertEqual(try XCTUnwrap(result.contrastRatio), 3.97665, accuracy: 0.0001)
    }

    func testDynamicAndTranslucentBackgroundsAreUnavailable() throws {
        let translucent = try fixedTestColor(components: [1, 1, 1, 0.5])
        for background in [Color.primary, translucent] {
            let result = Color.black.accessibilityResult(against: background)
            XCTAssertEqual(result.status, .unavailable)
            XCTAssertNil(result.contrastRatio)
            XCTAssertFalse(result.meetsTarget)
        }
    }

    func testUnsupportedNonfiniteAndOutOfGamutBackgroundsAreUnavailable() throws {
        let outOfGamut = try fixedTestColor(
            space: CGColorSpace.extendedSRGB,
            components: [1.25, 0.4, 0.6, 1]
        )
        let nonfinite = try fixedTestColor(
            space: CGColorSpace.extendedSRGB,
            components: [.infinity, 0.4, 0.6, 1]
        )
        let pattern = try patternTestColor()
        let cmyk = try fixedTestColor(
            space: CGColorSpaceCreateDeviceCMYK(),
            components: [0.2, 0.4, 0.6, 0.1, 1]
        )

        for background in [outOfGamut, nonfinite, pattern, cmyk] {
            let result = Color.black.accessibilityResult(against: background)
            XCTAssertEqual(result.status, .unavailable)
            XCTAssertNil(result.contrastRatio)
        }
    }

    func testContrastingEndpointReportsUnattainableAAAAsBestEffort() throws {
        let background = try fixedTestColor(components: [0.5, 0.5, 0.5, 1])
        let result = background.accessibleContrastingColorResult(for: .AAA)

        XCTAssertEqual(result.color, background.accessibleContrastingColor(for: .AAA))
        XCTAssertEqual(result.status, .bestEffort)
        XCTAssertLessThan(try XCTUnwrap(result.contrastRatio), WCAGContrastLevel.AAA.minimumRatio)
    }

    func testEnhancerAndVariantResultsPreserveLegacyCandidates() {
        let configuration = AccessibilityEnhancer.Configuration(
            targetLevel: .AA,
            strategy: .preserveHue
        )
        let enhancer = AccessibilityEnhancer(configuration: configuration)
        let color = Color(.sRGB, red: 0.7, green: 0.7, blue: 1)
        let background = Color.white

        let legacy = enhancer.enhanceColor(color, against: background)
        let result = enhancer.enhanceColorResult(color, against: background)
        XCTAssertEqual(result.color, legacy)
        XCTAssertEqual(result.status, .meetsTarget)

        let legacyVariants = enhancer.suggestAccessibleVariants(for: color, against: background, count: 3)
        let results = enhancer.suggestAccessibleVariantResults(for: color, against: background, count: 3)
        XCTAssertEqual(results.map(\.color), legacyVariants)
    }

    func testAssessedPalettePreservesDeterministicLegacyPalette() {
        let generator = AccessiblePaletteGenerator(configuration: .init(
            targetLevel: .AA,
            paletteSize: 3,
            includeBlackAndWhite: true
        ))
        let seed = Color.blue
        let palette = generator.generatePalette(from: seed)
        let results = generator.generateAssessedPalette(from: seed, against: .white)

        XCTAssertEqual(results.map(\.color), palette)
        XCTAssertEqual(results.map(\.targetLevel), Array(repeating: .AA, count: palette.count))
    }
}
