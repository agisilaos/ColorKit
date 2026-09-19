# Cache-boundary audit — 2026-09-19

Audited `origin/main` at `04343043859c4e6d25ad70ff0ee5559277088429`, after fetching and fast-forward synchronization (already current). Blending PR #76 is merged. ADR 0013 preserves shipped 3.x contracts; the initial audit changed no production code. The subsequent approved correction below preserves public declarations and frozen fixtures.

## Verified boundaries

The four public insertion methods write luminance, contrast, blended colors, and interpolated colors. LAB/HSL writers and the independent-cache initializer are internal; tests use `@testable` for those additional boundaries. Eligible keys preserve the original supported color space and exact components, including alpha. Contrast keys are symmetric; blend/interpolation keys are ordered. Stores may evict entries, so every new injection scenario verifies successful retrieval before exercising consumers.

| Injected cache | Affected public operations | Independent operations | Evidence |
| --- | --- | --- | --- |
| Luminance | `wcagRelativeLuminance`, `relativeLuminance`, `isDarkColor`, `suggestedColor`; `contrastRatio` and transitively `adjustedForAccessibility`; suggestion, enhancement, palette/theme generation decisions | `relativeLuminanceValue`, `wcagContrastRatio` (computes directly from RGB), strict contrast/comparison/components, strict endpoint assessment, blend calculations | Inject black with 0.875: legacy luminance = 0.875, suggested endpoint = black, `contrastRatio` against white = 1.05/0.925; strict luminance = 0 and both strict and WCAG contrast = 21. `testInjectedLuminanceDoesNotBecomeContrastMeasurement`. |
| Contrast ratio | `wcagContrastRatio` in both directions, `wcagCompliance`, legacy contrasting endpoint, legacy enhancer/variants, suggestions, palette generation; deprecated comparison's unavailable-input fallback | `contrastRatio` (uses luminance store instead), `contrastResult`, authoritative `comparisonResult`, direct `accessibilityResult`, `accessibleContrastingColorResult`, component conversions and blend calculations | Inject black/white with 1.25: legacy returns 1.25 and fails AA; strict comparison/contrast/accessibility/enhancement of already-compliant black remain 21. `testInjectedContrastDoesNotBecomeStrictMeasurement`. Opacity exception below is a defect, not a preserved contract. |
| Blended color | `blended` and its mode conveniences when amount >= 1; mode and operand order must match | `blendResult`; legacy zero/partial amounts; strict measurements of the original inputs | Inject red into gray × gray multiply: legacy full multiply returns red, strict red channel remains 0.25, partial amount 0.5 remains approximately 0.375. Strengthened existing blend test verifies insertion first. |
| Interpolated color | `interpolated` after amount clamping; `linearGradient` and complementary/analogous/triadic/split-complementary/tetradic gradients through their interpolation paths | Strict measurements/conversions/blending of original inputs; there is no new strict interpolation-result API | Inject red for black → white at 0.5 separately in RGB/HSL/LAB: interpolation and three-step gradient midpoint return red; original black conversion and strict black/white contrast remain unchanged. `testInjectedInterpolationFeedsGradientButNotInputMeasurements`. Existing tests cover clamping/order/exact amounts. |
| HSL/LAB (internal writers only) | Legacy HSL/LAB conversions and their generation/interpolation consumers | All seven `componentConversionResults` representations; strict comparison/contrast and blend calculations | Recognizable HSL (0.4, 0.2, 0.3), LAB (12, 34, 56), plus accepted markers in all four public stores. Red's strict HSL/LAB are correct and every strict component result equals its cleared-cache value. Strengthened component test. |

Direct cache readers were enumerated across `Sources/ColorKit`: HSL, LAB, WCAG compliance, blending, and gradient implementation. Transitive paths were traced through `Color+Adaptive`, `WCAGColorSuggestions`, `EnhancementCandidateSearch`, `AccessibilityEnhancer`, `AccessiblePaletteGenerator`, `Color+AccessiblePalette`, and `ColorComparison`. Table entries outside the named fixtures are source-trace findings, not claims of individually executed tests for every public wrapper.

## Measurement versus generation

`StrictWCAGContrast` and the authoritative comparison calculator resolve inputs directly and use `SRGBColorConversion`; component results and `blendResult` also bypass legacy cache lookup. Their independence is about the supplied inputs: strictly measuring an already cache-influenced generated color correctly measures that generated color.

`enhanceColorResult`, `enhancementResult`, and `suggestAccessibleVariantResults` use strict contrast and perceptual-distance acceptance, but their shared `EnhancementCandidateSearch` still reads legacy HSL/LAB and background luminance. Thus candidate selection is not independent of all cache stores. The new budgeted regression checks strict contrast, strict distance, and budget compliance across all four strategies and variant results under accepted luminance/contrast injections; it deliberately does not require candidate identity to remain unchanged.

A temporary probe reproduced the selection dependency on both platforms:

- Fixed sRGB gray `(0.6, 0.6, 0.6, 1)` against fixed white; `.preserveHue`, distance budget 100, `preferDarker: true`.
- Cold result: approximately `(0.45, 0.45, 0.45)`, ratio `4.75877700127318`.
- Inject white luminance `0.125` and confirm getter acceptance.
- Result: approximately `(0.88, 0.32, 0.32)`, ratio `3.8197320351684954` (honest best effort).

This is a traced legacy generation dependency, not evidence that the strict assessment fabricated a measurement. No regression freezes those particular candidate values.

