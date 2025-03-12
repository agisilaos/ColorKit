# Accessible Palette Generator

The Accessible Palette Generator is a powerful feature in ColorKit that helps you create color palettes that meet WCAG (Web Content Accessibility Guidelines) accessibility standards.

## Why Accessible Color Palettes Matter

1. **Accessibility Compliance**: Meeting WCAG standards is essential for creating inclusive applications and websites.
2. **User Experience**: Accessible colors ensure that all users, including those with visual impairments, can perceive your content clearly.
3. **Design Consistency**: Automatically generated accessible palettes help maintain visual harmony while ensuring readability.
4. **Development Efficiency**: Creating accessible color combinations manually is time-consuming and error-prone.

## Features

- Generate accessible color palettes from a seed color
- Create complete themes with accessible color combinations
- Find contrasting colors that meet specific WCAG levels
- Customize palette size and accessibility requirements

## Usage Examples

### Generating an Accessible Palette

```swift
// Generate a palette from a blue color that meets AA standards
let blue = Color.blue
let palette = blue.generateAccessiblePalette(targetLevel: .AA, paletteSize: 5)

// Use the palette in your UI
ForEach(0..<palette.count, id: \.self) { index in
    Rectangle()
        .fill(palette[index])
        .frame(height: 50)
}
```

### Creating an Accessible Theme

```swift
// Generate a complete theme from a primary color
let primaryColor = Color.purple
let theme = primaryColor.generateAccessibleTheme(name: "Purple Theme")

// Use the theme in your UI
Text("Heading")
    .foregroundColor(theme.primary.base)
    .background(theme.background.base)

Text("Body text")
    .foregroundColor(theme.text.base)
    .background(theme.background.base)
```

### Finding a Contrasting Color

```swift
// Find a color that contrasts well with a background color
let backgroundColor = Color.blue
let textColor = backgroundColor.accessibleContrastingColor(for: .AA)

// Use the colors in your UI
Text("This text is readable")
    .foregroundColor(textColor)
    .background(backgroundColor)
```

## Using the Demo View

ColorKit includes a demo view that lets you experiment with the Accessible Palette Generator:

```swift
// Show the demo view
struct ContentView: View {
    var body: some View {
        ColorKit.WCAG.accessiblePaletteDemoView()
    }
}
```

## Advanced Configuration

You can customize the palette generation with various options:

```swift
// Create a custom configuration
let configuration = AccessiblePaletteGenerator.Configuration(
    targetLevel: .AAA,          // Target AAA level (highest accessibility)
    paletteSize: 8,             // Generate 8 colors
    includeBlackAndWhite: true  // Include black and white in the palette
)

// Create a generator with the configuration
let generator = AccessiblePaletteGenerator(configuration: configuration)

// Generate a palette
let palette = generator.generatePalette(from: .red)
```

## WCAG Compliance Levels

The generator supports all WCAG contrast levels:

- **AA Large**: 3:1 contrast ratio (for large text)
- **AA**: 4.5:1 contrast ratio (for normal text)
- **AAA Large**: 4.5:1 contrast ratio (for large text)
- **AAA**: 7:1 contrast ratio (for normal text)

## Integration with Design Systems

The Accessible Palette Generator integrates seamlessly with design systems:

```swift
// Generate a theme
let theme = primaryColor.generateAccessibleTheme(name: "Brand Theme")

// Register it with the theme manager
ThemeManager.shared.register(theme: theme)

// Use it in your app
ThemeManager.shared.applyTheme(name: "Brand Theme")
``` 