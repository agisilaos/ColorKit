# Accessibility

Learn how to create accessible color combinations and ensure your app meets WCAG guidelines.

## Overview

For new callers, use result-bearing APIs and check `meetsTarget` or `status` before
using a candidate. Legacy color-returning methods do not guarantee the requested
target; legacy enhancement also ignores distance budgets.

### Contrast Checking

Check if your color combinations meet WCAG contrast requirements:

The receiver of `foreground.contrastResult(with: background)` is the foreground.
A translucent foreground composites over the opaque background; a translucent
background is unavailable. Reversing the arguments can change the result.

<!-- swift-example: contrast -->
```swift
let backgroundColor = Color(.sRGB, red: 1, green: 1, blue: 1)
let textColor = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.7)
switch textColor.contrastResult(with: backgroundColor) {
case .available(let measurement):
    print(measurement.ratio, measurement.passingLevels)
case .unavailable(let issues):
    print(issues.foreground, issues.background)
}
```

### Assessed Palettes

Assessment retains every outcome without imposing an enhancement budget or
certifying contrast between entries. Legacy palettes return candidates; themes
establish a black-and-white text/background pair. Assess other role combinations.

<!-- swift-example: assessed-palette -->
```swift
let seed = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.8)
let background = Color(.sRGB, red: 1, green: 1, blue: 1)
let results = AccessiblePaletteGenerator().generateAssessedPalette(from: seed, against: background)
for result in results {
    if result.meetsTarget {
        Text("WCAG AA").foregroundColor(result.color).background(background)
    } else {
        print(result.status)
    }
}
```

`accessibleContrastingColor(for:)` and `suggestedColor(for:)` ignore the requested
level and use different endpoint heuristics. Prefer `accessibleContrastingColorResult(for:)`
and inspect its outcome; even the stronger black-or-white endpoint may miss the target.

### Verifiable Results

Color-returning helpers remain available for compatibility. When correctness depends
on knowing the outcome, use the assessed interfaces. They distinguish a measured pass,
a measurable best effort below the target, and a result that cannot be measured from
the supplied colors.

<!-- swift-example: enhancement -->
```swift
let textColor = Color(.sRGB, red: 0.6, green: 0.6, blue: 0.6)
let backgroundColor = Color(.sRGB, red: 1, green: 1, blue: 1)
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
    Text("Required contrast or distance measurement is unavailable")
case .invalidConfiguration:
    Text("Use a finite distance budget from 0 through 100")
}
```

Assessment accepts finite, in-gamut sRGB colors and requires an opaque background.
A translucent foreground is composited over that background. Dynamic colors and
translucent backgrounds return `unavailable` because their contrast needs context
that the API was not given.

Result-bearing enhancement additionally requires an opaque, comparable original
foreground and enforces `maxPerceptualDistance` (default 30). It is an inclusive
CIEDE2000 Delta E 00 budget in `0...100`, measured from the original in D65 LAB with
reference weights of one. Zero preserves the original; no fallback may overshoot.
When no examined in-budget candidate passes, return highest-contrast best effort,
not a promise of a global optimum. Strategies are preferences, not guarantees.

Inspect `perceptualDistance`, `maximumPerceptualDistance`, and
`isWithinPerceptualDistanceBudget` for evidence. Invalid configuration or unavailable
distance may retain diagnostic contrast but never report success. Direct assessment
still supports composited translucent foregrounds and has no enhancement budget.
Legacy color-returning methods continue ignoring the budget. Result variants use
pairwise Delta E 00 below 5 for duplicates, preserve strategy order and best-effort
entries, and return one diagnostic result for a positive-count invalid or unavailable
request (an empty array for nonpositive counts).

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
opacity, when `contrastRatio(with:)` already meets or exceeds the requested minimum.
That measurement uses WCAG relative luminance, so its ratios match
`wcagContrastRatio(with:)` for opaque colors.

It ignores opacity, however: it compares two colors rather than compositing a
foreground over a background. A translucent color is therefore measured as though it
were fully saturated, and the returned color is not certified as compliant. Two further
limits apply: a foreground that cannot be converted to HSL is returned unchanged, and an
unsuccessful adjustment falls back to black or white, which may still fall short of the
requested ratio even though it is the stronger of the two endpoints.

`highContrastColor` delegates to this behavior. For an assessment that composites
opacity and reports whether the result actually meets a level, use
`accessibilityResult(against:targetLevel:)` or `contrastResult(with:)`.

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
- `Color.enhancementResult(with:targetLevel:strategy:maxPerceptualDistance:)`
- ``AccessibilityEnhancer``
- `Color.suggestedAccessibleColors(for:level:)`
- `Color.suggestAccessibleVariantResults(with:targetLevel:count:maxPerceptualDistance:)`
- `Color.accessibleContrastingColorResult(for:)`

### Palette Generation
- `Color.generateAccessiblePalette(targetLevel:paletteSize:includeBlackAndWhite:)`
- `Color.generateAccessibleTheme(name:targetLevel:)`
- `AccessiblePaletteGenerator.generateAssessedPalette(from:against:)`

### Adaptive Colors
- `View.adaptiveColor(light:dark:)`
- `View.highContrastColor(base:background:)`
- `View.onAdaptiveColorChange(_:)`
