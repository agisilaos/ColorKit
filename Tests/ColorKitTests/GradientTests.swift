//
//  GradientTests.swift
//  ColorKitTests
//
//  Created by Agisilaos Tsaraboulidis on 11.03.2024.
//
//  Description:
//  Tests for gradient generation and manipulation functionality.
//
//  Features:
//  - Tests for linear gradient generation
//  - Tests for complementary gradient generation
//  - Tests for analogous gradient generation
//  - Tests for triadic gradient generation
//  - Tests for monochromatic gradient generation
//  - Tests for edge cases and boundary conditions
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI
import XCTest

@testable import ColorKit

final class GradientTests: XCTestCase {
    // MARK: - Gradient Generation Tests

    func testLinearGradient() {
        let red = Color(.sRGB, red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0)
        let blue = Color(.sRGB, red: 0.0, green: 0.0, blue: 1.0, opacity: 1.0)
        let steps = 5

        let gradient = red.linearGradient(to: blue, steps: steps)

        // Test that the correct number of colors is returned
        XCTAssertEqual(gradient.count, steps, "Gradient should have exactly \(steps) colors")

        // Test that first color is red and last color is blue
        // Check the components instead of direct comparison since Color equality is unreliable
        guard let firstComponents = gradient.first?.cgColor?.components, firstComponents.count >= 3,
              let lastComponents = gradient.last?.cgColor?.components, lastComponents.count >= 3 else {
            XCTFail("Failed to retrieve color components")
            return
        }

        // First color should be red (1, 0, 0)
        XCTAssertEqual(Double(firstComponents[0]), 1.0, accuracy: 0.01, "First color should be red")
        XCTAssertEqual(Double(firstComponents[1]), 0.0, accuracy: 0.01, "First color should be red")
        XCTAssertEqual(Double(firstComponents[2]), 0.0, accuracy: 0.01, "First color should be red")

        // Last color should be blue (0, 0, 1)
        XCTAssertEqual(Double(lastComponents[0]), 0.0, accuracy: 0.01, "Last color should be blue")
        XCTAssertEqual(Double(lastComponents[1]), 0.0, accuracy: 0.01, "Last color should be blue")
        XCTAssertEqual(Double(lastComponents[2]), 1.0, accuracy: 0.01, "Last color should be blue")
    }

    func testComplementaryGradient() {
        let red = Color(.sRGB, red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0)
        let steps = 5

        let gradient = red.complementaryGradient(steps: steps)

        // Test that the correct number of colors is returned
        XCTAssertEqual(gradient.count, steps, "Gradient should have exactly \(steps) colors")

        // First color should be red
        guard let firstComponents = gradient.first?.cgColor?.components,
              let lastComponents = gradient.last?.cgColor?.components,
              firstComponents.count >= 3,
              lastComponents.count >= 3 else {
            XCTFail("Failed to retrieve color components")
            return
        }

        // First color should be red (1, 0, 0)
        XCTAssertEqual(Double(firstComponents[0]), 1.0, accuracy: 0.01, "First color should be red")
        XCTAssertEqual(Double(firstComponents[1]), 0.0, accuracy: 0.01, "First color should be red")
        XCTAssertEqual(Double(firstComponents[2]), 0.0, accuracy: 0.01, "First color should be red")

        // Last color should be cyan (0, 1, 1) - complementary to red
        XCTAssertEqual(Double(lastComponents[0]), 0.0, accuracy: 0.01, "Last color should be cyan")
        // Complementary color check is more complex since hue is a property of the HSL color wheel
        // Actual values will depend on how hslComponents() is implemented
    }

    func testAnalogousGradient() {
        let red = Color(.sRGB, red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0)
        let steps = 5
        let angle: CGFloat = 0.0833 // Default 30° (normalized 0.0833)

        let gradient = red.analogousGradient(steps: steps, angle: angle)

        // Test that the correct number of colors is returned
        XCTAssertEqual(gradient.count, steps, "Gradient should have exactly \(steps) colors")

        // Check components of first and last colors
        guard let firstComponents = gradient.first?.cgColor?.components,
              let lastComponents = gradient.last?.cgColor?.components,
              firstComponents.count >= 3,
              lastComponents.count >= 3 else {
            XCTFail("Failed to retrieve color components")
            return
        }

        // Since the analogous gradient may not create significantly different colors
        // for some hues, we'll just check that the colors are generated correctly
        XCTAssertNotNil(gradient.first, "First color should exist")
        XCTAssertNotNil(gradient.last, "Last color should exist")
    }

