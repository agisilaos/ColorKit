# Theming with ColorKit

Learn how to implement a comprehensive theming system in your SwiftUI app using ColorKit.

## Overview

ColorKit provides a powerful theming system that allows you to define, manage, and apply consistent color themes throughout your SwiftUI application. This article explains how to create and use themes effectively.

## Creating Themes

A theme in ColorKit is defined using the `ColorTheme` struct, which contains semantic color definitions:

```swift
// Define a custom theme
let oceanTheme = ColorTheme(
    name: "Ocean",
    primary: Color(hex: "#1E88E5"),    // Primary brand color
    secondary: Color(hex: "#00ACC1"),   // Secondary color
    accent: Color(hex: "#7E57C2"),      // Accent for highlights
    background: Color(hex: "#ECEFF1"),  // Main background
    text: Color(hex: "#263238")         // Primary text color
)
```

You can also create extended themes with additional color properties:

```swift
// Create a theme with extended properties
let extendedTheme = ColorTheme(
    name: "Extended Ocean",
    primary: Color(hex: "#1E88E5"),
    secondary: Color(hex: "#00ACC1"),
    accent: Color(hex: "#7E57C2"),
    background: Color(hex: "#ECEFF1"),
    text: Color(hex: "#263238"),
    
    // Extended colors
    success: Color(hex: "#4CAF50"),
    warning: Color(hex: "#FFC107"),
    error: Color(hex: "#F44336"),
    info: Color(hex: "#2196F3"),
    surface: Color(hex: "#FFFFFF"),
    onSurface: Color(hex: "#1C1C1C"),
    
    // Custom colors
    customColors: [
        "headerBackground": Color(hex: "#E1F5FE"),
        "cardBorder": Color(hex: "#BBDEFB"),
        "tabBar": Color(hex: "#0D47A1")
    ]
)
```

## Managing Themes

ColorKit's `ThemeManager` handles theme registration and switching:

```swift
// Register themes with the ThemeManager
ThemeManager.shared.register(theme: oceanTheme)
ThemeManager.shared.register(theme: extendedTheme)

// Set the active theme
ThemeManager.shared.setActiveTheme("Ocean")

// Get the current theme
let currentTheme = ThemeManager.shared.currentTheme

// Check if a theme exists
let exists = ThemeManager.shared.themeExists("Ocean") // true

// Get a list of all available themes
let themes = ThemeManager.shared.availableThemes
```

## Applying Themes to Your App

To use themes in your SwiftUI app, first apply the theme manager to your root view:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withThemeManager() // Enables theme support
        }
    }
}
```

## Using Themed Colors

ColorKit provides multiple ways to access theme colors:

```swift
// 1. Using the Color.themed extension
Text("Themed Text")
    .foregroundColor(Color.themed(.text))
    .background(Color.themed(.background))

// 2. Using modifiers for common components
Text("Primary Button Text")
    .themedText(.primary)

Button("Secondary Button") {}
    .themedButton(.secondary)

// 3. Using theme-aware View extensions
Rectangle()
    .fill(Color.themed(.accent))
    .themedCard() // Applies card styling based on theme

// 4. Custom theme colors
Rectangle()
    .fill(Color.themedCustom("cardBorder"))
```

## Creating Adaptive Themes

ColorKit supports automatic light/dark mode adaptation with themed colors:

```swift
// Create light and dark variants of a theme
let lightOceanTheme = ColorTheme(
    name: "Ocean-Light",
    primary: Color(hex: "#1E88E5"),
    secondary: Color(hex: "#00ACC1"),
    accent: Color(hex: "#7E57C2"),
    background: Color(hex: "#ECEFF1"),
    text: Color(hex: "#263238")
)

let darkOceanTheme = ColorTheme(
    name: "Ocean-Dark",
    primary: Color(hex: "#1976D2"),
    secondary: Color(hex: "#0097A7"),
    accent: Color(hex: "#673AB7"),
    background: Color(hex: "#102027"),
    text: Color(hex: "#ECEFF1")
)

// Create adaptive theme pair
ThemeManager.shared.createAdaptivePair(
    lightTheme: "Ocean-Light",
    darkTheme: "Ocean-Dark",
    pairName: "Ocean"
)

// Apply the adaptive pair - will switch automatically based on system appearance
ThemeManager.shared.setActiveTheme("Ocean")
```

## Responding to Theme Changes

Listen for theme changes to update UI elements:

```swift
struct ThemeAwareView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack {
            Text("Current theme: \(themeManager.currentTheme.name)")
            
            Button("Switch Theme") {
                // Switch between themes
                if themeManager.currentTheme.name == "Ocean" {
                    themeManager.setActiveTheme("Extended Ocean")
                } else {
                    themeManager.setActiveTheme("Ocean")
                }
            }
            .padding()
            .background(Color.themed(.primary))
            .foregroundColor(Color.themed(.background))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.themed(.background))
        .foregroundColor(Color.themed(.text))
    }
}
```

## Generating Accessible Themes

Create themes that comply with WCAG accessibility guidelines:

```swift
// Generate an accessible theme from a seed color
let seedColor = Color.blue
let accessibleTheme = seedColor.generateAccessibleTheme(
    name: "Accessible Blue",
    targetLevel: .AA
)

// Register and use the accessible theme
ThemeManager.shared.register(theme: accessibleTheme)
ThemeManager.shared.setActiveTheme("Accessible Blue")
```

## Theme Persistence

Save and restore user theme preferences:

```swift
// Save current theme preference
ThemeManager.shared.saveThemePreference()

// Restore theme preference (e.g., on app startup)
ThemeManager.shared.restoreThemePreference()
```

## Interactive Theme Preview

Experiment with themes using the interactive preview:

```swift
struct ThemeDemoView: View {
    var body: some View {
        ThemePreview()
    }
}
``` 