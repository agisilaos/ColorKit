# Compatibility gate verification

Validated locally on 2026-09-07 with Xcode 26.5 (17F42), Swift 6.3.2, and arm64.
The candidate started at `3f122111681538db5bd71a01891b7619fba00ba9` plus this
change; the release source is the pinned 3.0.0 commit in `Clients/3.0.0/revision`.

The simplification was rechecked with fresh release builds on both platforms,
25 tooling tests, SwiftLint, and all three source/API mutations below. The
behavioral assertions and Swift fixtures were unchanged; their runtime validation
below predates this tooling refactor.

## Positive checks

- `python3 scripts/check_compatibility.py`: all three client files compile against
  both 3.0.0 and the candidate on macOS and iOS Simulator. Both public API
  comparisons pass. Client deployment targets are macOS 12 and iOS 14. Release inventories are rebuilt on every invocation.
- `scripts/run_tests.sh --results-dir .build/compatibility/behavior`: all four
  canonical phases pass, including the serialized shared-state suites on both
  platforms and the strengthened legacy comparison/variant-order assertions.
- `python3 -m unittest discover -s scripts/tests`: 25 tests pass, including fixture
  edits/deletions, pinned revision changes, zero-exit API diagnostics, and release
  gate failure propagation.
- `swiftlint lint --strict`: zero violations.
- DocC builds with `OTHER_DOCC_FLAGS=--warnings-as-errors` using the documented
  `xcodebuild docbuild` command.
- `python3 scripts/check_documentation.py --derived-data .build/documentation`:
  28 current public examples, six README conversion results, and actual generated
  theme-code compilation pass.
- `swift test --package-path Benchmarks -c release`: five correctness tests pass.
  This change does not alter production workloads or claim a performance change.

## Deliberate regressions

Experiments used an archived candidate in an ignored temporary source directory.
Each source mutation was restored afterward. Library builds succeeded before
running the preserved clients; the ordinary checkout's production source stayed
unchanged.

| Injected change | Observed failure |
| --- | --- |
| Add a fifth, defaulted parameter to `Color.enhancementResult` | Stored client method references fail; API comparison reports the renamed declaration |
| Add `futureStatus` to `ColorAccessibilityResult.Status`, handling it inside the library's own switches | The old client's exhaustive switch fails; API comparison reports the new enum case |
| Remove `public` from `ThemeColorSet.init(base:light:dark:)` | The client initializer call fails; API comparison reports removal |
| Change legacy RGB fallback scaling from 255 to 254 | `ColorComparisonResultTests.deprecatedAdapterIdentifiesMetric` fails its independent 255 assertion; the targeted macOS test command exits 65 |

Run source experiments in a disposable copy: rebuild the module, typecheck the
unchanged files under `Clients/3.0.0`, and compare its API inventory using the
commands retained in a normal checker's `run-*` logs. For the behavior experiment,
run the updated `ColorComparisonResultTests` against the mutated implementation
with:

```sh
scripts/run_tests.sh macOS 'platform=macOS,arch=arm64' \
  -only-testing:ColorKitTests/ColorComparisonResultTests
```

The installed API digester printed `API breakage:` while returning exit status
zero. The checker explicitly rejects that diagnostic, and a regression test
preserves this failure rule. Relying on the digester's exit status alone failed
these experiments.

Full release preflight was not run on this feature branch: it requires clean,
synchronized `main` and an unused release version. Its new compilation/behavioral
command sequence and failure propagation were exercised by the CLI tooling tests.
