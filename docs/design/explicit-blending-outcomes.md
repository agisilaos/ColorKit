# Explicit blending outcomes

Status: implemented against the accepted design; validation and review are recorded in the pull request.

## Caller benefit

A blend editor needs to display and export a successfully computed color, including one whose components are unchanged, while reporting an unavailable operation and disabling export of that result. The existing color-returning method cannot distinguish these outcomes. One additive operation provides that distinction; release remains a separate decision.

## Accepted contract

- The receiver is the base operand; the argument is the blend operand. Their order matters.
- Success supplies a computed color, including legitimate unchanged components. It does not promise preserved color identity or a visible change.
- Resolve fixed RGB/grayscale inputs through the existing resolved-sRGBA policy. The caller owns explicit appearance capture; do not consult ambient appearance.
- Preserve existing blend-mode arithmetic in nonlinear sRGB. Weight the RGB effect by amount times blend alpha and preserve base alpha. This is not source-over compositing.
- Accept finite extended-sRGB inputs and preserve finite extended output, without adding clipping or gamut mapping. Existing bounds within individual mode formulas remain part of those formulas. Nonfinite calculations are unavailable.
- Require a finite amount in the inclusive range 0 through 1. Reject other values rather than clamp them.
- Both operands must resolve even at zero amount or zero blend alpha. After successful resolution, either zero contribution returns the resolved base successfully without executing blend arithmetic.
- Retain the resolver's first observable issue independently for each operand. Do not add arrays of cascading issues.

## Compatibility and scope

Preserve all shipped signatures and behavior under [ADR 0013](../adr/0013-preserve-shipped-3x-client-contracts.md), including the legacy method's clamping, zero-amount shortcut, receiver fallback, convenience methods, and public cache APIs. Preserve the extended-input policy from [ADR 0009](../adr/0009-resolve-blend-operands-through-snapshots.md).

No per-mode result variants, generic transformation framework, interpolation changes, theme redesign, automatic appearance resolution, new modes, or speculative performance work.

## Separate findings

Static inspection at released v3.1.1 (`b628fc27b40d3db520cd5e222598504671b8fa7c`) found that `.normal` documentation describes standard alpha composition although the implementation preserves base alpha. The preview also supplies its foreground-labeled color as the base operand. Review these separately; this design authorizes no correction to shipped behavior or preview ordering.

## Accepted documentation and preview follow-up

Implementation was authorized through the ship-change workflow after accepting
this contract. Remove the Performance control, panel, timer state, and callbacks:
the old interval measured main-queue callback delay, not rendering completion.
Show a checkmark and the selected accessibility trait on the selected mode.
Reserve the icon's space so selection does not shift buttons, and hide the
supplementary icon from accessibility. Mode names and ordering remain unchanged.
These are intentional presentation and accessibility changes.

The agreed presentation uses **Base color** for the first picker (currently blue)
and **Blend color** for the second (currently red), preserving the existing operand
order in `base.blendResult(with: blend, mode: mode, amount: amount)`. Display the
computed result separately over a neutral transparency checkerboard, rather than
over either operand. Relabelling the operands and replacing the colored backing
are intentional preview presentation changes, not behavior-preserving cleanup.

Use `ColorPicker` with `Binding<CGColor>`, explicit fixed sRGB blue/red defaults,
and opacity editing enabled. Convert selections to `Color` and let `blendResult`
validate their color models and components. Do not add implicit appearance
resolution, fallback conversion, or an appearance-capture control. Selections
remain fixed across appearance changes. Apple's documented CGColor binding and
the local SDK declarations support this policy at the package deployment targets;
actual picker interactions on iOS and macOS still require implementation validation.

On success, show the computed swatch under **Result**, with a visible **Success**
label and supplementary checkmark. At zero amount, explain: "Amount is 0%; the
result matches the base." Otherwise, when the resolved blend alpha is zero,
explain: "The blend color is fully transparent; the result matches the base."
Show these explanations only after success; zero contribution does not bypass
input validation. Other successes use the same presentation even when unchanged,
without color equality checks, an unchanged badge, or a permanent caveat.
VoiceOver receives the status and any contextual explanation.

On failure, replace the swatch and its checkerboard with **Result unavailable**.
Remove the prior success status and explanation from both the visible view and
the accessibility tree. Do not retain a last-successful swatch. Keep controls
usable and restore success presentation when a later edit succeeds.

Explain failures in plain language, identifying **Base color** and **Blend color**
independently when both have issues. Explain what could not be done and suggest
an applicable control to change; do not display enum names, rely on color alone,
or promise that appearance capture will fix an unresolved input. Amount and
calculation failures receive their own explanations. For example, an unresolved
base says: "This color doesn't provide fixed color values for blending. Choose
another base color." An unsupported model says: "This color uses a format the
preview can't blend. Choose an RGB or grayscale color." Invalid components and
failed color-space conversion must have distinct explanations: respectively,
the color contains unusable values, or its values cannot be converted for this
blend. Neither is described as an unsupported format. Calculation failure says:
"This combination produced color values the preview can't use. Try another blend
mode or different colors." Invalid amount says: "Choose a blend amount between
0% and 100%." Operand headings make clear which selection to change. Final
editorial wording may be refined without changing these distinctions.

