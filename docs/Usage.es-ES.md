# Recetas de ColorKit

[Volver al README](../README.es-ES.md) · [English](Usage.md)

Ejemplos concretos con las API públicas existentes. Importa `SwiftUI` y `ColorKit` en tu proyecto. Los contratos detallados están en las guías enlazadas, en inglés.

## ¿Qué API debo usar?

«Fijo» significa que los componentes RGB o de escala de grises están disponibles sin elegir una apariencia. Captura primero explícitamente los colores que dependen de la apariencia; consulta los [contratos de resolución y componentes](../Sources/ColorKit/Documentation.docc/Color-Spaces-article.md#component-conversion-results). Los límites de gama siguientes se aplican después de convertir a sRGB, no al nombre del espacio de color de origen.

| Tarea → método preferido de `Color` | Entradas | Retorno / fallo y límites esenciales |
| --- | --- | --- |
| Conversión de componentes → `componentConversionResults()` | Fijas | Siete campos `Result` independientes: `.success(value)` / `.failure(ColorConversionIssue)`. Sin recorte ni composición; alfa debe ser finito y estar en `0...1`. sRGBA extendido y XYZ/LAB finitos siguen disponibles fuera de gama; HSL/HSB/CMYK/Hex rechazan esas entradas. Solo sRGBA y Hex incluyen alfa. |
| Medición de contraste → `contrastResult(with:)` | Primer plano fijo (receptor), fondo fijo | `ColorContrastResult`: `.available(ContrastMeasurement)` / `.unavailable(ContrastIssues)` con problemas por entrada. Ambos deben estar dentro de gama; el primer plano translúcido se compone sobre un fondo opaco. La relación es `1...21`; `passingLevels` vacío indica una medición inferior a los objetivos. |
| Evaluación de accesibilidad → `accessibilityResult(against:targetLevel:)` | El mismo contrato de primer plano/fondo fijos que para contraste | `ColorAccessibilityResult`: color sin cambios, relación opcional y `.meetsTarget`, `.bestEffort` (medición inferior al objetivo) o `.unavailable`. Sin ajuste ni límite de distancia. |
| Mejora → `enhancementResult(with:targetLevel:strategy:maxPerceptualDistance:)` | Primer plano y fondo fijos, dentro de gama y opacos | `ColorAccessibilityResult`: candidato, contraste/distancia opcionales y estados de evaluación más `.invalidConfiguration`. Límite inclusivo CIEDE2000 ΔE00: finito en `0...100`, predeterminado `30`; cero conserva el original. El mejor esfuerzo abarca los candidatos examinados dentro del límite, no un óptimo global. |
| Comparación perceptual → `comparisonResult(with:)` | Dos colores fijos, dentro de gama y opacos | `ColorComparisonResult`: `.available(ColorDifference)` con CIEDE2000 / `.unavailable(ColorComparisonIssues)`. Atómico: sin mediciones parciales, recorte ni composición alfa. |
| HSL para la apariencia actual → `hslComponents()` | La plataforma resuelve colores con nombre/dinámicos para la apariencia actual | Tupla opcional `(hue, saturation, lightness)` en `0...1`; `nil` si falla la resolución. Recorta los canales de gama amplia a sRGB y omite alfa. Para una entrada fija con fallo de gama explícito, usa `componentConversionResults().hsl`. |

Los componentes cero o ΔE00 cero obtenidos con éxito son valores válidos. No disponible significa ausencia de medición, no cero ni una medición inferior al objetivo. En la mejora, puede conservarse contraste diagnóstico incluso con `.unavailable` o `.invalidConfiguration`; comprueba `status` / `meetsTarget`, no solo la relación. Consulta los [contratos de evaluación y límites](../Sources/ColorKit/Documentation.docc/Accessibility-article.md#verifiable-results).

**Código existente:** `rgbaComponents()` puede sustituir un fallo por `(0, 0, 0, 0)`; `ColorSpaceConverter.getAllColorComponents()` también oculta sustituciones. Ninguno comparte la semántica de resultados por campo. La aritmética XYZ/LAB heredada puede diferir de los resultados por componente. `contrastRatio(with:)` ignora alfa y usa valores de respaldo de luminancia; `wcagContrastRatio(with:)` usa el centinela `1` para entradas translúcidas, indistinguible de una relación medida de 1:1. La mejora heredada que devuelve colores ignora el límite de distancia y no garantiza el objetivo. Consulta los [contratos de conversión](../Sources/ColorKit/Documentation.docc/Color-Spaces-article.md) y la [compatibilidad del contraste](../MIGRATION.md).

`isPerceptuallySimilar(to:threshold:)` conserva CIE76, ignora alfa, acepta entradas extendidas cuando LAB está disponible y devuelve `false` si LAB no está disponible o la distancia es igual al umbral. Sus umbrales no son umbrales CIEDE2000. El método obsoleto `compare(with:)` devuelve CIEDE2000 cuando las entradas lo permiten y, en caso contrario, un valor de respaldo identificado como `.legacyRGBDistance`. Consulta los [contratos de comparación](../Sources/ColorKit/Documentation.docc/Utilities-article.md#color-comparison) y la [migración](../MIGRATION.md).

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
