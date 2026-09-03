import SwiftUI
import XCTest

@testable import ColorKit

final class AccessibilityAdjustmentTests: XCTestCase {
    func testAlreadyCompliantColorIsUnchangedIncludingOpacity() throws {
        let pairs: [(foreground: Color, background: Color)] = [
            (Color(.sRGB, red: 0.02, green: 0.08, blue: 0.12, opacity: 0.35), .white),
            (Color(.sRGB, red: 0.7, green: 0.8, blue: 0.6, opacity: 0.65), .black)
        ]

        for (foreground, background) in pairs {
            _ = try XCTUnwrap(foreground.hslComponents())
            XCTAssertGreaterThan(foreground.contrastRatio(with: background), 4.5)

            let adjusted = foreground.adjustedForAccessibility(with: background, minimumRatio: 4.5)

            XCTAssertEqual(adjusted, foreground)
            XCTAssertEqual(adjusted.cgColor?.alpha, foreground.cgColor?.alpha)
        }
    }

    func testColorExactlyAtMinimumRatioIsUnchanged() throws {
        let foreground = Color(.sRGB, red: 0.1, green: 0.2, blue: 0.3)
        let background = Color.white
        _ = try XCTUnwrap(foreground.hslComponents())
        let minimumRatio = foreground.contrastRatio(with: background)

        let adjusted = foreground.adjustedForAccessibility(with: background, minimumRatio: minimumRatio)

        XCTAssertEqual(adjusted, foreground)
    }

    func testUnattainableRatioUsesLegacyFallbackForBothBackgrounds() throws {
        let foreground = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5)
        _ = try XCTUnwrap(foreground.hslComponents())
        let pairs: [(background: Color, fallback: Color)] = [
            (Color(.sRGB, red: 0.25, green: 0.25, blue: 0.25), .white),
            (Color(.sRGB, red: 0.75, green: 0.75, blue: 0.75), .black)
        ]

        for (background, fallback) in pairs {
            for minimumRatio: CGFloat in [22, .infinity] {
                let adjusted = foreground.adjustedForAccessibility(with: background, minimumRatio: minimumRatio)

                XCTAssertEqual(adjusted, fallback)
                XCTAssertLessThan(adjusted.contrastRatio(with: background), minimumRatio)
            }
        }
    }

    func testExhaustedSearchKeepsLegacyFallbackEvenWhenBlackWouldPass() {
        let foreground = Color(.sRGB, red: 0.6, green: 0.6, blue: 0.6)
        let background = Color(.sRGB, red: 0.4, green: 0.4, blue: 0.4)
        XCTAssertLessThan(foreground.contrastRatio(with: background), 7)
        XCTAssertGreaterThan(Color.black.contrastRatio(with: background), 7)

        let adjusted = foreground.adjustedForAccessibility(with: background, minimumRatio: 7)

        XCTAssertEqual(adjusted, .white)
        XCTAssertLessThan(adjusted.contrastRatio(with: background), 7)
    }

    func testFailedForegroundConversionReturnsOriginalColor() {
        let foregrounds = [Color.primary, Color(CGColor(gray: 0.4, alpha: 0.3))]

        for foreground in foregrounds {
            XCTAssertNil(foreground.hslComponents())

            let adjusted = foreground.adjustedForAccessibility(with: .white, minimumRatio: 22)

            XCTAssertEqual(adjusted, foreground)
        }
    }

    func testNaNMinimumRatioKeepsLegacyFallback() {
        let foreground = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5)

        XCTAssertEqual(foreground.adjustedForAccessibility(with: .white, minimumRatio: .nan), .black)
        XCTAssertEqual(foreground.adjustedForAccessibility(with: .black, minimumRatio: .nan), .white)
    }

    @MainActor
    func testHighContrastModifierDelegatesCustomRatio() throws {
        guard #available(iOS 16.0, macOS 13.0, *) else {
            throw XCTSkip("ImageRenderer requires iOS 16 or macOS 13")
        }
        let cases: [(base: Color, background: Color, minimumRatio: CGFloat)] = [
            (Color(.sRGB, red: 0.02, green: 0.08, blue: 0.12, opacity: 0.35), .white, 4.5),
            (Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5), .white, 7),
            (Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5), .black, 22),
            (.primary, .white, 22)
        ]

        for (base, background, minimumRatio) in cases {
            let adjusted = base.adjustedForAccessibility(with: background, minimumRatio: minimumRatio)
            let actual = Rectangle().highContrastColor(base: base, background: background, minimumRatio: minimumRatio)
            let expected = Rectangle().foregroundColor(adjusted)

            XCTAssertEqual(try renderedPixel(of: actual), try renderedPixel(of: expected))
        }
    }

    @MainActor
    func testHighContrastModifierDefaultsToRatioOfFourPointFive() throws {
        guard #available(iOS 16.0, macOS 13.0, *) else {
            throw XCTSkip("ImageRenderer requires iOS 16 or macOS 13")
        }
        let base = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5)
        let adjusted = base.adjustedForAccessibility(with: .white, minimumRatio: 4.5)
        let actual = Rectangle().highContrastColor(base: base, background: .white)
        let expected = Rectangle().foregroundColor(adjusted)

        XCTAssertEqual(try renderedPixel(of: actual), try renderedPixel(of: expected))
    }
}
