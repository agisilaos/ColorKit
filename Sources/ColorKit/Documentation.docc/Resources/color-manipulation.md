# Color Manipulation

Learn how to manipulate colors by adjusting their components using ColorKit.

## Adjusting Color Components

ColorKit allows you to create new colors by extracting and modifying components in different color spaces:

### HSL Adjustments

```swift
let baseColor = Color(hex: "#3366CC")

// Extract HSL components and modify them
if let hsl = baseColor.hslComponents() {
    // Increase saturation
    let moreSaturated = Color(
        hue: hsl.hue,
        saturation: min(1, hsl.saturation * 1.2), // Increase by 20%
        lightness: hsl.lightness
    )
    
    // Decrease saturation
    let lessSaturated = Color(
        hue: hsl.hue,
        saturation: max(0, hsl.saturation * 0.8), // Decrease by 20%
        lightness: hsl.lightness
    )
    
    // Make it lighter
    let lighter = Color(
        hue: hsl.hue,
        saturation: hsl.saturation,
        lightness: min(1, hsl.lightness * 1.2) // Increase by 20%
    )
    
    // Make it darker
    let darker = Color(
        hue: hsl.hue,
        saturation: hsl.saturation,
        lightness: max(0, hsl.lightness * 0.8) // Decrease by 20%
    )
    
    // Shift hue
    let hueShifted = Color(
        hue: (hsl.hue + 0.25).truncatingRemainder(dividingBy: 1), // Shift by 90 degrees (0.25 in 0-1 range)
        saturation: hsl.saturation,
        lightness: hsl.lightness
    )
}
```

### CMYK Adjustments

```swift
let baseColor = Color(hex: "#3366CC")

// Extract CMYK components and modify them
if let cmyk = baseColor.cmykComponents() {
    // Increase cyan
    let moreCyan = Color(
        cyan: min(1, cmyk.cyan * 1.2), // Increase by 20%
        magenta: cmyk.magenta,
        yellow: cmyk.yellow,
        key: cmyk.key
    )
    
    // Adjust black component
    let darker = Color(
        cyan: cmyk.cyan,
        magenta: cmyk.magenta,
        yellow: cmyk.yellow,
        key: min(1, cmyk.key + 0.1) // Increase black by 10%
    )
    
    // Create a variation
    let variation = Color(
        cyan: max(0, cmyk.cyan - 0.1),
        magenta: min(1, cmyk.magenta + 0.1),
        yellow: cmyk.yellow,
        key: max(0, cmyk.key - 0.05)
    )
}
```

## Converting Between Color Spaces

You can create interesting color variations by converting between color spaces:

```swift
let color = Color(hex: "#3366CC")

// Convert to CMYK, modify, then to HSL
if let cmyk = color.cmykComponents() {
    let modified = Color(
        cyan: cmyk.cyan,
        magenta: cmyk.magenta,
        yellow: cmyk.yellow,
        key: min(1, cmyk.key + 0.1) // Make it darker
    )
    
    // Now convert to HSL and adjust saturation
    if let hsl = modified.hslComponents() {
        let final = Color(
            hue: hsl.hue,
            saturation: min(1, hsl.saturation * 1.1), // Increase saturation
            lightness: hsl.lightness
        )
    }
}
```

Note: All component values in ColorKit are normalized to the 0-1 range. When working with HSL colors, remember that hue is also in 0-1 range (multiply by 360 to get degrees). 