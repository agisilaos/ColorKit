# ColorKit recipes

[Back to README](../README.md) · [Español](Usage.es-ES.md)

Focused examples using existing public APIs. Import `SwiftUI` and `ColorKit` in your client. Detailed contracts live in the linked guides.

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
- [Palette export and sharing](../Sources/ColorKit/Documentation.docc/Utilities-article.md#palette-export)
- [Blending and gradients](../Sources/ColorKit/Documentation.docc/Utilities-article.md#gradient-generation)
- [Inspection tools](../Sources/ColorKit/Documentation.docc/Utilities-article.md#inspection-tools)
- [Performance and caching](../PERFORMANCE_IMPROVEMENTS.md)
- [Migration and compatibility](../MIGRATION.md)
