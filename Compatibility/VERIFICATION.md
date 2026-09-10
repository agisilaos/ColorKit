# Compatibility gate verification

## 3.1.0 frozen client — 2026-09-10

Branch `chore/freeze-3.1-client` starts at current `origin/main`,
`4bcc311c74e74096217097f8e38b6d93a147248e`. Verified with
`git ls-remote origin refs/tags/v3.1.0 'refs/tags/v3.1.0^{}'`:
the annotated tag object is `0eba424a95143c0a54ff58d9ae5edd6fca45d5d8`,
and its peeled commit is `4bcc311c74e74096217097f8e38b6d93a147248e`.
Local tag inspection and `git rev-parse 'v3.1.0^{commit}'` agree. The baseline
pins that released commit, even though main currently points to it too.

- `python3 scripts/check_compatibility.py`: PASS for **both 3.0.0 and 3.1.0**
  on macOS and iOS Simulator. The new client compiles against its archived release
  and the candidate; both releases' complete API comparisons pass on each platform.
  Automatic directory discovery required no checker or CI changes.
- Xcode 26.5 (17F42), Swift 6.3.2, arm64, Swift 6 language mode; client targets
  macOS 12 and iOS 14. Diagnostics: `.build/compatibility/run-cc0ibghq/`.
- `python3 -m unittest discover -s scripts/tests`: all 26 tests pass, including
  existing command/API failure propagation, zero-exit breakage diagnostics,
  release-gate failures, and fixture immutability. The added test confirms later
  release discovery and rejection of edits/deletions to either release's client
  and revision after preservation in the trusted Git base.
- `git diff --check`: PASS. The 3.0.0 baseline, mutable documentation fixture,
  production API/behavior, contrast example, and shared product docs are unchanged.
- `swiftlint lint --strict`: PASS, zero violations in 121 files.

The new fixture covers nonisolated typed/inferred/unbound method references, all
seven independently consumed results and payload fields, released conformances,
and exhaustive Result/issue handling. sRGB and Display P3 workflows preserve client
source for successful and partially unavailable conversions. These workflows are
typechecked, not executed. Runtime tests and the historical deliberate production
mutations below were not rerun for this fixture-only extension. This is not binary,
older-compiler, minimum-OS runtime, physical-device, or remote CI validation.

The normal run's log timestamps span about 60 seconds. The added 3.1.0 baseline
phases total about 16 seconds (macOS 9, iOS 7), measured from each baseline build
log's creation to its API comparison completion. These are local observations,
not a CI timing guarantee. Per platform the extra work is one release build, one
API extraction/comparison, and two client typechecks; candidate work is shared.
No version bump, release preflight, or release was performed.

## Original 3.0.0 gate verification

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
