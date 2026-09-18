# Explicar resultados no disponibles en el cliente

[English](unavailable-results.md)

Usa esta receta cuando un cliente necesite explicar conversiones de componentes y
resultados de contraste. Amplía las lecciones de presentación del [informe independiente
de pares de contraste](../../Examples/ContrastPairReport/README.md): identifica la
entrada afectada, conserva los problemas independientes y distingue una medición no
disponible de una medición inferior al objetivo. No añade UI ni una API pública de diagnóstico.

## Ejemplo para desarrolladores

Copia este ejemplo autocontenido en un cliente que importe SwiftUI y ColorKit.
Sus cadenas en inglés son ejemplos para desarrolladores, no texto localizado del
producto. Ambas traducciones contienen el mismo código Swift. Todas las funciones
pertenecen al cliente; no hay extensiones de la biblioteca, nuevas conformidades
con Error ni reparaciones automáticas.

Cada resultado de componentes se trata por separado. El rojo Display P3 conserva
LAB finito mientras Hex no está disponible. La sugerencia condicional menciona LAB
solo después de comprobar su éxito; los resultados tipados originales siguen
utilizables en `conversions`. La función genérica de presentación también acepta
los demás resultados de componentes, con formato y unidades propios de cada
representación. Los ceros obtenidos con éxito siguen siendo valores válidos.

<!-- swift-example: unavailable-results -->
```swift
func conversionExplanation(_ issue: ColorConversionIssue) -> (reason: String, nextStep: String?) {
    switch issue {
    case .unresolvedInput:
        return ("Fixed components could not be obtained.", nil)
    case .unsupportedColorModel:
        return ("The source color space is missing or is neither RGB nor grayscale.", nil)
    case .invalidComponents:
        return ("Source components are malformed, nonfinite, or have alpha outside 0...1.",
                "Inspect the source components and alpha.")
    case .colorSpaceConversionFailed:
        return ("The platform could not produce a valid extended-sRGB snapshot.", nil)
    case .outOfSRGBGamut:
        return ("This representation requires sRGB channels within 0...1; no clipping was applied.", nil)
    case .nonfiniteResult:
        return ("The calculation or a required XYZ dependency produced nonfinite coordinates.", nil)
    }
}

func componentText<Value>(
    _ name: String,
    result: Result<Value, ColorConversionIssue>,
    format: (Value) -> String
) -> String {
    switch result {
    case .success(let value):
        return "\(name): \(format(value))"
    case .failure(let issue):
        let explanation = conversionExplanation(issue)
        return "\(name) unavailable: \(explanation.reason)"
            + (explanation.nextStep.map { " " + $0 } ?? "")
    }
}

let conversions = Color(.displayP3, red: 1, green: 0, blue: 0).componentConversionResults()
let labText = componentText("LAB (D65)", result: conversions.lab) {
    "L*=\($0.lightness), a*=\($0.a), b*=\($0.b)"
}
var hexText = componentText("Hex", result: conversions.hex) { $0 }
if case .failure(.outOfSRGBGamut) = conversions.hex,
   case .success = conversions.lab {
    hexText += " Use the available LAB result if your task supports D65 LAB."
}
print(labText)
print(hexText)

func contrastExplanation(_ issue: ContrastInputIssue) -> (reason: String, nextStep: String?) {
    switch issue {
    case .unresolved:
        return ("Fixed, finite sRGB components could not be obtained.", nil)
    case .outOfSRGBGamut:
        return ("The input is outside the sRGB gamut; no clipping was applied.",
                "Explicitly choose an in-gamut input for this measurement.")
    case .translucentBackground:
        return ("The background is translucent, so the supplied context is insufficient.",
                "Supply an opaque background representing the intended surface.")
    }
}

func inputText(_ role: String, issues: [ContrastInputIssue]) -> String {
    guard !issues.isEmpty else { return "\(role): No issues reported." }
    return issues.map { issue in
        let explanation = contrastExplanation(issue)
        return "\(role): \(explanation.reason)"
            + (explanation.nextStep.map { " " + $0 } ?? "")
    }.joined(separator: "\n")
}

func contrastText(_ result: ColorContrastResult, target: WCAGContrastLevel) -> String {
    switch result {
    case .available(let measurement):
        let outcome = measurement.ratio >= target.minimumRatio ? "Meets target" : "Below target"
        let ratio = measurement.ratio.formatted(.number.precision(.fractionLength(2)))
        return "\(outcome): \(ratio):1; required \(target.minimumRatio):1."
    case .unavailable(let issues):
        return "Contrast unavailable.\n"
            + inputText("Foreground", issues: issues.foreground) + "\n"
            + inputText("Background", issues: issues.background)
    }
}

let foreground = Color(.displayP3, red: 1, green: 0, blue: 0)
let background = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.5)
let contrast = foreground.contrastResult(with: background)
print(contrastText(contrast, target: .AA))
```

