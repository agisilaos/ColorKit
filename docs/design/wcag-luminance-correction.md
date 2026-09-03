# WCAG relative luminance correction

Status: implemented.

## Problem

`Color.relativeLuminance()` was documented as following the WCAG 2.1 specification
but applied the 0.2126, 0.7152, and 0.0722 weights directly to gamma-encoded sRGB
components, omitting the linearization step the specification requires. Every API
built on it inherited the error:

- `contrastRatio(with:)`, documented as producing a WCAG ratio from 1 to 21;
- `isDarkColor()`, which chose a contrasting endpoint;
- `adjustedForAccessibility(with:minimumRatio:)` and the `highContrastColor`
  modifier, which searched for a color meeting a requested ratio.

The result understated contrast for every color except pure black and pure white:

| Foreground on white | WCAG | Previous |
| --- | --- | --- |
| `#595959` | 7.00:1 | 2.63:1 |
| `#767676` | 4.54:1 | 2.05:1 |
| `#008000` | 5.14:1 | 2.57:1 |

A caller requesting 4.5:1 for `#595959` on white, a color that passes AAA, saw a
measured 2.63:1, watched the greedy search fail, and received a black or white
fallback in place of a color that was already compliant.

The same method read `cgColor?.components` directly, so a wider-gamut color's
components were weighted as though they were sRGB, and an unresolvable color
returned `0`, which is indistinguishable from a measured black.

A correct implementation already existed in `wcagRelativeLuminance()`, giving the
library two divergent public contrast calculations with no stated relationship.

## Approach

Correct the calculation in place rather than preserving the previous numbers
behind an adapter. See [ADR 0006](../adr/0006-correct-wcag-luminance-in-place.md).

`relativeLuminance()` applies `SRGBColorConversion.wcagRelativeLuminance`, which was
already the single linearizing implementation behind `wcagContrastRatio(with:)` and
`accessibilityResult(against:targetLevel:)`; exposing it internally makes it the
one luminance calculation in the library rather than adding a third.

This change first resolved `relativeLuminance()` strictly, through the new
`relativeLuminanceValue()`. That reported zero for every named SwiftUI color and was
corrected in [opacity-aware WCAG contrast](wcag-contrast-opacity.md); see
[ADR 0010](../adr/0010-resolve-legacy-luminance-leniently.md).

`contrastRatio(with:)` keeps its body and inherits the correction, so it now
agrees with `wcagContrastRatio(with:)` for any color that resolves to finite,
in-gamut sRGB components.

## Dark color classification

`isDarkColor()` compared luminance against 0.5. Under linear luminance that value
has no contrast meaning: mid gray `#808080` has a relative luminance of 0.216, so
the midpoint classified most mid-tones as dark.

The threshold is now the luminance at which black and white contrast equally,
the solution to `(L + 0.05) / 0.05 == 1.05 / (L + 0.05)`, or approximately
0.1791. See [ADR 0007](../adr/0007-classify-dark-colors-at-equal-contrast.md).

This makes `background.isDarkColor() ? .white : .black` select the stronger
contrasting endpoint by construction. The previous behavior had a reachable case
where the fallback was the weaker endpoint, and a test documented it; with the
corrected threshold that case cannot occur, because any background classified
dark caps black's ratio at 4.58:1. The test now asserts the invariant instead.

## Unavailable measurements

`relativeLuminance()` and `contrastRatio(with:)` keep non-optional signatures and
an unresolvable input still contributes `0`. Two additions report that case:

- `relativeLuminanceValue() -> Double?` returns `nil` rather than `0`.
- `contrastResult(with:) -> ColorContrastResult` returns either a
  `ContrastMeasurement` carrying the ratio, both relative luminance values, and
  the passing WCAG levels, or `ContrastIssues` naming why each input failed.

Issues are retained independently for the foreground and background so one does
not hide the other, matching `ColorComparisonIssues`. A translucent foreground is
composited over the background rather than rejected, because the background
supplies the missing context; a translucent background is an issue, because it
does not. Wider-gamut colors are reported rather than clamped into eligibility.

`ContrastMeasurement.passingLevels` can be empty for a measured ratio. An empty
array means the ratio meets no level, which is distinct from an unavailable
measurement.

## Alternatives considered

- **Deprecate `contrastRatio(with:)` toward `wcagContrastRatio(with:)`.** Rejected
  because it would leave the understated calculation reachable and still driving
  `adjustedForAccessibility`, and because a value documented as WCAG that never
  matched WCAG is a defect rather than a compatibility surface.
- **Return an optional from `relativeLuminance()`.** Rejected as source-breaking
  for every caller, including those whose colors always resolve. The optional
  accessor is additive instead.
- **Route `wcagRelativeLuminance()` through `ResolvedSRGBA` in this change.**
  Deferred, and on investigation rejected outright. `ResolvedSRGBA` resolves through
  `cgColor`, which is `nil` for `Color.blue`, `.orange`, `.green`, `.red`, and
  `.gray`, while `wcagRGBAComponents()` resolves those through `UIColor`/`NSColor`.
  Switching would have made the most common SwiftUI colors report a contrast ratio
  of 1. The fail-open behavior that motivated this note came from dropped opacity
  rather than failed resolution, and is corrected in
  [opacity-aware WCAG contrast](wcag-contrast-opacity.md).
