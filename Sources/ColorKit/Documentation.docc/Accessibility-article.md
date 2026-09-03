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
let ratio = backgroundColor.contrastRatio(with: textColor)
print("Contrast ratio: \(ratio)")

// Or measure it without collapsing an unresolvable input to zero luminance
switch textColor.contrastResult(with: backgroundColor) {
case .available(let measurement):
    print("Contrast ratio: \(measurement.ratio)")
    print("Passing levels: \(measurement.passingLevels)")
case .unavailable(let issues):
    print("Unavailable: \(issues.foreground), \(issues.background)")
}

// Check WCAG compliance
let compliance = backgroundColor.wcagCompliance(with: textColor)
print("AA Large Text: \(compliance.passesAALarge)")
print("AA Normal Text: \(compliance.passesAA)")
print("AAA Large Text: \(compliance.passesAAALarge)")
print("AAA Normal Text: \(compliance.passesAAA)")
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

### Verifiable Results

Color-returning helpers remain available for compatibility. When correctness depends
on knowing the outcome, use the assessed interfaces. They distinguish a measured pass,
a measurable best effort below the target, and a result that cannot be measured from
the supplied colors.

```swift
let result = textColor.enhancementResult(
    with: backgroundColor,
    targetLevel: .AAA
)

switch result.status {
case .meetsTarget:
    if let ratio = result.contrastRatio {
        Text("Measured contrast: \(ratio):1")
    }
case .bestEffort:
    Text("Candidate is below \(result.minimumContrastRatio):1")
case .unavailable:
    Text("Resolve the colors in an explicit appearance before assessment")
}
```

Assessment accepts finite, in-gamut sRGB colors and requires an opaque background.
A translucent foreground is composited over that background. Dynamic colors and
translucent backgrounds return `unavailable` because their contrast needs context
that the API was not given.

### Fixed-Color CVD Simulation

Use ``ColorVisionDeficiency`` with `Color.simulated(for:)` to transform a fixed
color for full-severity protanopia, deuteranopia, or tritanopia:

```swift
let source = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.6)

if let simulated = source.simulated(for: .deuteranopia) {
    Rectangle().fill(simulated)
}
```

The transformation uses the Machado–Oliveira–Fernandes severity-1 matrices in
linear sRGB, clips output channels to the sRGB gamut, and preserves opacity. It
returns `nil` when the input is dynamic, semantic, pattern-based, unsupported,
nonfinite, or outside the sRGB gamut.

This API transforms fixed colors, not arbitrary rendered content. The deprecated
`colorBlindnessPreview(type:)` modifier remains source compatible but leaves its
content unchanged. Achromatopsia is not supported because a generic grayscale
conversion is not established by the selected model.

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

`adjustedForAccessibility(with:minimumRatio:)` preserves the original color, including
opacity, when its legacy contrast ratio already meets or exceeds the requested minimum.
Otherwise, it attempts to adjust lightness. Failed foreground conversion returns the
original color; unsuccessful adjustment retains the existing black/white fallback,
which may not meet the requested ratio. `highContrastColor` delegates to this behavior.
These legacy adjustments do not independently certify WCAG compliance.

## WCAG Guidelines

ColorKit supports both WCAG 2.1 AA and AAA levels:

- **AA Level**
  - Normal text: 4.5:1 minimum contrast ratio
  - Large text: 3:1 minimum contrast ratio

- **AAA Level**
  - Normal text: 7:1 minimum contrast ratio
  - Large text: 4.5:1 minimum contrast ratio

## Interface Overview

### Contrast Checking
- `Color.contrastRatio(with:)`
- `Color.contrastResult(with:)`
- `Color.relativeLuminance()`
- `Color.relativeLuminanceValue()`
- `Color.wcagCompliance(with:)`
- `Color.accessibilityResult(against:targetLevel:)`
- ``WCAGContrastLevel``
- ``WCAGComplianceResult``
- ``ColorAccessibilityResult``
- ``ColorContrastResult``
- ``ContrastMeasurement``
- ``ContrastIssues``
- ``ContrastInputIssue``

### Color Vision Deficiency Simulation
- ``ColorVisionDeficiency``
- `Color.simulated(for:)`

### Color Enhancement
- `Color.enhanced(with:targetLevel:)`
- `Color.enhancementResult(with:targetLevel:strategy:)`
- ``AccessibilityEnhancer``
- `Color.suggestedAccessibleColors(for:level:)`
- `Color.suggestAccessibleVariantResults(with:targetLevel:count:)`
- `Color.accessibleContrastingColorResult(for:)`

### Palette Generation
- `Color.generateAccessiblePalette(targetLevel:paletteSize:includeBlackAndWhite:)`
- `Color.generateAccessibleTheme(name:targetLevel:)`
- `AccessiblePaletteGenerator.generateAssessedPalette(from:against:)`

### Adaptive Colors
- `Color.adaptiveColor(light:dark:)`
- `Color.highContrastColor(base:background:)`
- `Color.onAdaptiveColorChange(_:)`
