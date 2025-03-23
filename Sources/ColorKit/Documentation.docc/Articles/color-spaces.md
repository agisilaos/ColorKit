# Color Spaces in ColorKit

Learn about the various color spaces supported by ColorKit and how to convert between them.

## Overview

ColorKit supports multiple color spaces, providing powerful tools for color manipulation and conversion. This article explains the different color spaces and how to use them in your SwiftUI projects.

## HEX Colors

HEX colors are widely used in web design and are represented as hexadecimal strings.

```swift
// Create a color from a HEX string
let redColor = Color(hex: "#FF0000")
let blueWithAlpha = Color(hex: "#0000FF80") // With alpha channel

// Convert a color to its HEX representation
let hexString = Color.purple.hexValue() // "#800080FF"
let hexNoAlpha = Color.purple.hexValue(includeAlpha: false) // "#800080"
```

## HSL Color Space

HSL (Hue, Saturation, Lightness) represents colors in a more intuitive way than RGB, making it easier to create color variations.

```swift
// Get HSL components from a color
let hsl = Color.red.hslComponents()
// (hue: 0.0, saturation: 1.0, lightness: 0.5)

// Create a color from HSL values
let customColor = Color(hue: 0.5, saturation: 1.0, lightness: 0.5)

// Adjust lightness while preserving hue and saturation
let lighterColor = Color(
    hue: hsl.hue,
    saturation: hsl.saturation,
    lightness: min(hsl.lightness + 0.2, 1.0)
)

// Adjust saturation while preserving hue and lightness
let lessSaturated = Color(
    hue: hsl.hue,
    saturation: max(hsl.saturation - 0.3, 0.0),
    lightness: hsl.lightness
)
```

## CMYK Color Space

CMYK (Cyan, Magenta, Yellow, Key/Black) is primarily used in print design.

```swift
// Get CMYK components from a color
let cmyk = Color.green.cmykComponents()
// (cyan: 1.0, magenta: 0.0, yellow: 1.0, key: 0.0)

// Create a color from CMYK values
let printColor = Color(cyan: 0.2, magenta: 0.8, yellow: 0.1, key: 0.1)

// Adjust individual CMYK components
let adjustedColor = Color(
    cyan: cmyk.cyan,
    magenta: min(cmyk.magenta + 0.2, 1.0),
    yellow: cmyk.yellow,
    key: cmyk.key
)
```

## LAB Color Space

LAB (also known as CIELAB) is a color space designed to approximate human vision, making it useful for perceptually accurate color manipulations.

```swift
// Get LAB components from a color
let lab = Color.blue.labComponents()
// (L: 32.3, a: 79.2, b: -107.9)

// Create a color from LAB values
let labColor = Color(L: 50.0, a: 25.0, b: -30.0)

// Adjust lightness in LAB space (perceptually accurate)
let brighterColor = Color(
    L: min(lab.L + 10, 100),
    a: lab.a,
    b: lab.b
)
```

## Color Interpolation

ColorKit allows interpolation between colors in different color spaces for different visual effects.

```swift
// Interpolate between two colors
let color1 = Color.red
let color2 = Color.blue
let amount = 0.5 // 50% blend

// Interpolate in RGB space (standard)
let rgbBlend = color1.interpolated(with: color2, amount: amount)

// Interpolate in HSL space (often more vibrant transitions)
let hslBlend = color1.interpolated(with: color2, amount: amount, in: .hsl)

// Interpolate in LAB space (perceptually uniform)
let labBlend = color1.interpolated(with: color2, amount: amount, in: .lab)
```

## Advanced Color Analysis

ColorKit provides tools for advanced color analysis and manipulation.

```swift
// Get components in all color spaces
let components = myColor.colorSpaceComponents()

// Display a visual color inspector
import SwiftUI

struct ColorInspectorView: View {
    let color: Color = .purple
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(color)
                .frame(height: 100)
                .cornerRadius(8)
            
            Text("RGB: \(rgbString(for: color))")
            Text("HSL: \(hslString(for: color))")
            Text("CMYK: \(cmykString(for: color))")
            Text("LAB: \(labString(for: color))")
            Text("HEX: \(color.hexValue())")
        }
        .padding()
    }
    
    private func rgbString(for color: Color) -> String {
        let rgb = color.rgbComponents()
        return String(format: "%.2f, %.2f, %.2f", rgb.red, rgb.green, rgb.blue)
    }
    
    private func hslString(for color: Color) -> String {
        let hsl = color.hslComponents()
        return String(format: "%.2f, %.2f, %.2f", hsl.hue, hsl.saturation, hsl.lightness)
    }
    
    private func cmykString(for color: Color) -> String {
        let cmyk = color.cmykComponents()
        return String(format: "%.2f, %.2f, %.2f, %.2f", cmyk.cyan, cmyk.magenta, cmyk.yellow, cmyk.key)
    }
    
    private func labString(for color: Color) -> String {
        let lab = color.labComponents()
        return String(format: "%.2f, %.2f, %.2f", lab.L, lab.a, lab.b)
    }
}
```

## Performance Considerations

Color space conversions can be computationally expensive. ColorKit automatically caches results for better performance:

```swift
// First call calculates and caches
let lab1 = color1.labComponents()

// Second call retrieves from cache (much faster)
let lab1Again = color1.labComponents()

// If needed, manually clear caches
ColorCache.shared.clearCache()
``` 