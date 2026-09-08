import SwiftUI
import XCTest

@testable import ColorKit

final class ColorComponentConversionResultsTests: XCTestCase {
    func testPrimaryAndSecondaryBoundedCoordinates() throws {
        let samples: [(rgb: [CGFloat], hue: Double, cmyk: CMYKComponents)] = [
            ([1, 0, 0, 1], 0, CMYKComponents(cyan: 0, magenta: 1, yellow: 1, key: 0)),
            ([1, 1, 0, 1], 1.0 / 6, CMYKComponents(cyan: 0, magenta: 0, yellow: 1, key: 0)),
            ([0, 1, 0, 1], 1.0 / 3, CMYKComponents(cyan: 1, magenta: 0, yellow: 1, key: 0)),
            ([0, 1, 1, 1], 0.5, CMYKComponents(cyan: 1, magenta: 0, yellow: 0, key: 0)),
            ([0, 0, 1, 1], 2.0 / 3, CMYKComponents(cyan: 1, magenta: 1, yellow: 0, key: 0)),
            ([1, 0, 1, 1], 5.0 / 6, CMYKComponents(cyan: 0, magenta: 1, yellow: 0, key: 0))
        ]
        for sample in samples {
            let result = try fixedTestColor(components: sample.rgb).componentConversionResults()
            XCTAssertEqual(try result.hsl.get(), HSLComponents(hue: sample.hue, saturation: 1, lightness: 0.5))
            XCTAssertEqual(try result.hsb.get(), HSBComponents(hue: sample.hue, saturation: 1, brightness: 1))
            XCTAssertEqual(try result.cmyk.get(), sample.cmyk)
        }
    }

    func testFixedSRGBReferenceCoordinates() throws {
        // Independent reference calculations, using the documented D65 matrix and exact LAB constants.
        // Values are pinned here, not obtained from either production conversion helper.
        let samples: [(rgb: [CGFloat], xyz: [Double], lab: [Double])] = [
            ([1, 0, 0, 1], [41.24564, 21.26729, 1.93339], [53.2407941413, 80.0924595964, 67.2031965159]),
            ([0.2, 0.4, 0.6, 1], [11.8642593355, 12.5052672891, 31.9193194523], [42.0081455965, -0.1517081972, -32.8460361881]),
            ([-0.5, 0, 0, 1], [-8.8282638255, -4.5520750066, -0.4138250006], [-41.1187249389, -184.4063430255, -64.9752096631]),
            ([-0.5, 0.2, 0.7, 1], [0.4388744237, 1.0487760246, 42.5532798427], [9.3913371873, -22.5017887795, -102.4466144904])
        ]
        for sample in samples {
            let color = try fixedTestColor(space: CGColorSpace.extendedSRGB, components: sample.rgb)
            let result = color.componentConversionResults()
            let xyz = try result.xyz.get()
            let lab = try result.lab.get()
            for (actual, expected) in zip([xyz.x, xyz.y, xyz.z], sample.xyz) {
                XCTAssertEqual(actual, expected, accuracy: 1e-9)
            }
            for (actual, expected) in zip([lab.lightness, lab.a, lab.b], sample.lab) {
                XCTAssertEqual(actual, expected, accuracy: 1e-9)
            }
        }
    }

    func testSuccessfulZeroCoordinatesAndWhiteScale() throws {
        for value: CGFloat in [0, 0.5, 1] {
            let result = try fixedTestColor(components: [value, value, value, 1]).componentConversionResults()
            XCTAssertEqual(try result.hsl.get(), HSLComponents(hue: 0, saturation: 0, lightness: Double(value)))
            XCTAssertEqual(try result.hsb.get(), HSBComponents(hue: 0, saturation: 0, brightness: Double(value)))
            XCTAssertEqual(try result.cmyk.get(), CMYKComponents(cyan: 0, magenta: 0, yellow: 0, key: Double(1 - value)))
            XCTAssertEqual(try result.srgba.get().alpha, 1)
            XCTAssertNoThrow(try result.hex.get())
            XCTAssertNoThrow(try result.lab.get())
            if value == 1 {
                XCTAssertEqual(try result.xyz.get().z, 108.883, accuracy: 1e-9)
            } else if value == 0 {
                XCTAssertEqual(try result.lab.get(), LABComponents(lightness: 0, a: 0, b: 0))
            }
        }
    }

