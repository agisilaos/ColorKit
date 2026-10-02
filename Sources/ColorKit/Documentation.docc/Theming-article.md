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

For SwiftUI styling that follows theme switches and local overrides, use the
view's `colorTheme` environment. Supply the manager's selection at the root with
`withThemeManager(_:)`, then use theme modifiers or read the environment in a
descendant view.

| Expression | Theme source | After a manager switch |
| --- | --- | --- |
| `.themedColor`, `.themedText`, `.themedButton`, `.themedBackground` | The view's `colorTheme` environment | Follows the managed theme unless a nearer local override applies |
| `@Environment(\.colorTheme)` and `theme.accent.base` | The reading view's environment | Same as the modifiers |
| `Color.themed(.accent)` | `ThemeManager.shared.currentTheme` when called | A new call reads the new selection; an already returned color keeps its selected value |

`Color.themed(_:)` does not read the environment and does not establish observation.
Use it when you explicitly want a color from the shared manager. Adding
`.applyTheme(...)` around a view does not change that lookup.

#### Global selection and a local override

This example uses the existing default themes for the app-wide selection and
Ocean for one subtree. The local theme does not need registration.

<!-- swift-example: theme-selection -->
```swift
import SwiftUI
import ColorKit

@MainActor
struct ThemeSelectionExample: View {
    @State private var selectionMessage = ""
    private let oceanTheme = ColorTheme(
        name: "Ocean",
        primary: .blue,
        secondary: .purple,
        accent: Color(red: 0, green: 0.45, blue: 0.5),
        background: .white,
        text: Color(red: 0.1, green: 0.15, blue: 0.3)
    )

    var body: some View {
        VStack {
            ThemeSample()
            ThemeSample()
                .applyTheme(oceanTheme)

            Button("Select Default Light") { select("Default Light") }
            Button("Select Default Dark") { select("Default Dark") }
            Text(selectionMessage)
        }
        .withThemeManager(ThemeManager.shared)
    }

    private func select(_ name: String) {
        if ThemeManager.shared.switchToTheme(named: name) {
            selectionMessage = "Selected \(name)"
        } else {
            selectionMessage = "Theme not registered; selection unchanged."
        }
    }
}

struct ThemeSample: View {
    @Environment(\.colorTheme) private var theme

    var body: some View {
        VStack {
            Text(theme.name).themedText(.primary)
            Text("Accent foreground").themedColor(.accent)
            Rectangle()
                .fill(theme.accent.base)
                .frame(width: 80, height: 20)
                .accessibilityLabel("Theme accent")
        }
        .themedBackground(.base)
    }
}
```

1. Select **Default Light**: the first sample reads Default Light; the second
   reads Ocean. `Color.themed(.text)` called at this point returns Default Light's
   text color, even from inside the Ocean subtree.
2. Select **Default Dark**: the first sample updates to Default Dark; the second
   keeps Ocean. A new `Color.themed(.text)` call returns Default Dark's text color.
3. Select an unregistered name: `switchToTheme(named:)` returns `false` and the
   selection stays unchanged. Registration alone does not select a theme.

The nearest provider to an environment-reading descendant wins. Read
`@Environment(\.colorTheme)` in a child such as `ThemeSample`: a modifier on a
view's returned content does not change the environment read by that enclosing
view itself. Without a provider, `colorTheme` uses an independent default theme;
it does not follow the shared manager automatically.

`withThemeManager(_:)` observes the supplied manager, so the enclosing view does
not need to observe it. The modifier also supplies the manager through
`@Environment(\.themeManager)` and `@EnvironmentObject`. Reading that manager's
`currentTheme` still gives the manager's selection, even within a local override.

#### Reading the shared manager directly

Use a fresh call for a fresh selection. This main-actor example temporarily
changes the shared selection and restores it when the function returns:

<!-- swift-example: global-theme-lookup -->
```swift
import SwiftUI
import ColorKit

@MainActor
func compareGlobalSelections() -> (saved: Color, fresh: Color) {
    let manager = ThemeManager.shared
    let originalTheme = manager.currentTheme
    defer { manager.switchTo(theme: originalTheme) }

    manager.switchToTheme(named: "Default Light")
    let saved = Color.themed(.text)

    manager.switchToTheme(named: "Default Dark")
    let fresh = Color.themed(.text)
    // saved still comes from Default Light; fresh comes from Default Dark.
    return (saved, fresh)
}

let colors = compareGlobalSelections()
```

A stored result does not track future manager selections. Calling `Color.themed`
inside `body` also does not make the view observe the manager. For reactive view
styling, use the environment path above; for a view deliberately tied to the
shared selection, explicitly observe the manager with `@ObservedObject` and read
its `currentTheme`.

A returned color can still be appearance-dependent; it simply does not reselect
its theme.

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

Choose light and dark colors explicitly with the adaptive view modifier. Theme
color sets provide variants; they do not automatically select a system appearance.

<!-- swift-example: dynamic-theme -->
```swift
let primary = ThemeColorSet(
    base: Color(.sRGB, red: 0.08, green: 0.4, blue: 0.75),
    light: Color(.sRGB, red: 0.56, green: 0.79, blue: 0.98),
    dark: Color(.sRGB, red: 0.05, green: 0.28, blue: 0.63)
)

Text("Adaptive text")
    .adaptiveColor(light: primary.dark, dark: primary.light)

// Observe the manager's published selection from a view
Text("Current theme")
    .onReceive(ThemeManager.shared.$currentTheme) { theme in
        print("Theme changed to: \(theme.name)")
    }
```

## Interface Overview

### Theme Management
- ``ColorTheme``
- ``ThemeManager``
- `View.withThemeManager(_:)`
- `View.applyTheme(_:)`
- `EnvironmentValues.colorTheme`

### Theme Components
- `View.themedText(_:)`
- `View.themedButton(_:)`
- `View.themedBackground(_:)`

### Theme Colors
- `View.themedColor(_:)` — environment-based foreground styling
- `Color.themed(_:)` — shared-manager lookup
- ``ThemedTextModifier``
- ``ThemedButtonModifier``
- ``ThemedBackgroundModifier``

### Theme Customization
- ``ColorTheme/init(name:primary:secondary:accent:background:text:status:)``
- ``ThemeManager/register(theme:)``
- ``ThemeManager/currentTheme``
