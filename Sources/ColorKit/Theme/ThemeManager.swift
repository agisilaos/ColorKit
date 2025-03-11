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

import SwiftUI
import Combine

/// Manages themes and provides the current theme to the application
@available(iOS 14.0, macOS 11.0, *)
public class ThemeManager: ObservableObject, @unchecked Sendable {
    /// The shared instance for app-wide theme management
    @MainActor public static let shared = ThemeManager()
    
    /// The currently active theme
    @Published public private(set) var currentTheme: ColorTheme
    
    /// All available themes
    public private(set) var availableThemes: [ColorTheme] = []
    
    /// Creates a new theme manager with default themes
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
    
    /// Registers a new theme
    /// - Parameter theme: The theme to register
    /// - Returns: True if the theme was added, false if a theme with the same name already exists
    @discardableResult
    public func register(theme: ColorTheme) -> Bool {
        // Check if a theme with this name already exists
        if availableThemes.contains(where: { $0.name == theme.name }) {
            return false
        }
        
        availableThemes.append(theme)
        return true
    }
    
    /// Switches to a theme by name
    /// - Parameter name: The name of the theme to switch to
    /// - Returns: True if the theme was found and applied, false otherwise
    @discardableResult
    public func switchToTheme(named name: String) -> Bool {
        guard let theme = availableThemes.first(where: { $0.name == name }) else {
            return false
        }
        
        currentTheme = theme
        return true
    }
    
    /// Switches to a specific theme
    /// - Parameter theme: The theme to switch to
    /// - Returns: True if the theme was found and applied, false otherwise
    @discardableResult
    public func switchTo(theme: ColorTheme) -> Bool {
        guard availableThemes.contains(where: { $0.name == theme.name }) else {
            return false
        }
        
        currentTheme = theme
        return true
    }
} 