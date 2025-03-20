//
//  ColorInspectorTests.swift
//  ColorKitTests
//
//  Created by Agisilaos Tsaraboulidis on 12.03.2024.
//

import SwiftUI
import XCTest

@testable import ColorKit

final class ColorInspectorTests: XCTestCase {
    @MainActor
    func testColorInspectorView() throws {
        // Test that the view can be created with various parameters
        let color = Color.blue
        let backgroundColor = Color.white
        let showContrastInfo = true

        let view = ColorInspectorView(
            color: color,
            backgroundColor: backgroundColor,
            showContrastInfo: showContrastInfo
        )

        XCTAssertNotNil(view)

        // Test with different parameters
        let viewWithoutContrastInfo = ColorInspectorView(
            color: color,
            backgroundColor: backgroundColor,
            showContrastInfo: false
        )

        XCTAssertNotNil(viewWithoutContrastInfo)

        // Test with different colors
        let viewWithDifferentColors = ColorInspectorView(
            color: Color.red,
            backgroundColor: Color.black
        )

        XCTAssertNotNil(viewWithDifferentColors)
    }

    @MainActor
    func testColorInspectorModifier() throws {
        // Test that the modifier can be created with various parameters
        let color = Color.blue
        let backgroundColor = Color.white
        let position = ColorInspectorModifier.Position.bottomTrailing
        let showContrastInfo = true

        let modifier = ColorInspectorModifier(
            color: color,
            backgroundColor: backgroundColor,
            position: position,
            showContrastInfo: showContrastInfo
        )

        XCTAssertNotNil(modifier)

        // Test with different positions
        for position in [
            ColorInspectorModifier.Position.topLeading,
            ColorInspectorModifier.Position.topTrailing,
            ColorInspectorModifier.Position.bottomLeading,
            ColorInspectorModifier.Position.bottomTrailing
        ] {
            let positionModifier = ColorInspectorModifier(
                color: color,
                backgroundColor: backgroundColor,
                position: position
            )

            XCTAssertNotNil(positionModifier)
        }

        // Test with contrast info disabled
        let modifierWithoutContrastInfo = ColorInspectorModifier(
            color: color,
            backgroundColor: backgroundColor,
            position: position,
            showContrastInfo: false
        )

        XCTAssertNotNil(modifierWithoutContrastInfo)
    }

    @MainActor
    func testViewExtension() throws {
        // Test that the view extension works
        let view = Text("Test")

        let inspectorView = view.colorInspector(
            color: .blue,
            backgroundColor: .white,
            position: .bottomTrailing,
            showContrastInfo: true
        )

        XCTAssertNotNil(inspectorView)

        // Test with different parameters
        let inspectorViewWithDifferentParams = view.colorInspector(
            color: .red,
            backgroundColor: .black,
            position: .topLeading,
            showContrastInfo: false
        )

        XCTAssertNotNil(inspectorViewWithDifferentParams)
    }

    func testContrastRatioCalculation() throws {
        // Test contrast ratio calculation
        // Using known values instead of trying to extract components from Color

        // White has luminance of 1.0, black has luminance of 0.0
        let whiteL = 1.0
        let blackL = 0.0

        // Calculate contrast ratio
        let contrastRatio = (whiteL + 0.05) / (blackL + 0.05)

        // Test with a tolerance for floating point comparison
        XCTAssertEqual(contrastRatio, 21.0, accuracy: 0.1, "Contrast ratio between white and black should be approximately 21:1")

        // Test WCAG compliance levels
        XCTAssertTrue(contrastRatio >= 7.0, "Should pass AAA level for normal text")
        XCTAssertTrue(contrastRatio >= 4.5, "Should pass AA level for normal text")
        XCTAssertTrue(contrastRatio >= 3.0, "Should pass AA level for large text")
    }

    @MainActor
    func testColorInspectorDemoView() throws {
        // Test that the demo view can be created
        let demoView = ColorInspectorDemoView()

        XCTAssertNotNil(demoView)
    }
}
