# Public consumer validation

These separate executable targets depend on the repository's `ColorKit` library
product through SwiftPM and use ordinary `import ColorKit`, without `@testable`.
They require Swift 6 and macOS 12 or later to run.

## First-use journey

From the repository root:

```sh
swift run --package-path Validation/ComponentConsumer -c release FirstUseConsumer
```

The first-use smoke run checks fixed and partially available conversion, directional
contrast and a WCAG target, all four bounded-adjustment outcomes, and explicit
light/dark appearance capture. Failed checks exit unsuccessfully. It remeasures
candidate contrast and distance through public APIs without fixing a strategy's
candidate or requiring every valid request to meet its target.

Compile the same consumer, including its UIKit capture path, for iOS 14 or later:

```sh
cd Validation/ComponentConsumer
xcodebuild -scheme FirstUseConsumer -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/colorkit-first-use-ios CODE_SIGNING_ALLOWED=NO build
```

This is an unsigned consumer compilation and link check, not an iOS app launch.
The macOS run does not prove minimum-OS runtime or physical-device behavior.
Build output and generated Xcode state stay out of version control.

The initial audit used main `0c2986e`: an external temporary package resolved the
GitHub URL at that revision, ran on macOS 26.6.2, and compiled/linked for iOS with
Xcode 26.5. No adoption blocker was found. The small guidance gaps were attaching
the library product to the consuming target and handling every adjustment outcome
in the usage recipe. The API map, partial-availability contract, and linked
appearance guidance were sufficient; no new API was needed. This records local
evidence, not CI or minimum-OS/device validation.

## Hosted component inspection

A separate macOS SwiftPM executable consumes the repository's library product with
ordinary public imports. It hosts its own SwiftUI inspection view in an AppKit
window; it does not import or instantiate the catalog implementation.

From the repository root:

```sh
swift run --package-path Validation/ComponentConsumer -c release ComponentConsumer
```

The smoke run checks 7/7, 3/7, and 0/7 available representations for fixed black,
P3 red, and dynamic primary, lays out each inspection, then exercises the documented
AppKit light/dark capture recipe. A failure exits unsuccessfully. Pass
`--interactive` to retain the final window for manual inspection.
This is consumer integration evidence, not a visual or accessibility audit.

The public behavioral assertions live in
`Tests/ColorKitTests/Utilities/PublicComponentConversionTests.swift` and run on both
platforms with the normal test runner. The existing nonisolated compilation fixture
remains `scripts/fixtures/component_results.swift`.
