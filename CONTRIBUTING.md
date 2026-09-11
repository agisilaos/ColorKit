# Contributing to ColorKit

Keep changes focused, preserve shipped contracts, and provide evidence for behavior changes. Use [GitHub Issues](https://github.com/agisilaos/ColorKit/issues) to discuss bugs or proposed features.

## Set up

1. Fork and clone the repository.
2. Create a branch beginning with `feature/`, `fix/`, `refactor/`, or `chore/`.
3. Select Xcode 26.5 to match the build and documentation CI jobs.
4. Install SwiftLint with `brew install swiftlint`.

The library requires Swift tools 6.0, iOS 14, and macOS 12. Examples may have higher requirements; check their own READMEs. See [Package.swift](Package.swift) for the library configuration.

## Implement and document

- Prefer clear call sites, focused functions, and established color terminology. Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
- Treat [.swiftlint.yml](.swiftlint.yml) as the lint source of truth. Package builds do not run lint; CI runs `swiftlint lint --strict`.
- Preserve released 3.x source and documented behavior, including legacy fallbacks. See [ADR 0013](docs/adr/0013-preserve-shipped-3x-client-contracts.md).
- Add focused regression tests for changed behavior. Keep tests independent; follow the shared-state rules below when independence is impossible.
- Document public APIs and update the relevant DocC article, English/Spanish README or usage recipes, changelog, and migration guidance when affected.
- Keep terminology in [CONTEXT.md](CONTEXT.md). Record consequential design decisions under `docs/adr/`; do not introduce abstractions solely for anticipated needs.

### Checked examples

`scripts/check_documentation.py` compiles actual Swift fences marked with `<!-- swift-example: example-id -->`. Add each marker to the script's explicit inventory; removing a required marker must not silently reduce coverage.

The READMEs contain checked quick starts and catalog examples. The bilingual [usage guides](docs/Usage.md) contain the conversion and workflow recipes. Keep snippets self-contained and translations semantically aligned.

The checker executes the guides' HSL, CMYK, LAB, and component-result recipes in both languages. Keep their variables aligned with `README_CHECKS`, the existing postcondition table in the script.

Named HSL inputs are checked for availability and normalized finite components, not appearance-specific values. Fixed conversion examples use numeric or availability postconditions. Add checks when examples promise specific results.

Generated theme code is compiled too, including named, translucent, grayscale, and Display P3 inputs. Temporary generated files are not committed.

A successful DocC build does not compile fenced Swift. Example checks cover selected snippets—not all prose, UI behavior, or performance claims. Preserve both documentation generation and compiler checks.

## Run checks

Run these from the repository root with Xcode 26.5 selected. These commands cover the current CI jobs:

```sh
swiftlint lint --strict
python3 -m unittest discover -s scripts/tests
python3 scripts/check_compatibility.py
swift test --package-path Benchmarks -c release
swift test --package-path Examples/ContrastPairReport
scripts/run_tests.sh
xcodebuild docbuild -scheme ColorKit -destination 'generic/platform=macOS' \
  -derivedDataPath .build/documentation \
  -skipMacroValidation \
  'OTHER_DOCC_FLAGS=--warnings-as-errors'
python3 scripts/check_documentation.py --derived-data .build/documentation
```

CI configuration lives in [.github/workflows/ci.yml](.github/workflows/ci.yml). For local iteration, start with the relevant subset; before review, disclose which checks ran and any gaps.

### Platform tests and diagnostics

The zero-argument test runner performs iOS and macOS tests with parallel testing enabled, followed by serialized shared-state suites on each platform. The pinned iOS destination is iPhone 17 with iOS 26.5.

Keep destinations and the shared-suite list in [scripts/run_tests.sh](scripts/run_tests.sh), not duplicated in CI. Override `COLORKIT_IOS_DESTINATION`, `COLORKIT_MACOS_DESTINATION`, or `COLORKIT_DERIVED_DATA` for local needs.

`ColorCacheIntegrationTests` and `ThemeManagerIntegrationTests` must run without parallel testing. The canonical runner handles this. Direct cache tests use independent instances; theme tests restore selection but leave registered fixtures in the process.

Build storage defaults to `.build/xcode`. Each matrix run retains logs and result bundles under a unique `.build/test-results` directory; `--results-dir TestResults` changes the parent.

For targeted runs, use `scripts/run_tests.sh --help`. Explicit single-destination runs support `--log-file`; create its parent directory first. CI retains test and compatibility artifacts for 14 days, including failed-run diagnostics.

If a simulator is missing, check CI's “Show Xcode and Available Simulators” output and the [runner image inventory](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md).

### Compatibility and performance

The [compatibility gate](Compatibility/README.md) protects pinned 3.0.0 and 3.1.0 clients and compares public APIs on iOS and macOS. Existing fixtures are immutable relative to the PR base; extend coverage with new files.

Fetch full Git history before compatibility checks. CI passes its exact base commit with `--fixture-base`; local checks default to `origin/main`. These checks do not prove binary compatibility or minimum-OS runtime behavior.

Benchmark correctness tests do not enforce machine-specific timing thresholds. For performance claims, run the [Release benchmark](Benchmarks/README.md) with other builds idle and retain the inputs, environment, and raw samples.

## Submit a pull request

- Keep commits focused and explain the change, its reason, and meaningful alternatives.
- Report commands run, results, and validation limitations. Distinguish local evidence from CI.
- Include Unreleased notes for notable changes and migration guidance for changed results, fallbacks, enum cases, or deprecations—not only signature changes.
- Reconcile documentation and migration notes after integrating overlapping work; rerun affected checks against the combined result.
- Attach UI review screenshots to the PR, not `docs/screenshots/`. Keep local captures ignored. Images used by published documentation may remain in the repository.

## Release preflight

After release preparation is merged, run `scripts/check_release.sh <version>` on clean, synchronized `main` before tagging. Omit the `v` prefix from the argument.

The script verifies version/changelog metadata and tag availability, then runs compatibility and the canonical behavioral matrix. It does not publish a release or replace documentation, lint, example, and benchmark checks.
