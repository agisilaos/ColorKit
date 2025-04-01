# Color Spaces

Learn about the different color spaces supported by ColorKit and how to convert between them.

## Overview

ColorKit supports multiple color spaces to give you flexibility in how you work with colors. Each color space has its own unique characteristics and use cases.

### RGB

The RGB color space is the most common color space used in digital displays. It represents colors using red, green, and blue components.

```swift
// Create a color using RGB values
let color = Color(red: 1.0, green: 0.5, blue: 0.2)

// Get RGB components
if let (red, green, blue, alpha) = color.rgbComponents() {
    print("R: \(red), G: \(green), B: \(blue), A: \(alpha)")
}
```

### HSL

The HSL (Hue, Saturation, Lightness) color space is particularly useful for color manipulation and creating color schemes.

```swift
// Create a color using HSL values
let color = Color(hue: 0.5, saturation: 1.0, lightness: 0.5)

// Get HSL components
if let components = color.hslComponents() {
    print("H: \(components.hue), S: \(components.saturation), L: \(components.lightness)")
}
```

### CMYK

The CMYK (Cyan, Magenta, Yellow, Key) color space is primarily used in print design and production.

```swift
// Create a color using CMYK values
let color = Color(cyan: 0.2, magenta: 0.8, yellow: 0.1, key: 0.1)

// Get CMYK components
if let components = color.cmykComponents() {
    print("C: \(components.cyan), M: \(components.magenta), Y: \(components.yellow), K: \(components.key)")
}
```

### LAB

The LAB color space is designed to be perceptually uniform and is often used in color management systems.

```swift
// Create a color using LAB values
let color = Color(L: 50.0, a: 25.0, b: -30.0)

// Get LAB components
if let components = color.labComponents() {
    print("L: \(components.L), a: \(components.a), b: \(components.b)")
}
```

## Color Space Conversion

ColorKit handles color space conversions automatically. When you create a color in one color space and request components in another, the conversion is done for you:

```swift
// Create a color in RGB
let color = Color(red: 1.0, green: 0.0, blue: 0.0)

// Get components in different color spaces
let hsl = color.hslComponents()
let cmyk = color.cmykComponents()
let lab = color.labComponents()
```

## Topics

### RGB
- ``Color/rgbComponents()``
- ``Color/init(red:green:blue:)``

### HSL
- ``Color/hslComponents()``
- ``Color/init(hue:saturation:lightness:)``
- ``Color/hslString()``

### CMYK
- ``Color/cmykComponents()``
- ``Color/init(cyan:magenta:yellow:key:)``
- ``Color/cmykString()``

### LAB
- ``Color/labComponents()``
- ``Color/init(L:a:b:)``
- ``Color/labString()``

### Utilities
- ``ColorSpaceConverter``
- ``ColorCache``