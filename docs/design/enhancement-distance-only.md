# Enhancement distance-only calculation

Status: implemented and locally validated.
Branch: `perf/enhancement-distance-only`.
Inspection baseline: `0c2986e`.

## Accepted scope

Investigate only a small internal optional-distance entry point in
`ColorComparison.swift`, sharing the existing eligibility checks and
RGB-to-LAB-to-CIEDE2000 calculation with full comparison. Budgeted enhancement
would use that entry point without computing the other comparison metrics.
Acceptance remains conditional on simplicity, differential correctness, and
measured benefit; retaining the current implementation is a valid outcome.

Do not add original-LAB caching, change variant deduplication, duplicate
CIEDE2000, add public API, or introduce a measurement framework. Original-color
resolution reuse and the merged candidate selector already exist and are not
part of this change.

Radical simplicity is a design requirement: aim for one small shared distance
function in the existing comparison code, reusing existing eligibility checks.
Do not introduce new types or configurable measurement paths. Retain the current
implementation if the extraction makes the code harder to follow.

Preserve exact eligibility and unavailable outcomes, existing LAB constants and
numerical operations, inclusive budgets, traversal, selection, ties, fallbacks,
full public comparison results, and released 3.x contracts. In particular, do
not substitute the newer component-conversion math for the comparison path.

## Validation requirements

Use separate unchanged-baseline and candidate builds with identical fixtures for
exact distance and complete-result differential validation. Do not add a frozen
copy of the comparison calculator to the test suite. Retain only focused regression
tests that add useful coverage; do not turn the differential exercise into a generic
validation framework. Compare each platform against its own baseline, preserving
numeric bit patterns and unavailable outcomes. Color identity must be checked
without relying on unstable textual descriptions across processes.

Compare old/new distances and complete enhancement results across all strategies,
boundary budgets, ties, unavailable inputs, and already-compliant colors. The
existing frozen selector calls production comparison, so it alone cannot detect
a shared calculation regression.

Accepted tie evidence: retain real original-color and repeated-endpoint tie
fixtures, compare candidate distances exactly against the baseline, and leave
selection code untouched. Equal distances with unchanged selection rules preserve
tie behavior. No synthetic measurement injection is needed. Explicitly report that
distinguishable candidates with exactly equal distances still lack a demonstrated
real fixture; do not describe that case as directly exercised.

Run relevant iOS/macOS tests and released-client compatibility checks. Measure
complete public enhancement requests in Release with identical workloads,
consumed results, and other builds idle. Retain raw samples and report limitations;
do not presume a speedup.

Only enhancement/comparison internals, focused tests, necessary benchmark coverage,
and this design record are in scope. No onboarding, diagnostic example, shared
README, or release metadata edits. Implementation requires separate approval;
committing, pushing, opening a PR, and releasing require a separate request.

Related contracts: [distance budgets](enhancement-distance-budget.md),
[candidate selection](enhancement-candidate-selection.md), and
[released-client compatibility](release-client-compatibility.md).

## Implementation and differential evidence

The production change is confined to `ColorComparison.swift` and
`BudgetedEnhancement.swift`. An internal optional-distance entry point uses the
existing comparison issue checks. The existing private calculator shares its
RGB-to-LAB-to-CIEDE2000 calculation between that entry point and full comparison.
No selection, candidate generation, resolution, conversion primitive, CIEDE2000,
or variant-deduplication code changes.

On Xcode 26.5, separate baseline and candidate builds matched all 10,463 keyed
records on each of macOS and iPhone 17 / iOS 26.5:

- 4,992 complete enhancement results across the existing strategy, preference,
  WCAG level, budget, and input matrix.
- 3,721 resolved-input pair records containing exact optional distance and full
  comparison fields or per-input issues.
- 268 generated candidates with source color identity, comparison fields, and
  distance; 666 complete enhancement results at candidate distances and adjacent
  representable budgets.
- 480 variant counts and 336 complete ordered variant entries.

Every numeric result was serialized by bit pattern, including nil, signed zero,
and nonfinite budgets. Fixed-color records preserve original CGColor space name,
model, and original component bit patterns. Each build also checks Color equality
against the existing reference selector, including unresolved-original outcomes.
Keys and complete records match, not just aggregate checksums or result counts.
The candidate probe calls the new distance entry point; the baseline probe reads
perceptualDifference from the old full comparison. Full comparisons are recorded
independently on both builds.

This was a temporary extension of the existing selection fixtures, removed from
the test target after capture. The permanent focused test checks 3,969 operand
pairs for exact distance parity and identical availability, including nil and
adjacent alpha/gamut boundaries. The accepted exact-tie fixture limitation above
still applies.

Local checks passed:

- Focused macOS comparison, distance-budget, and selection suites: 32 tests.
- `scripts/run_tests.sh --results-dir .build/distance-evidence/matrix`: 333 tests
  plus 15 separately serialized shared-state tests on each platform, no failures.
- `python3 scripts/check_compatibility.py --fixture-base 0c2986efb437f67a5c25e00c6d6572ee49a90d84`:
  preserved 3.0.0 and 3.1.0 clients and public API comparisons on macOS and iOS.
- `swiftlint lint --strict`: zero violations.
- `python3 -m unittest discover -s scripts/tests`: 35 tests.
- `swift test --package-path Benchmarks -c release`: five correctness tests,
  including all 16 benchmark fixtures, on both baseline and candidate.
- `swift test --package-path Examples/ContrastPairReport`: six tests.
- DocC warnings-as-errors and `python3 scripts/check_documentation.py`: passed.

