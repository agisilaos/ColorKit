# Reproducible palette generation

Status: accepted. Release placement remains undecided; this is not a prerequisite for 3.2. Review baseline: `25e386a`.

## Purpose and API

Allow callers to replay palette generation for tests, previews, and debugging. Add only these overloads:

```swift
public func generatePalette<R: RandomNumberGenerator>(
    from seedColor: Color, using random: inout R
) -> [Color]

public func generateAssessedPalette<R: RandomNumberGenerator>(
    from seedColor: Color, against backgroundColor: Color, using random: inout R
) -> [ColorAccessibilityResult]
```

Caller-owned randomness exposes the missing control over the existing search without committing ColorKit to a seeded-random algorithm. Supply a complete, checked app-owned generator example; do not add a library-owned seed API or public generator type. No new overload on the `Color` convenience or on theme generation, which currently consumes no randomness.

## Replay contract

- Advance the supplied generator directly through `inout`; do not retain, reset, or secretly copy it. Reuse continues the sequence; restoring its initial state permits replay. Protocol conformance alone does not establish determinism.
- Rejected candidates consume randomness. Requests needing no random candidates consume none. Assessment consumes none: equivalent candidate-only and assessed requests leave equivalent final random state, regardless of assessment background.
- Replay requires the same deterministic generator implementation and initial state, fixed color inputs, configuration, ColorKit version, platform, OS/framework versions, Swift toolchain/build settings, and appearance. Appearance also affects named fallback colors, even with fixed caller inputs. Within those conditions, replay includes separate process launches and preserves ordered color components, assessment outcomes, and final random state.
- No identical-output guarantee across platforms, toolchains, OS updates, or ColorKit versions. Exact draw counts are implementation details.
- Preserve existing input handling. Prefer explicit fixed sRGB inputs for replay; callers capture appearance-dependent colors using existing platform APIs when needed. Dynamic inputs remain accepted for generation and can yield unavailable assessments.
- Ordinary cache warming, clearing, or eviction must not change replay. Caller-inserted contrast values can affect legacy candidate selection and are outside this guarantee. Do not clear or bypass the shared cache. Assessment remains independent of legacy cached measurements.

State these conditions beside the public overloads and in the checked example. A seed alone does not identify a palette, and reproducibility does not establish accessibility.

## Behavior preserved by this change

Retain the current search: seed first; optional black then white; accepted candidates in discovery order; at most 100 attempts; then red, green, blue, orange, purple, yellow, and pink fallbacks under the existing similarity checks. Retain the extreme-lightness candidate when the initial contrast is insufficient. These are the implementation baseline, not a permanent algorithm or cross-version output promise.

Preserve partial palettes, configuration normalization, and the existing three initial entries for a size-two request with black and white enabled. Do not pad, truncate, sort, or deduplicate initial entries. Unresolvable HSL retains existing fallback behavior rather than causing a whole-request error.

Assessment retains every candidate in order, including passing, best-effort, and unavailable outcomes. It does not adjust candidates, certify pairwise accessibility, or apply an enhancement budget. Add no new thrown error, result status, or aggregate success flag.

## Compatibility and scope

Preserve shipped signatures, default arguments, method references, return types, and random defaults. Existing methods delegate with a local system generator. Preserve appearance-sensitive generation and strict assessment, including unavailable dynamic inputs and translucent backgrounds. No migration or deprecations.

No generator redesign, new color algorithm, automatic appearance framework, persistence, performance claims, or adjacent size/naming cleanup. No additional ADR is needed for this narrow additive API.

## Client examples

The complete app-owned deterministic generator, reset/replay call, and unavailable-assessment path live in the [checked replay example](../../Sources/ColorKit/Documentation.docc/Accessibility-article.md#replaying-a-palette). Callers inspect each result's status; generation itself has no new failure channel. A translucent assessment background retains candidates with unavailable measurements.

## Implementation and validation

1. Add the two overloads and thread `inout` randomness through the existing helper. Share candidate generation before assessment; keep production behavior and its regression tests together.
2. Use one deterministic/counting test fixture for replay, continuation, zero/rejected draws, candidate/assessment parity, and unavailable backgrounds. Add focused retry/fallback/partial-result and ordinary-cache-state checks; reuse existing assessment coverage. Exact fixture draw counts test the current implementation, not a cross-toolchain contract.
3. Publish one complete checked replay example. Run it twice in separate processes and compare stable component/assessment values and final fixture state using existing documentation tooling, without a new validation package. Run platform tests independently without cross-platform golden-output equality.
4. Verify existing typed/inferred method references, new public call sites, release-client compatibility, relevant macOS/iOS suites, lint, and documentation. Serialize shared-cache tests. Review for unintended search changes before publication.

## Inspection baseline

The design began at `07e6c4e`, with `v3.1.1` then the latest published release; implementation starts at `25e386a`. Generation uses appearance-resolved HSL and legacy cached contrast; strict assessment does not. Prior deterministic-palette coverage requested only the three initial entries and therefore did not exercise random search.
