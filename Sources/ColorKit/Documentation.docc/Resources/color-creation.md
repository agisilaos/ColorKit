# Creating Colors

Learn how to create colors using ColorKit in various color spaces.

## Creating Colors in Different Color Spaces

ColorKit allows you to create colors using different color spaces to suit your specific needs:

### RGB Colors

RGB (Red, Green, Blue) is the most common color space for digital displays:

```swift
// Create a color using RGB values (0-1 range)
let skyBlue = Color.rgb(red: 0.4, green: 0.7, blue: 0.9)

// Create a color using RGB values (0-255 range)
let coral = Color.rgb255(red: 255, green: 127, blue: 80)

// Create a color from a hex string
let brandColor = Color(hex: "#3A7BF7")
```

### HSL Colors

HSL (Hue, Saturation, Lightness) provides an intuitive way to describe colors:

```swift
// Create a color using HSL values
// Hue: 0-360, Saturation: 0-1, Lightness: 0-1
let purple = Color.hsl(hue: 270, saturation: 0.7, lightness: 0.5)
```

### HSB Colors

HSB (Hue, Saturation, Brightness) is similar to HSL with a different approach to lightness:

```swift
// Create a color using HSB values
// Hue: 0-360, Saturation: 0-1, Brightness: 0-1
let orange = Color.hsb(hue: 30, saturation: 0.8, brightness: 0.9)
```

### CMYK Colors

CMYK (Cyan, Magenta, Yellow, Key/Black) is primarily used in print design:

```swift
// Create a color using CMYK values (0-1 range)
let printBlue = Color.cmyk(cyan: 0.8, magenta: 0.2, yellow: 0, black: 0.1)
```

### LAB Colors

LAB is a perceptually uniform color space:

```swift
// Create a color using LAB values
// L: 0-100, a: -128 to 127, b: -128 to 127
let labColor = Color.lab(l: 65, a: -20, b: 40)
```

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