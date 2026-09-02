# Honest perceptual color difference

Status: implemented.

## Problem

`Color.compare(with:)` described its `perceptualDifference` as CIEDE2000 while calculating a normalized Euclidean RGB distance. It also built nonoptional RGB and HSL differences from platform APIs that could silently leave zero components behind when a `SwiftUI.Color` could not be resolved. The comparison UI compounded the mismatch by presenting the value as a percentage on a `0...255` scale.

## Authoritative contract

Add `comparisonResult(with:)` as the authoritative public entry point:

```swift
func comparisonResult(with other: Color) -> ColorComparisonResult

public enum ColorComparisonResult: Sendable {
    case available(ColorDifference)
    case unavailable(ColorComparisonIssues)
}

public struct ColorComparisonIssues: Sendable {
    public let firstColor: [ColorComparisonInputIssue]
    public let secondColor: [ColorComparisonInputIssue]
}

public enum ColorComparisonInputIssue: Sendable {
    case unresolved
    case translucent
    case outOfSRGBGamut
}
```

The receiver is `firstColor`; the argument is `secondColor`. Public construction is unavailable so callers cannot create an unavailable result with no issues, duplicate issues, or contradictory state.

The comparison is atomic. `.available` contains every advertised RGB, HSL, CIEDE2000, contrast, and WCAG measurement; `.unavailable` contains no partial or fabricated measurements.

## Input policy

Resolve each input exactly once through the uncached resolved-sRGBA path. A comparable input must be fixed, finite, opaque, and inside the standard sRGB gamut.

- Failed resolution produces only `.unresolved`, because no other property can be established.
- A resolved input may report `.translucent`, `.outOfSRGBGamut`, or both.
- Validate both inputs and retain their issues independently.
- Do not resolve a dynamic color against ambient appearance.
- Do not composite transparency without an explicit backing color.
- Do not clamp wider-gamut components into sRGB.

Grayscale inputs remain comparable when resolution produces an in-gamut opaque sRGB snapshot.

## Calculation

Derive every available metric from the same two resolved snapshots. Convert nonlinear sRGB through ColorKit's shared sRGB-to-XYZ-to-D65-LAB path, then calculate CIEDE2000 with `kL = kC = kH = 1`.

The CIEDE2000 calculator and its LAB value type remain internal and operate on `Double` values without allocation. They follow Sharma, Wu, and Dalal's implementation notes, including the four-quadrant hue calculation and boundary behavior needed by the supplementary fixtures:

- [Implementation paper](https://www.ece.rochester.edu/~gsharma/ciede2000/ciede2000noteCRNA.pdf)
- [Authors' implementation and test-data page](https://hajim.rochester.edu/ece/sites/gsharma/ciede2000/)

RGB and HSL values remain component differences, not perceptual metrics. Achromatic HSL colors use ColorKit's existing canonical hue coordinate of zero; this is a coordinate convention rather than a failed-conversion fallback.

## Compatibility

Keep `compare(with:)` as a deprecated source-compatibility adapter through ColorKit 2.x and remove it in 3.0, as recorded in [ADR 0001](../adr/0001-preserve-legacy-color-comparison-through-2x.md).

- For comparable inputs, the adapter unwraps the authoritative result and returns a genuine CIEDE2000 `ColorDifference`.
- For unavailable inputs only, it preserves the existing platform-defaulting calculation as an explicitly documented legacy fallback.
- `ColorDifference.perceptualDifferenceMetric` identifies `.ciede2000` or `.legacyRGBDistance`, so fallback provenance is inspectable.
- The legacy RGB distance must never be described as Delta E, CIEDE2000, or perceptual difference.
- ColorKit's own UI, examples, and primary documentation use only `comparisonResult(with:)`.

## Comparison UI

Continue showing both swatches in every state.

For an available result:

- label RGB and HSL sections as component differences;
- display `CIEDE2000 difference (Delta E 00)` as an unbounded numeric value to two decimal places;
- do not render Delta E 00 as a percentage, normalize it by 255, impose a visual maximum, or assign universal qualitative thresholds;
- retain the bounded RGB and HSL component bars.

For an unavailable result, replace the metrics and WCAG badges with one `Comparison unavailable` panel and human-readable per-input issues. Do not show empty bars, zeroes, partial metrics, or repeated unavailable placeholders.

## Validation

- Test all 34 rows of the authors' [supplementary LAB dataset](https://hajim.rochester.edu/ece/sites/gsharma/ciede2000/dataNprograms/ciede2000testdata.txt) against the published four-decimal results.
- Test identity and input-order symmetry separately.
- Test known sRGB integration pairs through `comparisonResult(with:)`.
- Test grayscale resolution and the achromatic HSL convention.
- Test unresolved, translucent, out-of-gamut, combined, and two-input failures without fabricated values.
- Test the deprecated adapter's genuine and legacy metric discriminators.
- Test available and unavailable UI presentation through a small presentation seam rather than fragile view-tree inspection.
- Run the complete macOS and iOS Simulator suites, strict lint, and DocC with warnings treated as errors.

## Documentation

Update public API comments, the DocC utilities article, `README.md`, `README.es-ES.md`, `Sources/ColorKit/Utilities/DOCUMENTATION.md`, and the changelog. Cite the reference paper and test data in the internal calculator and fixture tests. Every example should prefer the result-bearing API and demonstrate explicit unavailable handling.

## Performance

- Resolve each color once and derive all metrics in one pass.
- Keep the pure CIEDE2000 calculation allocation-free.
- Do not add a global result cache unless profiling demonstrates a material repeated-pair benefit.
- Add comparison as a permanent operation in the existing performance benchmark and test its result contract without a machine-specific timing threshold.
- Record release-build comparison throughput during implementation and use the measurement to guide any optimization.

An informational release-build run of 10,000 complete comparisons measured approximately 1.42 million comparisons per second on an Apple M4 Pro. This is implementation evidence, not a portable performance guarantee or test threshold; it did not justify adding cache state to the comparison path.

## Deferred scope

- Appearance-aware resolution of dynamic colors.
- Perceptual comparison of translucent colors over an explicit backing color.
- A public raw-LAB CIEDE2000 API.
- Application-specific CIEDE2000 weighting factors.
- Wider-gamut aggregate comparison.
- Universal similarity labels or pass/fail thresholds.
