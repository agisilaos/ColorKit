# ColorKit 3.1 component-conversion results

Status: agreed design; implementation authorized through the ship-change workflow.

Review fixed point: `1e1e8b6e5f52a67d46a257c17099952204604bb7` (`v3.0.1`),
fetched from `origin/main` on 2026-09-07. Work proceeds on
`chore/conversion-result-design` in an isolated worktree. The baseline was clean;
the initial design documents were the only uncommitted inputs to implementation.

## Agreed contract

`Color.componentConversionResults()` returns independent results derived from one
fixed, uncomposited sRGBA snapshot. Preserve each successful representation even
when others are unavailable. All shipped APIs and legacy behavior remain intact;
no deprecations, replacements, new legacy enum cases, or deployment changes.

```swift
let color = Color(.displayP3, red: 1, green: 0, blue: 0)
let conversions = color.componentConversionResults()
if case .success(let lab) = conversions.lab {
    print(lab.lightness, lab.a, lab.b)
}
switch conversions.hex {
case .success(let hex): print(hex)
case .failure(.outOfSRGBGamut): print("Hex would require clipping")
case .failure(let issue): print(issue)
}
```

The public aggregate is `ColorComponentConversionResults`, with seven read-only
fields using standard Swift `Result<Payload, ColorConversionIssue>`:

| Field | Payload | Units and limits |
| --- | --- | --- |
| `srgba` | `SRGBAComponents` | Nonlinear extended sRGB; finite RGB, separate unpremultiplied alpha 0–1 |
| `hsl` | `HSLComponents` | Hue in turns `[0,1)`; saturation/lightness fractions 0–1 |
| `hsb` | `HSBComponents` | HSV, named HSB; hue in turns `[0,1)`, saturation/brightness fractions 0–1 |
| `cmyk` | `CMYKComponents` | Algebraic sRGB complements, fractions 0–1; no printer/ink profile |
| `xyz` | `XYZComponents` | D65 XYZ, reference-white Y = 100; finite, not bounded to 100 |
| `lab` | `LABComponents` | D65 L*a*b*, white (95.047,100,108.883); finite extended coordinates, no forced bounds |
| `hex` | `String` | Uppercase `#RRGGBBAA`; nearest byte, ties upward |

Numeric fields use `Double`. Payloads are immutable `Sendable, Equatable` data with
internal construction. Aggregate construction is internal to protect the shared-input
invariant. There is no aggregate success flag or throwing conversion method.

### Input and appearance

Accept the existing fixed resolver's source set: `Color.cgColor` with an RGB or
grayscale model, valid component shape, finite components, and valid alpha. Convert
other eligible profiles to extended nonlinear sRGB using Core Graphics relative
colorimetric intent and no options; preserve existing sRGB/extended-sRGB values
directly. Linear RGB, grayscale, P3, and convertible RGB profiles qualify regardless
of cache eligibility. Patterns, CMYK sources, and other models do not.

Named and dynamic colors without fixed components are unavailable, including `.blue`
when it lacks `cgColor`. The caller explicitly captures an appearance-specific fixed
color first. No ambient appearance fallback, light/dark Boolean, or new ColorKit
appearance framework is introduced. Missing fixed components do not prove that
appearance resolution will help. See [ADR 0014](../adr/0014-require-fixed-inputs-for-component-results.md).

UIKit clients capture `Color(UIColor(color).resolvedColor(with: traits).cgColor)`.
AppKit clients obtain `NSColor(color).usingColorSpace(.extendedSRGB)?.cgColor` inside
the chosen appearance's `performAsCurrentDrawingAppearance` block, then wrap a
non-nil value in `Color`. Both recipes still allow unsupported capture/conversion.
The results retain coordinates, not the originating appearance or color identity.
Platform profile conversion is not a bitwise cross-OS reproducibility promise.

### Gamut, alpha, and numerical correctness

Preserve extended sRGBA and finite XYZ/LAB. HSL, HSB, CMYK, and Hex report
`outOfSRGBGamut` whenever RGB is outside `0...1`, even by one representable step.
No clipping, tolerance, or endpoint snapping; platform-converted white can lose
bounded representations. See [ADR 0016](../adr/0016-preserve-gamut-in-component-results.md).

Alpha remains in sRGBA and Hex; other coordinates describe uncomposited RGB and
omit opacity. Transparent red keeps red's coordinates. Invalid alpha makes the
shared snapshot unavailable for every field. Platform-sanitized values are judged
as received; ColorKit cannot reconstruct invalid values erased during construction.
Hex quantization loses at most `0.5/255` per channel and is not gamut mapping.

HSL/HSB use zero hue and saturation for achromatic colors. HSB brightness is maximum
RGB. CMYK uses `K = 1 - max`, `(max-channel)/max` for the complements, and
`(0,0,0,1)` for black. It does not predict printed appearance. Near-black arithmetic
must not divide by the rounded quantity `1-K`; HSL saturation near white must avoid
cancellation, and hue rounded to one turn is normalized to zero.

