# Cache ownership comparison — 2026-10-01

Recommendation: retain the production implementation for now. Direct computation
is a credible simpler alternative for the measured assessed-palette paths: it
reduced complete-request medians in all four cases, including primed-cache cases.
This result justifies a narrower design discussion; it does not justify removing
all caches or silently bypassing shipped caller-inserted values in 3.x.

## Question and approved scope

Does automatic caching earn its total cost in two complete assessed-palette
requests, compared with the same calculations performed directly?

The protocol below was approved before execution; the
[ownership investigation](../design/cache-ownership-investigation.md) records the
resulting decision. The
workloads are `palette-blue-white-5-seed-42` and
`palette-blue-white-8-seed-42`: fixed opaque sRGB blue `(0.2, 0.4, 0.7)` against
white, AA, black/white inclusion, SplitMix64 seed 42 reset outside every request.
These cover a small request and a previously observed search-limit request.
They do not sample the distribution of colors or seeds.

## Variants and isolation

Baseline: exact Git archive of `1f9ddf0687bcac52afae60b4a1cc8dfa06168d42`.
Candidate: a separate copy of the same archive, removing the six cache-read and
cache-write pairs from the direct consumers in `Color+HSL.swift`, `Color+LAB.swift`,
`Color+WCAGCompliance.swift`, `Color+Blending.swift`, and `Color+Gradient.swift`.
Only those five source files differ. Color calculations, resolution, opacity
eligibility, generation, assessment, and the benchmark sources are unchanged.

The candidate bypasses the entire lookup/write path, including key construction
and value bridging. It does not introduce a toggle, alternate storage, or public
replacement. `ColorCache` itself remains present; the harness still clears it
outside timing. The palette experiment does not establish the value of the
unexercised blend/interpolation paths even though their calls were also bypassed.

This is deliberately an incompatible diagnostic prototype: explicit insertion no
longer affects its operations, and automatic results no longer populate public
getters. No such change was made in the production checkout. Both source trees,
the original archive, full candidate patch, source hashes, and executables are
retained outside the worktree.

## Method and environment

Both variants use the unchanged repository Release harness. A local Python driver
selects the two fixtures and alternates variant process order for adjacent matched
cases; the second run reverses fixture/preparation order. Each variant has three
fresh process runs per fixture/preparation, ten untimed warm-up requests, and ten
samples of 100 individually timed complete requests. Total: 24 processes, 240
retained samples, 24,000 timed requests. No main-run sample was excluded or rerun.

Preparations are matched in both variants:

- `empty`: clear immediately before every measured request.
- `primed`: clear, execute the identical request outside timing, reset the RNG,
  then measure the request. In the direct variant this matches recent computation
  history; it does not imply cache population or hits.

Generation, rejection/fallback work, every assessment, input barriers, dispatch,
and complete-result consumption are timed. RNG reset, clearing, priming, fixture
checks, diagnostics, storage, and reporting are outside timing. Controls alternate
with workload samples and are reported without subtraction. Each sample averages
100 request intervals; these are not individual-request tail percentiles or
throughput measurements including preparation.

Environment: Apple M4 Pro, Mac16,7, 48 GiB, arm64 macOS 26.6.2 (25G83),
Xcode 26.5 (17F42), Swift 6.3.2, SDK 26.5, AC power. Appearance remained
`NSAppearanceNameDarkAqua` across all records. No competing compiler, xcodebuild,
or benchmark process was present in the pre-sampling process snapshot. The two
builds, tests, preflight, and disassembly work finished before sampling. Ordinary
desktop activity and CPU/OS cache state were not controlled.

The earlier September 30 investigation used Aqua and an earlier source revision.
Its timings are context only; this comparison uses newly built matched variants,
not a numerical before/after claim against that earlier report.

## Results

All times are **microseconds per complete request**, median [minimum–maximum]
of 30 sample means per cell. A negative difference favors direct computation.

| Requested size | Preparation | Current implementation | Direct computation | Direct minus current |
| --- | --- | ---: | ---: | ---: |
| 5 | Empty | 43.823 [42.733–45.097] | 28.047 [26.885–28.951] | -15.776 (-36.0%) |
| 5 | Primed | 29.532 [28.748–32.618] | 27.837 [26.909–28.899] | -1.695 (-5.7%) |
| 8 | Empty | 2284.571 [2228.147–2321.570] | 1709.961 [1658.345–1732.772] | -574.609 (-25.2%) |
| 8 | Primed | 2071.849 [2026.505–2100.321] | 1708.123 [1664.356–1724.808] | -363.725 (-17.6%) |

All three per-run medians favor direct computation in each case. Sample ranges
separate for the empty five-entry case and both eight-entry cases. The primed
five-entry ranges overlap slightly; its roughly 1.7-microsecond median difference
is a smaller result and is not a stand-alone optimization mandate. Median controls
were 0.017–0.048 microseconds and were not subtracted.

