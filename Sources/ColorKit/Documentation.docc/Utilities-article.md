# Utilities

Learn about ColorKit's utility features for color manipulation, export, and performance optimization.

## Overview

ColorKit provides various utility features to help you work with colors efficiently, export color palettes, and optimize performance.

### Color Comparison

Measure fixed, opaque, in-gamut sRGB colors with an atomic result:

```swift
let first = Color(.sRGB, red: 0.15, green: 0.35, blue: 0.75, opacity: 1)
let second = Color(.sRGB, red: 0.55, green: 0.25, blue: 0.65, opacity: 1)

switch first.comparisonResult(with: second) {
case .available(let difference):
    print("CIEDE2000 difference: \(difference.perceptualDifference)")
case .unavailable(let issues):
    print(issues.firstColor, issues.secondColor)
}
```

An available result derives RGB, HSL, CIEDE2000, contrast, and WCAG measurements from the same resolved snapshots. Dynamic or otherwise unresolved colors, translucent colors without a backing color, nonfinite components, and colors outside standard sRGB produce an unavailable result with per-input issues and no partial measurements.

CIEDE2000 uses the reference weighting factors set to one and is validated against Sharma, Wu, and Dalal's [implementation notes](https://www.ece.rochester.edu/~gsharma/ciede2000/ciede2000noteCRNA.pdf) and [supplementary data](https://hajim.rochester.edu/ece/sites/gsharma/ciede2000/dataNprograms/ciede2000testdata.txt). RGB and HSL values remain component-coordinate differences, not perceptual metrics.

### Color Cache

Improve performance by caching expensive color operations:

```swift
// First call calculates and caches
let lab1 = color1.labComponents()

// Second call retrieves from cache (much faster)
let lab1Again = color1.labComponents()

// Get cached contrast ratio
if let ratio = ColorCache.shared.getCachedContrastRatio(for: color1, with: color2) {
    print("Cached contrast ratio: \(ratio)")
}

// Cache a contrast ratio
ColorCache.shared.cacheContrastRatio(for: color1, with: color2, ratio: 4.5)

// Clear cache if needed
ColorCache.shared.clearCache()
```

### Palette Export

Export and share color palettes in various formats:

```swift
// Create a palette from colors
let colors: [Color] = [.red, .green, .blue]
let palette = PaletteExporter.createPalette(from: colors)

// Export to different formats
if let jsonData = PaletteExporter.export(
    palette: palette,
    to: .json,
    paletteName: "My Palette"
) {
    // Use the data
}

// Copy to clipboard
PaletteExporter.copyToClipboard(
    palette: palette,
    format: .css,
    paletteName: "My Palette"
)

// Export accessible palette
let accessiblePaletteData = seedColor.exportAccessiblePalette(
    targetLevel: .AA,
    to: .svg,
    paletteName: "Accessible Palette"
)
```

### Gradient Generation

Create beautiful gradients with various interpolation methods:

```swift
// Create a linear gradient
let gradient = color1.linearGradient(
    to: color2,
    in: .lab,
    steps: 10
)

// Create color harmonies
let monochromatic = color.monochromaticGradient(steps: 5)
let complementary = color.complementaryGradient()
let analogous = color.analogousGradient()
let triadic = color.triadicGradient()
```

### Color Blending

Blend colors using various blend modes:

```swift
// Simple blending
let blended = color1.blended(
    with: color2,
    mode: .overlay,
    amount: 0.5
)

// Advanced blending modes
let multiply = color1.blended(with: color2, mode: .multiply)
let screen = color1.blended(with: color2, mode: .screen)
let overlay = color1.blended(with: color2, mode: .overlay)
```

## Interface Overview

### Comparison
- ``ColorComparisonResult``
- ``ColorComparisonIssues``
- ``ColorComparisonInputIssue``
- ``ColorDifference``
- ``PerceptualDifferenceMetric``
- ``ColorComparisonView``

### Caching
- ``ColorCache``
- ``ColorCache/shared``
- ``ColorCache/clearCache()``

### Export
- ``PaletteExporter``
- ``PaletteExporter/export(palette:to:paletteName:)``

### Gradients
- `Color.linearGradient(to:in:steps:)`
- `Color.monochromaticGradient(steps:)`

### Blending
- `Color.blended(with:mode:amount:)`
- ``BlendMode``
- `Color.interpolated(with:amount:in:)`
