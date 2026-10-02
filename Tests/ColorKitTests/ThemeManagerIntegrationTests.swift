import Combine
import SwiftUI
import XCTest

import ColorKit

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

    func testSelectionOverloadsResolveToRegisteredTheme() throws {
        let manager = ThemeManager.shared
        let originalTheme = manager.currentTheme
        let originalRegistry = manager.availableThemes
        defer { manager.switchToTheme(named: originalTheme.name) }
        let lightTheme = try XCTUnwrap(originalRegistry.first { $0.name == "Default Light" })
        let darkTheme = try XCTUnwrap(originalRegistry.first { $0.name == "Default Dark" })
        let suppliedDarkTheme = makeTheme(name: darkTheme.name, primary: .red)

        XCTAssertNotEqual(suppliedDarkTheme, darkTheme)
        XCTAssertTrue(manager.switchToTheme(named: lightTheme.name))
        XCTAssertEqual(manager.currentTheme, lightTheme)
        XCTAssertTrue(manager.switchToTheme(named: darkTheme.name))
        XCTAssertEqual(manager.currentTheme, darkTheme)

        XCTAssertTrue(manager.switchToTheme(named: lightTheme.name))
        XCTAssertEqual(manager.currentTheme, lightTheme)
        XCTAssertTrue(manager.switchTo(theme: suppliedDarkTheme))
        XCTAssertEqual(manager.currentTheme, darkTheme)
        XCTAssertEqual(manager.availableThemes, originalRegistry)
    }

    func testSelectionOverloadsPreserveStateForUnregisteredTheme() {
        let manager = ThemeManager.shared
        let originalTheme = manager.currentTheme
        let originalRegistry = manager.availableThemes
        defer { manager.switchToTheme(named: originalTheme.name) }
        let missingTheme = makeTheme()

        XCTAssertFalse(manager.switchToTheme(named: missingTheme.name))
        XCTAssertEqual(manager.currentTheme, originalTheme)
        XCTAssertFalse(manager.switchTo(theme: missingTheme))
        XCTAssertEqual(manager.currentTheme, originalTheme)
        XCTAssertEqual(manager.availableThemes, originalRegistry)
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

    func testGlobalColorLookupIgnoresLocalOverrideAndRequiresFreshLookup() async throws {
        let manager = ThemeManager.shared
        let originalTheme = manager.currentTheme
        defer { manager.switchTo(theme: originalTheme) }
        let light = try XCTUnwrap(manager.availableThemes.first { $0.name == "Default Light" })
        let dark = try XCTUnwrap(manager.availableThemes.first { $0.name == "Default Dark" })
        let local = ColorTheme(
            name: UUID().uuidString,
            primary: .blue,
            secondary: .purple,
            accent: .green,
            background: .white,
            text: .red
        )
        XCTAssertTrue(manager.switchTo(theme: light))
        let saved = Color.themed(.text)
        let initial = expectation(description: "Local environment and global light lookup")
        let switched = expectation(description: "Local environment and fresh global dark lookup")
        var observedColors: [Color] = []
        let host = ThemeTestHost(rootView:
            GlobalThemeLookupProbe { environmentColor, globalColor in
                XCTAssertEqual(environmentColor, local.text.base)
                guard !observedColors.contains(globalColor) else { return }
                observedColors.append(globalColor)
                if globalColor == light.text.base {
                    initial.fulfill()
                } else if globalColor == dark.text.base {
                    switched.fulfill()
                } else {
                    XCTFail("Expected a shared-manager text color")
                }
            }
            .applyTheme(local)
            .withThemeManager(manager)
        )
        defer { host.close() }
        await fulfillment(of: [initial], timeout: 3)

        XCTAssertTrue(manager.switchTo(theme: dark))
        await fulfillment(of: [switched], timeout: 3)
        XCTAssertEqual(saved, light.text.base)
        XCTAssertEqual(Color.themed(.text), dark.text.base)
        XCTAssertFalse(manager.switchToTheme(named: local.name))
        XCTAssertEqual(manager.currentTheme, dark)
        XCTAssertEqual(Color.themed(.text), dark.text.base)
    }

    func testEveryColorRoleUsesItsVariantFromTheSelectedThemeSource() throws {
        guard #available(iOS 16.0, macOS 13.0, *) else {
            throw XCTSkip("ImageRenderer requires iOS 16 or macOS 13")
        }
        let manager = ThemeManager.shared
        let originalTheme = manager.currentTheme
        defer { manager.switchTo(theme: originalTheme) }
        let colors = (1...18).map { Color(.sRGB, red: Double($0) / 20, green: 0.25, blue: 0.5) }
        let localColors = Array(colors.reversed())
        let global = makeRoleTheme(colors: colors)
        let local = makeRoleTheme(colors: localColors)
        XCTAssertTrue(manager.register(theme: global))
        XCTAssertTrue(manager.switchTo(theme: global))

        let roles: [ThemeColorRole] = [
            .primary, .primaryLight, .primaryDark,
            .secondary, .secondaryLight, .secondaryDark,
            .accent, .accentLight, .accentDark,
            .background, .backgroundElevated, .backgroundLowered,
            .text, .textSecondary, .textTertiary,
            .success, .warning, .error
        ]
        for (index, role) in roles.enumerated() {
            XCTAssertEqual(Color.themed(role), colors[index], "Global role: \(role)")
            let actual = Rectangle()
                .themedColor(role)
                .applyTheme(local)
                .withThemeManager(manager)
            let expected = Rectangle().fill(localColors[index])
            XCTAssertEqual(
                try renderedPixel(of: actual),
                try renderedPixel(of: expected),
                "Local role: \(role)"
            )
        }
    }

    private func makeRoleTheme(colors: [Color]) -> ColorTheme {
        ColorTheme(
            name: UUID().uuidString,
            primary: ThemeColorSet(base: colors[0], light: colors[1], dark: colors[2]),
            secondary: ThemeColorSet(base: colors[3], light: colors[4], dark: colors[5]),
            accent: ThemeColorSet(base: colors[6], light: colors[7], dark: colors[8]),
            background: ThemeColorSet(base: colors[9], light: colors[10], dark: colors[11]),
            text: ThemeColorSet(base: colors[12], light: colors[13], dark: colors[14]),
            status: StatusColorSet(success: colors[15], warning: colors[16], error: colors[17])
        )
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

@MainActor
private struct GlobalThemeLookupProbe: View {
    let record: (Color, Color) -> Void
    @Environment(\.colorTheme)
    private var theme
    // Explicit observation triggers fresh lookups even while the local theme stays fixed.
    @ObservedObject private var manager = ThemeManager.shared

    var body: some View {
        Text(theme.name)
            .onAppear { record(theme.text.base, Color.themed(.text)) }
            .onChange(of: manager.currentTheme) { _ in
                record(theme.text.base, Color.themed(.text))
            }
    }
}
