import SwiftUI
import XCTest

@testable import ColorKit

final class ResolvedSRGBATests: XCTestCase {
    func testSRGBSnapshotsPreserveComponentsIncludingTransparentRGB() throws {
        for space in [CGColorSpace.sRGB, CGColorSpace.extendedSRGB] {
            for alpha: CGFloat in [0, 0.5, 1] {
                let expected: [CGFloat] = [0.5, 0.25, 0.75, alpha]
                let color = try fixedTestColor(space: space, components: expected)
                let snapshot = try XCTUnwrap(ResolvedSRGBA.resolve(color))

                XCTAssertEqual(values(snapshot), expected)
                XCTAssertTrue(snapshot.isInSRGBGamut)
            }
        }
    }

    func testEquivalentRGBRepresentationsProduceTheSameExtraction() throws {
        let original = try fixedTestColor(components: [0.2, 0.4, 0.6, 0.5])
        let source = try XCTUnwrap(original.cgColor)
        let expected = try XCTUnwrap(ResolvedSRGBA.resolve(original))
        let expectedCMYK = try XCTUnwrap(original.cmykComponents())

        for name in [CGColorSpace.linearSRGB, CGColorSpace.extendedLinearSRGB, CGColorSpace.displayP3] {
            let space = try XCTUnwrap(CGColorSpace(name: name))
            let represented = try XCTUnwrap(source.converted(to: space, intent: .relativeColorimetric, options: nil))
            let components = try XCTUnwrap(represented.components)
            XCTAssertNotEqual(Array(components.prefix(3)), [expected.red, expected.green, expected.blue])
            let color = try fixedTestColor(space: name, components: components)
            let snapshot = try XCTUnwrap(ResolvedSRGBA.resolve(color))
            let cmyk = try XCTUnwrap(color.cmykComponents())

            for (actual, expected) in zip(values(snapshot), values(expected)) {
                XCTAssertEqual(actual, expected, accuracy: 0.00001)
            }
            XCTAssertEqual(color.hexValue(), "#33669980")
            XCTAssertEqual(cmyk.cyan, expectedCMYK.cyan, accuracy: 0.00001)
            XCTAssertEqual(cmyk.magenta, expectedCMYK.magenta, accuracy: 0.00001)
            XCTAssertEqual(cmyk.yellow, expectedCMYK.yellow, accuracy: 0.00001)
            XCTAssertEqual(cmyk.key, expectedCMYK.key, accuracy: 0.00001)
        }
    }

    func testLinearRGBAndGrayscaleUseTheSRGBTransferFunction() throws {
        // The sRGB encoding of linear 0.25 is 0.5370987304831942.
        let encoded: CGFloat = 0.5370987304831942
        let reference = try fixedTestColor(components: [encoded, encoded, encoded, 0.5])
        for name in [CGColorSpace.linearSRGB, CGColorSpace.linearGray, CGColorSpace.extendedLinearGray] {
            let space = try XCTUnwrap(CGColorSpace(name: name))
            let components = Array(repeating: CGFloat(0.25), count: space.numberOfComponents) + [0.5]
            let color = try fixedTestColor(space: name, components: components)
            let snapshot = try XCTUnwrap(ResolvedSRGBA.resolve(color))

            for channel in [snapshot.red, snapshot.green, snapshot.blue] {
                XCTAssertEqual(channel, encoded, accuracy: 0.000001)
            }
            XCTAssertEqual(snapshot.alpha, 0.5)
            XCTAssertEqual(color.hexValue(), reference.hexValue())
            let cmyk = try XCTUnwrap(color.cmykComponents())
            XCTAssertEqual(cmyk.cyan, 0)
            XCTAssertEqual(cmyk.magenta, 0)
            XCTAssertEqual(cmyk.yellow, 0)
            XCTAssertEqual(cmyk.key, 1 - encoded, accuracy: 0.000001)
        }
    }

    func testEncodedGrayscaleExpandsToRGB() throws {
        for name in [CGColorSpace.genericGrayGamma2_2, CGColorSpace.extendedGray] {
            let color = try fixedTestColor(space: name, components: [0.5, 0.25])
            let snapshot = try XCTUnwrap(ResolvedSRGBA.resolve(color))

            XCTAssertEqual(snapshot.red, 0.5, accuracy: 0.00001)
            XCTAssertEqual(snapshot.green, snapshot.red)
            XCTAssertEqual(snapshot.blue, snapshot.red)
            XCTAssertEqual(snapshot.alpha, 0.25)
            XCTAssertEqual(color.hexValue(), "#80808040")
            XCTAssertNotNil(color.cmykComponents())
        }
    }

