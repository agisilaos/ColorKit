# Integrated component-conversion validation — 2026-09-08

**PASS within the requested feature scope. No production defect found.**
Candidate `bc46e3e1e264d8b7d420cb607d546bf7d014b9e3` matched fetched `origin/main`
with #62 and #63 integrated. This is evidence for considering 3.1, not release approval.
Changes add public tests, a separate consumer fixture, benchmark coverage, and evidence;
production behavior, deployment requirements, version metadata, and frozen clients are unchanged.

Review covered repository guidance, the [approved contract](../../design/component-conversion-results.md),
[catalog example](../../design/component-conversion-example.md), ADRs 0012–0016,
implementation/resolver, existing tests, and adoption material.

## Findings and follow-up

- **P2 — protect clients after publication.** The mutable nonisolated fixture
  `scripts/fixtures/component_results.swift` is compiled by the documentation job,
  but the 3.0.0 baseline cannot protect APIs introduced later. After 3.1 is published,
  preserve that fixture and representative payload getter/equality calls under
  `Compatibility/Clients/3.1.0/`, pinning `revision` to the full released commit.
  Use the [existing compatibility gate](../../../Compatibility/README.md); no unreleased baseline was registered.
- **P3 — retain extra validation where useful.** This audit's iOS example compilation
  and separate consumer smoke run are not additional CI requirements.
- **Documentation:** DocC, English/Spanish README sections, and MIGRATION.md agree
  with the implementation. Only ordinary release wording and frozen-fixture guidance
  need follow-up after publication; no adoption material needs rewriting.

## Checks performed

All checks passed with Xcode 26.5 / Swift 6.3.2 on macOS 26.6.2 and, where applicable,
an iPhone 17 simulator running iOS 26.5.

| Check | Evidence |
| --- | --- |
| Released clients/API | Frozen 3.0.0 clients compile against release and candidate on both platforms; API digester includes deprecated API; Swift 6, macOS 12 / iOS 14 client targets |
| Focused behavior | 71 existing XCTest tests per platform, serialized |
| Independent public imports | 3 Swift Testing functions / 5 invocations per platform: transparent green references, P3 snapshot replay, and unavailability versus black |
| Separate macOS consumer | Own hosted SwiftUI inspection: 7/7, 3/7, 0/7 availability, plus aqua/darkAqua capture |
| Documentation | DocC warnings-as-errors; 35 actual marked examples and existing nonisolated fixture compile on both platforms; 8 README examples execute on macOS; generated theme output compiles |
| Benchmark / hygiene | 5 Release tests cover all 8 scenarios and cache modes; strict SwiftLint and diff checks pass |

Existing suites: `ColorComponentConversionResultsTests`, `ResolvedSRGBATests`,
`ColorSpaceConverterTests`, `HSLResolutionTests`, `LABResolutionTests`,
`ColorCacheIntegrationTests`, and `ComponentConversionPreviewTests`.
Together with `PublicComponentConversionTests`, these cover units/ranges, signed
XYZ/LAB, alpha without compositing, byte rounding, adjacent gamut endpoints,
near-white/subnormal arithmetic, grayscale/linear/P3/Adobe profiles, overflow,
unsupported/nonfinite input, fixed versus dynamic capture, cache isolation, and legacy behavior.
Source inspection confirms one resolution and one XYZ calculation feeding LAB;
public snapshot replay checks agreement, not the exact invocation count.

## Release measurement

`component-results-red` measures one complete seven-field request for opaque sRGB red,
cache `unused`, with whole-result consumption. Apple M4 Pro (Mac16,7), arm64 Release,
AC power; this task's builds finished before sampling, but system load/thermals were uncontrolled.

| Median sample mean | Sample-mean range | Median control |
| ---: | ---: | ---: |
| 1,682.5 ns/request | 1,589.2–1,810.9 ns | 27.1 ns/request |

Three processes × 10 samples × 100 requests, plus 10 untimed warmups/process.
Request/control order alternates; control (~1.6%) is approximate and never subtracted.
Timing includes clocks, barriers, dispatch, conversion, and result lifetime;
input construction, preparation, validation, storage, and reporting are excluded.
[Raw data](raw.json) retain all 39 scenario/cache/run records, environment and executable hash;
[full summary](benchmark-summary.md) retains reference scenarios.
[Disassembly](disassembly.txt) confirms the aggregate call and consumption survive inside
the timed loop. These are machine-specific reference measurements, not profiling
attribution, thresholds, or speedup comparisons with different legacy contracts.

## Reproduce and inspect

Use the [documented gate commands](../../../CONTRIBUTING.md#ci-validation),
[consumer command](../../../Validation/ComponentConsumer/README.md), and
[Release runner](../../../Benchmarks/README.md). For focused tests, pass the suites
above to `scripts/run_tests.sh` with `-only-testing:ColorKitTests/SUITE` and
`-parallel-testing-enabled NO`. Destinations: `platform=macOS,arch=arm64` and
`platform=iOS Simulator,name=iPhone 17,OS=26.5`.

Extra iOS example compilation reused `scripts/check_documentation.py` extraction/wrapping
helpers with `xcrun swiftc -typecheck -swift-version 6 -target arm64-apple-ios14.0-simulator`,
the simulator SDK, and `.build/xcode/Build/Products/Debug-iphonesimulator` as import path.
Local logs, extracted iOS examples, and full disassembly: `.build/conversion-validation/`;
compatibility inventories: `.build/compatibility/run-3x3nv2ep/`;
XCTest bundles: `.build/xcode/Logs/Test/`. These local artifacts are ignored.

## Limits

Focused audit only: no full release matrix/final CI claim, minimum-OS runtime,
older-compiler, physical-device, Intel runtime, or binary-compatibility proof.
Consumer hosting was macOS-only; no new visual, spoken VoiceOver, or physical-gamut audit.
Platform-sanitized invalid inputs remain unobservable (direct resolver tests cover
alpha guards); no real `colorSpaceConversionFailed` fixture was manufactured.
Profile conversion is not bitwise portable across OS versions. One bounded-red
workload does not characterize P3 conversion, failures, rendering, or iOS performance.
