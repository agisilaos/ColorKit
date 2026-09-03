import SwiftUI
import XCTest

@testable import ColorKit

/// Covers luminance-derived behavior for named SwiftUI colors, which carry no
/// `cgColor` and previously measured as black.
final class NamedColorContrastTests: XCTestCase {
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

    func testNamedColorsHaveNonZeroLuminance() {
        for (name, color) in Self.namedColors {
            XCTAssertGreaterThan(color.relativeLuminance(), 0, name)
        }
    }

    func testNamedColorsContrastWithBothEndpoints() {
        // A luminance of zero reported 1:1 against black and 21:1 against white.
        for (name, color) in Self.namedColors {
            XCTAssertGreaterThan(color.contrastRatio(with: .black), 1, name)
            XCTAssertLessThan(color.contrastRatio(with: .white), 21, name)
        }
    }

    func testIsDarkColorSelectsTheStrongerEndpointForNamedColors() {
        for (name, color) in Self.namedColors {
            let againstBlack = color.contrastRatio(with: .black)
            let againstWhite = color.contrastRatio(with: .white)
            let fallback = color.isDarkColor() ? Color.white : Color.black

            XCTAssertEqual(fallback, againstBlack >= againstWhite ? .black : .white, name)
            XCTAssertEqual(
                fallback.contrastRatio(with: color),
                max(againstBlack, againstWhite),
                accuracy: 1e-9,
                name
            )
        }
    }

    func testNamedColorsPreferBlack() {
        // Every one of these is light enough that black is the stronger endpoint.
        for (name, color) in Self.namedColors {
            XCTAssertFalse(color.isDarkColor(), name)
        }
    }

    func testOrangeMatchesItsPublishedEndpointRatios() {
        XCTAssertEqual(Double(Color.orange.contrastRatio(with: .black)), 9.09, accuracy: 0.01)
        XCTAssertEqual(Double(Color.orange.contrastRatio(with: .white)), 2.31, accuracy: 0.01)
    }

    // MARK: - Adjustment fallback

    func testExhaustedAdjustmentAgainstNamedBackgroundUsesTheStrongerEndpoint() {
        let foreground = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5)

        for (name, background) in Self.namedColors {
            // An unattainable minimum forces the black-or-white fallback.
            let adjusted = foreground.adjustedForAccessibility(with: background, minimumRatio: 22)
            let againstBlack = background.contrastRatio(with: .black)
            let againstWhite = background.contrastRatio(with: .white)

            XCTAssertEqual(adjusted, againstBlack >= againstWhite ? .black : .white, name)
            XCTAssertEqual(
                adjusted.contrastRatio(with: background),
                max(againstBlack, againstWhite),
                accuracy: 1e-9,
                name
            )
        }
    }

    // MARK: - Agreement with the WCAG accessor

    func testLegacyAndWCAGRatiosAgreeForOpaqueColors() throws {
        let opaqueColors: [(name: String, color: Color)] = Self.namedColors + [
            ("hex", try XCTUnwrap(Color(hex: "#595959"))),
            ("black", .black),
            ("white", .white),
            ("displayP3", Color(.displayP3, red: 1, green: 0, blue: 0))
        ]

        // Both accessors now derive from the same luminance, as the accessibility
        // article states.
        for (name, color) in opaqueColors {
            XCTAssertEqual(
                Double(color.contrastRatio(with: .white)),
                color.wcagContrastRatio(with: .white),
                accuracy: 1e-12,
                name
            )
        }
    }

    // MARK: - Strict measurement is unchanged

    func testStrictMeasurementStillReportsNamedColorsUnavailable() {
        // Named colors resolve for the current appearance only, so the strict APIs
        // continue to report no measurement rather than an appearance-dependent one.
        for (name, color) in Self.namedColors {
            XCTAssertNil(color.relativeLuminanceValue(), name)
            XCTAssertNil(color.contrastResult(with: .white).ratio, name)
        }
    }
}
