//
//  ThemeTests.swift
//  ColorKitTests
//
//  Created by Agisilaos Tsaraboulidis on 12.03.2025.
//
//  Description:
//  Tests for the color theming system and theme management.
//
//  Features:
//  - Tests for theme creation and configuration
//  - Tests for theme management (registration, switching)
//  - Tests for theme color sets and variants
//  - Tests for default theme handling
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI
import XCTest

@testable import ColorKit

final class ThemeTests: XCTestCase {
    @MainActor
    func testThemeCreation() {
        // Test creating a theme with individual colors
        let theme = ColorTheme(
            name: "Test Theme",
            primary: Color.red,
            secondary: Color.blue,
            accent: Color.green,
            background: Color.white,
            text: Color.black
        )

        XCTAssertEqual(theme.name, "Test Theme")

        // Test creating a theme with color sets
        let primarySet = ThemeColorSet(base: Color.red, light: Color.pink, dark: Color.purple)
        let secondarySet = ThemeColorSet(base: Color.blue, light: Color.gray, dark: Color.purple)
        let accentSet = ThemeColorSet(base: Color.green, light: Color.purple, dark: Color.gray)
        let backgroundSet = ThemeColorSet(base: Color.white, light: Color.white, dark: Color.gray)
        let textSet = ThemeColorSet(base: Color.black, light: Color.gray, dark: Color.black)
        let statusSet = StatusColorSet(success: Color.green, warning: Color.yellow, error: Color.red)

        let fullTheme = ColorTheme(
            name: "Full Theme",
            primary: primarySet,
            secondary: secondarySet,
            accent: accentSet,
            background: backgroundSet,
            text: textSet,
            status: statusSet
        )

        XCTAssertEqual(fullTheme.name, "Full Theme")
    }

    @MainActor
    func testThemeColorSet() {
        // Test generating a color set from a base color
        let generatedSet = ThemeColorSet.from(base: Color.blue)

        XCTAssertNotNil(generatedSet)
    }
}
