# ColorKit recipes

[Back to README](../README.md) · [Español](Usage.es-ES.md)

Focused examples using existing public APIs. Import `SwiftUI` and `ColorKit` in your client. Detailed contracts live in the linked guides.

## Which API should I use?

“Fixed” means RGB or grayscale components are available without choosing an appearance. Capture appearance-dependent colors explicitly first; see [resolution and component contracts](../Sources/ColorKit/Documentation.docc/Color-Spaces-article.md#component-conversion-results). Gamut limits below apply after conversion to sRGB, not to the source color-space label.

| Task → preferred method on `Color` | Inputs | Return / failure and essential limits |
| --- | --- | --- |
| Component conversion → `componentConversionResults()` | Fixed | Seven independent `Result` fields: `.success(value)` / `.failure(ColorConversionIssue)`. No clipping or compositing; finite alpha must be in `0...1`. Extended sRGBA and finite XYZ/LAB survive out-of-gamut input; HSL/HSB/CMYK/Hex reject it. Only sRGBA and Hex include alpha. |
| Contrast measurement → `contrastResult(with:)` | Fixed foreground (receiver), fixed background | `ColorContrastResult`: `.available(ContrastMeasurement)` / `.unavailable(ContrastIssues)` with per-input issues. Both must be in gamut; translucent foreground composites over an opaque background. Ratio is `1...21`; empty `passingLevels` is a measured shortfall. |
| Accessibility assessment → `accessibilityResult(against:targetLevel:)` | Same fixed foreground/background contract as contrast | `ColorAccessibilityResult`: unchanged color, optional ratio, and `.meetsTarget`, `.bestEffort` (measured below target), or `.unavailable`. No adjustment or distance budget. |
| Enhancement → `enhancementResult(with:targetLevel:strategy:maxPerceptualDistance:)` | Fixed, in-gamut, opaque foreground and background | `ColorAccessibilityResult`: candidate, optional contrast/distance, assessment statuses plus `.invalidConfiguration`. Inclusive CIEDE2000 ΔE00 budget: finite `0...100`, default `30`; zero preserves the original. Best effort covers examined in-budget candidates, not a global optimum. |
| Perceptual comparison → `comparisonResult(with:)` | Two fixed, in-gamut, opaque colors | `ColorComparisonResult`: `.available(ColorDifference)` using CIEDE2000 / `.unavailable(ColorComparisonIssues)`. Atomic: no partial measurements, clipping, or alpha compositing. |
| HSL for the current appearance → `hslComponents()` | Platform resolves named/dynamic colors for the current appearance | Optional `(hue, saturation, lightness)` tuple in `0...1`; `nil` on resolution failure. Clips wider-gamut channels to sRGB and omits alpha. For fixed input with explicit gamut failure, use `componentConversionResults().hsl`. |

Successful zero components or zero ΔE00 are valid values. Unavailable means no measurement, not zero or a measured shortfall. For enhancement, diagnostic contrast can remain available even with `.unavailable` or `.invalidConfiguration`; check `status` / `meetsTarget`, not the ratio alone. See [assessment and budget contracts](../Sources/ColorKit/Documentation.docc/Accessibility-article.md#verifiable-results).

**Existing callers:** `rgbaComponents()` can substitute `(0, 0, 0, 0)` on failure; `ColorSpaceConverter.getAllColorComponents()` also hides substitutions. Neither shares per-field result semantics. Legacy XYZ/LAB arithmetic can differ from component results. `contrastRatio(with:)` ignores alpha and uses luminance fallbacks; `wcagContrastRatio(with:)` uses sentinel `1` for translucent inputs, indistinguishable from a measured 1:1 ratio. Legacy color-returning enhancement ignores the distance budget and does not guarantee the target. See [conversion contracts](../Sources/ColorKit/Documentation.docc/Color-Spaces-article.md) and [contrast compatibility](../MIGRATION.md).

`isPerceptuallySimilar(to:threshold:)` retains CIE76, ignores alpha, accepts extended inputs when LAB is available, and returns `false` for unavailable LAB or distance equal to the threshold. Its thresholds are not CIEDE2000 thresholds. Deprecated `compare(with:)` returns CIEDE2000 when eligible, otherwise a labeled `.legacyRGBDistance` fallback. See [comparison contracts](../Sources/ColorKit/Documentation.docc/Utilities-article.md#color-comparison) and [migration](../MIGRATION.md).

## Convert colors

Use per-representation results when availability matters. Supply a fixed color; capture the intended appearance explicitly for dynamic colors. One unavailable representation does not discard successful conversions.

<!-- swift-example: component-results -->
```swift
let conversions = Color(.displayP3, red: 1, green: 0, blue: 0).componentConversionResults()
if case .success(let lab) = conversions.lab {
    print(lab.lightness, lab.a, lab.b)
}
switch conversions.hex {
case .success(let hex): print(hex)
case .failure(let issue): print("Hex unavailable:", issue)
}
```

See [component contracts](../Sources/ColorKit/Documentation.docc/Color-Spaces-article.md#component-conversion-results) for gamut, alpha, units, and failure rules.

### HSL

The legacy HSL accessor resolves the current appearance and clips to sRGB. It returns `nil` if resolution fails.

<!-- swift-example: hsl -->
```swift
let hsl = Color.red.hslComponents()
let customColor = Color(hue: 0.5, saturation: 1.0, lightness: 0.5)
```

### CMYK

<!-- swift-example: cmyk -->
```swift
// Convert from RGB to CMYK
let red = Color(.sRGB, red: 1, green: 0, blue: 0)
let cmyk = red.cmykComponents()
// (cyan: 0.0, magenta: 1.0, yellow: 1.0, key: 0.0)

// Create color from CMYK values
let printColor = Color(cyan: 0.2, magenta: 0.8, yellow: 0.1, key: 0.1)
```

### LAB

<!-- swift-example: lab -->
```swift
// Resolve a fixed color and convert it to LAB
let red = Color(.sRGB, red: 1, green: 0, blue: 0)
let lab = red.labComponents()
if let lab {
    print(lab) // (L: 53.24, a: 80.09, b: 67.20)
}

// Create color from LAB values
let labColor = Color(L: 50.0, a: 25.0, b: -30.0)
```

CMYK and LAB accessors require fixed colors; they do not choose an appearance. See [color spaces](../Sources/ColorKit/Documentation.docc/Color-Spaces-article.md) for their distinct conversion policies and Hex support.

## Assess and adjust contrast

The receiver is the foreground. Translucent foregrounds composite over opaque backgrounds; translucent backgrounds are unavailable. A measured pass does not certify whole-app accessibility.

<!-- swift-example: budget -->
```swift
// Check WCAG compliance
let textColor = Color(.sRGB, red: 0.6, green: 0.6, blue: 0.6)
let backgroundColor = Color(.sRGB, red: 1, green: 1, blue: 1)
let assessment = textColor.accessibilityResult(against: backgroundColor, targetLevel: .AA)
print(assessment.status)

// Get budgeted candidates with explicit outcomes and measurement evidence
let suggestions = textColor.suggestAccessibleVariantResults(
    with: backgroundColor,
    targetLevel: .AA,
    maxPerceptualDistance: 30
)
```

### Generate an adjusted candidate

<!-- swift-example: enhancement -->
```swift
// Generate a candidate within a distance budget, then inspect its outcome
let originalColor = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.8)
let backgroundColor = Color(.sRGB, red: 1, green: 1, blue: 1)
let targetLevel = WCAGContrastLevel.AA

let result = originalColor.enhancementResult(
    with: backgroundColor,
    targetLevel: targetLevel
)
let enhancedColor = result.color

if result.meetsTarget {
    if let ratio = result.contrastRatio {
        print("Measured contrast: \(ratio):1")
    }
}
```

Inspect the outcome before using a candidate. The distance budget can prevent reaching the target. Legacy color-returning enhancement ignores that budget. See [enhancement contracts](../Sources/ColorKit/Documentation.docc/Accessibility-article.md#verifiable-results).

### Assess a generated palette

<!-- swift-example: accessible-palette -->
```swift
let seedColor = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.8)
let backgroundColor = Color(.sRGB, red: 1, green: 1, blue: 1)
let generator = AccessiblePaletteGenerator(configuration: .init(targetLevel: .AA))
let results = generator.generateAssessedPalette(from: seedColor, against: backgroundColor)
for result in results {
    if result.meetsTarget {
        Text("WCAG AA").foregroundColor(result.color).background(backgroundColor)
    } else {
        print(result.status)
    }
}

let textResult = backgroundColor.accessibleContrastingColorResult(for: .AA)
let textColor = textResult.color

switch textResult.status {
case .meetsTarget:
    if let ratio = textResult.contrastRatio {
        print("Contrast: \(ratio):1")
    }
case .bestEffort:
    print("Best available endpoint is below the requested target")
case .unavailable:
    print("Resolve the colors in an explicit appearance before assessment")
case .invalidConfiguration:
    print("Supply a finite perceptual-distance budget from 0 through 100")
}

// Use the demo view to experiment with palette generation
struct ContentView: View {
    var body: some View {
        ColorKit.ColorInspector.accessiblePaletteDemoView()
    }
}
```

Assessments retain every outcome and do not certify contrast between palette entries. See [assessed palettes](../Sources/ColorKit/Documentation.docc/Accessibility-article.md#assessed-palettes) for guarantees and legacy differences.

To assess your own explicit pairs, run the standalone macOS [contrast pair report](../Examples/ContrastPairReport/README.md).

## Compare colors

CIEDE2000 comparison requires fixed, opaque, in-gamut sRGB inputs. Unavailable measurements remain explicit.

<!-- swift-example: comparison -->
```swift
let color1 = Color(.sRGB, red: 0.15, green: 0.35, blue: 0.75, opacity: 1)
let color2 = Color(.sRGB, red: 0.55, green: 0.25, blue: 0.65, opacity: 1)

switch color1.comparisonResult(with: color2) {
case .available(let difference):
    print("CIEDE2000 difference: \(difference.perceptualDifference)")
case .unavailable(let issues):
    print("Comparison unavailable: \(issues)")
}

// Visual comparison view
ColorComparisonView(color1: color1, color2: color2)
```

The legacy similarity predicate uses CIE76, not CIEDE2000; thresholds are not interchangeable. See [comparison contracts](../Sources/ColorKit/Documentation.docc/Utilities-article.md).

## Explore the catalog

The catalog demonstrates blending, gradients, themes, palettes, inspection, animation, and accessibility. Embed it in a SwiftUI host:

<!-- swift-example: catalog -->
```swift
import ColorKit

struct ContentView: View {
    var body: some View {
        MainCatalogView()
    }
}
```

Or embed an individual preview:

<!-- swift-example: previews -->
```swift
// Use individual previews
ColorSpacePreview()
BlendingPreview()
GradientPreview()
ThemePreview()
PerformanceBenchmark()
ColorDebuggerPreview()
PaletteStudioPreview()
ColorAnimationPreview()
AccessibilityLabPreview()
```

## More recipes

- [Themes and adaptive colors](../Sources/ColorKit/Documentation.docc/Theming-article.md)
- [Palette export and sharing](../Sources/ColorKit/Utilities/PaletteExporter.md)
- [Blending and gradients](../Sources/ColorKit/Documentation.docc/Utilities-article.md#gradient-generation)
- [Inspection tools](../Sources/ColorKit/Utilities/DOCUMENTATION.md)
- [Performance and caching](../PERFORMANCE_IMPROVEMENTS.md)
- [Migration and compatibility](../MIGRATION.md)
