# Converting Between Color Spaces

Learn how to convert colors between different color spaces using ColorKit.

## Converting Colors Between Spaces

ColorKit makes it easy to convert colors between different color spaces, allowing you to work with the most appropriate representation for each task.

### Basic Conversions

```swift
// Start with a color in RGB
let blueColor = Color.rgb(red: 0.2, green: 0.4, blue: 0.8)

// Convert to HSL
let hslComponents = blueColor.hslComponents
// Access components
let hue = hslComponents.hue // 220 degrees
let saturation = hslComponents.saturation // 0.6
let lightness = hslComponents.lightness // 0.5

// Convert to HSB
let hsbComponents = blueColor.hsbComponents
// Access components
let brightness = hsbComponents.brightness // 0.8

// Convert to CMYK
let cmykComponents = blueColor.cmykComponents
// Access components
let cyan = cmykComponents.cyan // 0.75
let magenta = cmykComponents.magenta // 0.5
let yellow = cmykComponents.yellow // 0
let black = cmykComponents.black // 0.2

// Convert to LAB
let labComponents = blueColor.labComponents
// Access components
let l = labComponents.l // Lightness
let a = labComponents.a // Green-Red component
let b = labComponents.b // Blue-Yellow component
```

### Converting to Hex Strings

ColorKit provides convenient methods to convert colors to hex string representations:

```swift
let color = Color.rgb(red: 1.0, green: 0.5, blue: 0.0)

// Get a hex string with # prefix
let hexWithHash = color.hexString // "#FF8000"

// Get a hex string without # prefix
let hexRaw = color.hexStringWithoutHash // "FF8000"

// Get a hex string with alpha
let hexWithAlpha = color.hexStringWithAlpha // "#FF8000FF"
```

### Creating New Colors in Different Spaces

You can create new colors by extracting components from one color space and modifying them:

```swift
let originalColor = Color.rgb(red: 0.2, green: 0.5, blue: 0.8)

// Extract HSL components
let hsl = originalColor.hslComponents

// Create a new color with the same hue but different saturation and lightness
let newColor = Color.hsl(
    hue: hsl.hue,
    saturation: hsl.saturation * 0.8, // 80% of original saturation
    lightness: hsl.lightness * 1.2 // 120% of original lightness
)
```

## Working with Color Components

ColorKit allows you to work with individual color components directly:

```swift
let color = Color.rgb(red: 0.5, green: 0.3, blue: 0.7)

// RGB components
let red = color.redComponent // 0.5
let green = color.greenComponent // 0.3
let blue = color.blueComponent // 0.7

// HSL components
let hue = color.hueComponent // in degrees (0-360)
let saturation = color.saturationComponent // 0-1
let lightness = color.lightnessComponent // 0-1

// Alpha component
let alpha = color.alphaComponent // 1.0 (fully opaque)
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