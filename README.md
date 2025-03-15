# **ColorKit 🎨**  
![Swift Package Manager](https://img.shields.io/badge/SPM-Supported-green)  
![Swift Version](https://img.shields.io/badge/Swift-5.5%2B-blue)  

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
✅ **Auto-Generate Accessible Color Palettes**  
✅ **Export & Share Color Palettes**  
✅ **SwiftUI Modifiers for Dynamic Colors**  
✅ **Gradient Generation Utilities**  
✅ **Color Blending Modes (Overlay, Multiply, Screen, etc.)**  
✅ **Comprehensive Theming System**  
✅ **High-Performance Caching for Color Operations**  
✅ **AccessibilityEnhancer for Intelligent Color Adjustments**  

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

// Find a contrasting color that meets accessibility standards
let backgroundColor = Color.purple
let textColor = backgroundColor.accessibleContrastingColor(with: backgroundColor, targetLevel: .AA)

// Use the demo view to experiment with palette generation
struct ContentView: View {
    var body: some View {
        ColorKit.WCAG.accessiblePaletteDemoView()
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

// If needed, manually clear caches
ColorCache.shared.clearAllCaches()
```

For more details on performance improvements, see [PERFORMANCE_IMPROVEMENTS.md](PERFORMANCE_IMPROVEMENTS.md).

### **1️⃣4️⃣ AccessibilityEnhancer (v1.5.0+)**  
```swift
// Enhance a color to meet accessibility requirements while preserving brand identity
let originalColor = Color.blue
let backgroundColor = Color.white
let targetLevel = WCAGContrastLevel.AA

// Simple enhancement with default settings (preserves hue)
let enhancedColor = originalColor.enhanced(with: backgroundColor)

// Choose a specific enhancement strategy
let enhancedWithStrategy = originalColor.enhanced(
    with: backgroundColor,
    targetLevel: .AAA,
    strategy: .preserveSaturation
)

// Get multiple accessible color variants that maintain harmony
let variants = originalColor.suggestAccessibleVariants(
    with: backgroundColor,
    targetLevel: .AA,
    count: 3
)

// Use the AccessibilityEnhancer directly for more control
let enhancer = AccessibilityEnhancer(configuration: AccessibilityEnhancer.Configuration(
    targetLevel: .AA,
    strategy: .minimumChange,
    maxPerceptualDistance: 25,
    preferDarker: true
))

let customEnhancedColor = enhancer.enhanceColor(originalColor, with: backgroundColor)

// Use the demo view to experiment with enhancement strategies
struct ContentView: View {
    var body: some View {
        AccessibilityEnhancerDemoView()
    }
}
```

---

## **🛠 Contributing**  
We welcome contributions! Feel free to submit issues or open pull requests.  

## **📜 License**  
MIT License. See `LICENSE` for details.  

---
