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

Each release directory contains its pinned full commit in `revision` and its Swift clients.
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

The 3.1.0 baseline pins the peeled `v3.1.0` commit
`4bcc311c74e74096217097f8e38b6d93a147248e`. Its standalone `ComponentResults.swift`
client preserves nonisolated method references, all seven independent results and
payload fields, Sendable/Equatable conformances, and exhaustive Result/issue handling.
sRGB and Display P3 workflows are typechecked; runtime outcomes remain covered by
`ColorComponentConversionResultsTests` and `PublicComponentConversionTests`.

The normal checker discovers both baselines automatically. Each added release costs
one baseline build, one API extraction/comparison, and two client typechecks per
platform; candidate work is shared. The initial local 3.1.0 phases added about
16 seconds total on Xcode 26.5 (timing varies).

Do not edit existing client files to make an API change pass. Git compares the
fixture directory against the PR base (`--fixture-base`, default `origin/main`)
and rejects changes or deletions to existing files, including release revisions.
The first PR establishes the fixtures and requires review of their initial coverage.

To extend coverage, add a separate Swift file to the release directory. It must
compile against that release. For later releases, add a directory containing a
`revision` file and clients for newly shipped APIs. Fetch full history before
running the checker in a shallow clone.

## Builds and diagnostics

Every run archives each pinned release, then builds the release and candidate
with the same compiler, SDK, architecture, and settings on both platforms.
It compiles the clients against each module and compares their public APIs.
There is no compatibility cache: release builds and API extraction run every time.
This costs extra build time but avoids cache keys, receipts, and invalidation rules.
Temporary release sources and builds are removed when the check finishes.

Build products and logs default to `.build/compatibility`; override with `--storage`.
Each invocation retains the environment, command output, and both API inventories
under a unique `run-*` directory. CI uploads that directory with its test artifacts.
If a toolchain upgrade cannot build an original release, the check fails.

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