XYZ uses signed extended-sRGB decoding: `c/12.92` for `abs(c) <= 0.04045`, otherwise
`sign(c) * ((abs(c)+0.055)/1.055)^2.4`. Keep the documented sRGB/D65 matrix and use
exact LAB constants `epsilon = 216/24389`, `kappa = 24389/27`. The LAB transform is
`cbrt(t)` above epsilon, otherwise `(kappa*t+16)/116`, after reference-white scaling.
Finite XYZ is required for LAB; reject nonfinite arithmetic outcomes independently.

These new calculations deliberately differ from the legacy negative-channel decoder
and rounded LAB constants. Preserve the legacy arithmetic and call paths. See
[ADR 0015](../adr/0015-use-correct-extended-conversion-math-in-new-results.md) and
[W3C's conversion reference](https://www.w3.org/TR/css-color-4/#color-conversion-code).
Coordinates are not HDR luminance or evidence of contrast/perceptual similarity;
legacy clamping initializers are not general inverses of extended coordinates.

### Diagnostics

One observable blocker per representation, with deterministic precedence:

1. Missing fixed source: `unresolvedInput`.
2. Missing or unsupported source color model: `unsupportedColorModel`.
3. Malformed/nonfinite source components or invalid alpha: `invalidComponents`.
4. Failed target conversion or invalid converted snapshot: `colorSpaceConversionFailed`.
5. After successful resolution, bounded fields outside sRGB: `outOfSRGBGamut`.
6. Nonfinite conversion arithmetic, including LAB's XYZ dependency: `nonfiniteResult`.

A resolution failure propagates to every field; later failures affect only dependent
representations. Cases are typed diagnostics, not localized messages or guessed
platform causes. Successful zero coordinates remain distinguishable from absence.

## Minimal implementation

Use one internal result-bearing fixed resolver; keep its existing optional method
as an adapter that discards the issue. Preserve its guard ordering, conversion target,
intent, and snapshot validation. One conversion call produces one snapshot, one
shared gamut check, and one XYZ result used by LAB. Standard `map`/`flatMap` propagate
failures. Store the seven results; do not consult mutable legacy caches.

Keep plain payloads and small arithmetic helpers together. No conversion protocol,
strategy registry, appearance layer, lazy state, or cache is needed. One bounded
conversion produces HSL, HSB, CMYK, and Hex, sharing extrema and hue while protecting
rounding edge cases; the legacy HSL helper is unchanged. Corrected XYZ/LAB arithmetic
is isolated from legacy consumers. Changing internal structure is acceptable only with unchanged legacy
outcomes demonstrated by validation.

## Evidence and acceptance

The baseline [aggregate converter](../../Sources/ColorKit/Utilities/ColorSpaceConverter.swift)
mixes appearance RGB/HSL, unchecked platform HSB extraction, strict CMYK, and
XYZ/LAB derived from the RGB fallback. Existing `ColorComponents` does not identify
substitutions. Standalone LAB uses fixed extended sRGBA; Hex/CMYK require bounded
sRGB. Atomic contrast/comparison result types are not suitable aggregate models for
independent conversions. [ADR 0012](../adr/0012-resolve-hsl-through-the-lenient-policy.md)
protects legacy HSL clipping; [ADR 0013](../adr/0013-preserve-shipped-3x-client-contracts.md)
protects shipped 3.x clients. Neither is reversed here.

Implementation acceptance cases:

- Fixed sRGB primaries, black, white, gray, hue wrapping, near-white saturation,
  and near-black CMYK; legitimate zeros are successful values.
- Independent signed XYZ/LAB fixtures, exact LAB constants, and direct P3 reference
  values. The legacy LAB test's production-helper oracle is insufficient for new math.
- Equivalent interior sRGB, linear RGB, grayscale, P3, and Adobe RGB inputs, with
  justified numerical tolerances and source profiles preserved in fixtures.
- Partial success for P3/extended input and arithmetic overflow; strict endpoints
  and adjacent out-of-range values; Hex rounding including alpha.
- Alpha zero, partial, and one: RGB is preserved, non-alpha coordinates agree, no
  compositing; invalid inputs tested directly when construction sanitizes them.
- Named/dynamic inputs and explicit light/dark fixed captures; patterns, unsupported
  models, nonfinite inputs, and observable platform failures diagnosed consistently.
- Cache poisoning cannot affect new results or be overwritten by them.
- Existing resolver/conversion behavior on iOS and macOS, preserved released clients,
  new nonisolated method references, and actual README/DocC client examples compile.

The owning public reference is the [Color Spaces article](../../Sources/ColorKit/Documentation.docc/Color-Spaces-article.md#component-conversion-results).
English/Spanish READMEs, adoption guidance, and the Unreleased changelog accompany
the implementation. Naming was reviewed using the
[Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/);
standard `Result` is a design choice, not a guideline mandate.

## Open questions and validation limits

No core design decision remains open. Shipping still requires the documented gate
and independent review. Platform conversion failures must not be fabricated merely
to exercise a diagnostic; inability to construct a particular failure fixture must
be reported as a coverage limit. Minimum-deployment compilation is not runtime proof
on those OS versions. If validation requires changing an agreed contract, return
that specific decision to the maintainer.
