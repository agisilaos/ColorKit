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

// Register the theme from main-actor code
ThemeManager.shared.register(theme: oceanTheme)
```

### Applying Themes

Apply themes to your views using modifiers:

```swift
// Apply theme to view hierarchy
ContentView()
    .withThemeManager(ThemeManager.shared)

// Use themed colors in views
Text("Themed Text")
    .themedText(.primary)

Button("Primary Button") {}
    .themedButton(.primary)

Rectangle()
    .fill(Color.themed(.accent))
```

`withThemeManager(_:)` observes the supplied manager. Views that read
`@Environment(\.colorTheme)` receive later selections even when the enclosing
view does not observe the manager. The modifier also supplies the manager through
`@Environment(\.themeManager)` and `@EnvironmentObject`.

Apply a local override inside the managed hierarchy to keep that subtree's theme
independent of the manager's selection:

```swift
VStack {
    ContentView()
    PreviewView()
        .applyTheme(oceanTheme)
}
.withThemeManager(ThemeManager.shared)
```

The nearest theme provider to a descendant wins. The preview keeps `oceanTheme`
when the manager switches, and the override does not change the manager itself.

### Actor Isolation and Observation

`ThemeManager` and `withThemeManager(_:)` are isolated to `MainActor`. Access the
manager's state and call its methods from main-actor code; asynchronous callers
on another actor must use `await`. Synchronous helpers that access the manager
should also be marked `@MainActor`.

```swift
@MainActor
func selectTheme(_ theme: ColorTheme) {
    ThemeManager.shared.register(theme: theme)
    ThemeManager.shared.switchTo(theme: theme)
}

func selectFromAnotherActor(name: String, manager: ThemeManager) async -> Bool {
    await manager.switchToTheme(named: name)
}
```

The manager remains an `ObservableObject`. Both `currentTheme` and
`availableThemes` are published, so theme pickers update after successful
registration even when the selection stays unchanged. Rejected duplicate names
do not publish a registry change. iOS 14 and macOS 12 remain supported.

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

## Interface Overview

### Theme Management
- ``ColorTheme``
- ``ThemeManager``
- `View.withThemeManager(_:)`

### Theme Components
- `View.themedText(_:)`
- `View.themedButton(_:)`
- `View.themedBackground(_:)`

### Theme Colors
- `Color.themed(_:)`
- ``ThemedTextModifier``
- ``ThemedButtonModifier``
- ``ThemedBackgroundModifier``

### Theme Customization
- ``ColorTheme/init(name:primary:secondary:accent:background:text:status:)``
- ``ThemeManager/register(theme:)``
- ``ThemeManager/currentTheme``
