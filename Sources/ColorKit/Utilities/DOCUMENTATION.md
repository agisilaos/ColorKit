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

The `ColorComparison` utility helps you compare two colors across different color spaces and see their differences.

```swift
// Compare two colors
let color1 = Color.blue
let color2 = Color.purple
let difference = color1.compare(with: color2)

// Access difference metrics
let rgbDiff = difference.rgbDifference // RGB component differences
let hslDiff = difference.hslDifference // HSL component differences
let perceptualDiff = difference.perceptualDifference // Overall perceptual difference
let contrastRatio = difference.contrastRatio // WCAG contrast ratio
let wcagLevels = difference.wcagComplianceLevels // WCAG compliance levels that pass

// Get a human-readable description of the differences
print(difference.description)
```

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
    @State private var color1 = Color.blue
    @State private var color2 = Color.purple
    
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