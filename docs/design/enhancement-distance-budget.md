# Enhancement distance budget

Status: implemented and locally validated; publication pending.

Intended branch: `feature/enhancement-distance-budget`.

Dependency: priority 3's authoritative CIEDE2000 comparison, merged in
`d2a7394` (#48). Implementation must start from a current base containing that
dependency and preserve the glossary changes from this interview.

## Metric and boundaries

- Measure original foreground to candidate using authoritative CIEDE2000 Delta E 00
  over D65 LAB, with reference weighting factors `kL = kC = kH = 1`.
- Accept finite budgets in `0...100`, inclusive. Keep the default at `30`.
- A candidate is within budget exactly when its measured distance is `<=` the
  budget. Do not introduce an acceptance tolerance that permits overshoot.
- Zero permits only the original foreground. A measurable original that already
  passes returns `meetsTarget`; otherwise it returns `bestEffort`.
- The upper bound is a distance limit, not an assertion that every possible pair
  is eligible or that the search is unlimited.
- No fallback may exceed the budget merely to meet the WCAG target.

## Measurement and outcome

Validate configuration before selecting an enhancement candidate. The existing
nonfailable configuration initializer remains source-compatible and does not clamp
or trap on invalid budgets. A negative budget, a value above 100, NaN, or either
infinity produces `ColorAccessibilityResult.Status.invalidConfiguration` in the
result-bearing path. No enhancement search runs; retain the original foreground
and any measurable original contrast for diagnostics, with `meetsTarget == false`.

Budgeted enhancement requires a comparable original foreground under priority 3:
fixed, opaque, finite, in-gamut sRGB convertible to D65 LAB. It also requires
measurable contrast against the supplied background. If these requirements fail,
return the original foreground as `unavailable`, retaining independently available
diagnostics. In particular, a translucent foreground may have a measurable
composited contrast but still lack the standalone perceptual comparison required
for enhancement. This does not change ordinary direct contrast assessment.

The resulting precedence is invalid configuration, unavailable required
measurement, then measured target pass or below-target best effort. Neither an
invalid nor an unavailable outcome reports `meetsTarget`, even if its diagnostic
contrast ratio happens to pass.

## Public evidence

Extend `ColorAccessibilityResult` with optional `perceptualDistance` and
`maximumPerceptualDistance`, and a derived optional
`isWithinPerceptualDistanceBudget`. Ordinary contrast assessments have no budget
metadata. Valid selected enhancement candidates carry measured distance and budget;
budget satisfaction is indeterminate (`nil`) when no budget applies, the budget is
invalid, or distance cannot be measured.

Preserve existing result members and add the explicit `invalidConfiguration`
status. Update documentation and consumers that currently assume status can be
derived from contrast alone or that every unavailable result has no diagnostics.

## Search and selection

1. Examine the original foreground first for every valid, measurable request.
   Return it unchanged immediately if it already passes.
2. Retain existing strategy candidate sets and fallback relationships, rather than
   expanding this feature into a new color-search algorithm. Strategies are
   preferences, not hard preservation guarantees.
3. Examine candidates in stable strategy order. For `minimumChange`, order the
   candidate set by nondecreasing measured Delta E 00, retaining stable order for
   equal distances.
4. Skip an over-budget or unmeasurable intermediate candidate and continue; neither
   condition proves later candidates are ineligible.
5. Return the first eligible candidate meeting the requested contrast target.
6. If none passes, return the highest-contrast examined in-budget candidate as
   `bestEffort`. Break equal-contrast ties by smaller Delta E 00, then stable
   examination order. Including the original prevents regression below its contrast.

Best effort is scoped to the examined strategy candidates, not a global optimizer
or a mathematical proof that no compliant color exists. The same outcome applies
when compliance really is impossible within the budget.

Large-budget parity with legacy selection is a compatibility target where
measurement and ordering agree, not an unconditional guarantee: the agreed
`minimumChange` reordering, authoritative eligibility, and measured contrast can
change result-path selection. Do not make corresponding changes to the legacy
color-returning path as part of this feature.

## API boundary

- `AccessibilityEnhancer.enhanceColorResult` and
  `suggestAccessibleVariantResults` enforce the configured budget.
- The corresponding `Color` result conveniences gain a source-compatible trailing
  `maxPerceptualDistance` argument, defaulting to `30`.
- Legacy `enhanceColor`, `suggestAccessibleVariants`, `Color.enhanced`, and the
  color-returning variant convenience retain budget-ignoring behavior.
- Existing default result calls may now report best effort instead of returning an
  over-budget pass. Document this intentional behavior change.
- Direct assessment, contrasting endpoint selection, and assessed palette APIs do
  not acquire an enhancement budget simply because they share the result type.

## Variant collections

- Each candidate's budget is measured against the original foreground, never the
  previously returned variant.
- Preserve passing and best-effort results; callers can filter on `meetsTarget`.
- Preserve strategy order: preserve hue, preserve saturation, preserve lightness,
  minimum change, then the configured strategy with its opposite preference when
  needed. Do not sort surviving results by status, contrast, or distance.
- Result-bearing variants are duplicates when their pairwise Delta E 00 is `< 5`;
  equality at 5 is distinct. Legacy color-returning variants retain CIE76 behavior.
- Return at most the requested count, possibly fewer after deduplication.
- A nonpositive count returns `[]` before configuration evaluation.
- For a positive count with invalid configuration or unavailable anchor inputs,
  return exactly one diagnostic result with the corresponding status and original
  foreground, rather than an empty collection or duplicated errors.

## Validation and documentation

- Test exact candidate-distance boundaries using the same authoritative measurement:
  just below, equal, and just above; verify no hidden overshoot tolerance.
- Test valid zero and 100 budgets, the default 30, negative values, values above
  100, NaN, and both infinities. Verify invalid configuration takes precedence even
  when the original diagnostic contrast passes.
- Test already-passing originals, zero-budget shortfalls, highest-contrast best
  effort, tie-breaking, and no contrast regression below the original.
- Exercise all four strategies, their fallbacks, minimum-change ordering, and
  continued examination after ineligible intermediate candidates.
- Test unavailable foreground/background measurements and translucent-foreground
  diagnostic contrast without fabricated distance or success.
- Cover singular and convenience APIs, all metadata states, and unchanged direct
  assessments.
- Cover variant counts, stable ordering, pairwise distinctness at its boundary,
  per-original budgets, best-effort retention, and singleton diagnostic failures.
- Retain legacy behavior regressions across ordinary, zero, and invalid budgets.
- Update API comments, the existing accessibility-results design's deferred-budget
  section, user guides, and release notes. Explicitly distinguish result semantics
  from legacy behavior and strategy preference from guarantees.
- Run the repository's relevant iOS/macOS test suites, lint, and documentation
  validation before claiming implementation complete.

### Local validation record

On 2026-09-04, Xcode 26.5 passed 295 tests (385 runs including parameterized cases)
on each of macOS and iPhone 17 / iOS 26.5, plus all 14 shared-state tests separately
on each platform. Strict SwiftLint, DocC with warnings as errors, and whitespace
checks passed. Independent worktree review found no functional defects; follow-up
public-API fixtures cover continuation after an over-budget candidate, stable
endpoint ties, and real colors bracketing the Delta E 00 distinctness threshold.
