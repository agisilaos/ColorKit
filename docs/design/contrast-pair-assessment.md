# Contrast pair assessment — design discussion

Status: delivered in PRs #66, #67, and #68. Existing public APIs were sufficient;
no library API or version change was needed.

## Agreed scope

- Assess explicitly supplied foreground/background pairs, not every palette combination.
- Preserve the supplied order and identify each assessed pair.
- Report measured passes, below-target measurements, and unavailable measurements independently.
- Do not modify colors automatically or claim whole-app accessibility compliance.
- Start with a practical example using existing APIs; add a public abstraction only if the example demonstrates a useful need.
- Preserve shipped 3.x contracts. Protect newly shipped 3.1 clients as part of the first implementation work, without a separate release ceremony.

## Delivery outcome

- PR #66 preserved the released 3.1 client alongside the existing 3.0 baseline.
- PR #67 added the standalone macOS report and focused tests.
- PR #68 added English/Spanish discovery links and an example test step in existing CI.
- All three PRs are merged; the final PR's lint, documentation, and build/test checks passed.

## Agreed: caller-owned appearance resolution

Retain the existing strict contrast measurement contract. Callers explicitly capture
appearance-dependent colors before supplying them; unresolved inputs remain unavailable.
Light and dark appearances are separate caller-supplied pairs when both are relevant.
The example may demonstrate capture, but assessment does not infer ambient appearance,
automatically assess both appearances, or introduce a new appearance framework.

## Agreed: explicit per-pair targets

Each pair explicitly supplies an existing `WCAGContrastLevel`. Do not infer a target
from its label, font size, or UI role. The first scope has no collection-wide default
or custom numeric threshold. A passing result means the requested contrast target
is met, not that the UI is accessible as a whole.

## Agreed: labels do not establish identity

Labels are display text and need not be unique. Preserve every supplied entry in
input order, including duplicate labels and identical color pairs; do not merge,
deduplicate, or reject them. The initial example owns any identity needed for its
presentation in client code rather than introducing a public ID system.

## Agreed: explicit summary counts

Summarize entries with three separate counts: meets target, below target, and
unavailable. Keep the individual results visible; do not produce an overall
accessibility score or conflate unavailability with a measured shortfall.
Empty input displays “No pairs assessed” rather than a successful assessment.

## Agreed: visible per-pair evidence

Measured rows show the label, foreground/background swatches, requested target,
measured ratio, required ratio, and explicit outcome without requiring expansion.
Unavailable rows show the label, target, and independent foreground/background
explanations without an invented ratio. Classification uses the unrounded measured
ratio; display rounding must never change the outcome.

## Agreed: focused code-configured example

Begin with a small report configured through client code, using representative
pairs for passes, shortfalls, unavailable measurements, and duplicate labels,
plus a separate empty-input case. Developers can replace the samples with their
own inputs. Color pickers, persistence, export, and automatic fixes are out of
scope for the initial milestone.

## Agreed: no premature public abstraction

Use existing public methods first. Consider a new public abstraction only if the
example demonstrates reusable, nontrivial assessment logic—not presentation
formatting or a simple loop. Any proposed API requires a separate contract review
grounded in real client usage and preserving shipped 3.x behavior. If the example
is sufficient, publish it as a recipe without forcing a 3.2 version bump.

## Agreed: standalone example, not shipped library API

Keep the runnable report in the repository but outside the ColorKit library
target. Its views, sample inputs, and presentation helpers belong to the example;
they are not new public ColorKit declarations. Developers can run and adapt the
sample while the library continues to provide its existing measurement APIs.

## Agreed: focused validation using existing tooling

Cover measured passes, below-target measurements, unavailable results, duplicate
labels, empty input, and threshold rounding with a small set of automated checks.
Compile the actual runnable example and manually inspect its UI. Reuse existing
tooling rather than introduce a new testing framework.

## Delivery

The example and compatibility work were delivered independently, followed by
documentation and CI integration. Future public API additions require a separate
demonstrated need and contract decision. This milestone does not require a release.
