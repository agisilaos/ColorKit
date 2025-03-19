import SwiftUI
import XCTest

@testable import ColorKit

#if canImport(SwiftUI) && (os(iOS) && !(targetEnvironment(macCatalyst)) && swift(>=5.5))
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
    func testThemeManager() {
        let manager = ThemeManager.shared

        // Test default themes
        XCTAssertEqual(manager.availableThemes.count, 2)
        XCTAssertEqual(manager.currentTheme.name, "Default Light")

        // Test registering a new theme
        let newTheme = ColorTheme(
            name: "Custom Theme",
            primary: Color.purple,
            secondary: Color.orange,
            accent: Color.yellow,
            background: Color.gray,
            text: Color.white
        )

        let result = manager.register(theme: newTheme)
        XCTAssertTrue(result)
        XCTAssertEqual(manager.availableThemes.count, 3)

        // Test switching themes
        let switchResult = manager.switchToTheme(named: "Custom Theme")
        XCTAssertTrue(switchResult)
        XCTAssertEqual(manager.currentTheme.name, "Custom Theme")

        // Test switching to a non-existent theme
        let failedSwitchResult = manager.switchToTheme(named: "Non-existent Theme")
        XCTAssertFalse(failedSwitchResult)

        // Test registering a theme with a duplicate name
        let duplicateTheme = ColorTheme(
            name: "Custom Theme",
            primary: Color.red,
            secondary: Color.blue,
            accent: Color.green,
            background: Color.white,
            text: Color.black
        )

        let duplicateResult = manager.register(theme: duplicateTheme)
        XCTAssertFalse(duplicateResult)
        XCTAssertEqual(manager.availableThemes.count, 3)
    }

    @MainActor
    func testThemeColorSet() {
        // Test generating a color set from a base color
        let generatedSet = ThemeColorSet.from(base: Color.blue)

        XCTAssertNotNil(generatedSet)
    }
}
#endif