    func testConvertibleSourceDoesNotGainCacheEligibility() throws {
        let color = try fixedTestColor(space: CGColorSpace.adobeRGB1998, components: [0.5, 0.4, 0.6, 1])
        XCTAssertNotNil(ResolvedSRGBA.resolve(color))
        XCTAssertNotNil(color.hexValue())
        XCTAssertNotNil(color.cmykComponents())

        let cache = ColorCache()
        cache.cacheLuminance(for: color, luminance: 0.25)
        XCTAssertNil(cache.getCachedLuminance(for: color))
    }

    func testExtendedRangeIsRetainedButCannotBeExtractedAsHexOrCMYK() throws {
        for red: CGFloat in [-0.25, 1.25, -CGFloat.leastNonzeroMagnitude, CGFloat(1).nextUp, .greatestFiniteMagnitude] {
            let color = try fixedTestColor(space: CGColorSpace.extendedSRGB, components: [red, 0.4, 0.6, 0.5])
            let snapshot = try XCTUnwrap(ResolvedSRGBA.resolve(color))

            XCTAssertEqual(snapshot.red, red)
            XCTAssertFalse(snapshot.isInSRGBGamut)
            assertExtractionUnavailable(color)
        }
        let linear = try fixedTestColor(space: CGColorSpace.extendedLinearSRGB, components: [-0.25, 1.25, 0.25, 0.5])
        let snapshot = try XCTUnwrap(ResolvedSRGBA.resolve(linear))
        XCTAssertEqual(snapshot.red, -0.5370987304831942, accuracy: 0.000001)
        XCTAssertGreaterThan(snapshot.green, 1)
        XCTAssertEqual(snapshot.alpha, 0.5)
        assertExtractionUnavailable(linear)
    }

    func testDisplayP3RedIsConvertedWithoutClipping() throws {
        let color = try fixedTestColor(space: CGColorSpace.displayP3, components: [1, 0, 0, 0.5])
        let snapshot = try XCTUnwrap(ResolvedSRGBA.resolve(color))

        XCTAssertGreaterThan(snapshot.red, 1)
        XCTAssertLessThan(snapshot.green, 0)
        XCTAssertLessThan(snapshot.blue, 0)
        XCTAssertEqual(snapshot.alpha, 0.5)
        assertExtractionUnavailable(color)
    }

    func testConvertedWhiteUsesStrictRangeChecksWithoutTolerance() throws {
        for name in [CGColorSpace.linearSRGB, CGColorSpace.displayP3] {
            let color = try fixedTestColor(space: name, components: [1, 1, 1, 1])
            let snapshot = try XCTUnwrap(ResolvedSRGBA.resolve(color))
            for channel in [snapshot.red, snapshot.green, snapshot.blue] {
                XCTAssertEqual(channel, 1, accuracy: 0.000001)
            }
            // Platform conversion may overshoot 1 by a few ulps; do not silently snap it.
            if snapshot.isInSRGBGamut {
                XCTAssertEqual(color.hexValue(), "#FFFFFFFF")
                XCTAssertNotNil(color.cmykComponents())
            } else {
                assertExtractionUnavailable(color)
            }
        }
    }

    func testSnapshotRejectsMalformedComponentsAndInvalidAlpha() {
        for components: [CGFloat] in [[], [0.5], [0.5, 1], [0, 0, 0], [0, 0, 0, 1, 1]] {
            XCTAssertNil(ResolvedSRGBA(sRGBComponents: components))
        }
        for alpha: CGFloat in [-0.1, 1.1, .nan, .infinity, -.infinity] {
            XCTAssertNil(ResolvedSRGBA(sRGBComponents: [0.2, 0.4, 0.6, alpha]))
        }
        for index in 0..<4 {
            for value: CGFloat in [.nan, .infinity, -.infinity] {
                var components: [CGFloat] = [0.2, 0.4, 0.6, 0.5]
                components[index] = value
                XCTAssertNil(ResolvedSRGBA(sRGBComponents: components))
            }
        }
    }

    func testNonfiniteSourceComponentsDoNotBecomeZeroValues() throws {
        for index in 0..<3 {
            for value: CGFloat in [.nan, .infinity, -.infinity] {
                var components: [CGFloat] = [0.2, 0.4, 0.6, 0.5]
                components[index] = value
                let color = try fixedTestColor(space: CGColorSpace.extendedSRGB, components: components)
                XCTAssertNil(ResolvedSRGBA.resolve(color))
                assertExtractionUnavailable(color)
            }
        }
        let invalidAlpha = try fixedTestColor(space: CGColorSpace.extendedSRGB, components: [0.2, 0.4, 0.6, .nan])
        XCTAssertNil(ResolvedSRGBA.resolve(invalidAlpha))
        assertExtractionUnavailable(invalidAlpha)
    }