The eight-entry primed comparison shows a reduction of about 0.364 milliseconds
per request under these conditions. The empty comparison shows about 0.575
milliseconds. No application invocation rate or latency budget has been established,
so these differences do not establish a user-visible responsiveness problem.

This comparison includes the cost of caching, unlike empty-versus-primed analysis
alone. It does not attribute that cost to keys, allocations, bridging, storage
synchronization, or a particular store. It also does not compare selective or
request-local reuse. There are no memory, CPU-time, contention, iOS, or rendering
measurements.

## Correctness and validation

- `swift test --package-path <variant>/Benchmarks -c release`: both variants
  passed six tests in two suites, including all 33 existing fixtures in supported
  modes, preparation boundaries, RNG reset, and invalid-clock/argument rejection.
- Cross-variant preflight passed both fixtures in both preparations before main
  sampling. It used the unchanged executable with one sample of 100 requests;
  its timings are retained separately and not analyzed as experimental results.
- All 24 main records match preflight and one another for each fixture: ordered
  component snapshots, statuses/ratios, appearance, and final random state.
  Existing before/after checks also independently reassess each returned color.
- Five entries consume two draws and include three best efforts. Eight entries
  consume 100 draws and include two unavailable fallback entries. The prototype
  preserves those outcomes; it does not fabricate measurements for fallback colors.
- Source hashes were verified before preflight and sampling. The stored candidate
  patch contains only the six read/write removals and associated empty branches
  and comments; no calculation or harness change is hidden in the comparison.
- Release disassembly retains preparation before timing, the public assessed
  request and full-array consumption between clock reads, and the request loop.
  Relevant instruction addresses and full output are retained with the evidence.

An initial preflight attempt used one sample of one request. Its fourth process
failed with `BenchmarkError.invalidClock`; the first three completed records had
equal output diagnostics. A one-iteration control can produce a zero total, but
the exact failing interval was not instrumented. The failure and incomplete
preflight are preserved. Preflight was changed to the harness's usual 100 requests
per sample, leaving both executables and the main sampling protocol unchanged.
No failure or excluded sample occurred in the completed main comparison.

The build logs include the existing AppKit appearance deprecation warning. No
production fix was bundled into this experiment. Full iOS/macOS library tests,
release-client checks, DocC, minimum-OS runtime, and binary compatibility were not
run. Insertion-behavior tests would intentionally reject the direct prototype;
benchmark correctness is not evidence of 3.x compatibility.

## Reproduction and evidence

The [review evidence archive](evidence/cache-2026-10-01/README.md) contains samples,
patches, source hashes, scripts, and verification excerpts, with instructions for
reconstructing the pinned sources. Build products and full disassembly stay local.

Local evidence directory:
`/Users/agis/projects/ColorKit-evidence/cache-ownership-2026-10-01/`.
It contains `source.tar`, `source-manifest.json`, `candidate.patch`, both isolated
source/build trees, `prepare.py`, `compare.py`, `raw.json`, `summary.md`,
`analysis.json`, preflight artifacts, build logs, sampling log, and disassembly.
The scripts reject overwriting the principal artifacts.

Executed build and driver commands, from the evidence directory:

```sh
swift test --package-path baseline/Benchmarks -c release
swift test --package-path direct/Benchmarks -c release
python3 compare.py preflight
python3 compare.py sample
```

For a fresh reproduction, follow the
[evidence setup instructions](evidence/cache-2026-10-01/README.md#reconstruct-the-compared-sources),
then run the commands above with the matched toolchain. Use a separate run directory
to preserve the original artifacts. The driver records new binary hashes and
environment; compiler inspection must be repeated for the rebuilt binaries.

Measured executable SHA-256:

- Baseline: `4d819115b8b4d3e92ea540facccad6839783cc3346e54e3290725eb684ff03c5`.
- Direct: `a82ea011c0965b3f2934b8d0b7120ccfa451403f758ef5d4d597854afc60b059`.

## Design implication

Retaining the implementation remains the safest near-term choice because no
application need was established and public insertion/population is shipped
behavior. The reason to investigate further is now concrete: total caching cost
exceeded saved computation in these two palette workloads, even when primed.

The subsequent [HSL-only comparison](hsl-cache-performance-2026-10-01.md)
is complete. It isolated the internally writable HSL store and found both benefits
and regressions, supporting retention of HSL reuse. The all-cache bypass benefit
must not be attributed to HSL alone.

For a deliberate major release, direct computation should remain a first-class
alternative to selective internal or request-local reuse. Public insertion can
be reconsidered under the agreed ownership direction, with source and behavioral
migration guidance. A general cache framework, actors, TTLs, and tuning controls
are not supported by this evidence.