`generateAssessedPalette` explicitly calls legacy `generatePalette` and then strictly assesses each returned entry. Its candidates can depend on luminance/contrast caches, and generation includes randomness. The new regression checks each returned candidate's assessment directly, not equality between separately generated palettes. Result-returning APIs are not classified by their names.

## Reproduced defect: injected contrast bypasses the opacity guard

On both macOS and iOS, with fixed supported sRGB colors:

```swift
let faintBlack = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1)
let white = Color(.sRGB, red: 1, green: 1, blue: 1)
let cache = ColorCache.shared
cache.clearCache()
defer { cache.clearCache() }
// Cold wcagContrastRatio = 1; passesAAA = false.
cache.cacheContrastRatio(for: faintBlack, with: white, ratio: 21)
// Verify getCachedContrastRatio returns 21 before observing consumers.
// wcagContrastRatio = 21; wcagCompliance.passesAAA = true.
// contrastResult.ratio = 1.2538626591661473.
```

The executable probes used `fixedTestColor` to establish actual CGColor identity. At audited revision `0434304`, `Color+WCAGCompliance.swift` read the cached ratio at line 142 before the opacity guard at line 154. This contradicts its documented promise that translucent inputs are declined and satisfy no WCAG level. Symmetric keys expose the same bypass in the reverse direction. Ordinary cold computation does not populate a translucent ratio; the demonstrated trigger is explicit caller insertion.

Temporary audit probes asserted the documented sentinel and failed on each platform. The approved correction now enforces that sentinel before cache lookup; a permanent regression verifies both operand orders, every compliance flag, persistent direct cache retrieval, and strict composited assessment.

Public cache methods document storage, supported identity, and reuse; the cache design also preserves symmetry, ordering, and interpolation clamping. Documentation does not establish arbitrary caller-supplied values as authoritative measurements or permit them to bypass eligibility rules. These injection tests expose consumers and protect strict measurements; they do not endorse every injected value as a valid color calculation.

## Compatibility decision and correction

The accepted [compatibility policy](../design/release-client-compatibility.md) permits patch corrections that restore documented behavior. Both `v3.0.0` and `v3.1.1` contain the unconditional translucent-input promise and the cache-before-opacity defect. Restoring the sentinel is therefore a documented-contract correction, not a public API removal.

`wcagContrastRatio(with:)` now obtains its existing appearance-resolved RGBA tuples and applies its existing opacity guard before reading the contrast cache. Opaque cache hits, raw cache storage/retrieval, and strict APIs retain their behavior. Translucent entries remain directly retrievable; measurement does not remove or overwrite them. Validation of injected ratios such as NaN or negative values is outside this change.

Callers who injected ratios to bypass translucent eligibility will see a behavior change, including downstream legacy compliance or generation decisions. This restores the shipped promise and is noted in the changelog. Resolving both inputs on opaque cache hits adds component-resolution work. That tradeoff was accepted; this change makes no performance claim and does not introduce another alpha-resolution path.

## Coverage and validation

The change adds six tests and strengthens two existing tests in `ColorCacheIntegrationTests`. Existing setup/teardown clear shared caches before and after each test; shared-cache suites run with parallel testing disabled. Direct cache tests retain independent instances.

Initial audit validation at `0434304`: 27 cache tests passed on macOS and iOS, with strict file lint and diff checks passing. Temporary defect probes failed on both platforms as described above. Exploratory test assumptions about exact partial-blend rounding and equality across random palette generations were corrected before the passing runs.

Delivery base: `cea7451e0b5a1e78c4fa477c01e4f1c14290dfd2`, including merged DX PR #77. The correction does not edit its conformances, introductory examples, documentation checker, or compatibility fixtures. Shared changelog additions preserve its existing entries.

Validation environment: Xcode 26.5 (17F42), macOS 26.6.2 (25G83), iPhone 17 simulator with iOS 26.5. Delivery validation passed:

- The new opacity regression failed before the fix (24 assertion failures across repeated operand orderings), then passed after the guard moved. Focused macOS run: 34 tests passed (`ColorCacheIntegrationTests`, `ColorCacheTests`, `WCAGContrastOpacityTests`).
- `scripts/run_tests.sh --results-dir .build/opacity-test-results`: canonical iOS and macOS runs, then both serialized shared-state runs, passed.
- `python3 scripts/check_compatibility.py`: preserved 3.0.0/3.1.0 clients and API comparisons passed on both platforms, including current blend/DX public clients. Diagnostics: `.build/compatibility/run-etjye0rj`.
- `swiftlint lint --strict`: zero violations in 127 files.
- `python3 -m unittest discover -s scripts/tests`: 38 tests passed.
- `swift test --package-path Benchmarks -c release`: 5 correctness tests passed; no timing benchmark.
- `swift test --package-path Examples/ContrastPairReport`: 6 tests passed.
- `xcodebuild docbuild -scheme ColorKit -destination 'generic/platform=macOS' -derivedDataPath .build/opacity-documentation -skipMacroValidation 'OTHER_DOCC_FLAGS=--warnings-as-errors'`: passed.
- `python3 scripts/check_documentation.py --derived-data .build/opacity-documentation`: 53 public examples compiled, 16 runtime examples verified, generated themes compiled.
- `git diff --check`: passed.

Independent read-only worktree review found no actionable issues. The owning API documentation already states the opacity contract; the changelog records the correction. No public API or frozen compatibility fixture changed.
