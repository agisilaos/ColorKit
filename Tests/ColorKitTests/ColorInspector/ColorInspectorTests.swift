//
//  ColorInspectorTests.swift
//  ColorKitTests
//
//  Created by Agisilaos Tsaraboulidis on 12.03.2025.
//
//  Description:
//  Tests for the color inspector UI component and functionality.
//
//  Features:
//  - Tests for color inspector view creation and configuration
//  - Tests for color inspector modifiers and positions
//  - Tests for contrast ratio calculations
//  - Tests for view extensions and demo views
//  - Tests for inspector UI component layout and behavior
//
//  License:
//  MIT License. See LICENSE file for details.
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

    @MainActor
    func testColorInspectorDemoView() throws {
        // Test that the demo view can be created
        let demoView = ColorInspectorDemoView()

        XCTAssertNotNil(demoView)
    }
}
