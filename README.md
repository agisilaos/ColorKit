# ColorKit 🎨

Color conversion, contrast assessment, and adaptive themes for SwiftUI.

**Swift 6+ · iOS 14+ · macOS 12+**

**English** | [Español](README.es-ES.md)

## Features

- **Color conversion:** Hex, RGB, HSL, HSB, CMYK, XYZ, and LAB, with per-representation availability.
- **Contrast and accessibility:** WCAG assessment, bounded color adjustments, and color-vision deficiency simulation.
- **Color operations:** blending, interpolation, and gradients.
- **Adaptive themes:** light/dark colors, semantic roles, and SwiftUI modifiers.
- **Palettes and export:** generate candidates, assess them, and export or share palettes.
- **Inspection and previews:** visual inspectors, color comparisons, and an interactive catalog.

## Installation

In Xcode, choose **File → Add Packages** and enter:

```text
https://github.com/agisilaos/ColorKit.git
```

Upgrading an existing project? Read the [migration guide](MIGRATION.md) before changing your version requirement.

## Quick start

Measure a foreground against an explicit background. Handle unavailable inputs separately from measured contrast:

<!-- swift-example: contrast -->
```swift
import SwiftUI
import ColorKit

let foreground = Color(.sRGB, red: 0, green: 0, blue: 0)
let background = Color(.sRGB, red: 1, green: 1, blue: 1)

switch foreground.contrastResult(with: background) {
case .available(let measurement):
    print("Contrast:", measurement.ratio)
    print("Meets WCAG AA:", measurement.passingLevels.contains(.AA))
case .unavailable(let issues):
    print("Foreground issues:", issues.foreground)
    print("Background issues:", issues.background)
}
```

Supply fixed colors; resolve appearance-dependent colors explicitly first. A translucent foreground composites over an opaque background. A translucent background is unavailable, so argument order matters.

A contrast pass is not whole-app accessibility certification. When generating adjusted colors, inspect the result before using the candidate.

## Guides and examples

- [Usage guide](docs/Usage.md): conversion, blending, themes, palettes, export, and inspection examples.
- [Color spaces](Sources/ColorKit/Documentation.docc/Color-Spaces-article.md): component results and conversion contracts.
- [Accessibility](Sources/ColorKit/Documentation.docc/Accessibility-article.md): contrast targets, enhancement budgets, and simulation.
- [Theming](Sources/ColorKit/Documentation.docc/Theming-article.md): adaptive and semantic colors.
- [Comparisons and utilities](Sources/ColorKit/Documentation.docc/Utilities-article.md): perceptual differences and inspection.
- [Performance](PERFORMANCE_IMPROVEMENTS.md): caching and measurement guidance.

Run the standalone macOS [contrast pair report](Examples/ContrastPairReport/README.md) to assess your own pairs, or explore the interactive catalog in a SwiftUI view:

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

The standalone report has its own platform requirements; see its run instructions.

## Project

[Contributing](CONTRIBUTING.md) · [Changelog](CHANGELOG.md) · [Migration](MIGRATION.md) · [MIT license](LICENSE)
