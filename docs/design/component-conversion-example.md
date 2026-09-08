# Component Results catalog example

Dependency: approved contract in `component-conversion-results.md` and implementation
commit `4282e79ecc8712b90195032bbfe7c4fab1975da3` (PR #62).
Branch `feature/conversion-result-example` starts at that commit.

Open **ColorKit Catalog → Component Results**. Select fixed sRGB black for genuine
zeros, Display P3 red for partial availability, or dynamic primary for unavailable
fixed components. The example calls `componentConversionResults()` once per
inspection and switches on each field independently. It does not change existing
public previews or conversion APIs.

Hue turns become degrees; bounded fractions become percentages. Extended sRGBA,
XYZ and LAB retain their coordinate scales. Failed fields show explanations and
never pass through the numeric formatter. All fields describe the same fixed,
uncomposited snapshot; appearance-dependent input requires caller-side resolution.

Focused tests cover units, zero, independent failures, diagnostics, and hosted
light/dark rendering on iOS and macOS, including accessibility text size. Review
captures belong in ignored `.build/` storage and PR attachments, not Git.

Validation (2026-09-07): six focused tests passed on iOS 26.5 (iPhone 17
simulator) and macOS 26.6.2. Run with `scripts/run_tests.sh` and
`-only-testing:ColorKitTests/ComponentConversionPreviewTests -parallel-testing-enabled NO`.
Strict SwiftLint and `git diff --check` passed. The catalog and sample picker were
also exercised in native review hosts on both platforms. Accessibility labels and
values were inspected in the running apps; this was not a full spoken VoiceOver audit.

Final captures: `.build/review/accepted/ios/` and `.build/review/accepted/macos/`.
Each contains all three samples in both appearances. The iOS accessibility-size
capture includes the scrolled bottom, with a test asserting vertical scrolling
and no horizontal overflow. macOS does not scale these fonts via iOS Dynamic Type.
The tall hosted captures expose the inspection content for review; they are not
claims about physical screen size or display gamut accuracy.
