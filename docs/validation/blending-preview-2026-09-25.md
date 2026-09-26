# Blending preview validation follow-up — 2026-09-25

Status: partial. These observations close specific evidence gaps; they do not
establish complete release readiness or spoken VoiceOver verification.

Follow-up at `854fabc5437f663e54dd2921a766891448f1aeed` (3.2.0): actual iOS
wider-gamut selection and the iOS live accessibility-tree transition now have
runtime evidence. Spoken VoiceOver, complete macOS keyboard/picker workflows,
and the distinction between live macOS stripes and offscreen rendering remain
unverified. The September 26 Accessibility Inspector follow-up confirmed text
contrast defects and corrected them in the source identified below. The
correction is suitable for a 3.2.1 patch; it does not close the spoken
VoiceOver or remaining macOS interaction checks.

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
  diagnostics on both platforms remain unverified. Neither the retained nor
  fresh accessibility-tree observations establish speech, focus behavior, or
  announcements.
- Full macOS keyboard operation and actual picker opacity/wider-gamut workflows
  remain unverified. Attempts to open the native color panel did not provide a
  usable panel through the available automation surface. Arrow-key attempts did
  not establish keyboard focus/adjustment; do not count them as passing.
- macOS partial transparency still produces horizontal stripes in window
  captures. The fresh in-process `ImageRenderer` probe also produces stripes;
  this is no longer evidence limited to the original bitmap capture method.
  Neither observation establishes the live on-screen appearance. A direct
  human check remains necessary; no checkerboard pass or capture-only diagnosis
  is claimed.
- The live transitions use controlled internal fixtures, not picker-generated
  failures. Actual picker failure/recovery and spoken transition behavior remain
  unverified on both platforms. Physical iOS hardware and minimum-OS runtime
  behavior were not tested.

