# Recetas de ColorKit

[Volver al README](../README.es-ES.md) · [English](Usage.md)

Ejemplos concretos con las API públicas existentes. Importa `SwiftUI` y `ColorKit` en tu proyecto. Los contratos detallados están en las guías enlazadas, en inglés.

## Convertir colores

Usa resultados por representación cuando importe la disponibilidad. Proporciona un color fijo; captura explícitamente la apariencia deseada para colores dinámicos. Una representación no disponible no descarta las conversiones válidas.

<!-- swift-example: component-results -->
```swift
let conversions = Color(.displayP3, red: 1, green: 0, blue: 0).componentConversionResults()
if case .success(let lab) = conversions.lab {
    print(lab.lightness, lab.a, lab.b)
}
switch conversions.hex {
case .success(let hex): print(hex)
case .failure(let issue): print("Hex no disponible:", issue)
}
```

Consulta los [contratos de componentes](../Sources/ColorKit/Documentation.docc/Color-Spaces-article.md#component-conversion-results) para las reglas de gama, alfa, unidades y errores.

### HSL

El acceso HSL heredado resuelve la apariencia actual y recorta a sRGB. Devuelve `nil` si la resolución falla.

<!-- swift-example: hsl -->
```swift
let hsl = Color.red.hslComponents()
let customColor = Color(hue: 0.5, saturation: 1.0, lightness: 0.5)
```

### CMYK

<!-- swift-example: cmyk -->
```swift
// Convertir de RGB a CMYK
let red = Color(.sRGB, red: 1, green: 0, blue: 0)
let cmyk = red.cmykComponents()
// (cyan: 0.0, magenta: 1.0, yellow: 1.0, key: 0.0)

// Crear color a partir de valores CMYK
let printColor = Color(cyan: 0.2, magenta: 0.8, yellow: 0.1, key: 0.1)
```

### LAB

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

Los accesos CMYK y LAB requieren colores fijos; no eligen una apariencia. Consulta [espacios de color](../Sources/ColorKit/Documentation.docc/Color-Spaces-article.md) para sus distintas políticas de conversión y el soporte Hex.

## Evaluar y ajustar el contraste

El receptor es el primer plano. Los primeros planos translúcidos se componen sobre fondos opacos; los fondos translúcidos no permiten la medición. Superar el contraste no certifica toda la aplicación.

<!-- swift-example: budget -->
```swift
// Verificar cumplimiento WCAG
let textColor = Color(.sRGB, red: 0.6, green: 0.6, blue: 0.6)
let backgroundColor = Color(.sRGB, red: 1, green: 1, blue: 1)
let assessment = textColor.accessibilityResult(against: backgroundColor, targetLevel: .AA)
print(assessment.status)

// Obtener candidatos dentro del límite con resultados explícitos y evidencia de medición
let suggestions = textColor.suggestAccessibleVariantResults(
    with: backgroundColor,
    targetLevel: .AA,
    maxPerceptualDistance: 30
)
```

### Generar un candidato ajustado

<!-- swift-example: enhancement -->
```swift
// Generar un candidato dentro de un límite de distancia e inspeccionar su resultado
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

Comprueba el resultado antes de usar el candidato. El límite de distancia puede impedir alcanzar el objetivo. La mejora heredada que devuelve un color ignora ese límite. Consulta [contratos de mejora](../Sources/ColorKit/Documentation.docc/Accessibility-article.md#verifiable-results).

### Evaluar una paleta generada

<!-- swift-example: accessible-palette -->
```swift
let seedColor = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.8)
let backgroundColor = Color(.sRGB, red: 1, green: 1, blue: 1)
let generator = AccessiblePaletteGenerator(configuration: .init(targetLevel: .AA))
let results = generator.generateAssessedPalette(from: seedColor, against: backgroundColor)
for result in results {
    if result.meetsTarget {
        Text("WCAG AA").foregroundColor(result.color).background(backgroundColor)
    } else {
        print(result.status)
    }
}

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

Las evaluaciones conservan cada resultado y no certifican el contraste entre entradas de la paleta. Consulta [paletas evaluadas](../Sources/ColorKit/Documentation.docc/Accessibility-article.md#assessed-palettes) para las garantías y diferencias heredadas.

Para evaluar tus propios pares explícitos, ejecuta el [informe de pares de contraste](../Examples/ContrastPairReport/README.md) independiente para macOS.

## Comparar colores

La comparación CIEDE2000 requiere entradas fijas, opacas y dentro de la gama sRGB. Las mediciones no disponibles se indican explícitamente.

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

El predicado de similitud heredado usa CIE76, no CIEDE2000; los umbrales no son intercambiables. Consulta los [contratos de comparación](../Sources/ColorKit/Documentation.docc/Utilities-article.md).

## Explorar el catálogo

El catálogo muestra fusión, gradientes, temas, paletas, inspección, animación y accesibilidad. Intégralo en una aplicación SwiftUI:

<!-- swift-example: catalog -->
```swift
import ColorKit

struct ContentView: View {
    var body: some View {
        MainCatalogView()
    }
}
```

O integra una vista previa individual:

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

## Más recetas

- [Temas y colores adaptables](../Sources/ColorKit/Documentation.docc/Theming-article.md)
- [Exportar y compartir paletas](../Sources/ColorKit/Documentation.docc/Utilities-article.md#palette-export)
- [Fusión y gradientes](../Sources/ColorKit/Documentation.docc/Utilities-article.md#gradient-generation)
- [Herramientas de inspección](../Sources/ColorKit/Documentation.docc/Utilities-article.md#inspection-tools)
- [Rendimiento y caché](../PERFORMANCE_IMPROVEMENTS.md)
- [Migración y compatibilidad](../MIGRATION.md)
