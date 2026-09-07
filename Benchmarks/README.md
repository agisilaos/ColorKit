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

The output directory must be new. The command builds first, then runs seven named
scenarios serially, using a fresh process for every scenario/cache pair in each
of three runs. Each process performs 10 untimed warm-up requests and records 10
samples of 100 individually timed requests. Override these modest defaults with
`--runs`, `--samples`, and `--iterations`; keep settings equal when comparing runs.
Run with other builds and intensive applications idle, on consistent power
settings. The report records power information but does not control system load.

## What is measured

| Scenario | Complete request |
| --- | --- |
| `hsl-red` | Convert opaque sRGB red to HSL |
| `lab-red` | Convert opaque sRGB red to D65 LAB |
| `comparison-black-white` | Full comparison, including CIEDE2000, RGB/HSL deltas, contrast, and compliance |
| `enhancement-compliant` | Assess already-compliant black against white with a distance budget of 100 |
| `enhancement-adjusted` | Enhance sRGB 80% gray against white with a distance budget of 100 |
| `enhancement-best-effort` | Enhance the same gray with a distance budget of 25 |
| `palette-red-five` | Generate and assess one entire five-color palette from red against white |

Enhancement explicitly uses AA, preserveHue, and preferDarker. Palette generation
uses AA and includes black and white. Every fixture is validated before and after
measurement; invalid outputs fail the runner. The JSON contains each scenario's
purpose, exact inputs, settings, expected outcome, and operation unit. One palette
request includes all internal generation attempts and all five assessments.

The palette API uses internal, unseeded random hue shifts and has no public RNG
control. Its request inputs are fixed, but candidate colors, attempt counts, and
timings can vary. The priming request can populate different candidate entries
from the measured request. This scenario is labeled stochastic in the JSON and
must not be treated as a deterministic comparison of cache hits or library versions.

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
fixture validation, warm-up, sample storage, and report formatting. Each sample
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
details, executable hash, hardware, OS, Swift/Xcode/SDK, power, build mode, and
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
