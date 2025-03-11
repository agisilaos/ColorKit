import XCTest
import SwiftUI
@testable import ColorKit

final class ColorKitTests: XCTestCase {

    // MARK: - HEX Conversion Tests
    func testHexToColor() {
        let color = Color(hex: "#FF5733")
        XCTAssertNotNil(color, "Failed to create Color from HEX")
    }

    func testColorToHex() {
        let color = Color(red: 1.0, green: 0.341, blue: 0.2)
        let expectedHex = "#FF5632FF"
        XCTAssertEqual(color.hexValue(), expectedHex, "HEX conversion failed (may be due to rounding differences)")
    }


    // MARK: - HSL Conversion Tests
    func testColorToHSL() {
        let color = Color(red: 1.0, green: 0.0, blue: 0.0)
        guard let hsl = color.hslComponents() else {
            XCTFail("Failed to retrieve HSL components")
            return
        }

        XCTAssertEqual(Double(hsl.hue), 0.0, accuracy: 0.01, "Hue value incorrect")
        XCTAssertEqual(Double(hsl.saturation), 1.0, accuracy: 0.01, "Saturation value incorrect")
        XCTAssertEqual(Double(hsl.lightness), 0.5, accuracy: 0.01, "Lightness value incorrect")
    }

    func testHSLToColor() {
        let color = Color(hue: 0.0, saturation: 1.0, lightness: 0.5)
        guard let hsl = color.hslComponents() else {
            XCTFail("Failed to retrieve HSL components")
            return
        }

        XCTAssertEqual(Double(hsl.hue), 0.0, accuracy: 0.01, "Hue mismatch")
        XCTAssertEqual(Double(hsl.saturation), 1.0, accuracy: 0.01, "Saturation mismatch")
        XCTAssertEqual(Double(hsl.lightness), 0.5, accuracy: 0.01, "Lightness mismatch")
    }

    // MARK: - Adaptive Color Tests
    func testDarkColorDetection() {
        let darkColor = Color(hex: "#000000")
        XCTAssertTrue(darkColor?.isDarkColor() ?? false, "Black should be detected as dark")

        let lightColor = Color(hex: "#FFFFFF")
        XCTAssertFalse(lightColor?.isDarkColor() ?? true, "White should be detected as light")
    }

    func testContrastRatio() {
        let black = Color(hex: "#000000")!
        let white = Color(hex: "#FFFFFF")!
        let contrast = black.contrastRatio(with: white)
        XCTAssertGreaterThan(contrast, 7.0, "Contrast ratio between black and white should be high")
    }

    func testAccessibilityColorAdjustment() {
        let color = Color(hex: "#888888")! // Gray
        let background = Color(hex: "#FFFFFF")! // White

        let contrastBefore = color.contrastRatio(with: background)

        let adjustedColor = color.adjustedForAccessibility(against: background, minimumRatio: 4.5)
        let contrastAfter = adjustedColor.contrastRatio(with: background)

        XCTAssertGreaterThan(contrastAfter, 4.5, "Adjusted color should meet accessibility contrast")
    }
}
