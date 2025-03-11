//
//  ThemeEnvironment.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 11.03.25.
//
//  Description:
//  Integrates the theming system with SwiftUI's environment.
//
//  Features:
//  - Adds theme to SwiftUI environment
//  - Provides view modifiers for applying themes
//  - Enables dynamic theme switching
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

@available(iOS 14.0, macOS 11.0, *)
private struct ThemeKey: EnvironmentKey {
    // Using a default theme instead of accessing ThemeManager directly
    static let defaultValue: ColorTheme = ColorTheme(
        name: "Default",
        primary: Color.blue,
        secondary: Color.purple.opacity(0.8),
        accent: Color.purple,
        background: Color.white,
        text: Color.black
    )
}

@available(iOS 14.0, macOS 11.0, *)
private struct ThemeManagerKey: EnvironmentKey {
    // This will be set explicitly by the withThemeManager modifier
    static let defaultValue: ThemeManager? = nil
}

// Extension to add theme to the environment
@available(iOS 14.0, macOS 11.0, *)
public extension EnvironmentValues {
    /// The current color theme
    var colorTheme: ColorTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
    
    /// The theme manager
    var themeManager: ThemeManager? {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// View extension for applying themes
@available(iOS 14.0, macOS 11.0, *)
public extension View {
    /// Applies a specific color theme to this view and its descendants
    /// - Parameter theme: The theme to apply
    /// - Returns: A view with the theme applied
    func applyTheme(_ theme: ColorTheme) -> some View {
        environment(\.colorTheme, theme)
    }
    
    /// Uses the theme manager to dynamically update the theme
    /// - Parameter manager: The theme manager to use
    /// - Returns: A view that updates when the theme changes
    func withThemeManager(_ manager: ThemeManager) -> some View {
        environmentObject(manager)
            .environment(\.colorTheme, manager.currentTheme)
            .environment(\.themeManager, manager)
    }
} 