# Palette Exporter

The Palette Exporter is a powerful feature in ColorKit that allows you to export and share color palettes in various formats.

## Why Export Color Palettes?

1. **Workflow Integration**: Seamlessly integrate your ColorKit palettes with other design tools and applications.
2. **Collaboration**: Share your color palettes with team members, clients, or the design community.
3. **Documentation**: Create visual and code-based documentation of your color systems.
4. **Cross-Platform Use**: Use your palettes across different platforms and environments.

## Supported Export Formats

ColorKit supports exporting palettes in the following formats:

- **JSON**: For integration with web applications and data-driven tools
- **CSS**: For direct use in web development
- **SVG**: For visual representation and documentation
- **Adobe ASE**: For integration with Adobe design tools
- **PNG Image**: For visual sharing and documentation

## Usage Examples

### Basic Export

```swift
// Create a palette
let palette = [
    PaletteExporter.PaletteEntry(name: "Primary", color: .blue),
    PaletteExporter.PaletteEntry(name: "Secondary", color: .green),
    PaletteExporter.PaletteEntry(name: "Accent", color: .orange)
]

// Export to JSON
if let jsonData = PaletteExporter.export(
    palette: palette,
    to: .json,
    paletteName: "My Palette"
) {
    // Use the data
    // e.g., save to file, share, etc.
}
```

### Export from Theme

```swift
// Get a theme
let theme = ThemeManager.shared.currentTheme

// Create a palette from the theme
let palette = PaletteExporter.createPalette(from: theme)

// Export to CSS
if let cssData = PaletteExporter.export(
    palette: palette,
    to: .css,
    paletteName: theme.name
) {
    // Use the data
}
```

### Copy to Clipboard

```swift
// Copy palette to clipboard
let success = PaletteExporter.copyToClipboard(
    palette: palette,
    format: .css,
    paletteName: "My Palette"
)

if success {
    print("Copied to clipboard!")
}
```

## Using the Export UI

ColorKit provides a ready-to-use UI for exporting palettes:

```swift
// Create a palette
let palette = [
    PaletteExporter.PaletteEntry(name: "Primary", color: .blue),
    PaletteExporter.PaletteEntry(name: "Secondary", color: .green),
    PaletteExporter.PaletteEntry(name: "Accent", color: .orange)
]

// Show the export view
PaletteExportView(palette: palette, paletteName: "My Palette")
```

### Adding Export to Your Views

You can easily add export functionality to any view using the provided view modifiers:

```swift
// Add export to a view with a palette
myView.paletteExport(palette: palette, paletteName: "My Palette")

// Add export to a view with colors
myView.paletteExport(colors: [.red, .green, .blue], paletteName: "RGB Palette")

// Add export to a view with a theme
myView.paletteExport(theme: myTheme)
```

## Export Format Details

### JSON Format

The JSON format includes the palette name and an array of colors with their names, hex values, RGB components, and alpha values:

```json
{
  "name": "My Palette",
  "colors": [
    {
      "name": "Primary",
      "hex": "#0000FF",
      "rgb": {
        "r": 0,
        "g": 0,
        "b": 255
      },
      "alpha": 1.0
    },
    // More colors...
  ]
}
```

### CSS Format

The CSS format defines CSS variables for each color:

```css
/* My Palette Color Palette */
:root {
  --primary: #0000FF;
  --secondary: #00FF00;
  --accent: #FFA500;
}
```

### SVG Format

The SVG format creates a visual representation of the palette with color swatches, names, and hex values.

### Adobe ASE Format

The ASE format is compatible with Adobe design tools like Photoshop, Illustrator, and InDesign.

### PNG Image

The PNG format creates a visual image of the palette for easy sharing and documentation. 