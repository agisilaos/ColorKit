# Getting Started with ColorKit

Learn the basics of ColorKit and how to integrate it into your SwiftUI project.

## Overview

ColorKit is a Swift package that provides a comprehensive set of color utilities for SwiftUI apps. This guide will help you get started with installing the package and using its basic features.

## Installation

ColorKit supports Swift Package Manager (SPM).

1. Open your Xcode project.
2. Go to **File > Add Packages**.
3. Enter the URL:
   ```
   https://github.com/agisilaos/ColorKit.git
   ```
4. Click **Add Package**.

## Basic Usage

Once you've installed ColorKit, you can start using its features in your SwiftUI project.

### Color Creation and Conversion

```swift
import SwiftUI
import ColorKit

// Create a color from a HEX string
let redColor = Color(hex: "#FF0000")

// Get the HEX value of a color
let hexString = Color.blue.hexValue() // "#0000FFFF"

// Work with HSL color space
let hslComponents = Color.purple.hslComponents()
// (hue: 0.75, saturation: 1.0, lightness: 0.5)

// Create a color from HSL values
let customColor = Color(hue: 0.3, saturation: 0.8, lightness: 0.5)

// Work with CMYK color space
let cmykComponents = Color.green.cmykComponents()
// (cyan: 1.0, magenta: 0.0, yellow: 1.0, key: 0.0)

// Work with LAB color space
let labComponents = Color.red.labComponents()
// (L: 53.24, a: 80.09, b: 67.20)
```

### Adaptive Colors for Light and Dark Mode

```swift
Text("Adaptive Text")
    .adaptiveColor(light: .blue, dark: .orange)

Button("Action") {
    // Button action
}
.padding()
.background(
    Color.adaptive(light: .green, dark: .mint)
)
.foregroundColor(
    Color.adaptive(light: .black, dark: .white)
)
```

### Basic Accessibility Compliance

```swift
// Check if a color combination meets WCAG standards
let backgroundColor = Color.purple
let textColor = Color.white
let ratio = backgroundColor.contrastRatio(with: textColor)
let isAACompliant = backgroundColor.meetsContrastRequirements(with: textColor, level: .AA)

// Generate an accessible color for text
let accessibleTextColor = backgroundColor.accessibleContrastingColor()

// Create a Text view with guaranteed contrast
Text("Accessible Text")
    .highContrastColor(base: .blue, background: .white)
```

## Next Steps

Now that you have the basics of ColorKit, you can explore more advanced features:

- Learn about <doc:color-spaces> for in-depth color manipulation
- Discover how to create accessible designs with <doc:accessibility>
- Build a comprehensive theming system with <doc:theming>
- Follow the <doc:ColorBasics> tutorial for a hands-on approach 