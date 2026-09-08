# Color Spaces

Learn about the different color spaces supported by ColorKit and how to convert between them.

## Overview

ColorKit supports multiple color spaces to give you flexibility in how you work with colors. Each color space has its own unique characteristics and use cases.

### Component conversion results

Use `Color.componentConversionResults()` for independent availability
without fallback coordinates. Every success derives from the same fixed sRGBA
snapshot; a failed bounded representation does not discard finite extended coordinates.

<!-- swift-example: component-results -->
```swift
let conversions = Color(.displayP3, red: 1, green: 0, blue: 0).componentConversionResults()
if case .success(let xyz) = conversions.xyz {
    print(xyz.x, xyz.y, xyz.z)
}
switch conversions.hex {
case .success(let hex): print(hex)
case .failure(.outOfSRGBGamut): print("Hex would require clipping")
case .failure(let issue): print(issue)
}
```

| Field | Meaning and units | Limits |
| --- | --- | --- |
| `srgba` | Nonlinear extended sRGB, separate unpremultiplied alpha | Finite RGB, possibly outside 0–1; alpha 0–1 |
| `hsl` | Hue in turns `[0,1)`, saturation/lightness fractions 0–1 | In-gamut sRGB only; achromatic hue is zero |
| `hsb` | HSV coordinates, named HSB; hue in turns `[0,1)`, saturation/brightness 0–1 | In-gamut sRGB only; brightness is max(R,G,B), achromatic hue is zero |
| `cmyk` | Algebraic complements in 0–1, black K = 1 − max(R,G,B) | In-gamut sRGB only; no ink/printer profile or print-fidelity claim |
| `xyz` | CIE XYZ, D65, reference-white Y = 100 | Finite output, not percentages or bounded to 100 |
| `lab` | CIE L*a*b*, D65 white (95.047,100,108.883) | Finite output; no forced L*/a*/b* bounds for extended inputs |
| `hex` | Uppercase `#RRGGBBAA`, nearest-byte rounding, ties upward | In-gamut sRGB only; at most 0.5/255 quantization error per channel |

Alpha never premultiplies RGB, even at zero, and no background is assumed. Numeric
fields other than sRGBA omit alpha; keep it alongside the coordinates when needed.
HSL/HSB hue can be multiplied by 360 for degrees and fractions by 100 for percentages.
LAB lightness conventionally ranges from 0 to 100 for ordinary surface colors;
extended values are algebraic coordinates, not HDR luminance measurements.

Fixed RGB and grayscale inputs are converted through their source color space to
extended sRGB with relative-colorimetric intent. No gamut mapping, clipping, or
endpoint tolerance is applied, so a tiny platform overshoot can make a bounded
representation unavailable. Equivalent profiles may introduce numerical differences;
results do not promise bitwise equality across OS versions. Legacy caches are not used.

Named and dynamic colors without fixed `cgColor` components report `unresolvedInput`.
The caller must choose and capture an appearance before conversion. For UIKit,
capture `Color(UIColor(color).resolvedColor(with: traits).cgColor)` using the relevant
trait collection. For AppKit, inside the chosen appearance's
`performAsCurrentDrawingAppearance` block, obtain
`NSColor(color).usingColorSpace(.extendedSRGB)?.cgColor` and construct a `Color` from
the non-nil value. Capture failure is still possible. ColorKit does not infer the
missing appearance or retain it after capture.

``ColorConversionIssue`` records the first observable blocker: missing fixed input,
unsupported model, invalid source components, or failed platform conversion affects
all fields. Gamut rejection affects bounded fields; nonfinite XYZ also makes LAB
unavailable. A missing fixed input does not prove that appearance resolution will fix
it. Components sanitized by platform construction are judged as received.

Signed extended-sRGB decoding and exact LAB constants can yield different XYZ/LAB
results from legacy accessors for negative channels or near the LAB breakpoint.
Existing APIs, including ambient appearance resolution and clamping where documented,
remain unchanged and are not deprecated. Successful component conversion does not
establish WCAG contrast or perceptual similarity. Legacy color initializers can clamp
their inputs and are not general inverses of extended coordinates.

### RGB

The RGB color space is the most common color space used in digital displays. It represents colors using red, green, and blue components.

