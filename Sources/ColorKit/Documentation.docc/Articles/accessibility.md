# Accessibility in ColorKit

Learn how to create accessible color combinations and ensure WCAG compliance with ColorKit.

## Overview

Accessibility is a crucial aspect of modern app design. ColorKit provides comprehensive tools to ensure your color choices meet Web Content Accessibility Guidelines (WCAG) requirements, helping you create interfaces that are accessible to users with visual impairments.

## Understanding WCAG Contrast Requirements

WCAG defines minimum contrast ratios between text and background colors:

- **Level AA** requires a contrast ratio of at least 4.5:1 for normal text and 3:1 for large text
- **Level AAA** requires a contrast ratio of at least 7:1 for normal text and 4.5:1 for large text

ColorKit makes it easy to check and enforce these requirements.

## Checking Contrast Ratios

```swift
// Calculate the contrast ratio between two colors
let backgroundColor = Color.purple
let textColor = Color.white
let ratio = backgroundColor.contrastRatio(with: textColor)
// ratio ≈ 8.16

// Check if colors meet specific WCAG level requirements
let isAACompliant = backgroundColor.meetsContrastRequirements(with: textColor, level: .AA)
// true

let isAAACompliant = backgroundColor.meetsContrastRequirements(with: textColor, level: .AAA)
// true

// For large text (18pt bold or 24pt regular)
let isLargeTextAACompliant = backgroundColor.meetsContrastRequirements(
    with: textColor, 
    level: .AA, 
    isLargeText: true
)
// true
```

## Generating Accessible Colors

ColorKit can automatically generate colors that meet accessibility requirements:

```swift
// Generate an accessible color from a background color
let background = Color.indigo
let accessibleText = background.accessibleContrastingColor(targetLevel: .AA)

// Generate a color that maintains brand identity but meets contrast requirements
let brandColor = Color.blue
let accessibleBrandColor = brandColor.enhanced(
    with: .white,
    targetLevel: .AA
)

// Create a SwiftUI modifier that ensures text has sufficient contrast
Text("Accessible Text")
    .highContrastColor(base: .blue, background: .white)
```

## Creating Accessible Palettes

ColorKit can generate entire palettes of accessible colors:

```swift
// Generate an accessible palette from a seed color
let seedColor = Color.blue
let palette = seedColor.generateAccessiblePalette(
    targetLevel: .AA,      // WCAG compliance level
    paletteSize: 5,        // Number of colors to generate
    includeBlackAndWhite: true
)

// Use these colors in your UI
ForEach(0..<palette.count, id: \.self) { index in
    Rectangle()
        .fill(palette[index])
        .frame(height: 50)
}
```

## Creating Accessible Themes

Build entire themes that ensure accessibility throughout your app:

```swift
// Generate an accessible theme from a seed color
let seedColor = Color.indigo
let theme = seedColor.generateAccessibleTheme(
    name: "Accessible Indigo",
    targetLevel: .AA
)

// Register the theme
ThemeManager.shared.register(theme: theme)

// Apply theme to your app
ContentView()
    .withThemeManager()

// Use themed colors that are guaranteed to be accessible
Text("Primary Text")
    .foregroundColor(Color.themed(.text))
    .background(Color.themed(.background))
```

## Using the AccessibilityEnhancer

The `AccessibilityEnhancer` helps adjust colors to meet accessibility requirements while preserving brand identity:

```swift
// Enhance a color to meet accessibility requirements
let originalColor = Color.blue
let backgroundColor = Color.white
let targetLevel = WCAGContrastLevel.AA

// Simple enhancement with default settings (preserves hue)
let enhancedColor = originalColor.enhanced(with: backgroundColor)

// Custom enhancement with specific settings
let customEnhanced = originalColor.enhanced(
    with: backgroundColor,
    targetLevel: .AAA,
    preserveHue: true,
    maxLightnessShift: 0.3,
    maxSaturationShift: 0.2
)
```

## Interactive Accessibility Tools

ColorKit provides interactive tools to explore and test accessibility:

```swift
// Use the accessibility lab demo view
struct AccessibilityDemoView: View {
    var body: some View {
        ColorKit.WCAG.demoView()
    }
}

// Use the more comprehensive accessibility lab
struct ComprehensiveLabView: View {
    var body: some View {
        AccessibilityLabPreview()
    }
}
```

## WCAG Compliance Reports

Generate reports about the accessibility of your color combinations:

```swift
// Get a detailed WCAG compliance report
let background = Color.indigo
let foreground = Color.white
let report = background.wcagCompliance(with: foreground)

// Output report details
Text("Contrast Ratio: \(report.contrastRatio, specifier: "%.2f")")
Text("AA Compliant: \(report.passesAA ? "Yes" : "No")")
Text("AAA Compliant: \(report.passesAAA ? "Yes" : "No")")
Text("AA Large Text: \(report.passesAALargeText ? "Yes" : "No")")
Text("AAA Large Text: \(report.passesAAALargeText ? "Yes" : "No")")
``` 