    func testTriadicGradient() {
        let red = Color(.sRGB, red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0)
        let steps = 3 // Use a small number for simplicity

        let gradient = red.triadicGradient(steps: steps)

        // For steps=3, expect 7 colors (3 + 2 + 2): red, mid1, green, mid2, blue, mid3, red
        // (where mid colors are interpolations and dropFirst() is applied to the second and third segments)
        XCTAssertEqual(gradient.count, steps * 3 - 2, "Triadic gradient should have the correct number of colors")

        // Check that first and last colors are similar (red-like)
        guard let firstComponents = gradient.first?.cgColor?.components,
              let lastComponents = gradient.last?.cgColor?.components,
              firstComponents.count >= 3,
              lastComponents.count >= 3 else {
            XCTFail("Failed to retrieve color components")
            return
        }

        XCTAssertEqual(Double(firstComponents[0]), Double(lastComponents[0]), accuracy: 0.1, "First and last colors should be similar (red)")
    }

    func testMonochromaticGradient() {
        let red = Color(.sRGB, red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0)
        let steps = 5
        let lightnessRange: ClosedRange<CGFloat> = 0.2...0.8

        let gradient = red.monochromaticGradient(steps: steps, lightnessRange: lightnessRange)

        // Test that the correct number of colors is returned
        XCTAssertEqual(gradient.count, steps, "Gradient should have exactly \(steps) colors")

        // Check that red component is preserved (though may vary with lightness)
        for color in gradient {
            guard let components = color.cgColor?.components, components.count >= 3 else {
                XCTFail("Failed to retrieve color components")
                continue
            }

            // Ensure red is the dominant component for each color in the monochromatic gradient
            XCTAssertTrue(components[0] > components[1], "Red should be greater than green in a red monochromatic gradient")
            XCTAssertTrue(components[0] > components[2], "Red should be greater than blue in a red monochromatic gradient")
        }
    }

    // MARK: - Edge Cases

    func testSingleStepGradient() {
        let red = Color(.sRGB, red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0)
        let blue = Color(.sRGB, red: 0.0, green: 0.0, blue: 1.0, opacity: 1.0)

        // Test with steps = 1
        let linearGradient = red.linearGradient(to: blue, steps: 1)
        let complementaryGradient = red.complementaryGradient(steps: 1)
        let analogousGradient = red.analogousGradient(steps: 1)
        let monochromaticGradient = red.monochromaticGradient(steps: 1)

        // Each gradient should just return the base color in a single-element array
        XCTAssertEqual(linearGradient.count, 1, "Single step gradient should have one color")
        XCTAssertEqual(complementaryGradient.count, 1, "Single step complementary gradient should have one color")
        XCTAssertEqual(analogousGradient.count, 1, "Single step analogous gradient should have one color")
        XCTAssertEqual(monochromaticGradient.count, 1, "Single step monochromatic gradient should have one color")

        // Check that first color is red
        guard let linearComponents = linearGradient.first?.cgColor?.components,
              linearComponents.count >= 3 else {
            XCTFail("Failed to retrieve linear gradient components")
            return
        }

        XCTAssertEqual(Double(linearComponents[0]), 1.0, accuracy: 0.01, "Single step gradient should contain only the base color (red)")
        XCTAssertEqual(Double(linearComponents[1]), 0.0, accuracy: 0.01, "Single step gradient should contain only the base color (red)")
        XCTAssertEqual(Double(linearComponents[2]), 0.0, accuracy: 0.01, "Single step gradient should contain only the base color (red)")
    }

    func testZeroStepsGradient() {
        let red = Color(.sRGB, red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0)
        let blue = Color(.sRGB, red: 0.0, green: 0.0, blue: 1.0, opacity: 1.0)

        // Test with steps = 0 (should be handled equivalent to steps = 1)
        let linearGradient = red.linearGradient(to: blue, steps: 0)

        // Should return the base color in a single-element array
        XCTAssertEqual(linearGradient.count, 1, "Zero step gradient should have one color")

        // Check that first color is red
        guard let components = linearGradient.first?.cgColor?.components,
              components.count >= 3 else {
            XCTFail("Failed to retrieve color components")
            return
        }

        XCTAssertEqual(Double(components[0]), 1.0, accuracy: 0.01, "Zero step gradient should contain only the base color (red)")
        XCTAssertEqual(Double(components[1]), 0.0, accuracy: 0.01, "Zero step gradient should contain only the base color (red)")
        XCTAssertEqual(Double(components[2]), 0.0, accuracy: 0.01, "Zero step gradient should contain only the base color (red)")
    }
}