<!-- swift-example: rgb -->
```swift
// Create a color using RGB values
let color = Color(red: 1.0, green: 0.5, blue: 0.2)

// Get RGB components
let (red, green, blue, alpha) = color.rgbaComponents()
print("R: \(red), G: \(green), B: \(blue), A: \(alpha)")
```

`rgbaComponents()` is a nonoptional, lenient extraction API with fallback values.
It is not evidence that strict color resolution or accessibility measurement succeeded.

### HSL

The HSL (Hue, Saturation, Lightness) color space is particularly useful for color manipulation and creating color schemes.

<!-- swift-example: hsl -->
```swift
// Create a color using HSL values
let color = Color(hue: 0.5, saturation: 1.0, lightness: 0.5)

// Get HSL components
if let components = color.hslComponents() {
    print("H: \(components.hue), S: \(components.saturation), L: \(components.lightness)")
}
```

`hslComponents()` resolves named SwiftUI colors, grayscale colors, and dynamic colors
through the platform color types for the current appearance. It converts to sRGB and
clamps wider-gamut channels to `0...1` before HSL conversion. Hue, saturation, and
lightness are normalized to `0...1`; opacity is not part of HSL. It returns `nil` when
the platform cannot resolve the color, such as a pattern color. This lenient policy
does not extend to fixed-color extraction APIs such as CMYK and LAB.

### CMYK

The CMYK (Cyan, Magenta, Yellow, Key) color space is primarily used in print design and production.

```swift
// Create a color using CMYK values
let color = Color(cyan: 0.2, magenta: 0.8, yellow: 0.1, key: 0.1)

// Get CMYK components
if let components = color.cmykComponents() {
    print("C: \(components.cyan), M: \(components.magenta), Y: \(components.yellow), K: \(components.key)")
}
```

### LAB

The LAB color space is designed to be perceptually uniform and is often used in color management systems.

<!-- swift-example: lab -->
```swift
// Create a color using LAB values
let color = Color(L: 50.0, a: 25.0, b: -30.0)

// Get LAB components
if let components = color.labComponents() {
    print("L: \(components.L), a: \(components.a), b: \(components.b)")
}
```

## Color Space Conversion

Hex and CMYK extraction resolve fixed RGB and grayscale colors to nonlinear sRGB.
This includes linear RGB and Display P3 inputs; their raw components are not treated
as sRGB. Hex includes unpremultiplied alpha, and CMYK ignores alpha without compositing
against a background. CMYK uses an arithmetic approximation, not a printer profile.

These optional methods return `nil` for unresolved appearance-dependent colors,
patterns, other source color models, failed conversions, nonfinite components, invalid
alpha, or resolved RGB outside 0–1. They do not clip or apply a range tolerance, even
when platform conversion produces a tiny overshoot near white. Supply an already-resolved
fixed color when appearance matters. Existing nonoptional conversion fallbacks and
cached conversions retain their previous behavior.

LAB extraction also resolves fixed RGB and grayscale colors to nonlinear sRGB before
conversion, but it preserves finite channels outside 0–1 instead of rejecting them.
This allows LAB to describe Display P3 and other colors outside the sRGB gamut without
clipping. Alpha does not affect LAB coordinates, though it remains part of cache identity.
LAB extraction returns `nil` for unresolved dynamic colors, unsupported source models,
failed resolution, nonfinite input, or nonfinite conversion results. It does not choose
an appearance or substitute zero-valued LAB coordinates.

ColorKit handles color space conversions automatically. When you create a color in one color space and request components in another, the conversion is done for you:

```swift
// Create a color in RGB
let color = Color(red: 1.0, green: 0.0, blue: 0.0)

// Get components in different color spaces
let hsl = color.hslComponents()
let cmyk = color.cmykComponents()
let lab = color.labComponents()
```

## Interface Overview

### RGB
- `Color.rgbaComponents()`
- `Color.init(red:green:blue:)`

### HSL
- `Color.hslComponents()`
- `Color.init(hue:saturation:lightness:)`
- `Color.hslString()`

### CMYK
- `Color.cmykComponents()`
- `Color.init(cyan:magenta:yellow:key:)`
- `Color.cmykString()`

### LAB
- `Color.labComponents()`
- `Color.init(L:a:b:)`
- `Color.labString()`

### Utilities
- ``ColorSpaceConverter``
- ``ColorCache``
