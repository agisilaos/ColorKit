# Utilities

Compare and inspect colors, export palettes, and generate gradients.

## Overview

Use the examples below for common workflows and the symbol documentation for individual contracts.

### Color Comparison

Measure fixed, opaque, in-gamut sRGB colors with an atomic result:

<!-- swift-example: comparison -->
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

CIEDE2000 uses the reference weighting factors set to one and is validated against Sharma, Wu, and Dalal's [implementation notes](https://www.ece.rochester.edu/~gsharma/ciede2000/ciede2000noteCRNA.pdf) and [supplementary data](https://hajim.rochester.edu/ece/sites/gsharma/ciede2000/dataNprograms/ciede2000testdata.txt). RGB and HSL values remain component-coordinate differences, not perceptual metrics. The deprecated `compare(with:)` adapter remains supported through ColorKit 3.x; its unavailable-input fallback is labeled legacy RGB distance.

![A comparison of system blue and indigo showing raw CIEDE2000, component, contrast, and WCAG results.](ciede2000-comparison.jpg)

### Similarity and Components

`isPerceptuallySimilar(to:threshold:)` uses CIE76 in D65 LAB and `distance < threshold`
without validating the threshold. Equality or unavailable LAB returns `false`.
It ignores alpha without compositing and accepts extended sRGB when LAB is available.
CIEDE2000 requires opaque, in-gamut inputs; thresholds are not interchangeable.

<!-- swift-example: similarity -->
```swift
let color = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.8)
print(color.isPerceptuallySimilar(to: color, threshold: 0)) // false: equality
print(color.isPerceptuallySimilar(to: Color.primary)) // false: unavailable LAB
```

`rgbaComponents()` resolves the current appearance, preserving extended sRGB on UIKit
and converting to bounded sRGB on AppKit. Failure returns `(0, 0, 0, 0)`, indistinguishable
from transparent black. ``ColorSpaceConverter/getAllColorComponents()`` documents the
aggregate API's additional substitutions; use optional conversions when availability matters.

### Color Cache

``ColorCache`` automatically caches eligible repeated operations using thread-safe,
count-limited `NSCache` stores. Exact keys retain the original supported RGB or
grayscale space, components including alpha, and operation parameters. Inputs
without a supported fixed identity bypass caching. Eviction or a miss must not
change numerical results; a primed cache does not guarantee a hit or a speedup.

<!-- swift-example: cache -->
```swift
let color = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.8)
let first = color.labComponents()
let repeated = color.labComponents()
ColorCache.shared.clearCache()
```