Derive the displayed outcome from the current inputs and render success or
failure from that single outcome. No separate retained successful color is
needed. Keep presentation helpers internal; no new public API or view model is
required. Failure fixtures belong in tests or development previews rather than
adding error-injection controls to the user-facing picker.

### Documentation wording

Replace the legacy `.normal` claim of standard alpha composition with:

> Moves the base RGB channels toward the blend RGB channels, weighted by blend
> amount and blend opacity. Preserves base opacity; this is not source-over
> alpha compositing.

Use the shorter preview explanation:

> Blend amount and blend opacity control the effect. The result keeps the base
> color's opacity.

Correct all three standard-alpha-composition claims in `Color+Blending.swift`
(the convenience method, mode list, and enum case), the nearby overlaid-layer
description, and related amount wording that confuses effect strength with
output opacity. Describe legacy clamping and fallback accurately; do not imply
that legacy methods adopt the result API's validation. Preserve all blend
mathematics, legacy APIs, mode names, and cache behavior. No export feature,
benchmark claims, or cache changes are part of this follow-up.

### Affected files

- `Sources/ColorKit/ColorSpaces/Color+Blending.swift`: documentation corrections only.
- `Sources/ColorKit/PreviewCatalog/BlendingPreview.swift`: fixed picker inputs,
  operand labels, result-based presentation, accessible diagnostics, and the
  separately authorized Performance removal and selection checkmark.
- `Sources/ColorKit/PreviewCatalog/BlendingResultPreview.swift` (new): internal
  outcome presentation, diagnostic wording, and transparency backing.
- `Tests/ColorKitTests/BlendingPreviewTests.swift` (new): focused presentation and
  hosted-state coverage using internal fixtures as needed.
- `CHANGELOG.md` and `MIGRATION.md`: disclose the intentional preview changes.
- This design note: the single follow-up contract. Existing blend tests and
  `scripts/fixtures/blend_result.swift` remain validation inputs; extend only
  for missing coverage. Change `docs/Usage.md`, `docs/Usage.es-ES.md`, or the
  DocC Utilities article only if implementation exposes a concrete inconsistency,
  keeping bilingual executable examples identical.

### Validation plan

- Exercise initial fixed defaults, all modes, asymmetric operand ordering,
  amount zero/interior/one, transparent blend, and transparent/translucent base.
  Include a mode-specific unchanged success at nonzero contribution. Verify the
  result status does not depend on visible change, equality, or output opacity.
- Check each reachable input issue for base, blend, and both; invalid amount;
  nonfinite calculation; success-to-failure and failure-to-success transitions.
  Use injected internal fixtures where picker interactions cannot produce an
  error. Verify failures remove the previous swatch, checkerboard, success copy,
  and accessibility output. Never use an empty checkerboard as the failure state.
- Interact with actual iOS and macOS color pickers, including opacity and
  supported wider-gamut selections. Verify fixed selections survive light/dark
  changes and that unsupported inputs fail without clipping or fallback capture.
  SDK signatures establish availability, not runtime picker behavior.
- Review light/dark appearance, narrow layouts, large accessibility text, keyboard
  operation on macOS, and VoiceOver labels, selected mode, amount, status, and
  independently named input issues. Decorative icons/checkerboard must not add
  redundant announcements. Confirm the Performance control is absent.
- Build macOS and iOS Simulator at the declared deployment targets. Run focused
  preview and blend tests, existing compatibility checks, and the repository's
  canonical platform test matrix before delivery. Serialize shared-cache tests
  according to existing test tooling without modifying their contracts.
- Run strict SwiftLint, documentation compilation/checked examples via
  `scripts/check_documentation.py`, applicable parity checks, and DocC with
  warnings as errors. Existing mathematical and compatibility tests establish
  preservation; do not duplicate blend arithmetic in presentation tests.
- For the eventual PR, attach reviewed screenshots of success, explained
  unchanged success, transparent output, one/both operand failures, and recovery,
  with representative light/dark and large-text states on both platforms. Keep
  screenshots as review artifacts rather than repository assets. No PR is
  authorized by this design.

Validation evidence belongs in the PR and test artifacts. Hosted screenshots
are review evidence, not pixel assertions; live picker interaction and spoken
VoiceOver checks remain separate from compile-time and hosted-state coverage.

The existing glossary already owns the operand terminology.

## Accepted API

Add one method in the public `Color` extension and one public error enum:

```swift
func blendResult(
    with color: Color,
    mode: BlendMode,
    amount: CGFloat = 1
) -> Result<Color, ColorBlendError>

enum ColorBlendError: Error, Sendable, Equatable {
    case invalidAmount
    case unavailableInputs(
        base: ColorConversionIssue?,
        blend: ColorConversionIssue?
    )
    case nonfiniteResult
}
```

