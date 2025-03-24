# Color Manipulation

Learn how to manipulate colors by adjusting their properties, creating variations, and applying transformations.

## Adjusting Color Properties

ColorKit provides various methods to adjust color properties like saturation, lightness, and hue:

```swift
let baseColor = Color.rgb(red: 0.2, green: 0.5, blue: 0.8)

// Adjust saturation
let moreSaturated = baseColor.saturated(by: 0.2) // Increase saturation by 20%
let lessSaturated = baseColor.desaturated(by: 0.3) // Decrease saturation by 30%

// Adjust lightness
let lighter = baseColor.lightened(by: 0.15) // Increase lightness by 15%
let darker = baseColor.darkened(by: 0.25) // Decrease lightness by 25%

// Adjust hue
let hueShifted = baseColor.hueRotated(by: 30) // Rotate hue by 30 degrees
```

## Creating Color Variations

You can create variations of colors for different UI states or design needs:

```swift
let primaryColor = Color.rgb(red: 0.2, green: 0.5, blue: 0.8)

// Create tints (lighter variations)
let tint1 = primaryColor.tint(amount: 0.2) // 20% tint
let tint2 = primaryColor.tint(amount: 0.4) // 40% tint

// Create shades (darker variations)
let shade1 = primaryColor.shade(amount: 0.2) // 20% shade
let shade2 = primaryColor.shade(amount: 0.4) // 40% shade

// Create tones (mixed with gray)
let tone1 = primaryColor.tone(amount: 0.3) // 30% tone

// Create a monochromatic palette
let monoPalette = primaryColor.monochromaticVariations(count: 5)
```

## Color Transformations

Apply transformations to create related colors:

```swift
let originalColor = Color.rgb(red: 0.2, green: 0.5, blue: 0.8)

// Get complementary color (opposite on the color wheel)
let complementaryColor = originalColor.complementary()

// Get analogous colors (adjacent on the color wheel)
let analogousColors = originalColor.analogous()

// Get triadic colors (three equally spaced colors on the color wheel)
let triadicColors = originalColor.triadic()

// Get tetradic colors (four equally spaced colors on the color wheel)
let tetradicColors = originalColor.tetradic()

// Create split complementary colors
let splitComplementary = originalColor.splitComplementary()

// Invert the color
let invertedColor = originalColor.inverted()
```

## Blending Colors

Blend colors together using different methods:

```swift
let color1 = Color.rgb(red: 0.8, green: 0.2, blue: 0.2) // Red
let color2 = Color.rgb(red: 0.2, green: 0.2, blue: 0.8) // Blue

// Blend with different methods
let rgbBlend = color1.blended(with: color2, amount: 0.5, mode: .rgb)
let hslBlend = color1.blended(with: color2, amount: 0.5, mode: .hsl)
let labBlend = color1.blended(with: color2, amount: 0.5, mode: .lab)

// Use different blend modes
let screenBlend = color1.blended(with: color2, mode: .screen)
let multiplyBlend = color1.blended(with: color2, mode: .multiply)
let overlayBlend = color1.blended(with: color2, mode: .overlay)
```

## Adjusting Transparency

Modify the transparency of colors:

```swift
let solidColor = Color.rgb(red: 0.2, green: 0.5, blue: 0.8)

// Make it partially transparent
let semiTransparent = solidColor.withAlpha(0.5) // 50% opacity

// Make it more transparent
let moreTransparent = solidColor.moreTransparent(by: 0.2) // Reduce opacity by 20%

// Make it less transparent
let lessTransparent = semiTransparent.lessTransparent(by: 0.2) // Increase opacity by 20%
```

## Color Correction

Apply color correction techniques:

```swift
// Remove color cast
let correctedColor = discoloredImage.removeColorCast()

// Apply gamma correction
let gammaColor = originalColor.gammaAdjusted(gamma: 1.2)

// Color temperature adjustment
let warmerColor = originalColor.temperatureAdjusted(by: 1000) // Warmer by 1000K
let coolerColor = originalColor.temperatureAdjusted(by: -1000) // Cooler by 1000K
``` 