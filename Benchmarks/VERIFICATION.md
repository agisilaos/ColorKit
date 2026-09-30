# Harness verification — 2026-09-07

Local validation completed successfully on an Apple M4 Pro, macOS 26.6.2,
Xcode 26.5 (17F42), and Swift 6.3.2. The final run used clean source revision
`5918b1ac50c3dcc3209785e87ea2b10c1cd96b56`; both tracked changes and untracked
files were empty in the recorded metadata.

## Runtime evidence

`python3 Benchmarks/run.py --output .build/benchmark-results/5918b1a` completed
all 36 isolated processes: three runs of 12 scenario/cache pairs, with 10 samples
of 100 requests each. The local `raw.json` has `complete: true` and 360 samples;
it retains the source revision and environment. Its companion `summary.md`
reports sample means and control overhead without subtraction. Both files are
local ignored artifacts, not committed reference results.

The five-color palette workload remains stochastic. Small conversion and
comparison timings also showed variation between samples; these observations do
not establish speedups or regression thresholds.

## Optimized workload execution

Inspected the actual Release executable with:

```sh
xcrun llvm-objdump --disassemble --demangle \
  Benchmarks/.build/arm64-apple-macosx/release/ColorKitBenchmarks
```

Executable SHA-256:
`caedfa6e7082f2c6fa5b61cec8279d21ffe4f7cfb68e8eec1b5f135d8c24fb30`.

Its disassembly was identical to the initially inspected validation executable.

The specialized request loops retain the opaque input call, operation dispatch,
and complete-result consumption between the clock reads. Cache preparation
precedes the timed interval on each back edge. The following instruction
addresses identify the checked calls in this executable only:

| Result type | Input barrier | Operation dispatch | Result sink | Loop back edge |
| --- | --- | --- | --- | --- |
| HSL/LAB optional triple | `0x1000b5cac` | `0x1000b5cbc` | `0x1000b5cd8` | `0x1000b5d10` |
| Full comparison | `0x1000b5a4c` | `0x1000b5a5c` | `0x1000b5a7c` | `0x1000b5abc` |
| Enhancement result | `0x1000b57b8` | `0x1000b57c8` | `0x1000b57e8` | `0x1000b5828` |
| Assessed palette array | `0x1000b5518` | `0x1000b5528` | `0x1000b5558` | `0x1000b5598` |

The supplied operation closures still invoke HSL/LAB conversion, full
`comparisonResult(with:)`, the enhancer method, and `generateAssessedPalette`.
The tuple closures share a conversion trampoline; comparison stores its full
result, and palette consumption receives the complete returned array. This
inspection is evidence for the identified compiler and executable, not a promise
about future compiler behavior. Repeat it after harness or toolchain changes.

## Regression checks

- Full `scripts/run_tests.sh` iOS/macOS and serialized shared-state matrix: PASS.
- `swift test --package-path Benchmarks -c release`: PASS, five tests in two suites.
- Python tooling tests: PASS, 15 tests.
- Strict SwiftLint: PASS, no violations in 116 files.
- DocC warnings-as-errors build and executable documentation examples: PASS.
- `git diff --check`: PASS.

The test matrix's local logs and result bundles are under
`.build/test-results/run.ZUlj9O/`. These checks preserve the ColorKit 3.0.0 public
contract; they do not replace the separate committed-branch review or publication
steps.

## Palette replay harness — 2026-09-30

The assessed-palette investigation uses production revision
`43a4f45c3fa50c882bc23e02b313e4225b51833f` plus the captured harness changes.
Measured Release executable SHA-256:
`6f3115837199467fad25ee44eae0e146ad0ab2b8363c181fc90bab80bd5f0157`.
The final raw artifact's hash matches the inspected executable. Environment and
full results are in the [investigation note](../docs/validation/assessed-palette-performance-2026-09-30.md).

Repeated the disassembly command above, piped the output through `xcrun swift-demangle`,
and checked `xcrun llvm-objdump --macho --indirect-symbols` to identify clock stubs.
Local full output and selected function excerpts are retained under
`.build/palette-investigation/`. The request loops keep preparation before the first
clock and input barrier/operation dispatch/full-result sink between clock reads:

| Result | Input barrier | Operation dispatch | Sink | Request loop back edge |
| --- | --- | --- | --- | --- |
| Assessed palette array | `0x1000b7db8` | `0x1000b7dcc` | `0x1000b7de8` | `0x1000b7e20` |
| Enhancement | `0x1000b872c` | `0x1000b8744` | `0x1000b876c` | `0x1000b87a8` |
| Full comparison | `0x1000b9134` | `0x1000b9144` | `0x1000b9164` | `0x1000b919c` |
| HSL/LAB optional triple (merged loop) | `0x1000b9a88` | `0x1000b9a98` | `0x1000b9aac` | `0x1000b9adc` |
| Aggregate component results | `0x1000ba348` | `0x1000ba358` | `0x1000ba370` | `0x1000ba3ac` |

For the palette loop, preparation dispatch is at `0x1000b7d64`; clock reads use
`DispatchTime.now`/`uptimeNanoseconds` stubs at `0x1000c69f0`/`0x1000c69e4`.
The operation closure at `0x1000bc308` calls the public RNG-bearing assessed request
at `0x1000bc384`. All assessments remain in that complete public request.
The conversion closures retain HSL/LAB targets through a merged trampoline; the
comparison closure calls full `comparisonResult` at `0x1000c44d8`; enhancement
retains its processor method dispatch at `0x1000c53f4`. The enhancer metadata
(`0x10010cf68`) slot at offset `0x68` contains `0x100003ee0`, the
`enhanceColorResult` target. Addresses apply only to this
hash/toolchain. No underscored annotations were added to the public library.
