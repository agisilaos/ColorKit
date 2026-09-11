# ColorKit 🎨

![Swift Package Manager](https://img.shields.io/badge/SPM-Supported-green)
![Swift Version](https://img.shields.io/badge/Swift-6.0%2B-blue)

Conversión de colores, evaluación del contraste y temas adaptables para SwiftUI.

**Swift 6+ · iOS 14+ · macOS 12+**

[English](README.md) | **Español**

## Características

- **Conversión de colores:** Hex, RGB, HSL, HSB, CMYK, XYZ y LAB, con disponibilidad por representación.
- **Contraste y accesibilidad:** evaluación WCAG, ajustes de color acotados y simulación de deficiencias de visión del color.
- **Operaciones de color:** fusión, interpolación y gradientes.
- **Temas adaptables:** colores claros/oscuros, roles semánticos y modificadores de SwiftUI.
- **Paletas y exportación:** generar candidatos, evaluarlos y exportar o compartir paletas.
- **Inspección y vistas previas:** inspectores visuales, comparación de colores y catálogo interactivo.

## Instalación

En Xcode, selecciona **File → Add Packages** e introduce:

```text
https://github.com/agisilaos/ColorKit.git
```

¿Actualizas un proyecto existente? Consulta la [guía de migración](MIGRATION.md) antes de cambiar el requisito de versión.

## Inicio rápido

Mide un primer plano sobre un fondo explícito. Trata los datos no disponibles por separado del contraste medido:

<!-- swift-example: contrast -->
```swift
import SwiftUI
import ColorKit

let foreground = Color(.sRGB, red: 0, green: 0, blue: 0)
let background = Color(.sRGB, red: 1, green: 1, blue: 1)

switch foreground.contrastResult(with: background) {
case .available(let measurement):
    print("Contraste:", measurement.ratio)
    print("Cumple WCAG AA:", measurement.passingLevels.contains(.AA))
case .unavailable(let issues):
    print("Problemas del primer plano:", issues.foreground)
    print("Problemas del fondo:", issues.background)
}
```

Usa colores fijos; resuelve explícitamente los que dependan de la apariencia. Un primer plano translúcido se compone sobre un fondo opaco. Un fondo translúcido no permite medir el contraste: el orden importa.

Superar el contraste no certifica la accesibilidad de toda la aplicación. Al generar colores ajustados, comprueba el resultado antes de usar el candidato.

## Guías y ejemplos

- [Guía de uso](docs/Usage.es-ES.md): ejemplos de conversión, fusión, temas, paletas, exportación e inspección.
- [Espacios de color](Sources/ColorKit/Documentation.docc/Color-Spaces-article.md): resultados por componente y contratos de conversión.
- [Accesibilidad](Sources/ColorKit/Documentation.docc/Accessibility-article.md): objetivos de contraste, límites de ajuste y simulación.
- [Temas](Sources/ColorKit/Documentation.docc/Theming-article.md): colores adaptables y semánticos.
- [Comparaciones y utilidades](Sources/ColorKit/Documentation.docc/Utilities-article.md): diferencias perceptuales e inspección.
- [Rendimiento](PERFORMANCE_IMPROVEMENTS.md): caché y orientación sobre mediciones.

Ejecuta el [informe de pares de contraste](Examples/ContrastPairReport/README.md) para macOS con tus propios pares, o explora el catálogo interactivo en una vista SwiftUI:

<!-- swift-example: catalog -->
```swift
import SwiftUI
import ColorKit

struct CatalogExample: View {
    var body: some View {
        MainCatalogView()
    }
}
```

El informe independiente tiene sus propios requisitos de plataforma; consulta sus instrucciones. Las guías especializadas enlazadas están en inglés.

## Proyecto

[Contribuir](CONTRIBUTING.md) · [Historial de cambios](CHANGELOG.md) · [Migración](MIGRATION.md) · [Licencia MIT](LICENSE)
