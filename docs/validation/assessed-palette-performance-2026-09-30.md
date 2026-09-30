# Assessed-palette performance — 2026-09-30

Recommendation: **leave production implementation unchanged**. The selected
five-entry requests cost roughly 30–47 µs at their medians; eight-entry requests
cost 2.03–2.47 ms. No application slowdown, latency target, or invocation rate was
established. These macOS reference measurements do not justify an optimization.

## Question and agreed scope

“How much does one complete assessed-palette request cost, and what explains
variation between requests?” The use case is interactive regeneration after a
base-color change. The [agreed design](../design/benchmark-correctness.md#assessed-palette-investigation--2026-09-30)
selects AA, black/white inclusion, requested sizes 5/8, opaque sRGB red against
white and brand blue `(0.2, 0.4, 0.7)` against white/black. SplitMix64 seeds are
0, 42, and 2026, reset outside each request. Priming replays the identical request
and restores RNG state again. This is 18 cases × two cache states.

Only the repository-local harness and its guidance changed. Generation algorithms,
public APIs, legacy defaults, cache machinery, and release metadata are unchanged.
The stale “no public RNG control” guidance was a measurement/documentation gap,
not evidence of a runtime defect. The reviewed production revision is
`43a4f45c3fa50c882bc23e02b313e4225b51833f` (fetched origin/main); the harness was
measured with the uncommitted changes captured in raw metadata. The final harness
source snapshot matches the working files after measurement.

## Reproduction and evidence

```sh
swift test --package-path Benchmarks -c release
python3 Benchmarks/run.py --scenario-prefix palette- \
  --output .build/benchmark-results/palette-2026-09-30-final
```

Use a new output directory when reproducing. The completed local artifact is
`.build/benchmark-results/palette-2026-09-30-final/{raw.json,summary.md}`;
execution log and analysis are under `.build/palette-investigation/`.
Raw evidence is retained locally, ignored by Git. It includes the exact harness
sources, tracked patch, invocation, revision, executable hash, environment, ordered
samples/run identities, and untimed ordered output/RNG/appearance diagnostics.

Environment: Apple M4 Pro, Mac16,7, 48 GiB RAM, arm64 macOS 26.6.2 (25G83),
Xcode 26.5 (17F42), Swift 6.3.2, macOS SDK 26.5, AC power,
`NSAppearanceNameAqua`. Builds and other
investigation executions finished before the final sampling run; ordinary desktop
processes remained active. System load and CPU/OS caches were not controlled.

Three independent runs produced 108 isolated processes and 1,080 retained samples,
100 individually timed complete requests per sample (108,000 timed requests).
Each process performs 10 untimed warm-up requests. Scenario/cache order reverses
on the second run; request/control sample order alternates. Setup, RNG reset,
priming, validation, diagnostics, and reporting are untimed. Generation, retries,
fallbacks, every assessment, input barriers, dispatch, and complete-result consumption
are timed. No samples were excluded; the fixed count was not extended to select a
preferred result. Median control costs were 0.018–0.045 µs and were not subtracted.

An earlier complete run is retained at `.build/benchmark-results/palette-2026-09-30/`.
Independent worktree review found that replay comparisons happened only after all
processes completed. This was corrected to save the current record and immediately
stop on mismatch with `complete: false`; a failure-path test covers that behavior.
The fixed experiment was rerun in full. The earlier run is superseded, not pooled
with the final measurements; late review/tooling activity also overlapped that
initial run. No replay mismatch occurred in either run.

## Measurements

All values below are **µs per complete request**, shown as median [min–max] of
30 sample means. They are not individual-request percentiles. Each case returned
its requested count in this environment; the harness permits documented partial
results rather than treating an exact requested count as a universal promise.

| Input pair | Requested size | RNG seed | Empty cache | Primed cache | RNG draws |
| --- | ---: | ---: | ---: | ---: | ---: |
| red white | 5 | 0 | 44.99 [42.81–47.47] | 30.20 [28.90–31.33] | 2 |
| red white | 5 | 42 | 45.43 [44.79–46.20] | 29.77 [28.20–30.72] | 2 |
| red white | 5 | 2026 | 44.76 [42.67–46.06] | 29.97 [28.09–31.31] | 2 |
| red white | 8 | 0 | 2301.01 [2247.42–2346.96] | 2101.14 [2035.36–2136.63] | 100 |
| red white | 8 | 42 | 2237.82 [2196.18–2297.00] | 2027.06 [1948.84–2083.92] | 100 |
| red white | 8 | 2026 | 2306.53 [2257.67–2352.95] | 2090.73 [2058.48–2149.78] | 100 |
| blue white | 5 | 0 | 46.04 [44.12–48.40] | 30.63 [29.27–31.83] | 2 |
| blue white | 5 | 42 | 45.91 [43.78–47.19] | 31.03 [29.62–31.58] | 2 |
| blue white | 5 | 2026 | 47.25 [45.13–59.46] | 31.12 [29.54–32.56] | 2 |
| blue white | 8 | 0 | 2466.06 [2418.21–2514.17] | 2236.88 [2174.67–2300.25] | 100 |
| blue white | 8 | 42 | 2382.47 [2296.81–2437.27] | 2151.29 [2085.73–2181.36] | 100 |
| blue white | 8 | 2026 | 2454.82 [2376.15–2509.90] | 2247.45 [2171.12–2276.51] | 100 |
| blue black | 5 | 0 | 46.69 [44.84–47.59] | 31.40 [29.41–32.43] | 2 |
| blue black | 5 | 42 | 46.75 [45.09–47.46] | 31.09 [30.21–31.93] | 2 |
| blue black | 5 | 2026 | 47.30 [42.98–48.68] | 31.35 [29.83–33.35] | 2 |
| blue black | 8 | 0 | 2462.76 [2444.04–2519.60] | 2228.58 [2187.38–2276.85] | 100 |
| blue black | 8 | 42 | 2385.31 [2334.67–2440.96] | 2148.94 [2108.98–2195.69] | 100 |
| blue black | 8 | 2026 | 2468.36 [2396.85–2536.10] | 2241.09 [2188.57–2312.48] | 100 |

The five-entry cases consume two draws; all eight-entry cases consume 100. At this
revision, the selected eight-entry requests reach the bounded search limit before
using fallbacks. The timed generator has no draw counter; counts come from an
untimed wrapper verified to reproduce the same output and final state. Together
with the inspected search, these observations explain the large size-related
cost increase: additional distinct entries can require many rejected candidates,
so request cost does not scale linearly with returned count.

Primed medians are 32.4–34.5% lower for five entries and 8.5–9.9% lower for eight
entries than the matching empty-cache medians. These are cache-preparation
comparisons with unchanged production code, not library speedups or expected
application hit rates. Eight-entry empty medians span 2.24–2.47 ms across the input
and seed set, while primed medians span 2.03–2.25 ms. Blue/white and blue/black have
equal ordered candidates/final RNG state for matching size/seed, but differing
assessment outcomes. Background/seed timing differences overlap sample variability;
they do not establish a separate assessment bottleneck.

No phase timing, CPU time, allocations, or profiler traces were collected. We can
associate the larger workload with bounded-search work, but cannot assign an exact
percentage of latency to individual phases. Remaining variation within identical
seeded requests reflects observed timing variability; the experiment does not
isolate its environmental causes. Sample averaging hides individual-request tails.
There is no iOS, rendering, UI responsiveness, cross-version output, or regression
threshold claim. Replay retains the public environment/version/appearance limits.

## Correctness and checks

- Release benchmark tests: PASS, six tests (including all 33 fixtures in every
  supported cache mode, setup timing, RNG reset/priming, and invalid arguments).
- Python tooling: PASS, 42 tests, including report units, replay mismatch rejection,
  retained incomplete evidence, and immediate stopping.
- Strict SwiftLint: PASS, zero violations in 132 files.
- Focused serialized macOS scheme tests: PASS, 33 tests across
  `PaletteReplayTests`, `AccessiblePaletteGeneratorTests`,
  `ColorAccessibilityResultTests`, and `ColorCacheIntegrationTests`.
- Full experiment: PASS, `complete: true`; equal ordered components, assessments,
  final RNG state, and appearance diagnostics across independent runs/cache states.
  Every fixture is validated before/after timing, with independent public reassessment.
- Release compiler inspection: PASS for the measured executable; see
  [compiler verification](../../Benchmarks/VERIFICATION.md#palette-replay-harness--2026-09-30).
- Diff whitespace and frozen production/package/compatibility-fixture comparison:
  PASS against the assessed commit.

The scheme command was:

```sh
scripts/run_tests.sh --log-file .build/palette-investigation/palette-contracts.log \
  macOS 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -skipMacroValidation \
  -only-testing:ColorKitTests/PaletteReplayTests \
  -only-testing:ColorKitTests/AccessiblePaletteGeneratorTests \
  -only-testing:ColorKitTests/ColorAccessibilityResultTests \
  -only-testing:ColorKitTests/ColorCacheIntegrationTests
```

Untimed checks retain generation order and all assessments without an enhancement
budget. Five-entry benchmarks retain measured passes and best efforts. Eight-entry
benchmarks additionally retain two unavailable entries from named fallback colors;
AppKit appearance capture supplies diagnostic component snapshots, not fabricated
contrast measurements. Existing tests cover rejected draws, fallback order, partial
palettes, dynamic inputs, size normalization, and legacy random/default behavior.

Not run: full iOS/macOS matrix, release-client/API compatibility gate, DocC/example
catalog checks, minimum-OS runtime, binary compatibility, or hosted CI at the time
of these local measurements. Production APIs, public examples, package settings,
and preserved clients are untouched. The focused macOS checks establish this
investigation's contracts, not integrated release readiness.

## Separate consumer-usability review

Workflow: a developer discovers how to generate a repeatable palette and correctly
interpret its accessibility assessments. Reviewed production/docs revision:
`43a4f45c3fa50c882bc23e02b313e4225b51833f`. Public route: README → Usage “Assess a
generated palette” → DocC “Assessed Palettes” and “Replaying a Palette”, plus the
linked unavailable-results recipe. The route and required decisions were recorded
before this investigation inspected production implementation.

**No actionable consumer findings.** A scratch Release client with ordinary
`import SwiftUI` and `import ColorKit` compiled and executed the workflow:
reset replay, candidate/assessment ordering and RNG parity, five AA entries with
two measured passes/three best efforts, all-unavailable translucent background with
public per-input diagnosis, normalized −1/0/2 requests (two without endpoints,
three with endpoints), observed AAA request 50 returning ten entries, and documented
legacy defaults/small-count calls. It uses actual returned counts and never treats
unavailable as a measured shortfall.

The reviewer inherited implementation knowledge and encountered the public
Configuration initializer body alongside its declarations; this was not a blind
review. An initial reviewer-created assertion accessed a private field and failed
compilation; it was replaced with public Configuration fields. That mistake is
retained as evidence, not presented as a usability defect. No private helper or
test-only import completed the final client.

Client source, metadata, public attempt, successful output, and initial failure are
retained under `.build/palette-investigation/consumer/`. Command:

```sh
swift run --package-path .build/palette-investigation/consumer -c release PaletteConsumer
```

This is one macOS Release client within one process. It does not establish iOS
consumer behavior, exhaustive documentation correctness, source compatibility,
or performance. Consumer usability, benchmark correctness, and timing conclusions
remain separate assessments.
