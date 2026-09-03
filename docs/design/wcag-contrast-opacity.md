# Opacity-aware WCAG contrast and resolved blend operands

Status: implemented.

## Problem

Two unrelated surfaces were still reading color components in ways that produced
confident wrong answers.

### Contrast ignored opacity

`wcagContrastRatio(with:)` obtained components through `wcagRGBAComponents()`,
which returns alpha, and then discarded it. Every translucent color was measured
as though it were fully saturated:

| Foreground on white | Reported | True composited |
| --- | --- | --- |
| black at 10% opacity | 21.00:1 | 1.25:1 |
| `Color.primary` (alpha 0.847) | 21.00:1 | — |

This failed open. A barely visible overlay was reported at the maximum possible
contrast and passed every level including AAA through `wcagCompliance(with:)`.
`Color.primary` behaved the same way, because it resolves to black at 84.7%
opacity rather than to an opaque black.

### Blending and interpolation dropped or misread operands

`blended(with:mode:amount:)` and `interpolateRGB(with:amount:)` read
`cgColor?.components` and required at least three of them. A grayscale `CGColor`
carries two, so the guard failed and both operations silently returned the
receiver:

| Call | Expected | Returned |
| --- | --- | --- |
| `gray.multiply(with: .black)` | black | the original gray |
| `gray.interpolated(with: .white, amount: 0.5)` | a lighter gray | the original gray |

A silent no-op is indistinguishable from a successful blend. Display P3 operands
had the opposite failure: they carry four components, passed the guard, and were
read as though they were sRGB, so P3 red and sRGB red produced identical results.

## Approach

### Contrast

`wcagContrastRatio(with:)` reports 1 when either color is translucent. See
[ADR 0008](../adr/0008-decline-contrast-for-translucent-colors.md).

Compositing the foreground over the background was implemented first and then
rejected. It requires the method to treat its receiver as the foreground and its
argument as the background, but the method has always been symmetric:
`wcagCompliance(with:)` forwards to it, `WCAGColorSuggestions` calls
`baseColor.wcagCompliance(with: candidate)` with the base as the background, and
the shared contrast cache keys an unordered pair, so the two orderings returned
each other's cached results once the ratio stopped being symmetric.

Declining instead keeps the method symmetric and leaves every one of those callers
correct. The composited measurement already exists on the strict path:
`contrastResult(with:)` and `accessibilityResult(against:targetLevel:)` take an
explicit opaque background and composite a translucent foreground over it.

The resolution path is deliberately unchanged. `wcagRGBAComponents()` resolves
through `UIColor`/`NSColor`, which succeeds for `Color.blue`, `.orange`, `.green`,
`.red`, and `.gray`; `ResolvedSRGBA` resolves through `cgColor`, which is `nil`
for all of them. Routing contrast through the stricter path would have made the
most common SwiftUI colors report a ratio of 1.

### Blending and interpolation

Both operations resolve their operands through `ResolvedSRGBA`, which handles
monochrome and converts other RGB spaces to extended sRGB. See
[ADR 0009](../adr/0009-resolve-blend-operands-through-snapshots.md).

Out-of-gamut values are accepted rather than rejected. Requiring
`isInSRGBGamut` would turn the Display P3 error into a silent no-op, which is the
failure this change removes for grayscale. Extended values flow through the blend
arithmetic, so multiplying P3 red by white returns P3 red rather than sRGB red.

Genuinely unresolvable operands, such as dynamic colors with no fixed components,
still return the receiver. Blending has no result type, and adding one is a larger
change than this correction.

## Consequences

`Color.primary` and other translucent colors no longer pass any WCAG level through
`wcagCompliance(with:)`. A fixture in `WCAGColorSuggestionsTests` used
`Color.black.opacity(0.8)` as an already-compliant input; a translucent color can
no longer certify itself, so that fixture is now opaque and the translucent case
is covered separately.

`ColorCacheIntegrationTests` asserted that grayscale blending and interpolation
returned the operand unchanged. That test pinned the silent no-op as intended
behavior, and now compares cold and warm results the way the suite's other cache
tests do.

## Alternatives considered

- **Composite in `wcagContrastRatio(with:)`.** Implemented, then rejected for the
  symmetry and cache reasons above.
- **Fail closed only when resolution fails.** Rejected: `wcagRGBAComponents()`
  succeeds for the colors that were failing open, so this would not have fixed
  either reported case.
- **Deprecate `wcagContrastRatio(with:)` toward the result APIs.** Rejected. It is
  correct for every opaque, resolvable color, which is its normal use, and
  deprecating it would put a warning on internal call sites in
  `AccessiblePaletteGenerator` and `AccessibilityEnhancer` whose only migration is
  `contrastResult(...).ratio ?? 1`.
- **Require the sRGB gamut when blending.** Rejected because it substitutes one
  silent no-op for another.