    func testAlphaIsPreservedWithoutCompositing() throws {
        let reference = try fixedTestColor(components: [1, 0, 0, 1]).componentConversionResults()
        for (alpha, suffix): (CGFloat, String) in [(0, "00"), (0.5, "80"), (1, "FF")] {
            let result = try fixedTestColor(components: [1, 0, 0, alpha]).componentConversionResults()
            XCTAssertEqual(try result.srgba.get(), SRGBAComponents(red: 1, green: 0, blue: 0, alpha: Double(alpha)))
            XCTAssertEqual(try result.hex.get(), "#FF0000" + suffix)
            XCTAssertEqual(try result.hsl.get(), try reference.hsl.get())
            XCTAssertEqual(try result.hsb.get(), try reference.hsb.get())
            XCTAssertEqual(try result.cmyk.get(), try reference.cmyk.get())
            XCTAssertEqual(try result.xyz.get(), try reference.xyz.get())
            XCTAssertEqual(try result.lab.get(), try reference.lab.get())
        }
    }

    func testEquivalentProfiledInputsAndGrayscale() throws {
        let original = try fixedTestColor(components: [0.2, 0.4, 0.6, 0.5])
        let source = try XCTUnwrap(original.cgColor)
        let reference = original.componentConversionResults()
        for name in [CGColorSpace.linearSRGB, CGColorSpace.displayP3, CGColorSpace.adobeRGB1998] {
            let space = try XCTUnwrap(CGColorSpace(name: name))
            let converted = try XCTUnwrap(source.converted(to: space, intent: .relativeColorimetric, options: nil))
            let result = Color(converted).componentConversionResults()
            XCTAssertEqual(try result.srgba.get().red, try reference.srgba.get().red, accuracy: 1e-5)
            XCTAssertEqual(try result.lab.get().lightness, try reference.lab.get().lightness, accuracy: 0.001)
            XCTAssertEqual(try result.lab.get().a, try reference.lab.get().a, accuracy: 0.001)
            XCTAssertEqual(try result.lab.get().b, try reference.lab.get().b, accuracy: 0.001)
            XCTAssertEqual(try result.hex.get(), "#33669980")
            XCTAssertNoThrow(try result.cmyk.get())
            XCTAssertNoThrow(try result.hsl.get())
            XCTAssertNoThrow(try result.hsb.get())
        }
        let gray = try fixedTestColor(space: CGColorSpace.linearGray, components: [0.25, 0.5]).componentConversionResults()
        XCTAssertEqual(try gray.srgba.get().red, 0.5370987304831942, accuracy: 1e-6)
        XCTAssertEqual(try gray.hsl.get().saturation, 0)
        XCTAssertEqual(try gray.hex.get(), "#89898980")
    }

    func testWideGamutAndOverflowPreserveIndependentSuccesses() throws {
        let p3 = try fixedTestColor(space: CGColorSpace.displayP3, components: [1, 0, 0, 0.5])
        let result = p3.componentConversionResults()
        XCTAssertGreaterThan(try result.srgba.get().red, 1)
        XCTAssertLessThan(try result.srgba.get().green, 0)
        assertBoundedUnavailable(result)
        // Independent Display P3 red XYZ from its primaries, allowing platform/matrix rounding.
        let xyz = try result.xyz.get()
        XCTAssertEqual(xyz.x, 48.657095, accuracy: 0.02)
        XCTAssertEqual(xyz.y, 22.897456, accuracy: 0.02)
        XCTAssertEqual(xyz.z, 0, accuracy: 0.02)
        XCTAssertNoThrow(try result.lab.get())

        let extreme = try fixedTestColor(space: CGColorSpace.extendedSRGB, components: [.greatestFiniteMagnitude, 0.4, 0.6, 1])
        let overflow = extreme.componentConversionResults()
        XCTAssertEqual(try overflow.srgba.get().red, Double.greatestFiniteMagnitude)
        assertBoundedUnavailable(overflow)
        assertFailure(overflow.xyz, .nonfiniteResult)
        assertFailure(overflow.lab, .nonfiniteResult)
    }

    func testStrictEndpointsAndStableBoundedArithmetic() throws {
        for red: CGFloat in [-.leastNonzeroMagnitude, CGFloat(1).nextUp] {
            let result = try fixedTestColor(space: CGColorSpace.extendedSRGB, components: [red, 0.4, 0.6, 1]).componentConversionResults()
            assertBoundedUnavailable(result)
        }
        let nearWhite = try fixedTestColor(components: [1, CGFloat(1).nextDown, CGFloat(1).nextDown, 1]).componentConversionResults()
        XCTAssertEqual(try nearWhite.hsl.get().saturation, 1)
        let nearBlack = try fixedTestColor(components: [.leastNonzeroMagnitude, 0, 0, 1]).componentConversionResults()
        XCTAssertEqual(try nearBlack.cmyk.get(), CMYKComponents(cyan: 0, magenta: 1, yellow: 1, key: 1))
        let nearRed = try fixedTestColor(components: [1, 0, .leastNonzeroMagnitude, 1]).componentConversionResults()
        XCTAssertEqual(try nearRed.hsl.get().hue, 0)
        XCTAssertEqual(try nearRed.hsb.get().hue, 0)
        let rounded = try fixedTestColor(components: [0.5, 0.25, 0.125, 0.5]).componentConversionResults()
        XCTAssertEqual(try rounded.hex.get(), "#80402080")
    }

