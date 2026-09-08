# Component conversion consumer validation

A separate macOS SwiftPM executable consumes the repository's library product with
ordinary public imports. It hosts its own SwiftUI inspection view in an AppKit
window; it does not import or instantiate the catalog implementation.

From the repository root:

```sh
swift run --package-path Validation/ComponentConsumer -c release
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