These items remain open against the accepted
[preview validation plan](../design/explicit-blending-outcomes.md#validation-plan).
No production changes were made merely to accommodate an unverified automation
or capture limitation.

## Follow-up on the released source

### Revision, isolation, and retained checks

Fetched `origin/main` and inspected open PRs and local worktrees before making
changes. Main was `854fabc5437f663e54dd2921a766891448f1aeed`; the only open PR
was the separate CI parallelization work (#82). Work used the isolated
`/Users/agis/.codex/worktrees/2e9f/ColorKit` checkout on
`fix/blending-preview-validation`. Validation preceded the delivery commit;
no release or merge was performed.

Compared the retained `9e97a7431ec1c92e4bb8070ba2ece6232caa21dc` source with
this revision. Before the contrast correction below, `BlendingPreview`,
`BlendingResultPreview`, and `ResolvedSRGBA` were unchanged. The blending
implementation only gained the already-released
`ColorBlendMode` alias and documentation edits; its arithmetic is unchanged.
The hosted tests gained explicit layout/readiness handling in `41bb8b3`.

Reused the retained eight preview-test passes on each platform, including
fixed-P3/alpha coverage, independent diagnostic messages, and hosted result
states. The earlier macOS live accessibility transition and iOS opacity checks
remain applicable. The full release matrix was not repeated. New macOS and iOS
library builds succeeded at the tested revision to supply the fresh hosts.

Fresh environment: Xcode 26.5 (17F42), macOS 26.6.2 (25G83), arm64; iPhone 17
Simulator, iOS 26.5, UDID `9E466231-C3DC-4D34-B3B8-B2BD12B72AC6`. Host controls
for appearance and fixture selection are validation-only, outside the library.

### Actual iOS wider-gamut selection — pass within this environment

Operated the public preview's native Base color picker: Sliders → color-space
menu beside the hex field → Display P3 → `FF0000`. The picker showed Display P3
red and, after opacity editing, 5% opacity. Dismissal exposed Success and a
translucent result over alternating squares. The 5% value is the observed value;
an attempted 50% entry is not counted as a 50% pass.

Reopening the native picker showed an sRGB label. To avoid treating that label
alone as proof of clipping, made a temporary copy of the same preview source
with read-only `onChange` logging of its two `CGColor` states and resolved
components. The copy uses the shipped `ColorBlendMode` alias to avoid the
SwiftUI name collision; it changes no picker bindings or blending calculations.
It is additional instrumented evidence, distinct from the unmodified public
host. Values were selected through the actual native picker, not injected:

| Picker selection | Returned extended-sRGB RGBA, rounded | Conversion |
| --- | --- | --- |
| Base: Display P3 `00FF00` | `(-0.511642, 1.018265, -0.310638, 1)` | Success, components retained |
| Blend: Display P3 `FF0000` | `(1.093079, -0.226852, -0.150085, 1)` | Success, components retained |

Both bindings received `kCGColorSpaceExtendedSRGB`, including components outside
`0...1`. Selected multiply and changed light → dark → light appearance; the
accessibility tree retained the selected mode, both color labels, amount, and
Success. The observer recorded no input mutation from appearance changes.
This establishes actual wider-gamut picker acceptance on this simulator. It
does not establish physical-display color accuracy or spoken color descriptions.

### Live iOS success → failure → recovery — accessibility-tree pass

Used the unmodified internal result view in the fresh host, with one mounted
`@State` toggle and no changing `.id` or root-controller replacement. Amount
remained zero. Fixed inputs were replaced with `.primary`/`.secondary`, then
restored. In dark appearance, native accessibility inspection reported:

| State | Accessible result content |
| --- | --- |
| Fixed inputs | Result; Success; Amount is 0%; the result matches the base; opacity explanation |
| Both unavailable | Result; Result unavailable; separate Base color and Blend color diagnostics; opacity explanation |
| Recovered | Result; Success; Amount is 0%; the result matches the base; opacity explanation |

Failure removed Success and the unchanged-result explanation. The screenshot
also contained no swatch/checkerboard. Recovery removed both diagnostics and
restored accessible Success and its explanation. Decorative output added no
separate accessible element. Together with the retained macOS transition, this
closes the controlled live accessibility-tree transition gap on both platforms.
It does not close spoken VoiceOver validation.

### macOS attempts and checkerboard investigation — unresolved

The fresh public host exposed Base color and Blend color wells, selected normal,
the labeled amount/value, and Success. Invoking the well's Show color panel
action, clicking it, and a direct double-click did not expose a usable native
panel through automation. Raising the host and sending Tab did not establish
control focus. These are unsuccessful validation attempts, not confirmed
ColorKit defects or keyboard/picker passes.

For transparency, the controlled success fixture used fixed sRGB
`(0.2, 0.4, 0.8, 0.5)` at amount zero. Expected: alternating 16-point squares
under the translucent color. Observed: horizontal bands in the window capture.
A separate in-process `ImageRenderer` export of the unmodified
`BlendingResultPreview` at width 420 and scale 2 also showed horizontal bands.
Both observations are reproducible, but direct human observation of the live
window has not been supplied. Classification remains unresolved; neither a
capture-only explanation nor a confirmed live rendering defect is justified.
No speculative rendering workaround or regression test was added.

### Accessibility Inspector follow-up — 2026-09-26

Used Accessibility Inspector from the active Xcode 26.5 installation with the
same macOS 26.6.2 and iPhone 17 / iOS 26.5 environments. Its Captions control and
Back/Forward navigation produced the following **speech-preview text**, not
verified system-audio output or an actual VoiceOver navigation pass:

| Check | Inspector observation |
| --- | --- |
| iOS picker labels | `Base color, very dark blue, Button`; `Blend color, dark red, Button` |
| iOS mode selection | `normal, Button, Selected`; activating multiply removed Selected from normal and produced `multiply, Button, Selected` |
| iOS amount | `Blend amount, 100 percent, Adjustable`; Decrement changed it to `90 percent` on revisiting |
| iOS result | Result, Success, and the opacity explanation were reachable sequentially |
| iOS live failure | Result unavailable; separate complete Base color and Blend color recovery descriptions; no Success or zero-amount explanation in the traversal |
| iOS live recovery | Success and the zero-amount explanation returned; both error descriptions disappeared |
| macOS controls/result | Distinct Base/Blend color-well labels and RGB values, Blend amount with 100 percent, Result, Success, and opacity explanation |
| macOS selected mode | Inspector's advanced properties reported `Selected true` for normal, but its caption was only `normal, button`. This does not prove an actual VoiceOver omission; leave spoken selection unverified. |

The iOS state transitions used the existing mounted fixture's accessible
Activate action. No production state-injection API was introduced. After the
contrast correction, Inspector activation and navigation still produced
`screen, Button, Selected`, and the public hosts retained labels, amount, and
Success in both appearances. Captions were switched off after inspection.

Inspector also reported 14 unsupported-Dynamic-Type warnings. Moving its text
size slider from the original value to the maximum visibly enlarged the live
host labels, both picker labels, headings, and mode text. The setting was then
restored. This contradicts a blanket claim that these controls cannot scale;
the warnings were not treated as confirmed defects. Retained large-text hosted
checks and the affected hosted tests remain applicable. This is not an audit of
every text size, physical device, or assistive technology.

### Confirmed contrast defects and smallest correction

**Reproduction:** launch the unmodified public preview in the iOS host, use
light appearance and the default text size, select normal, then run Inspector's
audit. Inspect the two amount endpoints, current amount, opacity explanation,
and selected mode. Expected: at least 4.5:1 for these normal-sized text labels.

| Defect | Actual before correction | Correction |
| --- | --- | --- |
| Amount endpoints/current value and opacity explanation | Four warnings: 3.44:1, `#8A8A8E` against white, at 17 or 12 points | Use primary text for these four labels |
| Selected mode label/checkmark | 3.52:1, white against `#0088FF`, at 15 points; rendered tests also failed with yellow and purple accents | Use primary text with a 20%-opacity accent fill, retaining the existing checkmark, layout, actions, and selected trait |

The shared button label was made internally testable for rendering tests. The
button remains a native Button; public declarations, picker bindings, diagnostic
content, result-state structure, and blending arithmetic are unchanged.

**Regression coverage:** `BlendingPreviewContrastTests` samples rendered solid
foreground/background pixels, checks selected and unselected labels under blue,
yellow, and purple accents in both appearances, and separately crops the
opacity explanation's last line so a passing heading cannot mask a failing
footer. It uses the actual shared label; ImageRenderer cannot reliably render
the native macOS Button itself. Before correction, the tests recorded seven
failing cases on macOS (including selected blue at 3.5201:1 and the light footer
at 3.9494:1). After correction, both new tests passed on macOS and iOS.

The final regression fixtures pin the text size to Large so the pixel crops do
not depend on a tester's preferred text size. After that cleanup, the same ten
affected tests passed again on each platform with parallel testing disabled.
Full-repository strict SwiftLint passed with zero violations in 131 files;
whitespace validation and the changed-file TODO/FIXME scan were clean.

**Affected checks:** 10 tests passed on each platform (eight existing preview
tests plus two contrast tests). The iOS run disabled parallel testing and retained
`contrast-ios.xcresult`. Changed Swift files passed strict SwiftLint; whitespace
validation passed. The full release matrix and minimum-OS runtime tests were not
repeated. Both corrected interactive hosts were inspected in light and dark
appearance.

**Inspector recheck:** the five measured text-contrast warnings disappeared.
One contrast warning remained for a partially visible mode at the horizontal
scroll boundary. It initially named overlay, moved to screen after scrolling
overlay fully into view, and named clipped multiply in dark appearance. It
sampled white versus `#E8E8E8` (or black versus `#1C1C1D`), 1.23:1, rather than
the visible text's foreground. Fully visible overlay was no longer flagged.
This viewport-dependent audit warning is retained as a tooling limitation,
not a reason to hide controls or alter scrolling. The audit is not reported
as entirely clean; its Dynamic Type warnings also remain.

**Tested revision:** parent commit
`854fabc5437f663e54dd2921a766891448f1aeed` plus the uncommitted contrast changes.
Those checks preceded the delivery commit. SHA-256 of the corrected production
sources (independent of the later evidence-document and test-fixture cleanup):

| File | SHA-256 |
| --- | --- |
| `BlendingPreview.swift` | `caa352b3e886f4f80deddc20fd6d85e83b1e1c750447d39fbb5d2b69c7117fc7` |
| `BlendingResultPreview.swift` | `a29ec245a9e6bd2fb798f63d5f468a3828d8985f3c64873fd1d36e60df4ecf3d` |

### Human checklist — all items below remain unverified

A further VoiceOver attempt enabled macOS VoiceOver through System Settings
and completed its startup prompt. The VoiceOver process was running and its
caption-panel preference was already enabled. However, attempts to inspect
VoiceOver's output window through native automation timed out; a navigation
command sent to the host supplied no verifiable speech output. This session has
no tool for listening to system audio. VoiceOver was restored to its original
off state. No spoken check is counted as passed.

The connected iOS 26.5 simulator does not supply the newer
[`XCUIVoiceOverService`](https://developer.apple.com/documentation/xcuiautomation/xcuivoiceoverservice)
API. Local headers show that the installed Xcode-beta SDK provides it starting
at iOS/macOS 27; it is absent from the active Xcode 26.5 SDK. That newer API was
not exercised in this validation environment. The physical iPhone was listed
as unavailable by `devicectl`. These are validation constraints, not app defects.

1. **Spoken VoiceOver, iOS and macOS:** enable VoiceOver and navigate Base color,
   Blend color, blend modes, amount, and Result. Listen for distinct picker
   labels, the selected mode, the updated amount, and Success. Operate the
   controls through VoiceOver rather than reading an accessibility tree.
2. **Spoken transition, both platforms:** enable Transition fixture, then toggle
   Unavailable inputs on/off. Navigate the result each time. Hear both readable,
   independently named failure descriptions; old Success/explanation must be
   absent during failure, and recovered Success must be reachable without old
   errors. Record focus/announcement behavior separately.
3. **macOS keyboard and pickers:** with keyboard navigation enabled, use
   Tab/Shift-Tab, Space and arrow keys to reach/operate both wells, every mode
   (including horizontally offscreen modes), and amount. In both actual pickers,
   select opacity 0%, 50%, 100% and supported Display P3 colors; dismiss, switch
   appearance, and verify retained selections and result status.
4. **macOS live transparency:** in Transition fixture with Unavailable inputs
   off, look directly at the window's 50%-opaque blue result. Record squares or
   stripes, OS/display details, and whether resizing changes it. Do not infer
   the live appearance from the retained captures or exported image.

The temporary macOS `ColorKitValidation.app` and iOS simulator host are retained
under the follow-up artifact directory below. These fixtures make success and
failure reachable without adding public configuration API.

### Defect and patch assessment

The confirmed text-contrast defects and their focused corrections warrant a
3.2.1 patch. This recommendation does not certify spoken VoiceOver, macOS
keyboard/pickers, or the live checkerboard. No speculative fixes were made for
the macOS selected-mode caption, unsupported-font warnings, or capture stripes.
Release metadata is unchanged. This evidence does not authorize tagging,
publishing, or merging a release.

## Release decision

After the second integrated assessment, the maintainer authorized publishing
ColorKit 3.2.0 with these disclosed manual-validation gaps. This is a release
override for the outstanding evidence, not a claim that the checks passed or
that the observed macOS stripes are confirmed to be capture-only. At the time
of that decision, the final automated release preflight was still required
before tagging. The present follow-up does not repeat or authorize release work.

## Local artifacts

The integrated logs and result bundles were retained under
`/tmp/colorkit-3.2-evidence` and
`/tmp/colorkit-3.2-integrated-validation/.build/test-results/run.RfVSNg`.
Follow-up command logs and the temporary transition-host source were retained
under `/tmp/colorkit-3.2-fixes`. Native UI observations are also recorded in the
validation task's tool transcript. These local paths are session artifacts,
not durable CI download links. No review screenshots were added to the repository.

Fresh follow-up artifacts are under `/tmp/colorkit-preview-validation-20260925`:
`environment.txt`, macOS/iOS build logs, `ValidationHost.swift`, the two app
bundles, `ObservedHost.swift`, `ObservedBlendingPreview.swift`,
`instrumentation.diff`, `picker-values.log`, `RenderProbe.swift`, and
`image-renderer.png`. Native interaction/accessibility observations are in this
task's tool transcript; the tables above retain their relevant content. The
instrumentation source and log preserve the distinction between actual native
picker selections and the older fixed-CGColor unit fixtures. These are local
session artifacts, not durable CI attachments.

September 26 contrast artifacts in the same directory: `contrast-before.log`,
`mac-after.log`, `ios-after.log`, `contrast-ios.xcresult`, `contrast-lint.log`,
`ColorKitContrastValidation.app`, and `ColorKitValidationIOSFixed.app`. The
original macOS app remains available for comparison. Inspector captions,
per-element ratios, and audit iterations are retained in the task transcript;
the relevant observations are transcribed above. The corrected iOS bundle is
installed in the existing simulator.

Final delivery-check artifacts in the same directory: `precommit-macos.log`,
`precommit-macos.xcresult`, `precommit-ios.log`, `precommit-ios.xcresult`, and
`precommit-lint.log`. Hosted light/dark preview captures were exported from the
retained iOS result bundle and the final macOS result bundle for PR attachments.
They document appearance, not spoken VoiceOver or live checkerboard behavior.
