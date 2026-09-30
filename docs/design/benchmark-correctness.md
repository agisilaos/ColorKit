# Benchmark correctness and performance baseline

## Assessed-palette investigation — 2026-09-30

Status: measured; see the investigation evidence below. Production implementation
is unchanged.
Assessed baseline: `43a4f45c3fa50c882bc23e02b313e4225b51833f` (latest fetched
`origin/main`). Isolated branch: `chore/assessed-palette-performance`.

The agreed use case is interactive regeneration after changing a base color.
There is no assumed latency target, invocation rate, or demonstrated slowdown.
The agreed question is: “How much does one complete assessed-palette
request cost, and what explains variation between requests?” The decisions below
define workload selection, RNG/cache preparation, repetitions, stopping conditions,
and success criteria. Production optimization, public API additions, async wrappers,
and cache machinery are outside scope.

Agreed reference workloads: requested palette sizes 5 and 8, AA, and
`includeBlackAndWhite: true`, crossed with three fixed opaque sRGB pairs:
red `(1, 0, 0)` against white; brand blue `(0.2, 0.4, 0.7)` against white;
and the same blue against black. These six cases represent selected interactive
requests, not a population-weighted application workload. Count-limit and
unavailable cases belong in untimed correctness checks.

Agreed randomness and cache preparation: use the public documentation's app-owned
SplitMix64 generator with seeds 0, 42, and 2026, reporting each separately. Restore
its initial state outside timing before every request. Empty-cache preparation
clears `ColorCache.shared` and resets randomness. Primed-cache preparation clears
the cache, executes the identical seeded request untimed, then resets randomness
again before measurement. Priming describes preparation, not guaranteed hits.
Compare ordered components, assessments, and final random state outside timing
to establish equal workloads. Replay remains limited to the same library version,
execution environment, configuration, and appearance documented in the public
guide; no cross-version identical-output promise is added.

Agreed measurement boundary: elapsed monotonic time for one complete public
`generateAssessedPalette` request, including candidate generation, retries and
fallbacks, every assessment, the harness input barrier, and complete-result
consumption. RNG reset, cache preparation, warm-up, correctness checks, sample
storage, and reporting stay outside timing. Record untimed RNG draw counts,
returned counts, and assessment outcomes as diagnostic evidence for workload
differences; draw counts are revision-specific observations, not public contracts.
This measures neither CPU time nor rendering or iOS latency.

Agreed sampling and stopping: retain the harness defaults of three independent
runs, ten samples per case per run, one hundred individually timed requests per
sample, and ten untimed warm-up requests. Retain all samples and their order;
reverse scenario/cache order on alternate runs. Report the median and range of
the thirty sample means per workload/seed/cache combination, with control overhead
shown separately and not subtracted. These summaries do not establish
individual-request tail latency. Stop at the fixed run count, or on a correctness
or execution failure while preserving incomplete evidence; do not remove outliers
or extend sampling to obtain a preferred result.

Practical success is a reproducible, contract-checked account of elapsed request
cost and variation, or a precise explanation of unresolved measurement limits.
There is no speed threshold and no required optimization. A recommendation to
leave production implementation unchanged is a valid outcome.

Agreed minimal harness changes: replace the stochastic palette reference with the eighteen workload/seed combinations; add
an untimed RNG-reset hook for identical priming and measured requests; select
palette scenarios without running unrelated operations; retain untimed output
and RNG diagnostics alongside timing evidence. Preserve the existing timing loop,
control, process isolation, and environment recording. Update stale benchmark
guidance and repeat Release compiler verification. No production changes.

Before inspecting production implementation, the public documentation route was
recorded: README → Usage → Assess a generated palette → Accessibility article,
Assessed Palettes and Replaying a Palette. It supplies a deterministic generator
example, reset/continuation guidance, environment/version limits, outcome
interpretation, ordering, and palette-count limits. Focused client verification
and measurements are recorded in the
[investigation evidence](../validation/assessed-palette-performance-2026-09-30.md).
The reviewer has prior implementation knowledge; this is not a blind consumer attempt.

Inspection of the assessed baseline confirmed `palette-red-five` used the
stochastic overload and its benchmark guide said public RNG control was
unavailable, despite the documented replay overloads. This measurement/documentation
gap is corrected by this investigation. It was not evidence of a runtime defect.
The deterministic policy above supersedes the original stochastic fixture policy
below.

No overlapping investigation surfaced in the open GitHub issues/PRs checked on
2026-09-30; the only open PR was #82 (parallel compatibility CI). Unpublished
local work was not ruled out. Preparation and the public route are also retained
locally under `.build/palette-investigation/public-route.md`.

Status: reduced milestone implemented. This note supersedes the broader workload
and acceptance-framework proposals discussed earlier. See [the runner guide](../../Benchmarks/README.md)
for the chosen fixtures, repetition counts, timing boundaries, and reproduction commands.

## Agreed scope

Preserve ColorKit 3.0.0's public API and documented behavior throughout this work.
Correct the preview's conversion workload and gradient labels, then establish a
small, reproducible performance baseline for conversion, comparison, enhancement,
and assessed palette generation. No measured bottleneck or speedup has been
established.

Defer exhaustive input coverage, all-blend-mode and gradient-construction baseline
suites, formal measurement-status classifications, and automated regression
thresholds. Gradient rendering and speculative product optimizations remain out
of scope. Consumer SwiftLint dependency/build-cost evaluation, a separate
preserved-3.0.0 client compatibility gate, and release/version selection remain
follow-up work.

