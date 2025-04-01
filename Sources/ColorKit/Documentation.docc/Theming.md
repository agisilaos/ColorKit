# Theming

Learn how to use ColorKit's comprehensive theming system to create consistent and dynamic color schemes.

## Overview

ColorKit's theming system allows you to create, manage, and apply consistent color schemes across your app. The system supports dynamic themes that can adapt to light/dark mode and accessibility requirements.

### Creating Themes

Create custom themes by defining your color palette:

```swift
// Create a custom theme
let oceanTheme = ColorTheme(
    name: "Ocean",
    primary: Color(hex: "#1E88E5"),
    secondary: Color(hex: "#00ACC1"),
    accent: Color(hex: "#7E57C2"),
    background: Color(hex: "#ECEFF1"),
    text: Color(hex: "#263238")
)

// Register the theme
ThemeManager.shared.register(theme: oceanTheme)
```

### Applying Themes

Apply themes to your views using modifiers:

```swift
// Apply theme to view hierarchy
ContentView()
    .withThemeManager()

// Use themed colors in views
Text("Themed Text")
    .themedText(.primary)

Button("Primary Button") {}
    .themedButton(.primary)

Rectangle()
    .fill(Color.themed(.accent))
```

### Theme Components

Use semantic colors and components:

```swift
// Text styles
Text("Primary Text").themedText(.primary)
Text("Secondary Text").themedText(.secondary)
Text("Tertiary Text").themedText(.tertiary)

// Button styles
Button("Primary Action") {}.themedButton(.primary)
Button("Secondary Action") {}.themedButton(.secondary)
Button("Accent Action") {}.themedButton(.accent)

// Background styles
VStack {
    Text("Content")
}
.themedBackground(.base)

Card()
    .themedBackground(.elevated)

Footer()
    .themedBackground(.lowered)
```

### Dynamic Themes

Create themes that adapt to system settings:

```swift
// Create an adaptive theme
let adaptiveTheme = ColorTheme(
    name: "Adaptive",
    primary: Color.adaptive(light: .blue, dark: .lightBlue),
    secondary: Color.adaptive(light: .green, dark: .lightGreen),
    accent: Color.adaptive(light: .purple, dark: .lightPurple),
    background: Color.adaptive(light: .white, dark: .black),
    text: Color.adaptive(light: .black, dark: .white)
)

// Listen for theme changes
.onThemeChange { theme in
    print("Theme changed to: \(theme.name)")
}
```

## Topics

### Theme Management
- ``ColorTheme``
- ``ThemeManager``
- ``View/withThemeManager()``

### Theme Components
- ``View/themedText(_:)``
- ``View/themedButton(_:)``
- ``View/themedBackground(_:)``

### Theme Colors
- ``Color/themed(_:)``
- ``ThemedTextModifier``
- ``ThemedButtonModifier``
- ``ThemedBackgroundModifier``

### Theme Customization
- ``ColorTheme/init(name:primary:secondary:accent:background:text:)``
- ``ThemeManager/register(theme:)``
- ``ThemeManager/currentTheme``