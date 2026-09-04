# Migration Guide

## Unreleased

### HSL resolution

`hslComponents()` now resolves through the platform color types for the current
appearance, instead of reading raw `cgColor` components. Colors that previously
reported no value now convert:

| Input | Before | Now |
| --- | --- | --- |
| `.blue`, `.orange`, `.green`, `.red`, `.gray` | no value | resolved for the current appearance |
| grayscale `CGColor` | no value | resolved through its color space |
| `Color.primary` and other dynamic colors | no value | resolved for the current appearance |
| a pattern color | no value | no value |

**What changes for callers.** `adjustedForMode(isDarkMode:)` and
`adjustedForAccessibility(with:minimumRatio:)` return their input unchanged when HSL is
unavailable. Both were therefore silent no-ops for every named and grayscale color, and
both now perform the adjustment. If you relied on a named color passing through
untouched, pass an explicitly constructed color instead.

Dynamic colors are affected the same way: `adjustedForAccessibility(.primary, …)` now
adjusts rather than returning `.primary`, which freezes it to a fixed color for the
appearance in effect. `contrastRatio(with:)` already resolved `.primary` this way.

Wider-gamut colors are converted to sRGB and clamped before HSL conversion. Display P3
red still reports `H: 0°, S: 100%, L: 50%`, but other wider-gamut colors can change because
their components are now converted rather than read as sRGB. Colors already in the
sRGB gamut convert exactly as before.


### Enhancement distance budgets

`enhanceColorResult`, `enhancementResult`, and both result-bearing variant APIs now
enforce `maxPerceptualDistance`. The default remains 30, so an existing result call
may now return `bestEffort` instead of an over-budget passing color. Legacy
color-returning enhancement and variant methods still ignore the setting.

The budget is an inclusive CIEDE2000 Delta E 00 distance from the original foreground,
using D65 LAB with reference weights of one. It must be finite and in `0...100`.
Zero returns the unchanged original; exact equality is allowed without an overshoot
tolerance. If no examined in-budget candidate passes, best effort selects the highest
contrast, then smallest distance, then stable strategy order. This is not a global
optimality or impossibility guarantee. Strategies remain preferences, not preservation
constraints; even their fallbacks must fit the budget.

Handle the new `ColorAccessibilityResult.Status.invalidConfiguration` case in
exhaustive switches. Invalid values are not clamped or trapped: the result retains
the original and any measurable diagnostic contrast but never reports `meetsTarget`.
An `unavailable` enhancement can likewise retain contrast when its standalone
perceptual distance cannot be measured, such as with a translucent foreground.
Use `status` or `meetsTarget`, not a diagnostic ratio alone, for enhancement success.

```swift
let foreground = Color(.sRGB, red: 0.8, green: 0.8, blue: 0.8)
let result = foreground.enhancementResult(with: .white, maxPerceptualDistance: 15)
switch result.status {
case .meetsTarget:
    print("Pass within budget")
case .bestEffort:
    print("No examined in-budget candidate passed")
case .unavailable:
    print("Contrast or perceptual distance could not be established")
case .invalidConfiguration:
    print("Supply a finite budget from 0 through 100")
}
```

Budgeted results expose optional `perceptualDistance`, `maximumPerceptualDistance`,
and `isWithinPerceptualDistanceBudget`. Ordinary assessments leave these nil; the
budget check is also nil for invalid budgets or unavailable distance. The requested
maximum is retained verbatim for diagnostics, including invalid values.

Result-bearing variants keep stable strategy order and best-effort entries but use
Delta E 00 for pairwise deduplication: below 5 is a duplicate and exactly 5 is distinct.
This is separate from each variant's budget against the original. Positive-count
invalid or unavailable requests return one diagnostic result; nonpositive counts
return an empty array. Legacy variant arrays retain their CIE76 rule.

### Translucent contrast measurement

`wcagContrastRatio(with:)` now reports 1 when either color is translucent, rather
than measuring its components as though it were opaque. `wcagCompliance(with:)`
forwards to it, so a translucent color no longer passes any WCAG level.

Previously opacity was dropped entirely, which failed open:

| Foreground on white | Before | Now |
| --- | --- | --- |
| black at 10% opacity | 21.00:1, passes AAA | 1.00:1, passes nothing |
| `Color.primary` | 21.00:1, passes AAA | 1.00:1, passes nothing |

`Color.primary` is affected because it resolves to black at 84.7% opacity rather
than to an opaque black.

**What to change.** To measure a translucent foreground, supply the background it
sits on and use one of the result APIs, which composite before measuring:

```swift
switch foreground.contrastResult(with: opaqueBackground) {
case .available(let measurement):
    print(measurement.ratio, measurement.passingLevels)
case .unavailable(let issues):
    print(issues.foreground, issues.background)
}

// or, to assess a level directly
let result = foreground.accessibilityResult(against: opaqueBackground, targetLevel: .AA)
```

Ratios between opaque colors are unchanged, including every system color that
resolves through `UIColor`/`NSColor` such as `Color.blue` and `Color.orange`.

### Grayscale and wide-gamut blending

