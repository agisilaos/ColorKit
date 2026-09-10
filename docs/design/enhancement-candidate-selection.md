# Enhancement candidate selection

Status: implemented and locally validated on
`refactor/enhancement-candidate-selection`.
Review fixed point: `d2bcf32cc81869f6367ae986058105563c1e334e`.

## Scope and decision

Replace collection/sort/scan in `BudgetedEnhancement` with two request-local
results, `passing` and `bestEffort`, updated in the existing examine closure.
Preserve full traversal, measurement order, fallback evaluation, eligibility,
result construction, and every public result member. Strict comparisons retain
ordering and ties. No selection type, generic framework, measurement injection,
public API, candidate-generation, resolution, numerical, or caching changes.
The shared search comment is updated to describe selection during traversal.

The primary goal is a simpler implementation. No performance improvement is
claimed or benchmarked. Keep the old implementation if complexity moves into
helpers or test machinery. The existing [distance-budget contract](enhancement-distance-budget.md)
and [ADR 0011](../adr/0011-enforce-distance-budgets-in-enhancement-results.md) remain
unchanged; no new domain terms or ADR are needed.

The user approved this design and subsequently approved implementation, logical
commits, and push. The final validation decision accepts complete-result
differential tests plus the ordering proof below, with the exact-tie fixture
limitation stated explicitly. It does not require new production machinery to
make arbitrary synthetic streams injectable.

## Observed selection rules

Sources: `Sources/ColorKit/WCAG/BudgetedEnhancement.swift`,
`EnhancementCandidateSearch.swift`, `ColorAccessibilityResult.swift`,
`AccessibilityEnhancer.swift`, and `WCAGContrastLevel.swift` in the same directory.

| Condition | Current outcome |
| --- | --- |
| Budget nonfinite or outside 0...100 | Original, invalid configuration, original diagnostic contrast if available, nil distance, raw budget retained; no search |
| Valid budget but original contrast or distance unavailable | Original, unavailable, independently available measurements retained; no search |
| Measurable original already passes | Original unchanged, including its measured distance; no search |
| Valid zero, including negative zero, and original falls short | Original best effort; no generated candidates, even possible zero-distance duplicates |
| Intermediate distance unavailable or greater than budget | Skip; do not measure its contrast; continue traversal |
| Intermediate contrast unavailable | Skip; continue traversal |
| Eligible pass, hue/saturation/lightness strategy | First passing result in generation order |
| Eligible pass, minimum-change strategy | Smallest distance among all passes, including nested hue candidates and final fallback; equal distances retain generation order |
| No eligible pass, any strategy | Highest contrast among original and eligible candidates; equal contrast prefers smaller distance; equality of both retains original/earliest generated candidate |

Distance eligibility is exactly `distance <= budget`, without tolerance.
Passing is exactly `contrast >= target.minimumRatio`: AALarge 3, AA and AAALarge
4.5, AAA 7. A later passing candidate's higher contrast never breaks an
equal-distance passing tie. A nonpassing candidate closer than every pass does
not displace a pass.

The original is assessed before generation and seeds best effort. It is not
inserted into the sorted generated array. Search only starts for a positive-budget
original with status best effort. The original-to-original distance is measured,
not replaced with a fabricated zero.

The acceptance callback always returns false. Thus all callbacks run, followed by
one explicit examination of the returned fallback, even if an early candidate
passes. Eligible results are collected in callback order. Only minimum change
sorts them, by `(distance ascending, insertion offset ascending)`. The scan then
returns its first pass or reduces best effort with strict improvements.

## Exact traversal

All direction decisions use the existing legacy background luminance comparison
`> 0.5` (equality takes the lightening direction). Lightness steps clamp to 0...1;
saturation increments clamp to 1. No candidate deduplication occurs here.

