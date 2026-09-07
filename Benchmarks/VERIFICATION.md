# Initial harness verification — 2026-09-07

The initial local validation completed successfully on an Apple M4 Pro, macOS
26.6.2, Xcode 26.5 (17F42), and Swift 6.3.2. This was a dirty-worktree validation
based on `b54ca5adfc80290003c543a23483503d1c5f4d4b`, not a clean-revision published
baseline. Capture a fresh baseline after committing and reviewing the harness.

## Runtime evidence

`python3 Benchmarks/run.py --output .build/benchmark-results/validation` completed
all 36 isolated processes: three runs of 12 scenario/cache pairs, with 10 samples
of 100 requests each. The local `raw.json` has `complete: true` and 360 samples;
it retains the dirty-tree details and environment. Its companion `summary.md`
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
`097ef5a84c400879b1a92305e090ff00e078a5b61efd857600cef4dd6b191f3b`.

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
