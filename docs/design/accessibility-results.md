# ColorKit 2.1 — Verifiable accessibility results

Status: implemented.

The original 2.1 design below is extended by
[Enhancement distance budget](enhancement-distance-budget.md): result-bearing
enhancement now enforces a hard distance budget and reports invalid configuration.

## Problem

ColorKit's existing accessibility helpers return `Color` values. A caller cannot
tell whether a returned color meets the requested WCAG level, is merely the best
available fallback, or could not be measured from the supplied SwiftUI colors.
Some helpers also accept a target level even when their compatibility behavior
cannot guarantee that level.

## Interface

`ColorAccessibilityResult` is the shared result of assessing one foreground
candidate against one background for a requested `WCAGContrastLevel`.

It exposes:

- the candidate `color`;
- the requested `targetLevel` and its `minimumContrastRatio`;
- an optional measured `contrastRatio`;
- a derived `status`: `meetsTarget`, `bestEffort`, `unavailable`, or `invalidConfiguration`;
- optional enhancement distance, requested budget, and derived budget satisfaction;
- a derived `meetsTarget` Boolean for simple branching.

The status is derived from configuration validity, required measurements, and contrast.
An invalid or unavailable enhancement may retain diagnostic contrast, but cannot
claim success. Ordinary assessments continue deriving status from contrast alone.

New source-compatible entry points return this result from:

- direct foreground/background assessment;
- accessibility enhancement;
- black-or-white contrasting endpoint selection;
- accessibility variant suggestions;
- an existing generated palette assessed against an explicit background.

Existing color-returning entry points remain compatibility APIs and preserve their
color selection with respect to this enhancement budget. Budgeted enhancement now
selects within the configured constraint; endpoint and assessed-palette adapters
continue selecting through their existing methods before assessment.

## Measurement contract

- Both colors must resolve to finite, in-gamut nonlinear sRGB snapshots.
- The background must be opaque because contrast against a translucent background
  depends on an additional color behind it.
- A translucent foreground is composited over the opaque background before its
  relative luminance is calculated.
- Dynamic, semantic, pattern, unsupported, nonfinite, out-of-gamut, or translucent
  background inputs produce `unavailable`.
- A measurable ratio below the requested level produces `bestEffort`; this is
  distinct from conversion failure.

This strict measurement is isolated to the new assessed interface. Legacy WCAG
calculation and fallback behavior remain unchanged for source and behavior
compatibility.

## Palette contract

`generateAssessedPalette(from:against:)` preserves the existing palette generation
algorithm and ordering, then assesses every returned color against the explicit
background. It does not claim pairwise contrast between palette entries and does
not discard best-effort or unavailable entries. Callers can filter on
`meetsTarget` without losing diagnostic evidence about the other candidates.

## Deferred work

- Do not redesign the palette-generation search in this release.
- Do not change or remove existing methods before a major release.
- Do not make every palette entry contrast with every other entry.
- Budget semantics are now defined independently in the linked enhancement design;
  legacy color-returning APIs still ignore the setting.
- Do not resolve dynamic colors without an explicit appearance supplied by the
  caller.

## Validation

- Verify passing, best-effort, and unavailable statuses.
- Verify translucent foreground compositing and translucent-background rejection.
- Verify black-or-white selection reports unattainable AAA as best effort.
- Verify budgeted enhancer and variant contracts separately from legacy adapters.
- Verify assessed palette ordering and colors remain identical to the legacy
  generated palette.
- Run the full iOS and macOS suites, including serialized shared-state suites,
  strict SwiftLint, and DocC with warnings as errors.