| Strategy | Callback sequence when conversions succeed | Returned fallback, examined last |
| --- | --- | --- |
| preserveHue | 20 HSL steps from original HSL. If needDarker equals preferDarker, change lightness by 0.05 in the chosen direction before each callback. Otherwise increase saturation by 0.05 before each callback; after that callback, if saturation > 0.9, advance lightness by 0.05 for the next iteration. Hue stays fixed. | Black if darkening, white otherwise |
| preserveSaturation | 20 HSL steps from original HSL; change lightness by 0.05 and hue by `fmod(hue + 0.02, 1)` before each callback, keeping saturation fixed. | Same directional black/white |
| preserveLightness | 20 HSL steps from original HSL; increase saturation by 0.05 and hue by 0.02 modulo 1 before each callback, keeping lightness fixed. Then run the entire preserveHue path from the original, not the last candidate. | Nested hue path's return |
| minimumChange | 30 LAB steps indexed 0...29 from original LAB. L offset is step times 2 for steps 0...10, step times 4 for 11...29, signed by direction and clamped to 0...100. Add `sin(step * 0.2) * 2` to original a and `cos(step * 0.2) * 2` to original b. Then run the entire preserveHue path from the original. | Nested hue path's return |

In preserveHue's saturation branch, the additional post-callback color construction
is not itself submitted to the callback. In particular, the final post-callback
lightness adjustment is not an extra examined candidate. Preserve this detail.
Minimum-change step zero is not necessarily the original: its b offset is +2.
The 4-point LAB schedule is relative to original L, not cumulative.

If a path's initial HSL/LAB conversion fails, it returns its input original
immediately; the caller still examines that return. Nested hue failure therefore
returns the original after any preceding lightness/LAB callbacks. Repeated clamped
endpoints and a fallback identical to an earlier callback remain separate entries.
Successful ordinary paths produce 21, 21, 41, and 51 examinations respectively,
before eligibility filtering, excluding the original assessment.

Variant deduplication is separate: result variants use strategy order hue,
saturation, lightness, minimum change, then the configured strategy with opposite
preference, stopping at the requested count. Pairwise distance below 5 is a
duplicate. None of that changes in this investigation.

## Replacement

Keep the existing preflight and measurement guards. Seed best effort with the
original result, and leave passing empty. For each eligible candidate:

```text
if candidate passes:
    retain it if no pass exists
    or if minimumChange and its distance is strictly smaller
else:
    retain it as best effort if its contrast is greater
    or its contrast is equal and its distance is strictly smaller
```

Continue every callback with false and examine the returned fallback last.
Return `passing ?? bestEffort`. The original's early-return behavior is unchanged.

## Preservation argument and adversarial examples

After every prefix, passing holds the first pass for the three ordered strategies,
or the earliest minimum-distance pass for minimum change. Replacement uses strict
less-than, so ties cannot evict the earlier entry. At traversal completion this is
exactly the old first pass after its optional stable sort.

If there are no passes, best effort is a reduction by maximum contrast, then
minimum distance. Only equality of both needs ordering; equal-distance entries
retain generation order under the old sort. Seeding with the original preserves
its priority on a complete tie. When any pass exists, best effort is discarded,
so updating it beyond the old scan's stopping point cannot change the result.

Use distinguishable candidate colors/identities even when measurements tie.
For target 4.5 and budget 10, examples `(distance, contrast)` are:

| Ordered stream after below-target original | Expected selection |
| --- | --- |
| A (8, 4.5), B (2, 7) | A for hue/saturation/lightness; B for minimum change |
| A (2, 4.5), B (2, 7) | A for every strategy; higher contrast does not break passing ties |
| A (1, 4.4), B (8, 4.5) | B for every strategy despite larger distance |
| A (8, 4), B (2, 4) | B as best effort, provided original contrast is lower |
| A (2, 4), B (2, 4) | A as best effort, provided original contrast is lower |
| Original (0, 4), duplicate endpoint (0, 4) | Original retains identity |
| Unavailable, over-budget pass (11, 7), eligible B (10, 4.5) | B; both boundaries are inclusive |
| Early pass (8, 5), final fallback (2, 4.5) | Early pass for ordered strategies; fallback for minimum change |
| Early pass (2, 4.5), final fallback (2, 7) | Early pass for every strategy |

## Differential validation

