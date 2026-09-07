# Release client compatibility

Run `python3 scripts/check_compatibility.py` from any working directory. It builds
ColorKit and checks preserved clients against both the original release and the
current code on macOS and iOS Simulator, with Swift 6 language mode and client
minimum deployment targets of macOS 12 and iOS 14. Library builds use their package's
actual deployment requirements, so raising those requirements can fail the old client.
The checker also compares the complete public ColorKit API, including deprecated
declarations. Runtime behavior is checked by `scripts/run_tests.sh`.

CI runs both commands in the existing **Build and Test** job for every non-draft PR.
Release preflight (`scripts/check_release.sh <version>`) requires both to pass after
its metadata and Git checks. An unavailable compiler, missing baseline, empty API
inventory, failed compilation, or API diagnostic makes the check fail.

## Preserved clients

`baselines.json` pins full release commits and SHA-256 hashes of each client file.
The initial source baseline is 3.0.0 at
`b54ca5adfc80290003c543a23483503d1c5f4d4b`. Client files are typechecked with ordinary
public imports; they are separate from current examples and are intentionally
outside the normal formatting/lint inventory once preserved.

- `Methods.swift` preserves typed, inferred, bound, and unbound method references,
  plus ordinary calls that omit defaulted arguments and the deprecated adapter.
- `Enums.swift` exhaustively switches over all inhabited public enums in 3.0.0,
  including nested theme, inspector, and deprecated simulation enums.
- `Workflows.swift` covers public initializers and a stored initializer reference,
  conversion, enhancement, palette/export workflows, and actor-isolated theming
  and preview creation. Ordinary color work remains nonisolated.

Do not edit existing client files to make an API change pass. The checker compares
all existing client hashes and release commits with a trusted Git revision before
building. CI supplies the PR base SHA through `--fixture-base`; local runs default
to `origin/main`. A changed client fails even if its manifest hash changes with it.
The first PR establishes the initial inventory, so review that addition explicitly.

To extend coverage, add a separate client file and its hash to the matching release
record. It must also compile against that exact release. At each later release,
add its pinned commit and representative clients for newly shipped APIs; retain
older records and client files. Every registered release is checked on both
platforms. Fetch full history and tags before running the checker in a shallow clone.

## API inventories and cache

Each platform uses one compiler, SDK, architecture, Swift language mode, and build
configuration for the baseline and candidate. The original release source stays
fixed while API inventories are regenerated as the toolchain changes.

The cache key covers the release record, client hashes, Xcode and Swift versions,
SDK path/version/build, target, build settings, and checker contents. A completed
cache entry certifies that the client compiled against the release and contains a
checksum-verified, nonempty API inventory. Incomplete entries are rebuilt; corrupt
completed entries fail with their path. Remove only that generated entry to rebuild
it. Candidate builds, API extraction, and client compilation always run.

Build products and logs default to `.build/compatibility`; override this using
`--storage`. Each invocation retains its environment, both output streams, and API
diagnostics under a unique `run-*` directory. CI uploads those diagnostics with
its test artifacts. Baseline data is cached across CI runs; only verified complete entries are reused.
If a toolchain upgrade cannot build an original release, investigate the failure
before accepting the upgrade.

The checker currently has no diagnostic exceptions. A future exception requires
an exact diagnostic, a written reason, and a reproducer establishing source
compatibility. Broad suppression, including suppressing deprecated API removals,
would violate the accepted contract.

## Behavioral coverage

The canonical test matrix retains the existing tests below on iOS and macOS.
Only concrete gaps receive additional assertions.

| Promise | Test coverage |
| --- | --- |
| Strict comparison availability, per-input issues, metric provenance | `ColorComparisonResultTests` |
| Legacy comparison RGB/HSL fields, distance 255 for opposite endpoints, declined contrast sentinel | `ColorComparisonResultTests.deprecatedAdapterIdentifiesMetric` |
| WCAG measurements, compositing, unavailable outcomes | `ColorContrastResultTests`, `ColorAccessibilityResultTests`, `WCAGContrastOpacityTests` |
| Inclusive enhancement budgets, invalid/unavailable results, fallback search, stable ties | `EnhancementDistanceBudgetTests` |
| Variant order and distinctness, nonpositive counts, legacy budget independence | `EnhancementDistanceBudgetTests`, with an explicit released strategy order |
| Assessed palettes preserve their original palette | `ColorAccessibilityResultTests` |
| Deprecated arbitrary-view simulation remains a no-op | `ColorVisionSimulationTests.testLegacyArbitraryViewModifierLeavesRenderedContentUnchanged` |
| Theme selection and registry behavior | `ThemeTests`, serialized `ThemeManagerIntegrationTests` |

Compilation, API inventories, and these tests provide bounded evidence. They do
not prove every possible client workflow, binary compatibility, old-compiler
support, or runtime behavior on the minimum OS versions. See the
[accepted design](../docs/design/release-client-compatibility.md) and
[ADR 0013](../docs/adr/0013-preserve-shipped-3x-client-contracts.md).
