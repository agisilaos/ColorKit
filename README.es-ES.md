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

Al actualizar de 2.x a 3.0.0, ajusta el requisito de versión del paquete y consulta
la [guía de migración](MIGRATION.md#colorkit-300). Los switches exhaustivos sobre el
estado de accesibilidad y las referencias guardadas a métodos de mejora requieren
cambios. Las métricas de comparación, los límites de distancia perceptual y las
mediciones de color pueden producir resultados distintos.

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
<!-- swift-example: hsl -->
```swift
let hsl = Color.red.hslComponents()
let customColor = Color(hue: 0.5, saturation: 1.0, lightness: 0.5)
```

`hslComponents()` resuelve colores con nombre y dinámicos para la apariencia actual.
Convierte a sRGB y recorta los canales de gama más amplia a `0...1` antes de la
conversión; la opacidad no forma parte de HSL. Devuelve `nil` si la resolución falla,
por ejemplo, con un color de patrón. A diferencia de HSL, CMYK y LAB requieren
colores fijos y no eligen una apariencia. Consulta la
[guía de migración de HSL](MIGRATION.md#hsl-resolution).

### **3️⃣ Conversión CMYK**  
<!-- swift-example: cmyk -->
```swift
// Convertir de RGB a CMYK
let red = Color(.sRGB, red: 1, green: 0, blue: 0)
let cmyk = red.cmykComponents()
// (cyan: 0.0, magenta: 1.0, yellow: 1.0, key: 0.0)

// Crear color a partir de valores CMYK
let printColor = Color(cyan: 0.2, magenta: 0.8, yellow: 0.1, key: 0.1)
```

### **4️⃣ Conversión LAB**  
<!-- swift-example: lab -->
```swift
// Resolver un color fijo y convertirlo a LAB
let red = Color(.sRGB, red: 1, green: 0, blue: 0)
let lab = red.labComponents()
if let lab {
    print(lab) // (L: 53.24, a: 80.09, b: 67.20)
}

// Crear color a partir de valores LAB
let labColor = Color(L: 50.0, a: 25.0, b: -30.0)
```

`labComponents()` resuelve colores RGB y de escala de grises fijos —incluidos RGB
lineal y Display P3— a sRGB no lineal antes de la conversión. Los canales finitos
fuera de gama se conservan sin recorte. El método devuelve `nil` para los colores
que no puede resolver, como los colores dinámicos sin resolver; el canal alfa no
afecta a las coordenadas LAB.

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
<!-- swift-example: accessible-palette -->
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
let backgroundColor = Color(.sRGB, red: 0.5, green: 0.2, blue: 0.7)
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
case .invalidConfiguration:
    print("Proporciona un límite de distancia perceptual finito entre 0 y 100")
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
<!-- swift-example: enhancement -->
```swift
// Generar un candidato preservando la identidad de marca e inspeccionar su resultado
let originalColor = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.8)
let backgroundColor = Color(.sRGB, red: 1, green: 1, blue: 1)
let targetLevel = WCAGContrastLevel.AA

let result = originalColor.enhancementResult(
    with: backgroundColor,
    targetLevel: targetLevel
)
let enhancedColor = result.color

if result.meetsTarget {
    if let ratio = result.contrastRatio {
        print("Contraste medido: \(ratio):1")
    }
}
```

### **1️⃣5️⃣ Catálogo de vista previa**
El Catálogo de vista previa ofrece demostraciones interactivas de las características de ColorKit:

<!-- swift-example: catalog -->
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

<!-- swift-example: previews -->
```swift
// Usar vistas previas individuales
ColorSpacePreview()
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

<!-- swift-example: comparison -->
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

<!-- swift-example: budget -->
```swift
// Verificar cumplimiento WCAG
let textColor = Color(.sRGB, red: 0.6, green: 0.6, blue: 0.6)
let backgroundColor = Color(.sRGB, red: 1, green: 1, blue: 1)
let compliance = backgroundColor.wcagCompliance(with: textColor)

// Obtener candidatos dentro del límite con resultados explícitos y evidencia de medición
let suggestions = textColor.suggestAccessibleVariantResults(
    with: backgroundColor,
    targetLevel: .AA,
    maxPerceptualDistance: 30
)
```

Las APIs de mejora que devuelven resultados aplican un límite inclusivo CIEDE2000
Delta E 00 respecto al primer plano original (finito, en `0...100`, predeterminado: `30`).
Si ningún candidato examinado alcanza el objetivo, devuelven el mejor esfuerzo dentro
del límite, o un resultado explícito `invalidConfiguration` o `unavailable`.
Las APIs heredadas que devuelven solo colores siguen ignorando el límite.
Consulta la [guía de migración de mejoras](MIGRATION.md#enhancement-distance-budgets).

Consulta la [Documentación de depuración de colores](Sources/ColorKit/Utilities/DOCUMENTATION.md) para más detalles.

---

## **🛠 Contribuciones**  
¡Bienvenidas las contribuciones! No dudes en informar de problemas o abrir pull requests.  

## **📜 Licencia**  
Licencia MIT. Consulta `LICENSE` para ver los detalles.  

---
