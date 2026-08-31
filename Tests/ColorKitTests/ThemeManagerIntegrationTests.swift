import Combine
import SwiftUI
import XCTest

@testable import ColorKit

// Run this suite without parallel testing: the singleton has no reset or removal API.
@MainActor
final class ThemeManagerIntegrationTests: XCTestCase {
    func testRegistrationPublishesRegistryWithoutChangingSelection() {
        let manager = ThemeManager.shared
        let originalTheme = manager.currentTheme
        let originalRegistry = manager.availableThemes
        let theme = makeTheme()
        var registries: [[ColorTheme]] = []
        var selections: [ColorTheme] = []
        var objectChanges = 0
        let registrySubscription = manager.$availableThemes.dropFirst().sink { registries.append($0) }
        let selectionSubscription = manager.$currentTheme.dropFirst().sink { selections.append($0) }
        let objectSubscription = manager.objectWillChange.sink { objectChanges += 1 }
        defer {
            registrySubscription.cancel()
            selectionSubscription.cancel()
            objectSubscription.cancel()
        }

        XCTAssertTrue(manager.register(theme: theme))
        XCTAssertEqual(registries, [originalRegistry + [theme]])
        XCTAssertEqual(manager.availableThemes, originalRegistry + [theme])
        XCTAssertEqual(manager.currentTheme, originalTheme)
        XCTAssertTrue(selections.isEmpty)
        XCTAssertEqual(objectChanges, 1)

        XCTAssertFalse(manager.register(theme: makeTheme(name: theme.name, primary: .red)))
        XCTAssertEqual(registries.count, 1)
        XCTAssertEqual(manager.availableThemes, originalRegistry + [theme])
        XCTAssertEqual(manager.currentTheme, originalTheme)
        XCTAssertTrue(selections.isEmpty)
        XCTAssertEqual(objectChanges, 1)
    }

    func testSelectionPreservesNameAndInstanceSemantics() {
        let manager = ThemeManager.shared
        let originalTheme = manager.currentTheme
        defer { manager.switchTo(theme: originalTheme) }
        let registeredTheme = makeTheme()
        let suppliedTheme = makeTheme(name: registeredTheme.name, primary: .red)
        let missingTheme = makeTheme()

        XCTAssertTrue(manager.availableThemes.contains { $0.name == "Default Light" })
        XCTAssertTrue(manager.availableThemes.contains { $0.name == "Default Dark" })
        XCTAssertTrue(manager.register(theme: registeredTheme))
        XCTAssertNotEqual(registeredTheme, suppliedTheme)
        XCTAssertTrue(manager.switchTo(theme: suppliedTheme))
        XCTAssertEqual(manager.currentTheme, suppliedTheme)
        XCTAssertEqual(manager.availableThemes.last, registeredTheme)

        XCTAssertFalse(manager.switchToTheme(named: missingTheme.name))
        XCTAssertFalse(manager.switchTo(theme: missingTheme))
        XCTAssertEqual(manager.currentTheme, suppliedTheme)

        XCTAssertTrue(manager.switchToTheme(named: registeredTheme.name))
        XCTAssertEqual(manager.currentTheme, registeredTheme)
    }

    func testEnvironmentThemeUpdatesWithoutParentObservation() async {
        let manager = ThemeManager.shared
        let originalTheme = manager.currentTheme
        defer { manager.switchTo(theme: originalTheme) }
        let nextTheme = makeTheme()
        XCTAssertTrue(manager.register(theme: nextTheme))
        let observations = ThemeObservations()
        let initial = observations.expect(["theme": originalTheme], description: "Initial environment theme")

        // Neither this parent nor ThemeProbe observes the manager. Mount the root only once.
        let host = ThemeTestHost(rootView:
            ThemeProbe(key: "theme", observations: observations)
                .withThemeManager(manager)
        )
        defer { host.close() }
        await fulfillment(of: [initial], timeout: 3)

        let switched = observations.expect(["theme": nextTheme], description: "Updated environment theme")
        XCTAssertTrue(manager.switchToTheme(named: nextTheme.name))
        await fulfillment(of: [switched], timeout: 3)

        let restored = observations.expect(["theme": originalTheme], description: "Restored environment theme")
        XCTAssertTrue(manager.switchTo(theme: originalTheme))
        await fulfillment(of: [restored], timeout: 3)
    }

    func testNestedOverridesSurviveManagerChanges() async {
        let manager = ThemeManager.shared
        let originalTheme = manager.currentTheme
        defer { manager.switchTo(theme: originalTheme) }
        let nextTheme = makeTheme()
        let override = makeTheme()
        let outerTheme = makeTheme()
        XCTAssertTrue(manager.register(theme: nextTheme))
        let observations = ThemeObservations()
        let initial = observations.expect([
            "inherited": originalTheme,
            "override": override,
            "innerProvider": originalTheme,
            "innerOverride": override
        ], description: "Initial nested themes")
        let host = ThemeTestHost(rootView:
            VStack {
                ThemeProbe(key: "inherited", observations: observations)
                ThemeProbe(key: "override", observations: observations)
                    .applyTheme(override)
                ThemeProbe(key: "innerProvider", observations: observations)
                    .withThemeManager(manager)
                    .applyTheme(override)
                ThemeProbe(key: "innerOverride", observations: observations)
                    .applyTheme(override)
                    .withThemeManager(manager)
            }
            .withThemeManager(manager)
            .applyTheme(outerTheme)
        )
        defer { host.close() }
        await fulfillment(of: [initial], timeout: 3)

        let switched = observations.expect([
            "inherited": nextTheme,
            "override": override,
            "innerProvider": nextTheme,
            "innerOverride": override
        ], description: "Nested themes after switching")
        XCTAssertTrue(manager.switchToTheme(named: nextTheme.name))
        await fulfillment(of: [switched], timeout: 3)
        XCTAssertEqual(manager.currentTheme, nextTheme)
    }

    func testProviderSuppliesBothManagerEnvironmentAPIs() async {
        let manager = ThemeManager.shared
        let supplied = expectation(description: "Manager environment values")
        let host = ThemeTestHost(rootView:
            ThemeManagerAccessProbe { environmentManager, environmentObject in
                XCTAssertTrue(environmentManager === manager)
                XCTAssertTrue(environmentObject === manager)
                supplied.fulfill()
            }
            .withThemeManager(manager)
        )
        defer { host.close() }
        await fulfillment(of: [supplied], timeout: 3)
    }

    private func makeTheme(name: String = UUID().uuidString, primary: Color = .blue) -> ColorTheme {
        ColorTheme(
            name: name,
            primary: primary,
            secondary: .purple,
            accent: .green,
            background: .white,
            text: .black
        )
    }
}
