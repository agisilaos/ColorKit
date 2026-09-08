# Integrated component-conversion validation — 2026-09-08

**PASS within the requested feature-validation scope. No production defect found.**
This is evidence for considering 3.1, not release preflight or publication approval.

Candidate: `bc46e3e1e264d8b7d420cb607d546bf7d014b9e3`, verified equal to fetched
`origin/main`, including #62 and #63. Started clean and created
`chore/conversion-result-validation`. Production sources, package deployment
requirements, frozen 3.0.0 clients, and version metadata remain unchanged.
The only changes are public validation tests, a separate consuming app, one
benchmark scenario with its inventory/README update, and this evidence.

Reviewed AGENTS.md, CONTRIBUTING.md, CONTEXT.md, repository agent guidance,
component-conversion-results.md, component-conversion-example.md, ADRs 0012–0016,
release-client compatibility policy, implementation/resolver, existing focused
fixtures, inspector, and adoption material. Public calls were also checked against
the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
No API naming or contract contradiction was found.

## Findings ordered by caller impact

1. **P2, post-release compatibility protection:** the current nonisolated fixture
   (`scripts/fixtures/component_results.swift`) is compiled by the documentation
   job but is mutable with current examples. The frozen 3.0.0 API baseline cannot
   detect removal of an API that did not exist in that release. Once 3.1 is actually
   published, add `Compatibility/Clients/3.1.0/revision` pinned to its full released
   commit and preserve the existing fixture as a separate client in that directory.
   Include representative payload getter/equality use in the release client coverage;
   do not rely on evolving README examples for that promise. The existing checker
   discovers release directories, builds each pinned release and candidate on both
   platforms, compares APIs, and rejects edits to established fixtures relative to
   the PR base. No baseline was registered now, and no 3.0.0 client was edited.
2. **P3, repeatability of extra validation:** current CI compiles examples and the
   nonisolated fixture on macOS. This audit additionally compiled them for iOS, but
   that extra command and the separate consumer app are not new CI requirements.
   Consider retaining those checks when adopting the released fixture; this is a
   validation-maintenance opportunity, not an observed caller failure.

**Documentation follow-up:** no component-contract correction is required in DocC,
the English/Spanish README sections, or MIGRATION.md. They agree on independent
availability, fixed input, strict gamut, alpha, scales, and deliberate legacy math
differences. Preserve their existing content. After publication, perform ordinary
release wording updates and document the newly frozen fixture. Historical paths
and dates in the approved design/example documents describe their original work.

## Checks and results

| Check | Result |
| --- | --- |
| `python3 scripts/check_compatibility.py` | PASS: frozen 3.0.0 clients against release and candidate, full API digester including deprecated API, macOS and iOS Simulator; Swift 6 mode, client targets macOS 12 / iOS 14 |
| Existing focused behavioral suites on macOS 26.6.2 and iPhone 17 / iOS 26.5 Simulator | PASS: 71 XCTest tests on each platform, serialized |
| `PublicComponentConversionTests`, ordinary `import ColorKit` | PASS on both platforms: 3 Swift Testing functions, including 3 alpha argument cases (5 invocations) |
| Separate `Validation/ComponentConsumer` Release executable | PASS: hosted own SwiftUI view with 7/7, 3/7, 0/7 availability, then AppKit aqua/darkAqua capture |
| DocC `--warnings-as-errors` | PASS |
| Existing `scripts/check_documentation.py` | PASS: 35 actual marked examples compile, 8 actual English/Spanish README conversion examples execute; generated theme output compiles |
| Same extracted examples plus existing nonisolated fixture, iOS public module | PASS: 35 examples and fixture typecheck in Swift 6 with iOS 14 Simulator deployment target |
| `swift test --package-path Benchmarks -c release` | PASS: 5 tests, including all 8 scenarios and supported cache modes |
| Strict SwiftLint / `git diff --check` | PASS |

Focused XCTest suites: `ColorComponentConversionResultsTests`, `ResolvedSRGBATests`,
`ColorSpaceConverterTests`, `HSLResolutionTests`, `LABResolutionTests`,
`ColorCacheIntegrationTests`, and `ComponentConversionPreviewTests`.
The six catalog tests are supporting evidence, including hosted appearance/layout
checks; the separate consumer does not instantiate catalog types.

Coverage combines existing numerical tests with independent public-client checks:
primaries, legitimate zero, signed XYZ/LAB reference values, reference-white scales,
turns/fractions, alpha 0/0.5/1 without compositing, byte rounding, strict adjacent
endpoints, near-white HSL, subnormal CMYK/hue, grayscale/linear/P3/Adobe profiles,
extended gamut and overflow partial success, named/dynamic unavailable input,
light/dark fixed capture, unsupported models and surviving nonfinite input,
cache poisoning and unchanged legacy paths. Public tests independently pin green
XYZ/LAB coordinates, preserve transparent RGB, distinguish all-field unavailability
from black, and reconstruct a P3 result's published sRGBA to verify XYZ/LAB agreement.
Source inspection confirms one `resolveResult` call, one bounded branch, one XYZ
calculation feeding LAB, immutable stored outputs, and no legacy-cache consultation.
Replay equality alone is not proof of the exact resolver invocation count.

