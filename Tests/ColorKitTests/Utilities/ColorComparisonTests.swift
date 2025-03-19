import SwiftUI
import XCTest

@testable import ColorKit

final class ColorComparisonTests: XCTestCase {
    func testColorComparisonRGB() {
        // Test colors with known RGB values
        let color1 = Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0) // Red
        let color2 = Color(red: 0.0, green: 0.0, blue: 1.0, opacity: 1.0) // Blue

        let diff = color1.compare(with: color2)

        // Check RGB differences
        XCTAssertEqual(diff.rgbDifference.red, 1.0, accuracy: 0.01)
        XCTAssertEqual(diff.rgbDifference.green, 0.0, accuracy: 0.01)
        XCTAssertEqual(diff.rgbDifference.blue, 1.0, accuracy: 0.01)
    }

    func testColorComparisonHSL() {
        // Create colors with specific HSL values
        let color1 = Color(hue: 0.0, saturation: 1.0, brightness: 1.0) // Red
        let color2 = Color(hue: 0.5, saturation: 1.0, brightness: 0.5) // Dark green

        let diff = color1.compare(with: color2)

        // Check HSL differences (hue is normalized to 0-360)
        XCTAssertEqual(diff.hslDifference.hue, 180.0, accuracy: 5.0) // 0.5 in 0-1 scale = 180 degrees
        XCTAssertGreaterThan(diff.hslDifference.lightness, 0.0)
    }

    func testColorComparisonPerceptualDifference() {
        // Test similar colors
        let color1 = Color(red: 0.8, green: 0.8, blue: 0.8, opacity: 1.0) // Light gray
        let color2 = Color(red: 0.7, green: 0.7, blue: 0.7, opacity: 1.0) // Slightly darker gray

        let diff1 = color1.compare(with: color2)

        // Test very different colors
        let color3 = Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0) // White
        let color4 = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 1.0) // Black

        let diff2 = color3.compare(with: color4)

        // The perceptual difference should be greater for the white-black pair
        XCTAssertGreaterThan(diff2.perceptualDifference, diff1.perceptualDifference)
    }

    func testColorComparisonContrastRatio() {
        // White and black have the maximum contrast ratio
        let white = Color.white
        let black = Color.black

        let diff = white.compare(with: black)

        // WCAG contrast ratio for white and black should be 21:1
        XCTAssertEqual(diff.contrastRatio, 21.0, accuracy: 1.0)

        // Should pass all WCAG levels
        XCTAssertTrue(diff.wcagComplianceLevels.contains(.AA))
        XCTAssertTrue(diff.wcagComplianceLevels.contains(.AAA))
        XCTAssertTrue(diff.wcagComplianceLevels.contains(.AALarge))
        XCTAssertTrue(diff.wcagComplianceLevels.contains(.AAALarge))
    }

    func testColorComparisonDescription() {
        let color1 = Color.red
        let color2 = Color.blue

        let diff = color1.compare(with: color2)

        // Check that the description contains key information
        let description = diff.description
        XCTAssertTrue(description.contains("RGB Difference"))
        XCTAssertTrue(description.contains("HSL Difference"))
        XCTAssertTrue(description.contains("Perceptual Difference"))
        XCTAssertTrue(description.contains("Contrast Ratio"))
    }
}
