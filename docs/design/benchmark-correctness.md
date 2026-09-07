# Benchmark correctness and performance baseline

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

The authoritative baseline runner will be a repository-local command-line package
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

Choose and document the compact fixture inventory and exact settings during
implementation, using existing correctness tests where applicable.

Implementation inspection found that the public palette generator uses internal,
unseeded random hue shifts. Its seed color and configuration are fixed, but its
candidate search is stochastic. Retain the representative five-color request and
disclose that variability, including priming with different candidates, rather
than modifying the library to control its RNG. Validate palette invariants instead
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

Choose and document a modest repetition count during implementation. Check fixture
correctness, valid timing arithmetic, and optimized workload execution. Explain
noisy or overhead-dominated measurements directly; this milestone does not require
a formal classification system, statistical acceptance thresholds, or CI slowdown
gates. Do not interpret a shorter duration as an improvement if the expected
workload result is wrong.

The deliverable is corrected preview measurements and useful reference data for
future profiling decisions. Broaden the suite only when a concrete performance
question justifies the additional maintenance.
