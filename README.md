# **ColorKit 🎨**  
![Swift Package Manager](https://img.shields.io/badge/SPM-Supported-green)  
![Swift Version](https://img.shields.io/badge/Swift-6.0%2B-blue)  

**English** | [Español](README.es-ES.md)

A lightweight **Swift package** for **color manipulation, adaptive themes, and accessibility compliance** in SwiftUI.  

---

## **📦 Installation**  

ColorKit supports **Swift Package Manager (SPM)**.  

1. Open your Xcode project.  
2. Go to **File > Add Packages**.  
3. Enter the URL:  
   ```
   https://github.com/agisilaos/ColorKit.git
   ```
4. Click **Add Package**.  

---

## **🚀 Features**  

✅ **HEX <-> RGB Conversion**  
✅ **HSL Color Support**  
✅ **CMYK Color Support**  
✅ **LAB Color Support**  
✅ **Adaptive Colors (Light/Dark Mode)**  
✅ **WCAG Contrast Checking for Accessibility**  
✅ **Verifiable Accessibility Results**
✅ **Auto-Generate Accessible Color Palettes**  
✅ **Export & Share Color Palettes**  
✅ **SwiftUI Modifiers for Dynamic Colors**  
✅ **Gradient Generation Utilities**  
✅ **Color Blending Modes (Overlay, Multiply, Screen, etc.)**  
✅ **Comprehensive Theming System**  
✅ **High-Performance Caching for Color Operations**  
✅ **AccessibilityEnhancer for Intelligent Color Adjustments**  
✅ **Advanced Color Debugging Tools**  
✅ **Interactive Preview Catalog**  

---

## **🎨 Usage**  

### **1️⃣ HEX <-> RGB Conversion**  
```swift
let color = Color(hex: "#FF5733")
print(color.hexValue()) // "#FF5733FF"
```

### **2️⃣ HSL Conversion**  
```swift
let hsl = Color.red.hslComponents()
let customColor = Color(hue: 0.5, saturation: 1.0, lightness: 0.5)
```

### **3️⃣ CMYK Conversion**  
```swift
// Convert from RGB to CMYK
let cmyk = Color.red.cmykComponents()
// (cyan: 0.0, magenta: 1.0, yellow: 1.0, key: 0.0)

// Create color from CMYK values
let printColor = Color(cyan: 0.2, magenta: 0.8, yellow: 0.1, key: 0.1)
```

### **4️⃣ LAB Conversion**  
```swift
// Convert from RGB to LAB
let lab = Color.red.labComponents()
// (L: 53.24, a: 80.09, b: 67.20)

// Create color from LAB values
let labColor = Color(L: 50.0, a: 25.0, b: -30.0)
```

### **5️⃣ Adaptive Colors (Light/Dark Mode)**  
```swift
Text("Adaptive Text")
    .adaptiveColor(light: .blue, dark: .orange)
```

### **6️⃣ Ensuring High Contrast**  
```swift
Text("Accessible Text")
    .highContrastColor(base: .gray, background: .white)
```

### **7️⃣ Detecting Theme Changes**  
```swift
Text("Theme Change")
    .onAdaptiveColorChange { newScheme in
        print("Color scheme changed to: \(newScheme)")
    }
```

### **8️⃣ Gradient Generation Utilities**  
```swift
let gradient = Gradient(colors: [.red, .blue])
let linearGradient = LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom)
```

### **9️⃣ Color Blending Modes**  
```swift
let baseColor = Color.red
let blendColor = Color.blue
let blendedColor = baseColor.blended(with: blendColor, mode: .overlay)
```

### **🔟 Comprehensive Theming System**  
```swift
// Define a custom theme
let oceanTheme = ColorTheme(
    name: "Ocean",
    primary: Color(hex: "#1E88E5"),
    secondary: Color(hex: "#00ACC1"),
    accent: Color(hex: "#7E57C2"),
    background: Color(hex: "#ECEFF1"),
    text: Color(hex: "#263238")
)

// Register the theme
ThemeManager.shared.register(theme: oceanTheme)

// Apply theme to a view hierarchy
ContentView()
    .withThemeManager()

// Use themed colors in views
Text("Themed Text")
    .themedText(.primary)

Button("Primary Button") {}
    .themedButton(.primary)

// Use semantic colors
Rectangle()
    .fill(Color.themed(.accent))
```

### **1️⃣1️⃣ Auto-Generate Accessible Color Palettes**  
```swift
// Generate an accessible palette from a seed color
let seedColor = Color.blue
let palette = seedColor.generateAccessiblePalette(
    targetLevel: .AA,  // WCAG compliance level
    paletteSize: 5,    // Number of colors to generate
    includeBlackAndWhite: true
)

// Generate an accessible theme from a seed color
let theme = seedColor.generateAccessibleTheme(
    name: "Accessible Blue Theme",
    targetLevel: .AA
)

// Find the stronger black-or-white endpoint and inspect its measured outcome
let backgroundColor = Color.purple
let textResult = backgroundColor.accessibleContrastingColorResult(for: .AA)
let textColor = textResult.color

switch textResult.status {
case .meetsTarget:
    if let ratio = textResult.contrastRatio {
        print("Contrast: \(ratio):1")
    }
case .bestEffort:
    print("Best available endpoint is below the requested target")
case .unavailable:
    print("Resolve the colors in an explicit appearance before assessment")
}

// Use the demo view to experiment with palette generation
struct ContentView: View {
    var body: some View {
        ColorKit.ColorInspector.accessiblePaletteDemoView()
    }
}
```

### **1️⃣2️⃣ Export & Share Color Palettes**  
```swift
// Create a palette from colors
let colors: [Color] = [.red, .green, .blue]
let palette = PaletteExporter.createPalette(from: colors)

// Create a palette from a theme
let theme = ThemeManager.shared.currentTheme
let themePalette = PaletteExporter.createPalette(from: theme)

// Export to various formats
if let jsonData = PaletteExporter.export(
    palette: palette,
    to: .json,
    paletteName: "My Palette"
) {
    // Use the data (save to file, share, etc.)
}

// Copy to clipboard
PaletteExporter.copyToClipboard(
    palette: palette,
    format: .css,
    paletteName: "My Palette"
)

// Export accessible palette
let accessiblePaletteData = seedColor.exportAccessiblePalette(
    targetLevel: .AA,
    to: .svg,
    paletteName: "Accessible Palette"
)

// Add export functionality to any view
myView.paletteExport(colors: colors, paletteName: "RGB Palette")
myView.paletteExport(theme: theme)

// Use the export UI directly
PaletteExportView(palette: palette, paletteName: "My Palette")
```

### **1️⃣3️⃣ Performance Optimizations (v1.4.0+)**  
```swift
// ColorKit automatically caches expensive color operations
// No code changes required to benefit from performance improvements

// First call calculates and caches
let lab1 = color1.labComponents()

// Second call retrieves from cache (much faster)
let lab1Again = color1.labComponents()

// Blending with caching
let blended = color1.blended(with: color2, mode: .overlay, amount: 0.5)

// Gradient interpolation with caching
let interpolated = color1.interpolated(with: color2, amount: 0.5, in: .lab)

// Get cached contrast ratio
if let ratio = ColorCache.shared.getCachedContrastRatio(for: color1, with: color2) {
    print("Cached contrast ratio: \(ratio)")
}

// Cache a contrast ratio
ColorCache.shared.cacheContrastRatio(for: color1, with: color2, ratio: 4.5)

// If needed, manually clear caches
ColorCache.shared.clearCache()
```

For more details on performance improvements, see [PERFORMANCE_IMPROVEMENTS.md](PERFORMANCE_IMPROVEMENTS.md).

### **1️⃣4️⃣ AccessibilityEnhancer (v1.5.0+)**  
```swift
// Generate a candidate while preserving brand identity, then inspect its outcome
let originalColor = Color.blue
let backgroundColor = Color.white
let targetLevel = WCAGContrastLevel.AA

let result = originalColor.enhancementResult(
    with: backgroundColor,
    targetLevel: targetLevel
)
let enhancedColor = result.color

if result.meetsTarget {
    if let ratio = result.contrastRatio {
        print("Measured contrast: \(ratio):1")
    }
}
```

### **1️⃣5️⃣ Preview Catalog**
The Preview Catalog provides interactive demonstrations of ColorKit's features:

```swift
import ColorKit

struct ContentView: View {
    var body: some View {
        MainCatalogView()
    }
}
```

Available previews:

1. **BlendingPreview**
   - Interactive color blending with all blend modes
   - Real-time blend amount control
   - Performance metrics

2. **GradientPreview**
   - Linear, radial, and angular gradient creation
   - Color stop management
   - Code generation

3. **ThemePreview**
   - Light/dark mode testing
   - UI component showcase
   - Theme code generation

4. **PerformanceBenchmark**
   - Operation benchmarking
   - Caching metrics
   - Iteration control

5. **ColorDebuggerPreview**
   - Color space visualization
   - Component analysis
   - Visual comparison tools
   - Performance monitoring

6. **PaletteStudioPreview**
   - Palette generation
   - Export functionality
   - Harmony rules
   - Theme generation

7. **ColorAnimationPreview**
   - Color transition testing
   - Interpolation modes
   - Timing curves
   - Performance metrics

8. **AccessibilityLabPreview**
   - WCAG contrast checking
   - Color enhancement strategies
   - Accessible color suggestions
   - Educational guidelines

Each preview is designed to help developers understand and utilize ColorKit's features effectively. Access them through the `MainCatalogView` or individually:

```swift
// Use individual previews
BlendingPreview()
GradientPreview()
ThemePreview()
PerformanceBenchmark()
ColorDebuggerPreview()
PaletteStudioPreview()
ColorAnimationPreview()
AccessibilityLabPreview()
```

## **🎨 Debugging Tools**  

ColorKit now includes advanced debugging tools to help developers inspect colors, validate accessibility compliance, and ensure correct implementation. These tools include:

### **Color Inspection**  

Inspect colors in multiple color spaces (RGB, HSL, HSB, CMYK, LAB, XYZ):

```swift
// Get color components in all color spaces
let components = myColor.colorSpaceComponents()
print(components.description)

// Display visual color inspector in SwiftUI
ColorSpaceInspectorView(color: myColor)
```

### **Color Comparison**  

Compare two colors across different color spaces and see their differences:

```swift
// Get detailed comparison between two colors
let difference = color1.compare(with: color2)
print(difference.description)

// Visual comparison view
ColorComparisonView(color1: color1, color2: color2)
```

### **WCAG Accessibility Debugging**  

Validate and improve color accessibility:

```swift
// Check WCAG compliance
let compliance = backgroundColor.wcagCompliance(with: textColor)

// Get candidates with explicit pass, best-effort, or unavailable outcomes
let suggestions = textColor.suggestAccessibleVariantResults(
    with: backgroundColor,
    targetLevel: .AA
)
```

See [Color Debugging Documentation](Sources/ColorKit/Utilities/DOCUMENTATION.md) for more details.

---

## **🛠 Contributing**  
We welcome contributions! Feel free to submit issues or open pull requests.  

## **📜 License**  
MIT License. See `LICENSE` for details.  

---
