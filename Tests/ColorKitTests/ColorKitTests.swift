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

    // MARK: - CMYK Conversion Tests
    func testColorToCMYK() {
        let color = Color(red: 1.0, green: 0.0, blue: 0.0) // Pure red
        guard let cmyk = color.cmykComponents() else {
            XCTFail("Failed to retrieve CMYK components")
            return
        }

        XCTAssertEqual(Double(cmyk.cyan), 0.0, accuracy: 0.01, "Cyan value incorrect")
        XCTAssertEqual(Double(cmyk.magenta), 1.0, accuracy: 0.01, "Magenta value incorrect")
        XCTAssertEqual(Double(cmyk.yellow), 1.0, accuracy: 0.01, "Yellow value incorrect")
        XCTAssertEqual(Double(cmyk.key), 0.0, accuracy: 0.01, "Key value incorrect")
    }

    func testCMYKToColor() {
        let color = Color(cyan: 0.0, magenta: 1.0, yellow: 1.0, key: 0.0) // Should create pure red
        guard let components = color.cgColor?.components, components.count >= 3 else {
            XCTFail("Failed to get color components")
            return
        }

        XCTAssertEqual(Double(components[0]), 1.0, accuracy: 0.01, "Red component incorrect")
        XCTAssertEqual(Double(components[1]), 0.0, accuracy: 0.01, "Green component incorrect")
        XCTAssertEqual(Double(components[2]), 0.0, accuracy: 0.01, "Blue component incorrect")
    }

    func testCMYKRoundTrip() {
        // Use pure cyan (a primary color) which should round-trip perfectly
        let originalColor = Color(cyan: 1.0, magenta: 0.0, yellow: 0.0, key: 0.0)
        guard let cmyk = originalColor.cmykComponents() else {
            XCTFail("Failed to retrieve CMYK components")
            return
        }
        
        // Test that the values round-trip accurately
        XCTAssertEqual(Double(cmyk.cyan), 1.0, accuracy: 0.01, "Cyan value mismatch")
        XCTAssertEqual(Double(cmyk.magenta), 0.0, accuracy: 0.01, "Magenta value mismatch")
        XCTAssertEqual(Double(cmyk.yellow), 0.0, accuracy: 0.01, "Yellow value mismatch")
        XCTAssertEqual(Double(cmyk.key), 0.0, accuracy: 0.01, "Key value mismatch")
    }

    // MARK: - LAB Conversion Tests
    func testColorToLAB() {
        let color = Color(red: 1.0, green: 0.0, blue: 0.0) // Pure red
        guard let lab = color.labComponents() else {
            XCTFail("Failed to retrieve LAB components")
            return
        }

        // Expected values for pure red in LAB color space
        XCTAssertEqual(Double(lab.L), 53.24, accuracy: 0.1, "L* value incorrect")
        XCTAssertEqual(Double(lab.a), 80.09, accuracy: 0.1, "a* value incorrect")
        XCTAssertEqual(Double(lab.b), 67.20, accuracy: 0.1, "b* value incorrect")
    }

    func testLABToColor() {
        // Create a color using known LAB values for a specific RGB color
        let color = Color(L: 53.24, a: 80.09, b: 67.20) // Should approximate pure red
        guard let components = color.cgColor?.components, components.count >= 3 else {
            XCTFail("Failed to get color components")
            return
        }

        XCTAssertEqual(Double(components[0]), 1.0, accuracy: 0.01, "Red component incorrect")
        XCTAssertEqual(Double(components[1]), 0.0, accuracy: 0.01, "Green component incorrect")
        XCTAssertEqual(Double(components[2]), 0.0, accuracy: 0.01, "Blue component incorrect")
    }

    func testLABRoundTrip() {
        // Test with a mid-range color
        let originalColor = Color(L: 50.0, a: 25.0, b: -30.0)
        guard let lab = originalColor.labComponents() else {
            XCTFail("Failed to retrieve LAB components")
            return
        }

        XCTAssertEqual(Double(lab.L), 50.0, accuracy: 0.1, "L* value mismatch")
        XCTAssertEqual(Double(lab.a), 25.0, accuracy: 0.1, "a* value mismatch")
        XCTAssertEqual(Double(lab.b), -30.0, accuracy: 0.1, "b* value mismatch")
    }

    func testLABBoundaryValues() {
        // Test extreme values
        let blackColor = Color(L: 0, a: 0, b: 0)
        guard let blackLab = blackColor.labComponents() else {
            XCTFail("Failed to retrieve LAB components for black")
            return
        }
        XCTAssertEqual(Double(blackLab.L), 0.0, accuracy: 0.1, "Black L* value incorrect")

        let whiteColor = Color(L: 100, a: 0, b: 0)
        guard let whiteLab = whiteColor.labComponents() else {
            XCTFail("Failed to retrieve LAB components for white")
            return
        }
        XCTAssertEqual(Double(whiteLab.L), 100.0, accuracy: 0.1, "White L* value incorrect")
    }
}