Individual stores can also be cleared with `clearLABCache()`, `clearHSLCache()`,
`clearLuminanceCache()`, `clearContrastCache()`, `clearBlendedColorCache()`, and
`clearInterpolatedColorCache()`. Explicit contrast-cache access is available through
`getCachedContrastRatio(for:with:)` and `cacheContrastRatio(for:with:ratio:)`.
See the [Release benchmark runner](https://github.com/agisilaos/ColorKit/blob/main/Benchmarks/README.md)
for reproducible measurements and cache preparation, and the
[cache identity design](https://github.com/agisilaos/ColorKit/blob/main/docs/design/cache-identity.md)
for supported spaces and regression coverage.

### Palette Export

Create named entries with ``PaletteExporter/createPalette(from:namePrefix:)`` or
`PaletteExporter.createPalette(from: theme)`, then select an export format:

| Format | Contents |
| --- | --- |
| JSON | Palette `name`, and `colors` containing `name`, `hex`, integer `rgb` (`r`, `g`, `b`), and `alpha` |
| CSS | Color variables under `:root` |
| SVG | Swatches with names and Hex values |
| Adobe ASE | Binary RGB swatches for Adobe tools |
| PNG | A rendered palette image |

<!-- swift-example: palette-export -->
```swift
let palette = PaletteExporter.createPalette(from: [.red, .green, .blue])
if let data = PaletteExporter.export(palette: palette, to: .json, paletteName: "RGB") {
    print("Exported \(data.count) bytes")
}
let copied = PaletteExporter.copyToClipboard(palette: palette, format: .css, paletteName: "RGB")
PaletteExportView(palette: palette, paletteName: "RGB")
Text("Palette").paletteExport(palette: palette, paletteName: "RGB")
```

Export returns optional data; clipboard export returns success as a Boolean.
Legacy export conversions retain their substitutions: JSON uses appearance-resolved
RGBA and substitutes `#000000` for unavailable Hex; nonfinite RGBA makes JSON export
fail. Export does not certify accessibility. `exportAccessiblePalette` generates
and exports candidates; assess the color pairs you intend to use.

The `paletteExport` modifier also accepts a color array or a `ColorTheme`.
``AccessiblePaletteGenerator`` offers `exportPalette(_:to:paletteName:)` and
`exportTheme(_:to:)` for generated palettes and themes.

The export view offers Copy and Share on iOS, and Copy and Export on macOS.
Sharing prepares the selected format before presenting the sheet; dismissing it
discards that payload, and sharing again uses the current format. Copying and
saving do not retain a share payload. Cancelling the save panel shows no result
alert; preparation and file-write failures show an error alert.

### Inspection Tools

Use ``ColorSpaceInspectorView`` for aggregate components, ``ColorComparisonView``
for comparison results, or `colorInspector` for an overlay:

<!-- swift-example: inspection -->
```swift
let foreground = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.8)
let background = Color(.sRGB, red: 1, green: 1, blue: 1)
ColorSpaceInspectorView(color: foreground)
ColorComparisonView(color1: foreground, color2: background)
Text("Inspect me").colorInspector(
    color: foreground,
    backgroundColor: background,
    position: .topTrailing,
    showContrastInfo: true
)
```

The overlay defaults to a white background, bottom-trailing position, and visible
contrast information. All four corner positions are available. For a standalone
view, use `ColorInspectorView(color:backgroundColor:showContrastInfo:)`; the demo
is available through `ColorKit.ColorInspector.demoView()`.

The overlay derives its presentation from current inputs on each render. Unavailable
Hex displays `#??????`; unavailable RGB or HSL displays `Unavailable`. If either
color cannot provide contrast components, it displays `Ratio: Unavailable` without
compliance badges. A failed background conversion does not hide valid foreground
information. Hiding and showing contrast again uses the latest inputs, never stale
values. See the [rendered examples](https://github.com/agisilaos/ColorKit/blob/main/docs/images/inspector-presentation.png).

The overlay and aggregate converter preserve their legacy measurement behavior.
For explicit conversion availability use `componentConversionResults()`; for measured
contrast with foreground compositing use `contrastResult(with:)`. See
<doc:Color-Spaces-article> and <doc:Accessibility-article>.

### Gradient Generation

Generate color samples, then apply them with SwiftUI or ColorKit's gradient background modifiers:

<!-- swift-example: gradients -->
```swift
let start = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.8)
let end = Color(.sRGB, red: 0.8, green: 0.3, blue: 0.2)
let gradient = start.linearGradient(to: end, steps: 10, in: .lab)
let monochromatic = start.monochromaticGradient(steps: 5)
let complementary = start.complementaryGradient(steps: 5)
let analogous = start.analogousGradient(steps: 5)
let triadic = start.triadicGradient(steps: 5)
Text("Gradient").linearGradientBackground(from: start, to: end, in: .lab)
```

### Color Blending

<!-- swift-example: blending -->
```swift
let base = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.8)
let overlay = Color(.sRGB, red: 0.8, green: 0.3, blue: 0.2)
let blended = base.blended(with: overlay, mode: .overlay, amount: 0.5)
let multiply = base.blended(with: overlay, mode: .multiply)
let screen = base.blended(with: overlay, mode: .screen)
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
- `Color.linearGradient(to:steps:in:)`
- `Color.monochromaticGradient(steps:)`

### Blending
- `Color.blended(with:mode:amount:)`
- ``BlendMode``
- `Color.interpolated(with:amount:in:)`
