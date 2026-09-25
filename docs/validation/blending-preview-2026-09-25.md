# Blending preview validation follow-up — 2026-09-25

Status: partial. These observations close specific evidence gaps; they do not
establish complete release readiness or spoken VoiceOver verification.

## Scope and environment

The temporary hosts linked the ColorKit module built from
`9e97a7431ec1c92e4bb8070ba2ece6232caa21dc`. Subsequent migration and benchmark
manifest fixes do not change library or preview source. The environment was
Xcode 26.5 (17F42), macOS 26.6.2 arm64, and iPhone 17 Simulator on iOS 26.5.

The earlier integrated run passed the canonical iOS/macOS matrix, including
serialized cache/theme suites, compatibility, lint, tooling, DocC, checked
examples, Release benchmark correctness, and standalone contrast-report tests.
This follow-up did not repeat that entire matrix or measure performance.

## Actual iOS picker interaction

A temporary SwiftUI host displayed the public `BlendingPreview()` and a host-only
light/dark toggle. Native UI automation operated the actual picker:

1. Opened Base color, selected a gray, entered 50% in the opacity field, and
   dismissed the picker. The result remained Success and showed a translucent
   red result over the checkerboard with the normal mode and opaque red blend.
2. Switched the host to dark appearance. The selected colors and translucent
   result remained visually unchanged; the accessibility tree retained the
   selected normal mode, labeled blend amount, and Success status.
3. Opened Blend color and entered 0% opacity. After dismissal, the accessibility
   tree identified the blend as transparent and exposed Success followed by
   “The blend color is fully transparent; the result matches the base.” The
   result visibly retained the gray base over the checkerboard.

These checks establish specific picker/opacity interactions and appearance
retention on this simulator. They do not establish every opacity value, wider-
gamut picker selection, minimum-OS behavior, or spoken announcements.

## Live macOS accessibility transition

A separate temporary host used the internal `BlendingResultPreview` with a
single `@State` toggle. It derived `BlendingPreviewOutcome` from fixed inputs or
`.primary`/`.secondary`, with amount zero. The view stayed in the same hierarchy;
there was no changing `.id` or replacement of a hosting controller's root view.
Native accessibility inspection reported:

| State | Result text in the accessibility tree |
| --- | --- |
| Fixed inputs | Result; Success; Amount is 0%; the result matches the base; opacity explanation |
| Both unavailable | Result; Result unavailable; independently named Base color and Blend color diagnostics; opacity explanation |
| Fixed inputs again | Result; Success; Amount is 0%; the result matches the base; opacity explanation |

Failure removed the old Success and unchanged explanation. Recovery removed
both error messages. The failure screenshot contained no swatch or checkerboard.
Decorative swatches/icons were not separate accessibility elements in these
observed states. A public-preview host also exposed the selected mode trait and
labeled blend-amount value; selecting multiply updated the selected trait.

This is direct runtime accessibility-tree evidence for the internal presentation
branch, not a spoken VoiceOver test or an actual picker-generated failure.

## Remaining evidence

- Spoken VoiceOver navigation, status, selection, amount and independent input
  diagnostics on both platforms remain unverified.
- Full macOS keyboard operation and actual picker opacity/wider-gamut workflows
  remain unverified. Attempts to open the native color panel did not provide a
  usable panel through the available automation surface. Arrow-key attempts did
  not establish keyboard focus/adjustment; do not count them as passing.
- Wider-gamut selection through the actual iOS picker remains unverified;
  existing fixed-CGColor tests are separate evidence.
- A macOS window capture of successful partial transparency showed horizontal
  stripes rather than a checkerboard, consistent with the earlier reported
  capture limitation. This run did not distinguish a capture artifact from a
  live rendering issue. A direct visual check through a reliable capture or
  human observation is still required; no macOS checkerboard pass is claimed.
- The live transition accessibility check above was performed on macOS only.
  The iOS transition screenshots/tests are narrower evidence and do not replace
  an accessibility-tree or VoiceOver transition check.

These items remain open against the accepted
[preview validation plan](../design/explicit-blending-outcomes.md#validation-plan).
No production changes were made merely to accommodate an unverified automation
or capture limitation.

## Release decision

After the second integrated assessment, the maintainer authorized publishing
ColorKit 3.2.0 with these disclosed manual-validation gaps. This is a release
override for the outstanding evidence, not a claim that the checks passed or
that the observed macOS stripes are confirmed to be capture-only. The final
automated release preflight is still required before tagging.

## Local artifacts

The integrated logs and result bundles were retained under
`/tmp/colorkit-3.2-evidence` and
`/tmp/colorkit-3.2-integrated-validation/.build/test-results/run.RfVSNg`.
Follow-up command logs and the temporary transition-host source were retained
under `/tmp/colorkit-3.2-fixes`. Native UI observations are also recorded in the
validation task's tool transcript. These local paths are session artifacts,
not durable CI download links. No review screenshots were added to the repository.
