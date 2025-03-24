# Creating Colors

Learn how to create colors using ColorKit in various color spaces.

## Creating Colors in Different Color Spaces

ColorKit allows you to create colors using different color spaces to suit your specific needs:

### Hex Colors

The most common way to specify colors in web and app design:

```swift
// Create a color from a hex string
let brandColor = Color(hex: "#3A7BF7") // RGB format
let transparentBlue = Color(hex: "#3A7BF7CC") // RGBA format with alpha
```

### HSL Colors

HSL (Hue, Saturation, Lightness) provides an intuitive way to describe colors:

```swift
// Create a color using HSL values
// All values are in 0-1 range
let purple = Color(
    hue: 0.75,        // 270° mapped to 0-1 range
    saturation: 0.7,  // 70% saturation
    lightness: 0.5    // 50% lightness
)

// Extract HSL components
if let hsl = purple.hslComponents() {
    let hue = hsl.hue         // 0-1 range
    let saturation = hsl.saturation // 0-1 range
    let lightness = hsl.lightness   // 0-1 range
}
```

### CMYK Colors

CMYK (Cyan, Magenta, Yellow, Key/Black) is primarily used in print design:

```swift
// Create a color using CMYK values (0-1 range)
let printBlue = Color(
    cyan: 0.8,    // 80% cyan
    magenta: 0.2, // 20% magenta
    yellow: 0.0,  // 0% yellow
    key: 0.1      // 10% black
)

// Extract CMYK components
if let cmyk = printBlue.cmykComponents() {
    let cyan = cmyk.cyan       // 0-1 range
    let magenta = cmyk.magenta // 0-1 range
    let yellow = cmyk.yellow   // 0-1 range
    let black = cmyk.key       // 0-1 range
}
```

### Converting Between Formats

You can convert colors between different formats using ColorKit's component extraction methods:

```swift
let color = Color(hex: "#3A7BF7")

// Get hex string representation
let hexString = color.hexString() // Returns "#3A7BF7FF"

// Get CMYK components
if let cmyk = color.cmykComponents() {
    // Use CMYK values
}

// Get HSL components
if let hsl = color.hslComponents() {
    // Use HSL values
}
```

Note: All component values in ColorKit are normalized to the 0-1 range. For HSL, this means hue is also in 0-1 range (multiply by 360 to get degrees).

## Creating Colors from System Colors

ColorKit also allows you to work with system colors while adding additional capabilities:

```swift
// Use system colors
let systemBlue = Color.blue
let systemRed = Color.red

// Combine with ColorKit extensions
let enhancedBlue = Color.blue.saturated(by: 0.2)
```

## Advanced Color Creation

For more advanced use cases, ColorKit provides additional creation methods:

```swift
// Create a color with a specific alpha (transparency)
let transparentRed = Color.rgb(red: 1, green: 0, blue: 0, alpha: 0.5)

// Create a random color
let randomColor = Color.random()

// Create a color from a wavelength of visible light (in nanometers)
let violetColor = Color.fromWavelength(380) // Visible spectrum starts around 380nm
``` 