`blended(with:mode:amount:)` and `interpolated(with:amount:)` now resolve their
operands through the resolved sRGBA snapshot.

Grayscale colors previously failed an internal component check, and both
operations returned the receiver unchanged. Multiplying a gray by black returned
the gray rather than black. They now blend and interpolate normally.

Display P3 operands were read as though their components were sRGB, so P3 red and
sRGB red produced identical results. They are now converted, which means a
wide-gamut operand can produce components outside 0–1 in extended sRGB. Blending
two colors that were already sRGB is unchanged.

Operands with no fixed components, such as dynamic colors, still return the
receiver unchanged.


### WCAG relative luminance

`relativeLuminance()` now follows WCAG 2.1. It linearizes each nonlinear sRGB
component before applying the 0.2126, 0.7152, and 0.0722 weights. The previous
implementation applied those weights to gamma-encoded components, which
under-reported the luminance of every color except pure black and pure white.

`contrastRatio(with:)`, `isDarkColor()`, `adjustedForAccessibility(with:minimumRatio:)`,
and the `highContrastColor` modifier are all built on that luminance, so their
results change as well. Ratios were previously understated for mid-tone colors:

| Foreground on white | Before | Now (WCAG) |
| --- | --- | --- |
| `#595959` | 2.63:1 | 7.00:1 |
| `#767676` | 2.05:1 | 4.54:1 |
| `#008000` | 2.57:1 | 5.14:1 |

**What to change.** If you calibrated a `minimumRatio` against the old numbers,
re-check it against the WCAG scale. A threshold chosen to compensate for the old
understatement will now be stricter than you intended. Colors that already met
their target no longer get adjusted: `#595959` on white passes AAA and is now
returned unchanged, where it was previously replaced by the black-or-white fallback.

Values from `wcagContrastRatio(with:)` and `accessibilityResult(against:targetLevel:)`
did not change. `contrastRatio(with:)` now agrees with them for any color that
resolves to finite, in-gamut sRGB components.

### Dark color classification

`isDarkColor()` now compares relative luminance against approximately 0.1791, the
luminance at which black and white contrast equally against a color, instead of
against 0.5. This makes the black-or-white contrast fallback always the stronger
contrasting endpoint. Colors between the two thresholds change classification;
mid gray `#808080` is now classified light rather than dark.

### Unavailable measurements

`relativeLuminance()` still returns `0` for a color it cannot resolve, which is
indistinguishable from a measured black. Two additions report that case honestly:

```swift
// nil rather than 0 when the color cannot be resolved
let luminance: Double? = color.relativeLuminanceValue()

switch foreground.contrastResult(with: background) {
case .available(let measurement):
    print(measurement.ratio, measurement.passingLevels)
case .unavailable(let issues):
    print(issues.foreground, issues.background)
}
```

`contrastResult(with:)` composites a translucent foreground over an opaque
background, and reports a translucent background, an unresolvable color, or a
wider-gamut color as an issue rather than measuring it anyway.

## ColorKit 2.0.0

ColorKit 2.0.0 makes theme ownership explicit at compile time and tightens
selection of registered themes. Most color conversion, accessibility, export,
and preview fixes in this release require no caller changes.

### Theme ownership

`ThemeManager` is now isolated to `MainActor` as a whole. Previously only
`ThemeManager.shared` required main-actor access; code holding a manager reference
could read or mutate its state without isolation. That synchronous access from
nonisolated code is now a source compatibility break.

Mark synchronous callers that read `currentTheme` or `availableThemes`, subscribe
to their publishers, register themes, or switch themes as `@MainActor`. The
`withThemeManager(_:)` view modifier also requires a main-actor context. SwiftUI
view bodies already provide that context; separately declared helpers may need
an annotation.

```swift
@MainActor
func configureTheme(_ theme: ColorTheme) {
    let manager = ThemeManager.shared
    manager.register(theme: theme)
    manager.switchTo(theme: theme)
}

// From asynchronous code on another actor:
func selectTheme(named name: String, manager: ThemeManager) async -> Bool {
    await manager.switchToTheme(named: name)
}
```

Use `await MainActor.run { ... }` when several synchronous manager operations
must happen together from asynchronous code. Merely running on the main thread
does not replace the compiler's actor-isolation requirement. The unchecked
`Sendable` conformance is removed; main-actor isolation protects the manager's
state instead. No synchronous API silently schedules work for later.

`ObservableObject`, `@Published currentTheme`, the singleton's private initializer,
and the iOS 14 / macOS 12 deployment targets are unchanged. `availableThemes` now
publishes successful registrations. `withThemeManager(_:)` observes the manager
itself, so parents no longer need to observe it just to refresh the environment.
Local `applyTheme(_:)` overrides retain their normal subtree precedence.