`ReferenceBudgetedEnhancement.swift` is a test-only copy of the complete baseline
selector from the review fixed point, with its original preflight, measurements,
collection, stable sort, and scan. It shares unchanged candidate generation but
never calls production selection. There is no second production path.

`EnhancementSelectionTests.swift` compares all stored and derived public members:
color equality, target level, contrast, distance, raw budget, minimum contrast,
status, meetsTarget, and budget satisfaction. Optional numeric values are compared
by bit pattern, retaining nil, NaN payloads, signed zero, and exact finite evidence.
No numeric tolerance masks a different selected result.

Coverage:

- 4,992 complete-result comparisons: four strategies, both preferences, all four
  WCAG levels, 12 budgets, and 13 foreground/background pairs. Fixtures cover
  passing originals, searching passes, shortfalls, nested fallbacks, endpoints,
  unresolved/out-of-gamut/translucent inputs, and diagnostic precedence.
- Budgets include positive and negative zero, 0.001, 5, 15, 30, 100, negative,
  just above 100, NaN, and both infinities. Additional comparisons cover every
  available generated candidate distance and its adjacent representable budgets
  within 0...100 for a fixed chromatic input, across strategies and preferences.
- 480 ordered variant-array comparisons cover strategy/preference propagation,
  negative/zero/positive counts, deduplication, passes, best effort, and singleton
  diagnostics. Expected entries come from the frozen selector using the unchanged
  variant traversal.
- Existing enhancement-distance-budget tests retain exact inclusive boundaries,
  original ties, fallback continuation, and legacy behavior checks.

### Exact-tie and reachability limitation

A bounded macOS probe across 60 HSL originals, five backgrounds, four strategies,
and both preferences did not find distinguishable Color pairs with exactly equal
measured distance. A targeted gray-0.99/white-fallback probe showed that generated
HSL white equals named Color.white. Replacing those equal endpoints cannot be
observed through Color equality. This does not prove distinct exact ties impossible.

The adversarial table above is a preservation argument, not a claim that those
arbitrary streams were executed through production. Distinguishable exact-distance
passing ties, arbitrary candidate permutations, and unavailable intermediate
measurements have no demonstrated real fixture. Unavailable originals/backgrounds
are tested directly; valid preflight inputs normally produce measurable generated
candidates. The user accepted this empirical coverage gap with the strict-ordering
proof and real-input differential tests. Approximate ties and a copied test-only
version of the new algorithm are not substitutes for production evidence.

## Delivery and validation record

Production and its regression coverage form one logical commit; this design
record follows as a documentation commit. Independent worktree review found no
actionable defects in behavior preservation, test independence, scope, or simplicity.

Local validation passed with Xcode 26.5 and Apple Swift 6.3.2:

- `swift test --filter EnhancementSelectionTests`: all three tests / 24 parameter
  cases passed on macOS, including the comparisons described above.
- `scripts/run_tests.sh --results-dir .build/selection-validation`: iOS 26.5 on
  iPhone 17 and macOS passed, with both shared-state suites serialized separately
  on each platform. Results: `.build/selection-validation/run.Ps7VkO`.
- `swiftlint lint --strict`: zero violations.
- `python3 -m unittest discover -s scripts/tests`: 25 tooling tests passed.
- `python3 scripts/check_compatibility.py --fixture-base d2bcf32cc81869f6367ae986058105563c1e334e`:
  preserved 3.0.0 and 3.1.0 clients and API comparisons passed on macOS and iOS.
- `xcodebuild docbuild -scheme ColorKit -destination 'generic/platform=macOS' -derivedDataPath .build/selection-docc -skipMacroValidation 'OTHER_DOCC_FLAGS=--warnings-as-errors'`:
  documentation built successfully.
- `python3 scripts/check_documentation.py`: public examples and behavior checks passed.
- `swift test --package-path Examples/ContrastPairReport`: six tests passed.
- `swift test --package-path Benchmarks -c release`: five correctness tests passed.
  This validates benchmark fixtures, not a runtime performance improvement.

These are local results, not claims about hosted CI. No screenshots are needed
for this selection-only refactor, and no release or user-facing API documentation
change is required.
