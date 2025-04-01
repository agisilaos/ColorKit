//
//  ThemeManager.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 11.03.25.
//
//  Description:
//  Manages themes and provides the current theme to the application.
//
//  Features:
//  - Singleton manager for app-wide theme management
//  - Supports registering and switching between multiple themes
//  - Observable object for SwiftUI integration
//
//  License:
//  MIT License. See LICENSE file for details.
//

import Combine
import SwiftUI

/// Manages themes and provides the current theme to the application.
///
/// `ThemeManager` is a singleton class that handles theme management across your
/// application. It provides functionality for:
/// - Registering new themes
/// - Switching between themes
/// - Maintaining a list of available themes
/// - Providing the current theme to SwiftUI views
///
/// The manager is designed to work seamlessly with SwiftUI's environment system
/// and supports dynamic theme switching.
///
/// Example usage:
/// ```swift
/// // Access the shared instance
/// let manager = ThemeManager.shared
///
/// // Register a custom theme
/// let customTheme = ColorTheme(
///     name: "Custom",
///     primary: .blue,
///     secondary: .gray,
///     accent: .purple,
///     background: .white,
///     text: .black
/// )
/// manager.register(theme: customTheme)
///
/// // Switch themes
/// manager.switchToTheme(named: "Custom")
///
/// // Use in SwiftUI
/// struct ThemedView: View {
///     @ObservedObject var themeManager = ThemeManager.shared
///
///     var body: some View {
///         Text("Themed Text")
///             .foregroundColor(themeManager.currentTheme.text.base)
///             .background(themeManager.currentTheme.background.base)
///     }
/// }
/// ```
public class ThemeManager: ObservableObject, @unchecked Sendable {
    /// The shared instance for app-wide theme management.
    ///
    /// This singleton instance should be used throughout your application to
    /// ensure consistent theme management. It's marked as `@MainActor` to
    /// ensure thread-safe access to theme state.
    ///
    /// Example:
    /// ```swift
    /// let manager = ThemeManager.shared
    /// print("Current theme: \(manager.currentTheme.name)")
    /// ```
    @MainActor public static let shared = ThemeManager()

    /// The currently active theme.
    ///
    /// This property is marked with `@Published` to enable automatic SwiftUI
    /// view updates when the theme changes. Observe this property to react
    /// to theme changes in your views.
    ///
    /// Example:
    /// ```swift
    /// struct ThemeAwareView: View {
    ///     @ObservedObject var themeManager = ThemeManager.shared
    ///
    ///     var body: some View {
    ///         Text("Current theme: \(themeManager.currentTheme.name)")
    ///     }
    /// }
    /// ```
    @Published public private(set) var currentTheme: ColorTheme

    /// All available themes registered with the manager.
    ///
    /// This array contains all themes that can be switched to. The default
    /// implementation includes a light and dark theme, but you can register
    /// additional themes as needed.
    ///
    /// Example:
    /// ```swift
    /// let manager = ThemeManager.shared
    /// for theme in manager.availableThemes {
    ///     print("Available theme: \(theme.name)")
    /// }
    /// ```
    public private(set) var availableThemes: [ColorTheme] = []

    /// Creates a new theme manager with default themes.
    ///
    /// This initializer sets up the manager with two default themes:
    /// - A light theme with white background and dark text
    /// - A dark theme with black background and light text
    ///
    /// Both themes use blue as the primary color and purple as the accent color.
    private init() {
        // Create default light theme
        let lightTheme = ColorTheme(
            name: "Default Light",
            primary: Color.blue,
            secondary: Color.purple.opacity(0.8),
            accent: Color.purple,
            background: Color.white,
            text: Color.black
        )

        // Create default dark theme
        let darkTheme = ColorTheme(
            name: "Default Dark",
            primary: Color.blue,
            secondary: Color.purple.opacity(0.8),
            accent: Color.purple,
            background: Color.black,
            text: Color.white
        )

        self.availableThemes = [lightTheme, darkTheme]
        self.currentTheme = lightTheme
    }

    /// Registers a new theme with the manager.
    ///
    /// This method adds a new theme to the available themes list. If a theme
    /// with the same name already exists, the registration will fail.
    ///
    /// Example:
    /// ```swift
    /// let customTheme = ColorTheme(
    ///     name: "Custom",
    ///     primary: .blue,
    ///     secondary: .gray,
    ///     accent: .purple,
    ///     background: .white,
    ///     text: .black
    /// )
    ///
    /// if manager.register(theme: customTheme) {
    ///     print("Theme registered successfully")
    /// } else {
    ///     print("Theme with this name already exists")
    /// }
    /// ```
    ///
    /// - Parameter theme: The theme to register
    /// - Returns: `true` if the theme was added successfully, `false` if a theme
    ///           with the same name already exists
    @discardableResult
    public func register(theme: ColorTheme) -> Bool {
        // Check if a theme with this name already exists
        if availableThemes.contains(where: { $0.name == theme.name }) {
            return false
        }

        availableThemes.append(theme)
        return true
    }

    /// Switches to a theme by its name.
    ///
    /// This method attempts to find and activate a theme with the specified name.
    /// If no matching theme is found, the current theme remains unchanged.
    ///
    /// Example:
    /// ```swift
    /// // Switch to a specific theme
    /// if manager.switchToTheme(named: "Dark Mode") {
    ///     print("Theme switched successfully")
    /// } else {
    ///     print("Theme not found")
    /// }
    ///
    /// // Switch between light and dark themes
    /// let isDarkMode = true
    /// manager.switchToTheme(named: isDarkMode ? "Default Dark" : "Default Light")
    /// ```
    ///
    /// - Parameter name: The name of the theme to switch to
    /// - Returns: `true` if the theme was found and applied, `false` otherwise
    @discardableResult
    public func switchToTheme(named name: String) -> Bool {
        guard let theme = availableThemes.first(where: { $0.name == name }) else {
            return false
        }

        currentTheme = theme
        return true
    }

    /// Switches to a specific theme instance.
    ///
    /// This method attempts to activate the provided theme. The theme must be
    /// registered with the manager for the switch to succeed.
    ///
    /// Example:
    /// ```swift
    /// let theme = ColorTheme(
    ///     name: "Custom",
    ///     primary: .blue,
    ///     secondary: .gray,
    ///     accent: .purple,
    ///     background: .white,
    ///     text: .black
    /// )
    ///
    /// // Register and switch to the theme
    /// manager.register(theme: theme)
    /// if manager.switchTo(theme: theme) {
    ///     print("Theme activated")
    /// }
    /// ```
    ///
    /// - Parameter theme: The theme to switch to
    /// - Returns: `true` if the theme was found and applied, `false` otherwise
    @discardableResult
    public func switchTo(theme: ColorTheme) -> Bool {
        guard availableThemes.contains(where: { $0.name == theme.name }) else {
            return false
        }

        currentTheme = theme
        return true
    }
}