Before ColorKit 2.0.0, registration rejected
duplicate names, switching by name selected the registered value, and switching
by instance selected the supplied value if its name was registered. ColorKit
2.0.0 changes those instance-selection semantics; see
[Canonical theme selection](#canonical-theme-selection).

### Canonical theme selection

`switchTo(theme:)` now treats its argument as a selection request identified by
name. When that name is registered, the manager selects the canonical registered
theme rather than installing the supplied value.

Previously, a caller could pass altered colors under an existing registered name
and make that unregistered value current. Code relying on that behavior must give
the variant a unique name, register it, and then select it:

```swift
let variant = ColorTheme(
    name: "Custom Variant",
    primary: .red,
    secondary: .gray,
    accent: .orange,
    background: .white,
    text: .black
)

manager.register(theme: variant)
manager.switchTo(theme: variant)
```

The public method signatures and return values are unchanged. Both selection
overloads return `false` and preserve the current theme when the requested name
is not registered. ColorKit 2.0.0 does not add replacement semantics for
registered themes.

## ColorKit 1.5.0

This guide helps you migrate your code from ColorKit 1.4.x to version 1.5.0. The main changes in this version focus on standardizing parameter naming across the library for better consistency and intuitiveness.

## Breaking Changes

### Parameter Naming Standardization

#### Accessibility Methods
```swift
// Old
color.adjustedForAccessibility(against: background, minimumRatio: 4.5)
color.enhanced(against: background, targetLevel: .AA)
color.suggestAccessibleVariants(against: background, count: 3)
color.wcagContrastRatio(against: background)
color.wcagRelativeLuminance(against: background)

// New
color.adjustedForAccessibility(with: background, minimumRatio: 4.5)
color.enhanced(with: background, targetLevel: .AA)
color.suggestAccessibleVariants(with: background, count: 3)
color.wcagContrastRatio(with: background)
color.wcagRelativeLuminance(with: background)
```

#### Color Cache Methods
```swift
// Old
ColorCache.shared.getCachedContrastRatio(for: color1, and: color2)
ColorCache.shared.cacheContrastRatio(for: color1, and: color2, ratio: 4.5)
ColorCache.shared.getCachedBlendedColor(color1: color1, and: color2, blendMode: mode)
ColorCache.shared.cacheBlendedColor(color1: color1, and: color2, blendMode: mode)
ColorCache.shared.getCachedInterpolatedColor(color1: color1, and: color2, amount: 0.5)
ColorCache.shared.cacheInterpolatedColor(color1: color1, and: color2, amount: 0.5)

// New
ColorCache.shared.getCachedContrastRatio(for: color1, with: color2)
ColorCache.shared.cacheContrastRatio(for: color1, with: color2, ratio: 4.5)
ColorCache.shared.getCachedBlendedColor(color1: color1, with: color2, blendMode: mode)
ColorCache.shared.cacheBlendedColor(color1: color1, with: color2, blendMode: mode)
ColorCache.shared.getCachedInterpolatedColor(color1: color1, with: color2, amount: 0.5)
ColorCache.shared.cacheInterpolatedColor(color1: color1, with: color2, amount: 0.5)
```

#### Blending and Interpolation Methods
```swift
// Old
color1.blend(color2, mode: .normal, alpha: 0.5)
color1.interpolate(to: color2, fraction: 0.5)
color1.blended(color2, mode: .normal, alpha: 0.5)

// New
color1.blend(color2, mode: .normal, amount: 0.5)
color1.interpolate(to: color2, amount: 0.5)
color1.blended(with: color2, mode: .normal, amount: 0.5)
```

#### Gradient Methods
```swift
// Old
color.linearGradient(to: otherColor, fraction: 0.5)
color.monochromaticGradient(fraction: 0.5)

// New
color.linearGradient(to: otherColor, amount: 0.5)
color.monochromaticGradient(amount: 0.5)
```

## Migration Steps

1. **Update Package Dependency**
   ```swift
   // In your Package.swift
   dependencies: [
       .package(url: "https://github.com/agisilaos/ColorKit.git", from: "1.5.0")
   ]
   ```

2. **Search and Replace**
   - Search for `against:` and replace with `with:`
   - Search for `and:` and replace with `with:`
   - Search for `alpha:` and replace with `amount:`
   - Search for `fraction:` and replace with `amount:`
   - Search for `blended(color:` and replace with `blended(with:`

3. **Update Documentation**
   - Update any internal documentation or comments that reference the old parameter names
   - Update any code examples in your project's documentation

4. **Run Tests**
   - Run your test suite to catch any missed parameter name updates
   - Pay special attention to tests involving:
     - Color accessibility checks
     - Color caching operations
     - Color blending and interpolation
     - Gradient generation

## Benefits

- More consistent and intuitive parameter naming across the library
- Better alignment with Swift's standard library naming conventions
- Improved code readability and maintainability
- Clearer intent in method signatures

## Support

If you encounter any issues during migration:
1. Check the documentation included with the ColorKit package in Xcode
2. Open an issue on the [GitHub repository](https://github.com/agisilaos/ColorKit/issues)
3. Contact the maintainers through the project's communication channels

## Next Steps

After completing the migration:
1. Review your codebase for any other potential improvements
2. Consider updating to the latest Swift version if you haven't already
3. Test your app thoroughly, especially color-related features
4. Update your CI/CD pipelines if necessary