    func testPlatformSanitizedAlphaIsNotAnInvalidFixture() throws {
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.extendedSRGB))
        for (input, represented): (CGFloat, CGFloat) in [(-0.2, 0), (1.2, 1)] {
            let source = try XCTUnwrap(CGColor(colorSpace: space, components: [0.2, 0.4, 0.6, input]))
            let color = Color(source)
            XCTAssertEqual(try XCTUnwrap(color.cgColor).alpha, represented)
            XCTAssertEqual(try XCTUnwrap(ResolvedSRGBA.resolve(color)).alpha, represented)
        }
    }

    func testDynamicAndSemanticColorsRemainUnavailable() {
        #if canImport(AppKit)
        let dynamic = Color(NSColor(name: nil) { _ in .red })
        #else
        let dynamic = Color(UIColor { _ in .red })
        #endif
        for color in [dynamic, Color.primary, Color.secondary] {
            XCTAssertNil(color.cgColor)
            XCTAssertNil(ResolvedSRGBA.resolve(color))
            assertExtractionUnavailable(color)
        }
    }

    func testPatternAndCMYKSourcesRemainUnavailable() throws {
        let pattern = try patternTestColor()
        let space = CGColorSpaceCreateDeviceCMYK()
        let source = try XCTUnwrap(CGColor(colorSpace: space, components: [0.2, 0.4, 0.6, 0.1, 1]))
        let cmyk = Color(source)
        XCTAssertEqual(cmyk.cgColor?.colorSpace?.model, .cmyk)

        for color in [pattern, cmyk] {
            XCTAssertNil(ResolvedSRGBA.resolve(color))
            assertExtractionUnavailable(color)
        }
    }

    func testCompatibilityFallbacksRemainAtLegacyCallers() throws {
        let color = try patternTestColor()
        XCTAssertNil(ResolvedSRGBA.resolve(color))
        let rgba = color.rgbaComponents()
        XCTAssertEqual([rgba.red, rgba.green, rgba.blue, rgba.alpha], [0, 0, 0, 0])
        let aggregate = color.colorSpaceComponents()
        XCTAssertEqual([aggregate.cmyk.cyan, aggregate.cmyk.magenta, aggregate.cmyk.yellow, aggregate.cmyk.key], [0, 0, 0, 0])
    }

    func testHexFormattingAndCMYKAlphaCompatibility() throws {
        for (alpha, suffix): (CGFloat, String) in [(0, "00"), (0.5, "80"), (1, "FF")] {
            let color = try fixedTestColor(components: [1, 0, 0, alpha])
            let hex = try XCTUnwrap(color.hexComponents())
            XCTAssertEqual([hex.red, hex.green, hex.blue, hex.alpha], ["FF", "00", "00", suffix])
            XCTAssertEqual(color.hexValue(), "#FF0000" + suffix)
            XCTAssertEqual(color.hexString(), color.hexValue())
            XCTAssertEqual(color.cmykString(), "cmyk(0%, 100%, 100%, 0%)")
        }
        let black = try fixedTestColor(components: [0, 0, 0, 0])
        XCTAssertEqual(black.hexValue(), "#00000000")
        XCTAssertEqual(black.cmykString(), "cmyk(0%, 0%, 0%, 100%)")
        let fractional = try fixedTestColor(components: [0.5, 0.25, 0.125, 1])
        XCTAssertEqual(fractional.hexValue(), "#804020FF")
        XCTAssertEqual(fractional.cmykString(), "cmyk(0%, 50%, 75%, 50%)")
        let truncated = try fixedTestColor(components: [1, 0.333, 0.666, 1])
        XCTAssertEqual(truncated.cmykString(), "cmyk(0%, 66%, 33%, 0%)")
        let roundTrip = try XCTUnwrap(Color(hex: "#23232380"))
        XCTAssertEqual(roundTrip.hexString(), "#23232380")
    }

    private func values(_ snapshot: ResolvedSRGBA) -> [CGFloat] {
        [snapshot.red, snapshot.green, snapshot.blue, snapshot.alpha]
    }

    private func assertExtractionUnavailable(_ color: Color, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNil(color.hexValue(), file: file, line: line)
        XCTAssertNil(color.hexString(), file: file, line: line)
        XCTAssertNil(color.hexComponents(), file: file, line: line)
        XCTAssertNil(color.cmykComponents(), file: file, line: line)
        XCTAssertNil(color.cmykString(), file: file, line: line)
    }
}
