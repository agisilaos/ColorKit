# **ColorKit 🎨**  
![Swift Package Manager](https://img.shields.io/badge/SPM-Supported-green)  
![Swift Version](https://img.shields.io/badge/Swift-6.0%2B-blue)  

[English](README.md) | **Español**

Un **paquete ligero de Swift** para **manipulación de colores, temas adaptables y cumplimiento de accesibilidad** en SwiftUI.  

---

## **📦 Instalación**  

ColorKit es compatible con **Swift Package Manager (SPM)**.  

1. Abre tu proyecto en Xcode.  
2. Ve a **File > Add Packages**.  
3. Ingresa la URL:  
   ```
   https://github.com/agisilaos/ColorKit.git
   ```
4. Haz clic en **Add Package**.  

---

## **🚀 Características**  

✅ **Conversión HEX <-> RGB**  
✅ **Soporte para color HSL**  
✅ **Soporte para color CMYK**  
✅ **Soporte para color LAB**  
✅ **Colores adaptables (Modo Claro/Oscuro)**  
✅ **Verificación de contraste WCAG para accesibilidad**  
✅ **Resultados de accesibilidad verificables**
✅ **Generación automática de paletas de colores accesibles**  
✅ **Exportar y compartir paletas de colores**  
✅ **Modificadores de SwiftUI para colores dinámicos**  
✅ **Utilidades de generación de gradientes**  
✅ **Modos de fusión de colores (Superposición, Multiplicar, Trama, etc.)**  
✅ **Sistema de temas integral**  
✅ **Caché de alto rendimiento para operaciones de color**  
✅ **AccessibilityEnhancer para ajustes inteligentes de color**  
✅ **Herramientas avanzadas de depuración de colores**  
✅ **Catálogo de vista previa interactivo**  

---

## **🎨 Uso**  

### **1️⃣ Conversión HEX <-> RGB**  
```swift
let color = Color(hex: "#FF5733")
print(color.hexValue()) // "#FF5733FF"
```

### **2️⃣ Conversión HSL**  
```swift
let hsl = Color.red.hslComponents()
let customColor = Color(hue: 0.5, saturation: 1.0, lightness: 0.5)
```

### **3️⃣ Conversión CMYK**  
```swift
// Convertir de RGB a CMYK
let cmyk = Color.red.cmykComponents()
// (cyan: 0.0, magenta: 1.0, yellow: 1.0, key: 0.0)

// Crear color a partir de valores CMYK
let printColor = Color(cyan: 0.2, magenta: 0.8, yellow: 0.1, key: 0.1)
```

### **4️⃣ Conversión LAB**  
```swift
// Convertir de RGB a LAB
let lab = Color.red.labComponents()
// (L: 53.24, a: 80.09, b: 67.20)

// Crear color a partir de valores LAB
let labColor = Color(L: 50.0, a: 25.0, b: -30.0)
```

### **5️⃣ Colores adaptables (Modo Claro/Oscuro)**  
```swift
Text("Adaptive Text")
    .adaptiveColor(light: .blue, dark: .orange)
```

### **6️⃣ Garantizar alto contraste**  
```swift
Text("Accessible Text")
    .highContrastColor(base: .gray, background: .white)
```

### **7️⃣ Detección de cambios de tema**  
```swift
Text("Theme Change")
    .onAdaptiveColorChange { newScheme in
        print("El esquema de color cambió a: \(newScheme)")
    }
```

### **8️⃣ Utilidades de generación de gradientes**  
```swift
let gradient = Gradient(colors: [.red, .blue])
let linearGradient = LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom)
```

### **9️⃣ Modos de fusión de colores**  
```swift
let baseColor = Color.red
let blendColor = Color.blue
let blendedColor = baseColor.blended(with: blendColor, mode: .overlay)
```

### **🔟 Sistema de temas integral**  
```swift
// Definir un tema personalizado
let oceanTheme = ColorTheme(
    name: "Ocean",
    primary: Color(hex: "#1E88E5"),
    secondary: Color(hex: "#00ACC1"),
    accent: Color(hex: "#7E57C2"),
    background: Color(hex: "#ECEFF1"),
    text: Color(hex: "#263238")
)

// Registrar el tema
ThemeManager.shared.register(theme: oceanTheme)

// Aplicar tema a una jerarquía de vistas
ContentView()
    .withThemeManager()

// Usar colores con tema en las vistas
Text("Themed Text")
    .themedText(.primary)

Button("Primary Button") {}
    .themedButton(.primary)

// Usar colores semánticos
Rectangle()
    .fill(Color.themed(.accent))
```

### **1️⃣1️⃣ Generación automática de paletas de colores accesibles**  
```swift
// Generar una paleta accesible a partir de un color base
let seedColor = Color.blue
let palette = seedColor.generateAccessiblePalette(
    targetLevel: .AA,  // Nivel de cumplimiento WCAG
    paletteSize: 5,    // Número de colores a generar
    includeBlackAndWhite: true
)

// Generar un tema accesible a partir de un color base
let theme = seedColor.generateAccessibleTheme(
    name: "Accessible Blue Theme",
    targetLevel: .AA
)

// Encontrar el extremo blanco o negro con mayor contraste e inspeccionar el resultado
let backgroundColor = Color.purple
let textResult = backgroundColor.accessibleContrastingColorResult(for: .AA)
let textColor = textResult.color

switch textResult.status {
case .meetsTarget:
    if let ratio = textResult.contrastRatio {
        print("Contraste: \(ratio):1")
    }
case .bestEffort:
    print("El mejor extremo disponible no alcanza el objetivo")
case .unavailable:
    print("Resuelve los colores con una apariencia explícita antes de evaluarlos")
}

// Usar la vista de demostración para experimentar con la generación de paletas
struct ContentView: View {
    var body: some View {
        ColorKit.ColorInspector.accessiblePaletteDemoView()
    }
}
```

### **1️⃣2️⃣ Exportar y compartir paletas de colores**  
```swift
// Crear una paleta a partir de colores
let colors: [Color] = [.red, .green, .blue]
let palette = PaletteExporter.createPalette(from: colors)

// Crear una paleta a partir de un tema
let theme = ThemeManager.shared.currentTheme
let themePalette = PaletteExporter.createPalette(from: theme)

// Exportar a varios formatos
if let jsonData = PaletteExporter.export(
    palette: palette,
    to: .json,
    paletteName: "My Palette"
) {
    // Usar los datos (guardar en archivo, compartir, etc.)
}

// Copiar al portapapeles
PaletteExporter.copyToClipboard(
    palette: palette,
    format: .css,
    paletteName: "My Palette"
)

// Exportar paleta accesible
let accessiblePaletteData = seedColor.exportAccessiblePalette(
    targetLevel: .AA,
    to: .svg,
    paletteName: "Accessible Palette"
)

// Agregar funcionalidad de exportación a cualquier vista
myView.paletteExport(colors: colors, paletteName: "RGB Palette")
myView.paletteExport(theme: theme)

// Usar la interfaz de exportación directamente
PaletteExportView(palette: palette, paletteName: "My Palette")
```

### **1️⃣3️⃣ Optimizaciones de rendimiento (v1.4.0+)**  
```swift
// ColorKit almacena automáticamente en caché las operaciones de color costosas
// No se requieren cambios de código para beneficiarse de las mejoras de rendimiento

// La primera llamada calcula y almacena en caché
let lab1 = color1.labComponents()

// La segunda llamada recupera desde la caché (mucho más rápido)
let lab1Again = color1.labComponents()

// Fusión con caché
let blended = color1.blended(with: color2, mode: .overlay, amount: 0.5)

// Interpolación de gradiente con caché
let interpolated = color1.interpolated(with: color2, amount: 0.5, in: .lab)

// Obtener relación de contraste en caché
if let ratio = ColorCache.shared.getCachedContrastRatio(for: color1, with: color2) {
    print("Cached contrast ratio: \(ratio)")
}

// Almacenar una relación de contraste en caché
ColorCache.shared.cacheContrastRatio(for: color1, with: color2, ratio: 4.5)

// Si es necesario, borrar manualmente las cachés
ColorCache.shared.clearCache()
```

Para más detalles sobre las mejoras de rendimiento, consulta [PERFORMANCE_IMPROVEMENTS.md](PERFORMANCE_IMPROVEMENTS.md).

### **1️⃣4️⃣ AccessibilityEnhancer (v1.5.0+)**  
```swift
// Mejorar un color para cumplir con los requisitos de accesibilidad mientras se preserva la identidad de marca
let originalColor = Color.blue
let backgroundColor = Color.white
let targetLevel = WCAGContrastLevel.AA

// Mejora simple con la configuración predeterminada (preserva el matiz)
let enhancedColor = originalColor.enhanced(with: backgroundColor)
```

### **1️⃣5️⃣ Catálogo de vista previa**
El Catálogo de vista previa ofrece demostraciones interactivas de las características de ColorKit:

```swift
import ColorKit

struct ContentView: View {
    var body: some View {
        MainCatalogView()
    }
}
```

Vistas previas disponibles:

1. **BlendingPreview**
   - Fusión de color interactiva con todos los modos de fusión
   - Control en tiempo real de la cantidad de fusión
   - Métricas de rendimiento

2. **GradientPreview**
   - Creación de gradientes lineales, radiales y angulares
   - Gestión de paradas de color
   - Generación de código

3. **ThemePreview**
   - Pruebas de modo claro/oscuro
   - Muestra de componentes de interfaz
   - Generación de código de tema

4. **PerformanceBenchmark**
   - Análisis comparativo de operaciones
   - Métricas de caché
   - Control de iteraciones

5. **ColorDebuggerPreview**
   - Visualización del espacio de color
   - Análisis de componentes
   - Herramientas de comparación visual
   - Monitoreo de rendimiento

6. **PaletteStudioPreview**
   - Generación de paletas
   - Funcionalidad de exportación
   - Reglas de armonía
   - Generación de temas

7. **ColorAnimationPreview**
   - Pruebas de transición de color
   - Modos de interpolación
   - Curvas de temporización
   - Métricas de rendimiento

8. **AccessibilityLabPreview**
   - Verificación de contraste WCAG
   - Estrategias de mejora de color
   - Sugerencias de colores accesibles
   - Directrices educativas

Cada vista previa está diseñada para ayudar a los desarrolladores a comprender y utilizar eficazmente las características de ColorKit. Accede a ellas a través de `MainCatalogView` o de forma individual:

```swift
// Usar vistas previas individuales
BlendingPreview()
GradientPreview()
ThemePreview()
PerformanceBenchmark()
ColorDebuggerPreview()
PaletteStudioPreview()
ColorAnimationPreview()
AccessibilityLabPreview()
```

## **🎨 Herramientas de depuración**  

ColorKit ahora incluye herramientas avanzadas de depuración para ayudar a los desarrolladores a inspeccionar colores, validar el cumplimiento de accesibilidad y garantizar una implementación correcta. Estas herramientas incluyen:

### **Inspección de colores**  

Inspecciona colores en múltiples espacios de color (RGB, HSL, HSB, CMYK, LAB, XYZ):

```swift
// Obtener componentes de color en todos los espacios de color
let components = myColor.colorSpaceComponents()
print(components.description)

// Mostrar inspeccionador visual de color en SwiftUI
ColorSpaceInspectorView(color: myColor)
```

### **Comparación de colores**  

Compara colores sRGB fijos, opacos y dentro de gama mediante diferencias de componentes, métricas WCAG y CIEDE2000:

```swift
let color1 = Color(.sRGB, red: 0.15, green: 0.35, blue: 0.75, opacity: 1)
let color2 = Color(.sRGB, red: 0.55, green: 0.25, blue: 0.65, opacity: 1)

switch color1.comparisonResult(with: color2) {
case .available(let difference):
    print("Diferencia CIEDE2000: \(difference.perceptualDifference)")
case .unavailable(let issues):
    print("Comparación no disponible: \(issues)")
}

// Vista de comparación visual
ColorComparisonView(color1: color1, color2: color2)
```

Los colores dinámicos, translúcidos, no finitos o fuera de la gama sRGB devuelven problemas explícitos en vez de mediciones inventadas.

### **Depuración de accesibilidad WCAG**  

Valida y mejora la accesibilidad de los colores:

```swift
// Verificar cumplimiento WCAG
let compliance = backgroundColor.wcagCompliance(with: textColor)

// Obtener candidatos con resultados explícitos: aprobado, mejor esfuerzo o no disponible
let suggestions = textColor.suggestAccessibleVariantResults(
    with: backgroundColor,
    targetLevel: .AA
)
```

Consulta la [Documentación de depuración de colores](Sources/ColorKit/Utilities/DOCUMENTATION.md) para más detalles.

---

## **🛠 Contribuciones**  
¡Bienvenidas las contribuciones! No dudes en informar de problemas o abrir pull requests.  

## **📜 Licencia**  
Licencia MIT. Consulta `LICENSE` para ver los detalles.  

---
