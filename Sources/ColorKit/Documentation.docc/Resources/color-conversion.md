# Converting Between Color Spaces

Learn how to convert colors between different color spaces using ColorKit.

## Converting Colors Between Spaces

ColorKit makes it easy to convert colors between different color spaces, allowing you to work with the most appropriate representation for each task.

### Basic Conversions

```swift
// Start with a color from hex
let blueColor = Color(hex: "#3366CC")

// Convert to HSL
if let hsl = blueColor.hslComponents() {
    // Access components (all in 0-1 range)
    let hue = hsl.hue         // Multiply by 360 for degrees
    let saturation = hsl.saturation 
    let lightness = hsl.lightness
    
    // Create a new color with modified HSL values
    let newColor = Color(
        hue: hue,
        saturation: min(1, saturation * 1.2), // Increase saturation by 20%
        lightness: lightness
    )
}

// Convert to CMYK
if let cmyk = blueColor.cmykComponents() {
    // Access components (all in 0-1 range)
    let cyan = cmyk.cyan
    let magenta = cmyk.magenta
    let yellow = cmyk.yellow
    let black = cmyk.key
    
    // Create a new color with modified CMYK values
    let newColor = Color(
        cyan: cyan,
        magenta: magenta,
        yellow: yellow,
        key: min(1, black + 0.1) // Make it slightly darker
    )
}
```

### Converting to Hex Strings

ColorKit provides methods to convert colors to hex string representations:

```swift
let color = Color(hex: "#FF8000")

// Get a hex string (includes alpha)
let hexString = color.hexString() // "#FF8000FF"

// Get a hex string (alternative method)
let hexValue = color.hexValue() // Same as hexString()
```

### Working with Color Components

When working with color components in ColorKit, remember these key points:

1. All component values are normalized to the 0-1 range
2. HSL hue is in 0-1 range (multiply by 360 to get degrees)
3. Component extraction methods return optional values
4. Always handle the optional return values appropriately

Example of safe component handling:

```swift
let color = Color(hex: "#FF8000")

// Safe HSL component extraction
if let hsl = color.hslComponents() {
    // Use the components
    let adjustedColor = Color(
        hue: hsl.hue,
        saturation: hsl.saturation,
        lightness: max(0, min(1, hsl.lightness + 0.1)) // Lighten by 10%
    )
}

// Safe CMYK component extraction
if let cmyk = color.cmykComponents() {
    // Use the components
    let adjustedColor = Color(
        cyan: cmyk.cyan,
        magenta: cmyk.magenta,
        yellow: cmyk.yellow,
        key: max(0, min(1, cmyk.key - 0.1)) // Reduce black by 10%
    )
}
```

## Converting for Specific Use Cases

ColorKit provides specialized conversions for particular use cases:

```swift
// Get a grayscale version of a color
let grayColor = colorfulImage.grayscale()

// Get the complementary color (opposite on the color wheel)
let complementaryColor = blueColor.complementary()

// Convert to a color suitable for light or dark backgrounds
let adaptiveColor = originalColor.adaptiveColor(for: .dark)
``` 