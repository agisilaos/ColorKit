# ColorKit Debugging Utilities

This document describes the debugging utilities available in ColorKit to help developers with color inspection, accessibility validation, and more.

## Color Inspection Utilities

ColorKit provides several utilities to help you inspect and debug colors in your application.

### Color Space Converter

The `ColorSpaceConverter` allows you to convert colors between different color spaces and view their components.

```swift
// Get a color's components in all color spaces
let color = Color.blue
let components = color.colorSpaceComponents()

// Access individual color space representations
let rgb = components.rgb // (red: Double, green: Double, blue: Double, alpha: Double)
let hsl = components.hsl // (hue: Double, saturation: Double, lightness: Double)
let hsb = components.hsb // (hue: Double, saturation: Double, brightness: Double)
let cmyk = components.cmyk // (cyan: Double, magenta: Double, yellow: Double, key: Double)
let lab = components.lab // (l: Double, a: Double, b: Double)
let xyz = components.xyz // (x: Double, y: Double, z: Double)

// Get a human-readable description of all color components
print(components.description)
```

### Color Comparison

The color-comparison API measures fixed, opaque, in-gamut sRGB colors without inventing components when resolution fails. It reports RGB and HSL component differences, CIEDE2000 perceptual difference, WCAG contrast, and passing WCAG levels as one atomic result.

```swift
let color1 = Color(.sRGB, red: 0.15, green: 0.35, blue: 0.75, opacity: 1)
let color2 = Color(.sRGB, red: 0.55, green: 0.25, blue: 0.65, opacity: 1)

switch color1.comparisonResult(with: color2) {
case .available(let difference):
    let rgbDiff = difference.rgbDifference // Normalized sRGB component differences
    let hslDiff = difference.hslDifference // HSL coordinate differences
    let deltaE00 = difference.perceptualDifference // Raw, unbounded CIEDE2000 value
    let contrastRatio = difference.contrastRatio // WCAG contrast ratio
    let wcagLevels = difference.wcagComplianceLevels // Passing WCAG levels
    print(difference.description)
case .unavailable(let issues):
    print("First color issues: \(issues.firstColor)")
    print("Second color issues: \(issues.secondColor)")
}
```

The comparison rejects dynamic or otherwise unresolved colors, translucency without an explicit backing color, nonfinite components, and colors outside the standard sRGB gamut. The unavailable result contains all provable issues for each input and no partial measurements. `compare(with:)` remains deprecated through ColorKit 2.x solely as a compatibility adapter; unavailable inputs may receive its explicitly labeled legacy RGB-distance fallback.

ColorKit implements CIEDE2000 with the reference weighting factors set to one and validates it against all 34 color pairs published with Sharma, Wu, and Dalal's [implementation notes](https://www.ece.rochester.edu/~gsharma/ciede2000/ciede2000noteCRNA.pdf) and [supplementary test data](https://hajim.rochester.edu/ece/sites/gsharma/ciede2000/dataNprograms/ciede2000testdata.txt).

### Color Space Inspector View

The `ColorSpaceInspectorView` provides a SwiftUI view for displaying detailed color information:

```swift
struct ContentView: View {
    @State private var color = Color.blue
    
    var body: some View {
        VStack {
            ColorPicker("Select a color", selection: $color)
                .padding()
            
            ColorSpaceInspectorView(color: color)
                .padding()
        }
    }
}
```

### Color Comparison View

The `ColorComparisonView` provides a SwiftUI view for comparing two colors:

```swift
struct ContentView: View {
    @State private var color1 = Color(.sRGB, red: 0.15, green: 0.35, blue: 0.75, opacity: 1)
    @State private var color2 = Color(.sRGB, red: 0.55, green: 0.25, blue: 0.65, opacity: 1)
    
    var body: some View {
        VStack {
            HStack {
                ColorPicker("Color 1", selection: $color1)
                ColorPicker("Color 2", selection: $color2)
            }
            .padding()
            
            ColorComparisonView(color1: color1, color2: color2)
                .padding()
        }
    }
}
```

## WCAG Compliance Debugging

ColorKit includes utilities to help ensure your colors meet accessibility standards.

### WCAG Contrast Checker

Check the contrast ratio between two colors to ensure they meet accessibility standards:

```swift
let backgroundColor = Color.white
let textColor = Color.gray

// Get the contrast ratio
let ratio = backgroundColor.wcagContrastRatio(with: textColor)

// Check if it meets various WCAG levels
let compliance = backgroundColor.wcagCompliance(with: textColor)

if compliance.passesAA {
    print("Meets AA standard")
} else {
    print("Does not meet AA standard")
}
```

### Accessible Color Suggestions

Get suggested alternative colors that would meet accessibility requirements:

```swift
let backgroundColor = Color.white
let problematicColor = Color(red: 0.7, green: 0.7, blue: 0.7) // Light gray

// Get suggested colors that would pass AA level
let suggestions = backgroundColor.suggestedAccessibleColors(
    for: problematicColor, 
    level: .AA, 
    preserveHue: true
)

if let suggestedColor = suggestions.first {
    // Use the suggested color instead
    Text("This text is accessible")
        .foregroundColor(suggestedColor)
        .background(backgroundColor)
}
```

The `preserveHue` parameter controls whether the suggested colors should try to maintain the original hue. This is useful when you want to keep the same color family for brand consistency.

### Advanced Color Suggestions

For more control over the suggestion process, you can use the `WCAGColorSuggestions` class directly:

```swift
// Create a suggestions generator
let suggester = WCAGColorSuggestions(
    baseColor: backgroundColor,
    targetColor: problematicColor,
    targetLevel: .AAA // Target AAA compliance
)

// Generate suggestions
let suggestions = suggester.generateSuggestions(preserveHue: false)
```

## Best Practices

1. **Use the inspection tools during development**: Add the `ColorSpaceInspectorView` to your development/debug builds to quickly see color properties.

2. **Always check contrast ratios**: Ensure text has sufficient contrast with its background for readability.

3. **Test with different accessibility settings**: Use the utilities to check how your colors appear with various accessibility settings.

4. **Maintain brand consistency**: When fixing accessibility issues, use `preserveHue: true` to maintain your color palette's feel.

5. **Document color decisions**: Use the tools to document why specific colors were chosen, especially when addressing accessibility concerns.
