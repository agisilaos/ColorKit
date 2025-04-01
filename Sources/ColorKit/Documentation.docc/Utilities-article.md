# Utilities

Learn about ColorKit's utility features for color manipulation, export, and performance optimization.

## Overview

ColorKit provides various utility features to help you work with colors efficiently, export color palettes, and optimize performance.

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

## Topics

### Caching
- ``ColorCache``
- ``ColorCache/shared``
- ``ColorCache/clearCache()``

### Export
- ``PaletteExporter``
- ``PaletteExporter/export(palette:to:paletteName:)``

### Gradients
- ``Color/linearGradient(to:in:steps:)``
- ``Color/monochromaticGradient(steps:)``

### Blending
- ``Color/blended(with:mode:amount:)``
- ``BlendMode``
- ``Color/interpolated(with:amount:in:)``
