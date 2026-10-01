# HSL-only cache comparison — 2026-10-01

Recommendation: **retain automatic HSL caching for now**. Bypassing it helped
several selected requests, but increased the cost of primed standalone HSL
conversion and a primed five-entry palette. This is a measured trade-off, not a
simplification with uniformly preserved performance. No application frequency or
latency budget establishes that accepting those regressions is worthwhile.

## Approved question

Does HSL caching explain any of the benefit from the earlier all-cache bypass,
and would removing HSL reuse trade palette cost for repeated-conversion cost?

The protocol below was approved before execution. The
[ownership investigation](../design/cache-ownership-investigation.md#hsl-only-reuse)
records the resulting decision. This experiment compares current production behavior with a
temporary candidate; it does not authorize a production change or API removal.

## Variants and measurement

Both variants use an archive of revision
`1f9ddf0687bcac52afae60b4a1cc8dfa06168d42`. The sole library difference is removal
of the lookup and insertion in `hslComponents()` in the isolated `hsl-direct`
copy. Its appearance resolution, clamping, HSL formula, and optional return remain
unchanged. The HSL store, its internal accessors, public clearing methods, and
the other five stores remain intact. This prototype measures bypassing automatic
reuse; it does not implement a complete removal of now-unused machinery.

Both copies have the same small `Runner.swift` addition to capture actual HSL
components before and after measurement, outside timing. `Measurement.swift`,
the fixtures, and the timing boundaries are unchanged. The HSL snapshot uses the
same public fixed-red request and selected preparation; it clears afterward.
The driver compares snapshots with each other and with `[0, 1, 0.5]`.

Three complete public workloads were measured:

| Fixture | Complete operation | Reason |
| --- | --- | --- |
| `palette-blue-white-5-seed-42` | Generate and assess the whole five-entry palette | Small request from the first comparison |
| `palette-blue-white-8-seed-42` | Generate and assess the whole eight-entry palette | Previously observed search-limit request |
| `hsl-red` | Resolve fixed opaque red and return its HSL components | Standalone conversion and repeated-input reuse |

Palette settings are unchanged: opaque sRGB blue `(0.2, 0.4, 0.7)` against white,
AA, black/white inclusion, SplitMix64 seed 42 reset outside every request. The
HSL fixture is fixed opaque sRGB `(1, 0, 0)`; it does not represent every HSL input.

Each fixture runs under `empty` and `primed` preparation in both variants.
`empty` clears all stores before each request; `primed` clears, runs the identical
request outside timing, resets the RNG where applicable, then times the request.
The other five stores still participate normally in the candidate. Thus priming
the candidate can still benefit a palette through those stores.

Three fresh processes per variant/fixture/preparation each perform ten untimed
warm-ups and ten samples of 100 individually timed requests. This is 36 processes,
360 samples, **36,000 timed requests**. Variant order alternates within matched
pairs; the second run reverses fixture/preparation order. The run stopped at the
agreed fixed count. No records or samples were excluded, and no failure or retry
occurred in this experiment.

Timing includes input barriers, dispatch, complete public operations, and result
consumption. Preparation, RNG reset, warm-up, correctness checks, diagnostics,
and reporting are outside timing. Request/control sample order alternates. Control
costs are retained and not subtracted. Results are sample means, not individual
request tails or throughput including preparation.

## Environment

Apple M4 Pro, Mac16,7, 48 GiB, arm64 macOS 26.6.2 (25G83), Xcode 26.5 (17F42),
Swift 6.3.2, macOS SDK 26.5, AC power. All palette diagnostics report
`NSAppearanceNameDarkAqua`. Both builds, correctness tests, preflight, and compiler
inspection completed before sampling. The pre-sampling process snapshot found no
competing compiler, xcodebuild, or benchmark process. Ordinary desktop activity,
scheduling, and CPU/OS caches were not controlled.

The baseline was sampled again with the same diagnostic harness as the candidate.
Do not subtract timings or percentages from the earlier all-cache experiment to
infer a precise share of overhead: these are separate runs and cache interactions
are not established to be additive.

## Results

All values are **microseconds per complete operation**, median [minimum–maximum]
of 30 sample means. Positive differences mean the HSL-direct candidate was slower.

| Workload | Preparation | Current implementation | HSL direct | Candidate minus current |
| --- | --- | ---: | ---: | ---: |
| Five-entry palette | Empty | 45.139 [43.255–46.792] | 36.263 [34.810–37.619] | -8.876 (-19.7%) |
| Five-entry palette | Primed | 30.024 [29.153–33.226] | 32.563 [31.198–37.316] | +2.539 (+8.5%) |
| Eight-entry palette | Empty | 2321.827 [2210.362–2383.155] | 2188.037 [2136.941–2236.659] | -133.790 (-5.8%) |
| Eight-entry palette | Primed | 2111.247 [2066.543–2145.292] | 1983.078 [1914.397–2008.161] | -128.169 (-6.1%) |
| HSL red conversion | Empty | 2.865 [2.723–3.313] | 1.274 [1.185–1.460] | -1.590 (-55.5%) |
| HSL red conversion | Primed | 0.991 [0.947–1.140] | 1.260 [1.184–1.395] | +0.269 (+27.1%) |

All three run medians agree with the overall direction in each case. Sample
ranges overlap for the primed five-entry palette and empty eight-entry palette;
the other four comparisons have separated ranges. The primed conversion slowdown
is about **269 nanoseconds** per call: the percentage is noticeable because the
operation is short, not evidence of a significant application problem. Median
controls span 0.014–0.050 microseconds and remain much smaller than requests.

HSL reuse therefore has demonstrated value for at least the repeated fixed-red
conversion under these conditions. Bypassing it also has demonstrated costs and
benefits at complete-operation level. Neither "all caching is waste" nor "every
conversion benefits from caching" follows. The earlier all-cache result did not
predict the sign of every HSL-only result.

This experiment does not attribute differences to key construction, allocation,
bridging, NSCache synchronization, or compiler effects. The candidate's HSL body
was inlined into the benchmark operation closure, while the baseline retains a
call through a shared conversion trampoline; the compiler still performs input
resolution and the HSL formula. These are normal optimized builds of the two
implementations. The result measures their total effect, not isolated storage cost.

## Correctness and verification

- Both variants passed six Release benchmark tests, including all 33 fixtures in
  supported modes, preparation boundaries, RNG reset, and argument/clock guards.
- Both variants passed all 13 existing `HSLResolutionTests` on macOS in Release:
  named colors, grayscale/space handling, unavailable input, opacity independence,
  Display P3 conversion/clamping, fixed sRGB, and downstream adaptive adjustments.
- Cross-variant preflight passed all six fixture/preparation pairs before main
  sampling. It used one sample of 100 requests per process; those timings are
  retained separately and not analyzed as main-run samples.
- Every main record matches its preflight and cross-variant evidence. Palette
  order, component snapshots, ratios/statuses, appearance, and final RNG state
  match. Five/eight entries retain two/100 draws respectively; the eight-entry
  unavailable fallbacks remain unavailable. HSL before/after snapshots are exactly
  `[0, 1, 0.5]`. Existing fixture checks still run before/after timing.
- Source manifests verify that the library differs in one file only and that the
  harness addition is identical in both copies. Binary hashes match preflight and
  the main artifact. Python driver syntax validation passed.
- Release disassembly verifies preparation before the clock, operation dispatch
  and complete-result consumption inside timing for both palette and HSL result
  types, the palette public-operation call, and actual HSL computation. Full output
  and address-level notes are retained locally.

The library tests ran with SwiftPM on macOS; they are not the canonical iOS/macOS
scheme matrix. No iOS, release-client/API compatibility gate, full shared-cache
integration suite, DocC, minimum-OS runtime, or binary-compatibility checks ran.
Those remain requirements for any later implementation. Tests that inject HSL
through `@testable` would intentionally detect this prototype's changed internal
behavior; no test or fixture was edited to conceal that difference.

## Evidence and reproduction

The [review evidence archive](evidence/cache-2026-10-01/README.md) contains samples,
patches, source hashes, scripts, and verification excerpts, with instructions for
reconstructing the pinned sources. Build products and full disassembly stay local.

Local evidence directory:
`/Users/agis/projects/ColorKit-evidence/hsl-cache-2026-10-01/`.

Retained files include `source.tar`, `source-manifest.json`, `candidate.patch`,
`harness.patch`, preparation/comparison/compiler scripts, both source/build trees,
test logs, `preflight.json`, `raw.json`, `summary.md`, `analysis.json`, sampling log,
and disassembly. The raw artifact contains commands, ordered records, environment,
source/harness differences, full harness sources, and executable hashes.

Commands from the evidence directory:

```sh
swift test --package-path baseline/Benchmarks -c release
swift test --package-path baseline -c release --filter HSLResolutionTests
swift test --package-path hsl-direct/Benchmarks -c release
swift test --package-path hsl-direct -c release --filter HSLResolutionTests
python3 inspect_compiler.py
python3 compare.py preflight
python3 compare.py sample
```

For a fresh reproduction, follow the
[evidence setup instructions](evidence/cache-2026-10-01/README.md#reconstruct-the-compared-sources),
then run the commands above. Use a separate run directory to preserve the original
artifacts, and repeat compiler inspection for newly built executables.

Measured executable SHA-256:

- Baseline: `3925c09db4496dd750eeea8ba18bd721e73971d7b1d7e7d6483c088ddc12a6fb`.
- HSL direct: `594207958d9397e46a8cdc3bcddd69d986d8f3965a7ced20ccd8b11dfdd46ee4`.

## Design implication

For 3.x, retaining HSL reuse is the smallest recommendation supported by the
current evidence and the stated aim of avoiding weaker performance. Accepting
the measured regressions in exchange for less machinery would require an explicit
trade-off based on caller workloads; no such decision has been made. There is no
case here for adding cache settings, a hybrid policy, actors, or another framework.

The future ownership direction remains valid: automatic reuse can become an
implementation concern in a deliberate major release, without public insertion
as a customization mechanism. This result favors evaluating reuse operation by
operation; it does not yet select global, request-local, or absent reuse generally.
No further experiment or production implementation is authorized by this report.
