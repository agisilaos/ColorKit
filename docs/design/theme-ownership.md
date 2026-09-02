# F05 — Observed theme ownership

Status: accepted for implementation.

## Requested scope

- Isolate `ThemeManager` to `MainActor` and remove its unchecked concurrency promise.
- Preserve `ObservableObject` and publish changes to `availableThemes` as well as `currentTheme`.
- Have `withThemeManager(_:)` use a small observing provider so descendants receive updated environment themes without requiring parent observation.
- Preserve injection of the manager through both the environment object and `themeManager` environment value, and preserve nested theme overrides.
- Preserve the iOS 14 and macOS 12 deployment targets and existing selection behavior. F06 is separate.
- Document the actor-related source compatibility changes for callers.

## Existing selection behavior to preserve

Registration rejects duplicate names and does not change the current theme. At the time of F05, switching by name selected the registered value while switching by instance selected the supplied value after checking its name. [F06 canonical theme selection](theme-selection.md) supersedes that instance-selection behavior. Failed switches still leave the current theme unchanged.

## Required validation

- Host a view whose parent does not observe the manager and whose descendant reads only the environment theme; verify that switching themes reaches the descendant.
- Verify registry publication after successful registration, including when selection does not change, and no publication for rejected duplicate registration.
- Verify nested override precedence before and after a manager theme change.
- Retain regression coverage of selection behavior.

## Singleton test isolation

The initializer stays private, and there is no reset or removal API.

Use unique registration names and baseline-relative assertions, restore the previous selected value, and run `ThemeManagerIntegrationTests` without parallel testing. Registered test themes remain for the lifetime of the test process; tests must tolerate this explicitly. The old fixed-count test is replaced by coverage that does not depend on test order or a fresh singleton.

An internal initializer would allow independent instances but would expand construction access solely for testing. We chose to preserve the existing construction boundary.

## Provider boundary

`withThemeManager(_:)` wraps its content in a small `@ObservedObject` provider. The provider injects the selected theme, the manager environment value, and the manager environment object at the same hierarchy boundary as before. A descendant's closer override still wins. The environment keys keep their independent default theme and nil manager; they do not access the singleton.

The manager and modifier require main-actor access. This deliberately changes source compatibility for nonisolated callers holding a manager reference, rather than retaining an unchecked concurrency promise or silently scheduling formerly synchronous operations.
