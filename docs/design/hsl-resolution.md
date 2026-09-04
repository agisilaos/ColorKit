# HSL resolution

Status: implemented.

## Problem

`hslComponents()` read `cgColor?.components` and required at least three of them:

| Input | Reported |
| --- | --- |
| `.blue`, `.orange`, `.green`, `.red`, `.gray` | no value, because they carry no `cgColor` |
| grayscale `CGColor` | no value, because it carries two components |
| Display P3 red | `H: 0°, S: 100%, L: 50%`, identical to sRGB red |

Two adaptive APIs return their input unchanged when HSL is unavailable:

```swift
adjustedForMode(isDarkMode: true) on .orange                        // orange
adjustedForAccessibility(.orange, with: .white, minimumRatio: 4.5)  // orange
```

Both were therefore silent no-ops for every named SwiftUI color and every grayscale
color. A no-op is indistinguishable from "no adjustment was needed", so callers had
no signal that the adaptive behavior they asked for never ran.

## Approach

`hslComponents()` resolves through `AppearanceResolvedSRGBA`, the platform resolution
that already backed `wcagRelativeLuminance()`. See
[ADR 0012](../adr/0012-resolve-hsl-through-the-lenient-policy.md).

`ResolvedSRGBA` could not fix this. It resolves through `cgColor` and reports nothing
for named colors, which is the case that matters most here; using it would have fixed
grayscale while leaving `adjustedForMode(isDarkMode:)` a no-op for `.blue` and its
siblings. The strict and lenient policies now live together in `ResolvedSRGBA.swift`
so the difference between them is visible in one place.

`wcagRGBAComponents()` keeps its behavior and delegates to the same resolution,
substituting all zeros when it fails, so there is one platform resolution rather than
two copies.

## Wider-gamut input

Platform resolution converts a wider-gamut color to sRGB. UIKit preserves extended
components, while AppKit clamps them. `hslComponents()` explicitly clamps the resolved
components to 0-1 before conversion, so Display P3 red still reports
`H: 0°, S: 100%, L: 50%` on both platforms. Other P3 colors can change because their
components are now converted rather than read as though they were sRGB. HSL is defined
on sRGB, so this is the conversion the coordinate space asks for. Clamping belongs to
HSL so the shared resolver preserves the existing legacy WCAG behavior.

## Failure is still reachable

A pattern color cannot be resolved by either platform type, so `hslComponents()` still
reports no value and the `adjustedForAccessibility` early return still has a subject.
SwiftUI does expose a `cgColor` for a pattern color, so it fails platform resolution
without failing every conversion; `unresolvableTestColor()` covers that case.

## Consequences

Dynamic colors now resolve. `Color.primary.hslComponents()` reports the appearance in
effect, and `adjustedForAccessibility` adjusts it instead of returning it unchanged,
which freezes a dynamic color to a fixed one. This is the behavior
[ADR 0010](../adr/0010-resolve-legacy-luminance-leniently.md) already established for
`contrastRatio(with:)`, which resolves `Color.primary` the same way; the two accessors
would otherwise disagree about whether the same color is measurable.

The color inspector is now internally inconsistent. `ColorInspectorPresentation` reads
raw `cgColor` components for its RGB and contrast fields and calls `hslComponents()` for
HSL, so a named or grayscale color shows an HSL row beside "Unavailable" RGB and
contrast rows. The HSL row is the correct one; the others are the surface that has not
been converted yet. Resolving that presentation the same way is the follow-up, and it
also holds the last private copy of the WCAG linearization.

Four tests pinned the previous behavior and were updated:
`AccessibilityAdjustmentTests` split its failure case onto a pattern color and added
coverage for the resolvable ones, `ColorCacheIntegrationTests` now expects grayscale HSL,
and two `ColorInspectorPresentationTests` cases assert the mixed availability above.
