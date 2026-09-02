# F08 — Single directional saturation endpoint attempt

Status: accepted and implemented.

## Problem

`WCAGColorSuggestions.generateSaturationAdjustedSuggestions` currently checks saturation factors `0.8`, `0.6`, `0.4`, and `0.2` while fixing HSL lightness at zero when darkening or one when lightening. At either lightness endpoint, HSL construction produces black or white regardless of hue or saturation, so every iteration checks the same effective color.

F08 removes the redundant checks without changing which endpoint is tried or what happens before or after that attempt.

## Agreed scope

- Replace the saturation-adjustment loop with one directional endpoint attempt.
- Preserve the first iteration's construction exactly:
  - multiply the source HSL saturation by `initialSaturationFactor`, which remains `0.8`;
  - use lightness `0` when `needsDarkening` is true and `1` otherwise;
  - construct the candidate with `Color(hue:saturation:lightness:)` using the source hue, adjusted saturation, and directional lightness endpoint.
- Check that candidate once with the existing `isColorCompliant` method.
- Return a one-element array containing the candidate on success and an empty array on failure.
- Remove `saturationStepSize` and comments that describe progressive saturation reduction. Retain the existing private helper and its place in the generation sequence.

The one-attempt body is equivalent to the loop's first pass:

```swift
let adjustedSaturation = hsl.saturation * Self.initialSaturationFactor
let adjustedLightness = needsDarkening ? 0.0 : 1.0
let adjustedColor = Color(
    hue: hsl.hue,
    saturation: adjustedSaturation,
    lightness: CGFloat(adjustedLightness)
)

return isColorCompliant(adjustedColor) ? [adjustedColor] : []
```

This is an implementation target, not authorization to alter the surrounding algorithm.

## Existing behavior to preserve

- An already-compliant input is returned unchanged before HSL conversion or adjustment, for either `preserveHue` value.
- A target whose HSL components are unavailable is returned unchanged.
- Direction remains based solely on `baseColor.wcagRelativeLuminance() > 0.5`: true selects darkening and false selects lightening.
- With `preserveHue == true`, the existing ten-step lightness search runs first with the original hue and saturation. The endpoint attempt runs only if that search returns no suggestion.
- With `preserveHue == false`, the lightness search remains skipped and the single directional endpoint attempt runs immediately.
- Compliance remains `baseColor.wcagCompliance(with: candidate).passes.contains(targetLevel)`.
- An exhausted adjustment still falls back to black when darkening and white when lightening, even if that fallback does not meet the requested level.
- Generation continues to return exactly one color on every existing terminal path.

## Excluded work

- Do not compare black and white or select the stronger endpoint.
- Do not try the endpoint opposite the existing direction.
- Do not add or imply a guarantee that every returned suggestion meets the requested level.
- Do not change the direction threshold, HSL initializer, lightness search, target levels, compliance calculation, fallback, or public API.
- Do not introduce a generalized candidate-search abstraction, strategy type, instrumentation hook, or test-only visibility change.
- Do not redesign hue preservation or other accessibility-adjustment APIs.

## Validation approach

Use focused black-box tests through `WCAGColorSuggestions.generateSuggestions(preserveHue:)`. Establish every fixture's routing preconditions independently so a passing result cannot conceal entry into the wrong branch. Keep the helper private; verify the exactly-one-attempt property structurally in the production diff.

### Direction and hue-preservation matrix

| Direction | `preserveHue` | Required route and assertions |
| --- | --- | --- |
| Darkening | `true` | Use a noncompliant chromatic target against a base whose luminance is greater than `0.5`, with a compliant intermediate lightness candidate. Assert the result moves to lower lightness, is not black, preserves hue using circular hue distance, preserves saturation within conversion tolerance, and meets the requested level. This validates that the unchanged lightness search still wins before the endpoint attempt. |
| Darkening | `false` | Use a noncompliant target against a base whose luminance is greater than `0.5`. Independently assert that black meets the requested level, then assert the result is black. This is a successful directional endpoint attempt with the lightness search skipped. |
| Lightening | `true` | Use a noncompliant chromatic target against a base whose luminance is at most `0.5`, with a compliant intermediate lightness candidate. Assert the result moves to higher lightness, is not white, preserves hue using circular hue distance, preserves saturation within conversion tolerance, and meets the requested level. This validates that the unchanged lightness search still wins before the endpoint attempt. |
| Lightening | `false` | Use a noncompliant target against a sufficiently dark base whose luminance is at most `0.5`. Independently assert that white meets the requested level, then assert the result is white. This is a successful directional endpoint attempt with the lightness search skipped. |

For each case, assert before generation that the target has HSL components, the target initially fails the requested level, and the base luminance selects the stated direction. Assert that generation returns exactly one color.

### Already-compliant inputs

Use already-compliant targets in both light-base and dark-base contexts. For each target, call generation with `preserveHue` set to both `true` and `false` and assert that the exact original `Color` value is returned as the sole result. Include opacity in at least one fixture so the assertion proves the original value was returned rather than reconstructed. Direction is only hypothetical in these cases because the early return must occur before direction selection.

### Failed directional endpoint and fallback

Use a noncompliant target and a base with luminance at most `0.5` but high enough that white fails `.AAA`. Establish these facts before generation:

- the target fails `.AAA`;
- the base selects lightening;
- the white directional endpoint also fails `.AAA`.

Run the fixture with both hue-preservation settings:

- With `preserveHue == false`, the single endpoint attempt fails and generation returns the unchanged white contrast fallback.
- With `preserveHue == true`, the lightness search exhausts, the same endpoint attempt fails, and generation returns the unchanged white contrast fallback.

In both cases, assert that white is the sole result and still fails `.AAA`. This protects fallback behavior without creating a new accessibility guarantee.

A failed darkening endpoint is unreachable under the current public levels: darkening requires base luminance greater than `0.5`, which gives black a contrast ratio greater than `11:1`, above the maximum `.AAA` requirement of `7:1`. Do not fabricate a private level or alter direction merely to add a symmetric failure case.

### Structural and regression checks

- Inspect the helper after implementation: it contains no loop or saturation decrement, constructs one candidate, and performs one compliance branch.
- Confirm `saturationStepSize` is removed and `initialSaturationFactor` remains `0.8`.
- Run the focused suggestion tests and the existing WCAG test suite on macOS and iOS Simulator where available, because SwiftUI color conversion is platform-backed.
- Run the repository's normal lint and formatting checks, including `git diff --check`.

## Documentation boundary

The domain glossary defines already-compliant input, directional endpoint attempt, successful directional endpoint attempt, exhausted adjustment, and contrast fallback. This design note holds F08's localized implementation and validation contract. No ADR is needed because the correction is narrow, unsurprising once the HSL endpoint behavior is understood, and inexpensive to reverse.