These are local checks, not hosted CI or minimum-OS runtime evidence. User-facing
API documentation requires no changes because the public contract is unchanged.

The local differential capture and its temporary probe are retained in
`.build/distance-evidence/differential-evidence.zip`. Sorted JSON SHA-256 digests
match between baseline and candidate:

- macOS: `432affa942a7874eef37c61e915f46eea6b255232c44cdc573ad1325809e8316`
- iOS: `344ec5ed3cefeb9f0f73d121d19c9b0f879ec5b77a6a551afc7bbe91965fe34a`

The capture scripts and raw files are local validation artifacts, not a new
production or test framework. The two platform captures need not match each other;
platform resolution and existing HSL behavior can differ.

## Release measurements and acceptance

Keep the extraction: it removes unnecessary comparison metrics with 15 added and
3 removed lines in the comparison file and a one-line enhancement call. No new
production types or files are needed. Exact differential equality and repeatable
benefits on several searching workloads justify this limited change.

[Raw samples and environment](../../Benchmarks/Results/enhancement-distance-only.json)
retain every request/control total, workload, run order, timestamp, and binary
hash from the completed pass. Each side has four process runs per workload/cache
pair, five samples per run, and 100 complete requests per sample (20 sample means
per side). Table values are medians of those 20 sample means, in nanoseconds
per request; change is candidate relative to baseline. Controls are retained
without subtraction.

| Request / cache | Baseline ns | Candidate ns | Change |
| --- | ---: | ---: | ---: |
| comparison-black-white / unused | 607.9 | 602.7 | -0.9% |
| enhancement-compliant / unused | 926.9 | 929.4 | +0.3% |
| enhancement-adjusted / empty | 30619.8 | 29712.5 | -3.0% |
| enhancement-adjusted / primed | 24862.3 | 24052.5 | -3.3% |
| enhancement-best-effort / empty | 22514.0 | 22239.2 | -1.2% |
| enhancement-best-effort / primed | 17330.8 | 17600.0 | +1.6% |
| enhancement-preserveHue-false / empty | 21817.9 | 21526.7 | -1.3% |
| enhancement-preserveHue-false / primed | 16854.4 | 15764.2 | -6.5% |
| enhancement-preserveHue-true / empty | 20993.4 | 19402.1 | -7.6% |
| enhancement-preserveHue-true / primed | 15923.6 | 14025.4 | -11.9% |
| enhancement-preserveSaturation-false / empty | 23235.6 | 21680.0 | -6.7% |
| enhancement-preserveSaturation-false / primed | 18128.1 | 16796.8 | -7.3% |
| enhancement-preserveSaturation-true / empty | 23738.3 | 22381.7 | -5.7% |
| enhancement-preserveSaturation-true / primed | 18687.9 | 16041.3 | -14.2% |
| enhancement-preserveLightness-false / empty | 49524.4 | 46835.9 | -5.4% |
| enhancement-preserveLightness-false / primed | 43327.0 | 39975.8 | -7.7% |
| enhancement-preserveLightness-true / empty | 46931.3 | 45971.4 | -2.0% |
| enhancement-preserveLightness-true / primed | 40431.3 | 38887.7 | -3.8% |
| enhancement-minimumChange-false / empty | 58843.5 | 55232.9 | -6.1% |
| enhancement-minimumChange-false / primed | 50832.9 | 47658.5 | -6.2% |
| enhancement-minimumChange-true / empty | 56247.7 | 55337.0 | -1.6% |
| enhancement-minimumChange-true / primed | 48758.9 | 46546.9 | -4.5% |

The preserve-lightness workloads improved in every paired run for both preferences
and cache modes; minimum-change with preferDarker false did too. Across those six
workload/cache pairs, median reductions were 2.0–7.7%. Other cases were noisier:
some paired runs regressed even when the aggregate median improved. Already-compliant
requests changed by +0.3%, full comparison by -0.9%, and primed gray best effort by
+1.6%; these small differences do not establish a useful change for those paths.
There is no general speedup claim or CI performance threshold.

Method: build baseline and candidate Release executables before timing, with
identical `Scenarios.swift` and unchanged `Measurement.swift`. Use the existing
public-request runner, including its opaque input and complete-result consumption,
10 untimed warmups, untimed per-request cache preparation, and alternating
request/control sample order. Reverse workload order on alternating runs and
alternate which executable runs first. Check for compiler/build processes before
and after each invocation. A single capture can be reproduced with:

```sh
swift build --package-path Benchmarks -c release
Benchmarks/.build/release/ColorKitBenchmarks enhancement-preserveLightness-false primed 5 100
```

For the old side, check out the inspection baseline into a directory named
`ColorKit`, copy only the candidate benchmark scenario and correctness-test files
into it, and build its benchmark package. Run the same scenario/cache pairs on
both binaries in the order above. The local orchestrating script is retained at
`.build/distance-evidence/measure.py`; it does not change the benchmark runner.

Limitations: one Apple M4 Pro on battery power, macOS 26.6.2, Xcode 26.5 / Swift
6.3.2; these are sample means, not individual-request latency percentiles. Compiler
checks bracket each invocation, not continuous system tracing; ordinary background
OS activity remains possible. Three earlier passes detected unrelated compiler
activity and were excluded in full; their incomplete captures remain locally in
`.build/distance-evidence/performance-interrupted*.json`. The final pass completed
without detected build activity. No iOS performance, minimum-OS runtime, physical
device, or broad application speedup is established.
