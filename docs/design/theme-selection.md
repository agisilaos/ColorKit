# F06 — Canonical theme selection

Status: accepted and implemented.

## Resolved behavior

- The theme registry owns the canonical value for every registered name.
- `switchTo(theme:)` treats its argument as a name-bearing selection request. When the supplied theme has a registered name but different colors, the registered theme becomes the current theme.
- `switchTo(theme:)` delegates directly to `switchToTheme(named:)`, making the named selector the single implementation of registry lookup and selection.
- The behavior change is deliberate: a same-name supplied theme is no longer installed outside the registry.

## Preserved boundaries

- `ThemeManager` remains isolated to `MainActor`.
- Both public method names, parameter labels, and return types remain unchanged.
- Registry lookup retains its existing order.
- An unregistered name returns `false` and leaves the current theme unchanged.

## Non-goal

F06 does not add a way to replace or update a registered theme. A distinct variant must use a unique name and be registered before selection; a deliberate replacement API, if needed, is separate work.

## Test design

Cover both return-value parity and resulting-state parity without registering test fixtures:

- For successful selection, use both existing default registrations. Select Default Light as the baseline, select Default Dark through the named overload, return to Default Light, then select through the instance overload using a deliberately different payload named Default Dark. Both overloads must return `true` and select the registered Default Dark value. The intervening baseline transition prevents a no-op implementation from passing.
- For failed selection, use one unregistered name. Both overloads must return `false` and leave the current theme unchanged.
- Snapshot the registry and assert it is unchanged by both scenarios.
- Restore the previous current theme after each test so later singleton tests do not inherit the selection.

Failed-switch coverage is state-based: it verifies the return value, current theme, and registry. It does not make exact Combine notification counts part of the contract.

## Documentation

- Update the `switchTo(theme:)` API comment to say that the argument identifies a registered theme by name and that the registered value is selected.
- Add an Unreleased F06 migration section describing the deliberate same-name payload behavior change.
- Tell callers that relied on installing altered colors under an existing name to register the variant under a unique name.
- Add the behavior change to the Unreleased changelog.
- Keep the accepted F05 design note as historical context, but point readers to F06 where its preserved selection semantics are superseded.