    func testObservableResolutionIssuesPropagateToEveryField() throws {
        for color in [Color.blue, .primary, .secondary] {
            XCTAssertNil(color.cgColor)
            assertAllUnavailable(color.componentConversionResults(), .unresolvedInput)
        }
        assertAllUnavailable(try patternTestColor().componentConversionResults(), .unsupportedColorModel)
        let cmyk = try fixedTestColor(space: CGColorSpaceCreateDeviceCMYK(), components: [0.2, 0.4, 0.6, 0.1, 1])
        assertAllUnavailable(cmyk.componentConversionResults(), .unsupportedColorModel)
        for index in 0..<4 {
            for invalid: CGFloat in [.nan, .infinity, -.infinity] {
                var components: [CGFloat] = [0.2, 0.4, 0.6, 0.5]
                components[index] = invalid
                // Core Graphics may sanitize infinite alpha; NaN alpha survives construction.
                if index == 3, !invalid.isNaN { continue }
                let color = try fixedTestColor(space: CGColorSpace.extendedSRGB, components: components)
                assertAllUnavailable(color.componentConversionResults(), .invalidComponents)
            }
        }
    }

    func testExplicitAppearanceCaptureProducesStableFixedResults() throws {
        #if canImport(UIKit)
        let dynamic = UIColor { $0.userInterfaceStyle == .dark ? .white : .black }
        let lightColor = Color(dynamic.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).cgColor)
        let darkColor = Color(dynamic.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).cgColor)
        #else
        let dynamic = NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .white : .black
        }
        func capture(_ name: NSAppearance.Name) throws -> Color {
            let appearance = try XCTUnwrap(NSAppearance(named: name))
            var fixed: CGColor?
            appearance.performAsCurrentDrawingAppearance {
                fixed = dynamic.usingColorSpace(.extendedSRGB)?.cgColor
            }
            return Color(try XCTUnwrap(fixed))
        }
        let lightColor = try capture(.aqua)
        let darkColor = try capture(.darkAqua)
        #endif
        assertAllUnavailable(Color(dynamic).componentConversionResults(), .unresolvedInput)
        let light = lightColor.componentConversionResults()
        let dark = darkColor.componentConversionResults()
        XCTAssertEqual(try light.srgba.get().red, 0, accuracy: 1e-6)
        XCTAssertEqual(try dark.srgba.get().red, 1, accuracy: 1e-6)
        XCTAssertEqual(try lightColor.componentConversionResults().srgba.get(), try light.srgba.get())
    }

    private func assertBoundedUnavailable(_ result: ColorComponentConversionResults, file: StaticString = #filePath, line: UInt = #line) {
        assertFailure(result.hsl, .outOfSRGBGamut, file: file, line: line)
        assertFailure(result.hsb, .outOfSRGBGamut, file: file, line: line)
        assertFailure(result.cmyk, .outOfSRGBGamut, file: file, line: line)
        assertFailure(result.hex, .outOfSRGBGamut, file: file, line: line)
    }

    private func assertAllUnavailable(_ result: ColorComponentConversionResults, _ issue: ColorConversionIssue, file: StaticString = #filePath, line: UInt = #line) {
        assertFailure(result.srgba, issue, file: file, line: line)
        assertFailure(result.hsl, issue, file: file, line: line)
        assertFailure(result.hsb, issue, file: file, line: line)
        assertFailure(result.cmyk, issue, file: file, line: line)
        assertFailure(result.xyz, issue, file: file, line: line)
        assertFailure(result.lab, issue, file: file, line: line)
        assertFailure(result.hex, issue, file: file, line: line)
    }

    private func assertFailure<Value>(_ result: Result<Value, ColorConversionIssue>, _ issue: ColorConversionIssue, file: StaticString = #filePath, line: UInt = #line) {
        guard case .failure(let actual) = result else {
            return XCTFail("Expected \(issue)", file: file, line: line)
        }
        XCTAssertEqual(actual, issue, file: file, line: line)
    }
}
