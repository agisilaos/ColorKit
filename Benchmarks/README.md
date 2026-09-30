# ColorKit reference benchmarks

This repository-local macOS package measures complete requests through ColorKit's
public API in Release mode. It adds no product or dependency to the library's
manifest. The SwiftUI preview remains an exploratory tool with uncontrolled cache
state; gradient timings there measure value construction only.

From the repository root, with Xcode selected:

```sh
swift test --package-path Benchmarks -c release
python3 Benchmarks/run.py --output .build/benchmark-results/first
```

The output directory must be new. The command builds first, then runs 33 named
scenarios serially, using a fresh process for every scenario/cache pair in each
of three runs. Each process performs 10 untimed warm-up requests and records 10
samples of 100 individually timed requests. Override these modest defaults with
`--runs`, `--samples`, and `--iterations`; keep settings equal when comparing runs.
Run with other builds and intensive applications idle, on consistent power
settings. The report records power information but does not control system load.

## What is measured

| Scenario | Complete request |
| --- | --- |
| `component-results-red` | All seven component-conversion results for opaque sRGB red (cache unused) |
| `hsl-red` | Convert opaque sRGB red to HSL |
| `lab-red` | Convert opaque sRGB red to D65 LAB |
| `comparison-black-white` | Full comparison, including CIEDE2000, RGB/HSL deltas, contrast, and compliance |
| `enhancement-compliant` | Assess already-compliant black against white with a distance budget of 100 |
| `enhancement-adjusted` | Enhance sRGB 80% gray against white with a distance budget of 100 |
| `enhancement-best-effort` | Enhance the same gray with a distance budget of 25 |
| `palette-{pair}-{size}-seed-{seed}` | Generate and assess one entire palette; three input pairs × sizes 5/8 × RNG seeds 0/42/2026 |

Enhancement reference cases explicitly use AA, preserveHue, and preferDarker;
additional chromatic enhancement cases cover the strategy/direction combinations.
Palette generation uses AA and includes black and white. Palette input pairs are
opaque fixed sRGB red `(1, 0, 0)` against white, brand blue `(0.2, 0.4, 0.7)` against
white, and the same blue against black. Requested sizes are 5 and 8. Every fixture
is validated before and after measurement; invalid outputs fail the runner.
The JSON retains exact inputs, settings, expected outcome, and operation unit.
One palette request includes all internal generation attempts and every returned
entry's assessment; a partial palette is permitted by the public contract.

## Repeatable palette experiment

Run only the eighteen palette workload/seed combinations (36 cache pairs):

```sh
python3 Benchmarks/run.py --scenario-prefix palette- \
  --output .build/benchmark-results/palette-reference
```

The harness uses the app-owned SplitMix64 generator from the public
[replay example](../Sources/ColorKit/Documentation.docc/Accessibility-article.md#replaying-a-palette).
It resets state outside timing for every request. Priming executes the **identical**
seeded request, then restores the initial random state before the measured call.
Empty and primed modes therefore replay the same ordered candidate workload.
They describe ColorKit cache preparation, not guaranteed hits or application cache
patterns after a base-color change. Seeds are reference cases, not a statistical
sample of all possible requests. Legacy calls still use system randomness.

Untimed diagnostics retain random draws, final state, ordered component snapshots,
assessment statuses/ratios, requested count, and appearance. The timed generator
has no draw counter. Before/after checks compare exact ordered output and final
state to an untimed reference and independently reassess every color. The report
also rejects differing diagnostics across runs or cache modes. Fixed component
results are preferred; named fallback colors that lack fixed components are
explicitly captured through AppKit for the current appearance. That capture does
not make an unavailable accessibility assessment available.

Replay requires the same generator implementation/initial state, fixed inputs,
configuration, ColorKit version, platform, OS/framework versions, toolchain,
build settings, and appearance (including fallback colors). It does **not** promise
identical output across versions or environments. Exact draw counts describe this
revision's work, not a public contract. See the
[agreed investigation](../docs/design/benchmark-correctness.md#assessed-palette-investigation--2026-09-30).

## Cache and timing boundaries

- `empty`: clear `ColorCache.shared` immediately before **each** timed request.
- `primed`: clear, execute the same request once outside timing, then time its next execution.
- `unused`: the operation does not use ColorKit's cache (full comparison and the
  already-compliant enhancement path).

Each enhancement or palette request retains caches populated by its own internal
operations. Priming describes preparation, not a guaranteed hit rate. No claim is
made about CPU or OS cache state. Public cache controls and process isolation keep
the library's public API unchanged.

The monotonic interval includes input barriers, request dispatch, the public
operation, and consumption of its complete result. It excludes cache preparation,
RNG reset, fixture validation, diagnostic requests, warm-up, sample storage, and
report formatting. Each sample
stores a sum of request intervals and its request count. The enclosing loop and
preparation wall time are not reported as request throughput.

A control uses the same timing and preparation with a precomputed result of the
same type. It includes an extra input-consumption call and may retain/release
values differently; it is an approximate overhead comparison, not a subtraction
calibration. It alternates before/after each workload sample. Both raw totals are
saved without subtraction. When the control approaches the request time, or the
sample range is large, avoid interpreting small differences as performance changes.

## Results and compiler verification

`raw.json` retains all samples and run identities plus source revision, dirty-tree
details, tracked patch, exact harness source snapshot, invocation, executable hash,
hardware, OS, Swift/Xcode/SDK, power, build mode, and
sampling settings. `complete: false` means execution stopped before all scenarios
finished; such an artifact is not a completed baseline. `summary.md` reports the
median and range of sample means in nanoseconds per complete request.

The barriers use `@_optimize(none)` and `@inline(never)`; their presence alone does
not prove work survived optimization. After harness or toolchain changes, inspect
the Release executable with `xcrun llvm-objdump --disassemble --demangle` (or `otool
-tvV`) and verify the timer/request/consume calls remain inside the request loop.
Check each specialized result type and confirm the operation closures still call
HSL/LAB conversion, full comparison, enhancement, and palette generation. Record
this verification alongside baseline results. No underscored annotation is added
to ColorKit's public API.

See [harness verification](VERIFICATION.md) for the checked executable
and local validation evidence.

These measurements establish reference data for this machine and toolchain. They
do not establish a speedup, a performance regression threshold, an iOS baseline,
or rendering performance. See the [agreed design](../docs/design/benchmark-correctness.md).

Completed palette investigations: [2026-09-30](../docs/validation/assessed-palette-performance-2026-09-30.md).