## Measurements

Added `component-results-red`: one complete public aggregate request for fixed
opaque sRGB red, all seven fields validated outside timing, whole result consumed.
ColorKit cache mode is `unused`. Harness timing/preparation code was not changed.

Apple M4 Pro (Mac16,7), macOS 26.6.2 (25G83), Xcode 26.5 (17F42), Swift 6.3.2,
arm64 Release, AC power. This task's builds/tests finished before sampling;
other system activity and thermals were not controlled.

| Workload | Median sample mean | Sample-mean range | Median control |
| --- | ---: | ---: | ---: |
| Seven-field red aggregate | 1,682.5 ns/request | 1,589.2–1,810.9 ns | 27.1 ns/request |

Three independent processes, 10 samples/process, 100 requests/sample: 3,000 measured
aggregate requests, plus 10 untimed warmups/process. Request/control sample order
alternates. The approximately 1.6% control is reported without subtraction and is
not a precise decomposition of overhead. The interval includes clock/barrier,
dispatch, conversion, result lifetime/consumption costs; construction, cache
preparation, correctness checks, storage, and reporting stay outside it.

[Raw samples and environment](raw.json) retain all 39 scenario/cache/run records
(`complete: true`) and the executable hash; [full summary](benchmark-summary.md)
includes the unchanged reference scenarios. Individual legacy HSL/LAB calls perform
different work, have different cache policies, and may have different numeric
contracts. Their timings do not establish a speedup or regression for this API.
No thresholds, overhead subtraction, iOS claims, or before/after claims were added.

[Disassembly excerpts](disassembly.txt) show the aggregate specialization's timed
loop retaining input barrier, indirect operation call, whole-result consume and
destruction, and clock calls before/after. The operation closure directly calls
`Color.componentConversionResults()` at `0x1000ca640`. The timed operation at
`0x1000c8d70` and consume at `0x1000c8d88` remain within the loop; cache preparation
precedes the start clock. Full local disassembly is retained under `.build`.
This validates optimization boundaries, not a Time Profiler attribution of cost.

## Reproduction and local artifacts

```sh
python3 scripts/check_compatibility.py
swift run --package-path Validation/ComponentConsumer -c release
swift test --package-path Benchmarks -c release
python3 Benchmarks/run.py --output .build/conversion-validation/new-benchmark-run
xcodebuild docbuild -scheme ColorKit -destination 'generic/platform=macOS' \
  -derivedDataPath .build/conversion-validation/docc -skipMacroValidation \
  'OTHER_DOCC_FLAGS=--warnings-as-errors'
python3 scripts/check_documentation.py --derived-data .build/conversion-validation/docc
swiftlint lint --strict
git diff --check
```

For focused tests use `scripts/run_tests.sh --log-file PATH PLATFORM DESTINATION
-parallel-testing-enabled NO`, followed by one
`-only-testing:ColorKitTests/SUITE` per suite named above and
`PublicComponentConversionTests`. Destinations used were
`platform=macOS,arch=arm64` and `platform=iOS Simulator,name=iPhone 17,OS=26.5`.

Local raw logs: `.build/conversion-validation/{compatibility,macos,ios,public-macos,
consumer,docc,examples,ios-examples,benchmark-tests,benchmark-run,lint}.log`.
Compatibility inventories/environment: `.build/compatibility/run-3x3nv2ep/`.
XCTest bundles: `.build/xcode/Logs/Test/`. These local logs/build products are ignored;
the measurement JSON, summary, and bounded disassembly excerpts are retained here.
The iOS compilation reused the documentation checker's extraction/wrapping helpers,
with `xcrun swiftc -typecheck -swift-version 6 -target arm64-apple-ios14.0-simulator`,
the simulator SDK, and `.build/xcode/Build/Products/Debug-iphonesimulator` as import
path. Extracted sources remain in `.build/conversion-validation/ios-examples/`.

During fixture preparation one benchmark build rejected a test file modified while
compilation was running; the subsequent stable-source run passed. Initial lint
reported two attribute-placement errors in the new public tests; formatting was
corrected and strict lint passed. Neither failure involved production behavior.

## Limits

This is a focused feature audit, not the full release matrix or final CI state.
Minimum-deployment compilation does not prove runtime on iOS 14/macOS 12, older
compilers, physical devices, Intel runtime, or binary compatibility. Consumer
hosting was exercised on macOS only; iOS has public behavioral tests and client
compilation. No new visual, spoken VoiceOver, or physical gamut audit was performed.
Platform-sanitized invalid inputs cannot be reconstructed; direct resolver tests
cover otherwise unobservable alpha validation. A real platform
`colorSpaceConversionFailed` was not manufactured, and cross-OS profile conversion
is not guaranteed bitwise identical. One bounded red benchmark does not characterize
P3 profile conversion, failures, UI rendering, or all caller workloads.
