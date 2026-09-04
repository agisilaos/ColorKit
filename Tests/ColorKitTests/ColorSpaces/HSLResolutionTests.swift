import SwiftUI
import XCTest

@testable import ColorKit

/// Covers how `hslComponents()` resolves its input, and the adaptive APIs that were
/// silent no-ops while it reported no value.
final class HSLResolutionTests: XCTestCase {
    private static let namedColors: [(name: String, color: Color)] = [
        ("blue", .blue),
        ("orange", .orange),
        ("green", .green),
        ("red", .red),
        ("gray", .gray)
    ]

    override func setUp() {
        super.setUp()
        ColorCache.shared.clearCache()
    }

    override func tearDown() {
        ColorCache.shared.clearCache()
        super.tearDown()
    }

    // MARK: - Resolution

    func testNamedColorsResolve() {
        for (name, color) in Self.namedColors {
            XCTAssertNotNil(color.hslComponents(), name)
        }
    }

    func testGrayscaleResolves() throws {
        let gray = Color(CGColor(gray: 0.5, alpha: 1))

        // Two components previously failed the raw component check.
        XCTAssertEqual(try XCTUnwrap(gray.cgColor?.components).count, 2)

        let hsl = try XCTUnwrap(gray.hslComponents())
        XCTAssertEqual(hsl.saturation, 0, accuracy: 1e-6)
        XCTAssertGreaterThan(hsl.lightness, 0)
    }

    func testGrayscaleResolvesThroughItsColorSpace() throws {
        // Generic gray 0.5 is not sRGB 0.5, so the raw component would give the wrong value.
        let gray = Color(CGColor(gray: 0.5, alpha: 1))

        let hsl = try XCTUnwrap(gray.hslComponents())

        XCTAssertNotEqual(hsl.lightness, 0.5, accuracy: 1e-3)
    }

    func testUnresolvableColorStillReportsNoValue() {
        XCTAssertNil(unresolvableTestColor().hslComponents())
    }

    func testOpacityIsNotPartOfHSL() throws {
        let opaque = Color(.sRGB, red: 0.2, green: 0.6, blue: 0.4)
        let translucent = Color(.sRGB, red: 0.2, green: 0.6, blue: 0.4, opacity: 0.3)

        let opaqueHSL = try XCTUnwrap(opaque.hslComponents())
        let translucentHSL = try XCTUnwrap(translucent.hslComponents())

        XCTAssertEqual(opaqueHSL.hue, translucentHSL.hue, accuracy: 1e-9)
        XCTAssertEqual(opaqueHSL.saturation, translucentHSL.saturation, accuracy: 1e-9)
        XCTAssertEqual(opaqueHSL.lightness, translucentHSL.lightness, accuracy: 1e-9)
    }

    func testDisplayP3PrimariesClampToSRGBBeforeHSLConversion() throws {
        let primaries: [(color: Color, hue: CGFloat)] = [
            (Color(.displayP3, red: 1, green: 0, blue: 0), 0),
            (Color(.displayP3, red: 0, green: 1, blue: 0), 1.0 / 3),
            (Color(.displayP3, red: 0, green: 0, blue: 1), 2.0 / 3)
        ]

        for (color, hue) in primaries {
            let hsl = try XCTUnwrap(color.hslComponents())

            // Color-space conversion can leave small residual components near zero.
            XCTAssertEqual(hsl.hue, hue, accuracy: 1e-4)
            XCTAssertEqual(hsl.saturation, 1, accuracy: 1e-6)
            XCTAssertEqual(hsl.lightness, 0.5, accuracy: 1e-6)
        }
    }

    func testDisplayP3OrangeConvertsBeforeClamping() throws {
        let orange = Color(.displayP3, red: 1, green: 0.5, blue: 0)

        let hsl = try XCTUnwrap(orange.hslComponents())

        // P3 orange converts to approximately (1.07407, 0.46249, -0.21044)
        // in extended sRGB, then clamps to (1, 0.46249, 0).
        XCTAssertEqual(hsl.hue, 0.46249 / 6, accuracy: 1e-5)
        XCTAssertEqual(hsl.saturation, 1, accuracy: 1e-6)
        XCTAssertEqual(hsl.lightness, 0.5, accuracy: 1e-6)
    }

    func testSRGBResolutionIsUnchanged() throws {
        let color = Color(.sRGB, red: 0.5, green: 0.25, blue: 0.75)

        let hsl = try XCTUnwrap(color.hslComponents())

        XCTAssertEqual(hsl.hue, 270.0 / 360, accuracy: 1e-6)
        XCTAssertEqual(hsl.saturation, 0.5, accuracy: 1e-6)
        XCTAssertEqual(hsl.lightness, 0.5, accuracy: 1e-6)
    }

    // MARK: - Adaptive APIs that depended on it

    func testAdjustedForModeChangesNamedColors() {
        // This returned its input unchanged for every named color.
        for (name, color) in Self.namedColors {
            XCTAssertNotEqual(color.adjustedForMode(isDarkMode: true), color, name)
            XCTAssertNotEqual(color.adjustedForMode(isDarkMode: false), color, name)
        }
    }

    func testAdjustedForModeChangesGrayscale() {
        let gray = Color(CGColor(gray: 0.5, alpha: 1))

        XCTAssertNotEqual(gray.adjustedForMode(isDarkMode: true), gray)
    }

    func testAdjustedForModeMovesLightnessInTheRequestedDirection() throws {
        let color = Color(.sRGB, red: 0.4, green: 0.5, blue: 0.6)
        let original = try XCTUnwrap(color.hslComponents())

        let lightened = try XCTUnwrap(color.adjustedForMode(isDarkMode: true).hslComponents())
        let darkened = try XCTUnwrap(color.adjustedForMode(isDarkMode: false).hslComponents())

        XCTAssertGreaterThan(lightened.lightness, original.lightness)
        XCTAssertLessThan(darkened.lightness, original.lightness)
    }

    func testAdjustedForAccessibilityAdjustsNamedColors() {
        // The lightness search was previously skipped entirely for these.
        for (name, color) in Self.namedColors {
            let adjusted = color.adjustedForAccessibility(with: .white, minimumRatio: 7)

            XCTAssertNotEqual(adjusted, color, name)
            XCTAssertGreaterThanOrEqual(
                Double(adjusted.contrastRatio(with: .white)),
                7,
                name
            )
        }
    }

    func testAlreadyCompliantNamedColorIsPreserved() {
        // Black-on-white already exceeds the minimum, so no adjustment is attempted.
        XCTAssertEqual(Color.black.adjustedForAccessibility(with: .white, minimumRatio: 4.5), .black)
    }
}