## Agreed harness

The authoritative baseline runner is a repository-local command-line package
under `Benchmarks/`, importing ColorKit through its existing public API and running
in Release mode. macOS is the initial reference platform; recorded results must
identify that platform and cannot establish iOS performance.

This arrangement supports repeatable invocations, fresh processes for cache
experiments, and machine-readable results while exercising operations available
to library consumers. Private conversion kernels are outside this harness's
reach. The SwiftUI performance preview retains its public API and receives the
workload corrections agreed during this design session.

## Agreed workload families

The first baseline covers these four families, with cases reported separately:

| Family | Operations |
| --- | --- |
| Conversion | Real public conversion requests, starting with HSL and LAB components |
| Comparison | Full `comparisonResult(with:)`, including all its metrics |
| Enhancement | Budgeted enhancement, separating already-compliant inputs from inputs requiring adjustment |
| Palette | Assessed palette generation with fixed seeds and configuration |

The preview's gradient cases must explicitly describe value construction. That
label correction does not require adding gradient cases to the baseline runner.

## Agreed fixture policy

Use a small, checked-in set of named scenarios with explicit color components and
configurations. Report each scenario separately so changes in the workload mix
cannot conceal a regression. Validate expected outcomes before timing.

Clarity is part of this contract: every scenario has a stable identifier, a
plain-language purpose, exact inputs (including color space and opacity), explicit
operation settings, and an expected outcome. Include those details with the timing
results so readers can understand what was measured without reading source code.

Enhancement scenarios include an already-compliant black foreground against white,
and sRGB `(0.8, 0.8, 0.8)` against white with distance budgets of 100 and 25 to
exercise a passing adjustment and budget-constrained best effort respectively.
Pin the strategy, direction preference, and target level for these fixtures and
verify their expected outcomes before accepting measurements. Start with a small
set of explicit sRGB fixtures; exhaustive color-space and edge-case coverage is
deferred.

The [runner guide](../../Benchmarks/README.md) records the compact fixture inventory
and exact settings, checked against existing correctness expectations.

At the original baseline, implementation inspection found that the public palette
generator used internal, unseeded random hue shifts. Its seed color and configuration are fixed, but its
candidate search is stochastic. Retain the representative five-color request and
disclose that variability, including priming with different candidates, rather
than modifying the library to control its RNG. ColorKit 3.2 subsequently added
caller-owned randomness; the 2026-09-30 investigation above supersedes this
stochastic fixture policy with deterministic replay through those public overloads. Validate palette invariants instead
of exact generated colors; do not interpret this case as a deterministic cache-hit
or version comparison.

## Agreed operation unit

One operation is one complete request through the selected API:

- Conversion: convert one color using the selected API.
- Comparison: process one color pair.
- Enhancement: process one foreground/background request.
- Palette: generate and assess one entire palette.

A five-color assessed palette counts as one palette request. All internal
candidate searches and per-entry assessments are part of that request. Results
use explicit units such as nanoseconds per comparison and palettes per second.
Input preparation and report formatting happen outside the timed work. The cost
of result consumption is included as described below.

## Agreed result consumption

Pass every complete result to a small benchmark sink designed to keep the result
observable to the optimizer. The timed measurement includes both the request and
its sink call. Validate correctness outside the timed section.

Measure loop and sink overhead separately and disclose it without subtracting it
from the reported request measurements. Explain when harness overhead prevents a
useful measurement of a cheap operation.
Detailed per-iteration checksums are not the chosen consumption mechanism because
their cost could dominate small workloads.

During implementation, inspect optimized code to verify that workload calls remain
inside the loop. A sink's presence alone is not evidence that repeated work survives
optimization. The sink implementation and verification must cover every result
type used by the harness.

Reference: [Swift benchmarking guidance](https://www.swift.org/blog/benchmarks/)
demonstrates consuming results with `blackHole`.

## Agreed cache protocol

Define cache preparation at the start of each complete request:

| Mode | Preparation outside timing |
| --- | --- |
| Empty ColorKit cache | Clear `ColorCache.shared` immediately before the measured request. |
| Primed ColorKit cache | Clear `ColorCache.shared`, execute the same scenario once outside timing, then measure its next execution. |

Cache entries created during an enhancement or palette request remain available
to its internal operations. The request includes that natural cache behavior.
Clearing once before a loop does not qualify the entire loop as empty-cache work;
each measured request must receive the stated preparation.

Run scenarios serially in isolated runner processes. These labels describe only
ColorKit cache preparation, not CPU or operating-system cache state. Priming does
not guarantee that every internal lookup hits. Operations that never use ColorKit's
cache have a single measurement mode.

## Baseline deliverable

Save repeated timings and raw samples with a concise human-readable summary of
typical request time, variation, and measurement limitations. Record the source
revision, fixture settings, cache preparation, Release build configuration,
hardware, OS, and Swift/Xcode versions so results can be reproduced.

The runner defaults to three independent runs, each with ten samples of 100
requests. Check fixture correctness, valid timing arithmetic, and optimized workload
execution. Explain noisy or overhead-dominated measurements directly; this milestone does not require
a formal classification system, statistical acceptance thresholds, or CI slowdown
gates. Do not interpret a shorter duration as an improvement if the expected
workload result is wrong.

The deliverable is corrected preview measurements and useful reference data for
future profiling decisions. Broaden the suite only when a concrete performance
question justifies the additional maintenance.