## Explica solo lo que demuestra el diagnóstico

- Una entrada sin resolver no demuestra que capturar una apariencia vaya a ayudar.
  Solo si el cliente sabe por otros medios que el color depende de la apariencia
  debería considerar capturar una apariencia elegida explícitamente antes de reintentar.
  Nunca se debe inferir la apariencia del entorno.
- No se recortan silenciosamente las entradas fuera de gama. Elegir otra entrada es
  una decisión explícita del cliente que cambia lo que se mide; no repara el resultado original.
- Con un fondo translúcido, el cliente debe tener en cuenta la superficie subyacente
  al proporcionar el fondo opaco previsto. Cambiar simplemente alfa a uno no es
  equivalente. La API de contraste compone los primeros planos translúcidos.
- Los componentes inválidos justifican inspeccionar el origen. Los demás fallos de
  conversión reciben explicaciones sin remedios supuestos ni promesas de que reintentar funcione.
- El contraste conserva todos los problemas de cada entrada, incluidos varios
  problemas del fondo. «No issues reported» no es una medición que cumpla el objetivo.
  Una salida no disponible no contiene relación ni veredicto sobre el umbral.
  Los resultados disponibles se clasifican con la relación sin redondear; la
  presentación con dos decimales sigue la convención del informe.

## Texto para usuarios y localización

La aplicación cliente es responsable de las cadenas localizadas, la terminología,
el formato numérico y las acciones disponibles. Usa los diagnósticos tipados en
el cliente; no analices los mensajes en inglés para desarrolladores ni expongas
descripciones de enumeraciones como texto del producto. Por ejemplo, adapta estas
cadenas al contexto de la aplicación:

| Evidencia | Texto en inglés | Texto en español |
| --- | --- | --- |
| Hex no disponible fuera de sRGB | Hex is unavailable for this color. | Hex no está disponible para este color. |
| Conversión LAB realizada con éxito | LAB values are still available. | Los valores LAB siguen disponibles. |
| Primer plano sin resolver para contraste | Contrast could not be calculated from this foreground. | No se pudo calcular el contraste con este primer plano. |
| Fondo translúcido | Contrast needs an opaque background. | El contraste necesita un fondo opaco. |

Mantén visibles las etiquetas de entrada y representación. La aplicación puede
omitir una sugerencia si no ofrece la acción correspondiente. Estos ejemplos no
implementan localización ni establecen un modelo universal de errores. Una futura
API pública de diagnóstico requiere una decisión aparte respaldada por usos reales
repetidos en clientes.

## Validación

Ejecuta `python3 scripts/check_documentation.py` desde la raíz del repositorio.
El comprobador existente compila este bloque real en ambas páginas y ejecuta
comprobaciones específicas de éxito parcial de conversión, ceros válidos,
sugerencias conservadoras, problemas independientes por entrada y contraste
medido frente a no disponible. No se necesita un ejecutor nuevo.
