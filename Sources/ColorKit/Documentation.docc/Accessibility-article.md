# Accessibility

Learn how to create accessible color combinations and ensure your app meets WCAG guidelines.

## Overview

ColorKit provides comprehensive tools for ensuring your app's colors meet accessibility standards, particularly the Web Content Accessibility Guidelines (WCAG).

### Contrast Checking

Check if your color combinations meet WCAG contrast requirements:

```swift
let backgroundColor = Color.white
let textColor = Color.gray

// Check contrast ratio
if let ratio = backgroundColor.contrastRatio(with: textColor) {
    print("Contrast ratio: \(ratio)")
}

// Check WCAG compliance
let compliance = backgroundColor.wcagCompliance(with: textColor)
print("AA Large Text: \(compliance.passesAA(isLargeText: true))")
print("AA Normal Text: \(compliance.passesAA(isLargeText: false))")
print("AAA Large Text: \(compliance.passesAAA(isLargeText: true))")
print("AAA Normal Text: \(compliance.passesAAA(isLargeText: false))")
```

### Accessible Color Generation

Generate accessible color variations that maintain your brand identity:

```swift
// Find an accessible color that meets AA standards
let enhancedColor = textColor.enhanced(
    with: backgroundColor,
    targetLevel: .AA
)

// Generate an accessible color palette
let palette = seedColor.generateAccessiblePalette(
    targetLevel: .AA,
    paletteSize: 5,
    includeBlackAndWhite: true
)

// Create an accessible theme
let theme = seedColor.generateAccessibleTheme(
    name: "Accessible Theme",
    targetLevel: .AA
)
```

### Adaptive Colors

Create colors that adapt to light and dark mode:

```swift
Text("Adaptive Text")
    .adaptiveColor(light: .blue, dark: .orange)

Button("High Contrast Button") {
    // Action
}
.highContrastColor(base: .gray, background: .white)

// Listen for color scheme changes
Text("Dynamic Text")
    .onAdaptiveColorChange { newScheme in
        print("Color scheme changed to: \(newScheme)")
    }
```

## WCAG Guidelines

ColorKit supports both WCAG 2.1 AA and AAA levels:

- **AA Level**
  - Normal text: 4.5:1 minimum contrast ratio
  - Large text: 3:1 minimum contrast ratio

- **AAA Level**
  - Normal text: 7:1 minimum contrast ratio
  - Large text: 4.5:1 minimum contrast ratio

## Topics

### Contrast Checking
- ``Color/contrastRatio(with:)``
- ``Color/wcagCompliance(with:)``
- ``WCAGContrastLevel``
- ``WCAGComplianceResult``

### Color Enhancement
- ``Color/enhanced(with:targetLevel:)``
- ``AccessibilityEnhancer``
- ``Color/suggestedAccessibleColors(for:level:)``

### Palette Generation
- ``Color/generateAccessiblePalette(targetLevel:paletteSize:includeBlackAndWhite:)``
- ``Color/generateAccessibleTheme(name:targetLevel:)``

### Adaptive Colors
- ``Color/adaptiveColor(light:dark:)``
- ``Color/highContrastColor(base:background:)``
- ``Color/onAdaptiveColorChange(_:)``