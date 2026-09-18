# Explain unavailable results in client code

[Español](unavailable-results.es-ES.md)

Use this recipe when a client needs to explain component conversions and contrast
results. It extends the presentation lessons of the [standalone contrast-pair
report](../../Examples/ContrastPairReport/README.md): name the affected input,
retain independent issues, and distinguish unavailable measurements from measured
shortfalls. It adds no UI or public diagnostic API.

## Developer-facing example

Paste this self-contained example into a client importing SwiftUI and ColorKit.
Its English strings are developer-facing examples, not localized product copy.
The same Swift code appears in both translations. All helpers belong to the client;
there are no library extensions, new error conformances, or automatic repairs.

Each component result is handled independently. Display P3 red retains finite LAB
while Hex is unavailable. The conditional suggestion mentions LAB only after its
success is established; the original typed results remain usable in `conversions`.
The generic display helper also accepts the other component results, with a
representation-specific formatter and units. Successful zeros remain valid values.

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

## Explain only what the diagnostic establishes

- An unresolved input does not prove that appearance capture will help. Only when
  the caller independently knows a color is appearance-dependent should it consider
  capturing a deliberately chosen appearance before retrying. Never infer ambient appearance.
- Out-of-gamut input is not silently clipped. Choosing another input is an explicit
  client decision that changes what is measured; it does not repair the original result.
- For a translucent background, the client must account for any underlying surface
  when supplying the intended opaque background. Merely setting alpha to one is not
  equivalent. A translucent foreground is composited by the contrast API.
- Invalid components justify inspecting the source. Other conversion failures get
  explanations without guessed remedies or promises that retrying will succeed.
- Contrast preserves every issue for each input, including multiple background
  issues. “No issues reported” is not a measured contrast pass. Unavailable output
  contains no ratio or threshold verdict. Available results use the unrounded ratio
  for classification; two-decimal display follows the report's convention.

## End-user copy and localization

The consuming app owns localized strings, terminology, number formatting, and any
available action. Switch on typed diagnostics in the client; do not parse the
English developer messages or expose enum descriptions as product copy.
For example, adapt these strings to the app's context:

| Evidence | English copy | Spanish copy |
| --- | --- | --- |
| Hex unavailable outside sRGB | Hex is unavailable for this color. | Hex no está disponible para este color. |
| LAB conversion actually succeeded | LAB values are still available. | Los valores LAB siguen disponibles. |
| Unresolved contrast foreground | Contrast could not be calculated from this foreground. | No se pudo calcular el contraste con este primer plano. |
| Translucent background | Contrast needs an opaque background. | El contraste necesita un fondo opaco. |

Keep role and representation labels visible. An app may omit a suggestion when it
cannot offer the corresponding action. These examples do not implement localization
or establish a universal error model. A future public diagnostic API requires a
separate decision supported by repeated real client usage.

## Validation

Run `python3 scripts/check_documentation.py` from the repository root. The existing
checker compiles this actual fence in both pages and executes focused checks for
partial conversion success, valid zeros, conservative suggestions, independent
input issues, and measured versus unavailable contrast. No new runner is needed.