These declarations are additive to the v3.1.1 release. No result wrapper, throwing method, convenience properties, or per-mode variants are needed. Success contains only the computed `Color`; diagnostic presentation belongs to the application.

Validate amount first. If valid, resolve both operands and retain their issues independently. An emitted `unavailableInputs` must contain at least one non-nil issue. Allowing clients to construct a both-nil error is accepted in exchange for avoiding additional public types. Calculate only after both operands resolve, applying the accepted zero-contribution shortcuts first. Nonfinite blend arithmetic produces `nonfiniteResult`.

The new operation neither reads nor writes the legacy blend cache and introduces no new cache. Public cache insertion accepts arbitrary caller-supplied results, so a hit cannot establish this operation's success contract. Recomputing is the accepted simplicity trade-off; legacy cache behavior is unchanged.

## Caller examples

The executable bilingual recipe is maintained in `docs/Usage.md` and `docs/Usage.es-ES.md`. These sketches illustrate the same handling. `showPreview` and `showUnavailable` are application-owned handlers; unavailable handling clears the computed preview and disables exporting it.

```swift
let base = Color(.sRGB, red: 0.8, green: 0.2, blue: 0.1)
let blend = Color(.sRGB, red: 0.2, green: 0.6, blue: 0.9)

switch base.blendResult(with: blend, mode: .multiply) {
case .success(let color):
    showPreview(color)
case .failure(let error):
    showUnavailable(error)
}

// Successful result with unchanged resolved components.
let unchanged = base.blendResult(
    with: Color(.sRGB, red: 1, green: 1, blue: 1),
    mode: .multiply
)

// Unavailable blend operand; no substituted base color is returned.
let unavailable = base.blendResult(with: .primary, mode: .multiply)
```

## Required validation

- Exercise all existing modes with fixed inputs and independently expected component values. Verify operand ordering using an asymmetric mode, ordinary partial/full amounts, and unchanged-success cases.
- Verify base alpha is preserved for zero, partial, and opaque base alpha. Blend alpha scales the effect; explicitly distinguish this contract from source-over compositing.
- Cover amounts zero and one, interior values, negative and above-one values, NaN, and both infinities. Invalid amount takes precedence over input issues. Zero amount and zero blend alpha still require both operands to resolve and then skip mode arithmetic.
- Cover fixed sRGB, grayscale, linear RGB, Display P3, and finite extended-sRGB inputs, including negative and above-one channels. Verify finite extended output survives color construction; do not silently clip it. Test nonfinite arithmetic and existing mode-specific bounds.
- Cover either and both unavailable operands, independently retained conversion issues, named/dynamic inputs, explicit fixed appearance capture, unsupported models, and malformed/nonfinite components where platform construction permits them. Establish which invalid fixtures survive platform sanitization.
- Verify emitted unavailable-input errors never have both issues absent. Test the nonfinite arithmetic guard directly through an internal seam if extreme values cannot survive public color construction; retain public-path coverage for representable fixtures.
- Demonstrate that legacy cache contents, including a caller-inserted unrelated result, cannot alter the new operation or be modified by it. Preserve existing cache and convenience-method behavior. Serialize shared-cache checks as required by the repository.
- Compile a standalone public-import client at the declared deployment targets on macOS and iOS Simulator. Cover ordinary nonisolated calls, omitted amount, typed and inferred method references, exhaustive result/error handling, and the error's Sendable/Equatable conformances.
- Run existing compatibility gates and relevant numerical tests on both platforms. Preserve the existing released-client fixtures; do not rewrite them to accommodate the addition.
- Provide executable ordinary, unchanged-success, and unavailable examples with application-owned presentation. Explain fixed versus appearance-captured inputs, alpha semantics, amount validation, extended output, and legacy fallback differences. Keep bilingual executable examples identical and run documentation compilation, parity, DocC, and lint checks appropriate to the changed files.

## Implementation handoff

Recommendation: go for one additive operation. Its demonstrated benefit is allowing a caller to distinguish a valid unchanged result from an unavailable blend without inspecting output equality or duplicating resolution rules. A 3.2 release remains conditional on implementation and validation; this note does not authorize release.

Delivery slices:

1. Add the error enum and operation against the accepted contract. Reuse the existing resolver and mode arithmetic without changing legacy control flow or caching.
2. Add focused contract tests and the public-import client. Test design can proceed independently from implementation using this contract; execution depends on task 1.
3. Add the caller example and concise public documentation. Drafting can proceed independently from tasks 1 and 2; compilation and final wording depend on the implementation. Do not quietly change the existing preview's operand ordering.
4. Integrate and run the platform, compatibility, and documentation checks after tasks 1–3. Record any platform output-construction limitation as a blocker for contract review rather than changing gamut semantics silently.

There are no unresolved design questions. Runtime behavior for extreme representable inputs and output construction remains implementation validation work. The original API implementation excluded the alpha-documentation and preview-role findings; the accepted follow-up above now owns them. Agreed domain terms live only in `CONTEXT.md`; this note owns the contract and acceptance criteria.
