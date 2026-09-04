# Changelog

All notable changes to ColorKit will be documented in this file.

## [Unreleased]

### Fixed
- Resolve `hslComponents()` through the platform color types, so named SwiftUI colors such as `Color.orange` and grayscale colors report HSL instead of no value. `adjustedForMode(isDarkMode:)` and `adjustedForAccessibility(with:minimumRatio:)` return their input when HSL is unavailable, so both were silent no-ops for every named and grayscale color. See [the migration guide](MIGRATION.md#hsl-resolution).

### Added
- Expose enhancement distance and budget evidence in accessibility results, including an explicit `invalidConfiguration` status.
- Add an atomic color-comparison result that reports per-input resolution, translucency, and sRGB-gamut issues.
- Add CIEDE2000 comparison to the preview catalog's performance benchmark.
- Add `contrastResult(with:)`, which reports a measured contrast ratio with its relative luminance values and passing WCAG levels, or an unavailable result with independent per-input issues.
- Add `relativeLuminanceValue()`, which returns `nil` for an unresolvable color instead of the zero that `relativeLuminance()` reports.

### Changed
- Enforce `maxPerceptualDistance` as an inclusive CIEDE2000 hard budget in enhancement and variant result APIs. Keep the default at 30 and preserve legacy color-returning behavior; result calls may now report best effort instead of an over-budget pass. Result variants use Delta E 00 for distinctness. See [the migration guide](MIGRATION.md#enhancement-distance-budgets).
- Deprecate `compare(with:)` in favor of explicit unavailable-result handling while preserving its ColorKit 2.x fallback behavior.
- Show CIEDE2000 as a raw Delta E 00 value and replace unavailable comparison metrics with actionable per-color messages.

### Fixed
- Measure named SwiftUI colors such as `Color.blue` and `Color.orange` in `relativeLuminance()`, `contrastRatio(with:)`, and `isDarkColor()`. They carry no `cgColor`, so they previously measured as black, reported 1:1 against black and 21:1 against white, and made the black-or-white contrast fallback select the weaker endpoint.
- Report a WCAG contrast ratio of 1 when either color is translucent, instead of measuring it as though it were opaque. Black at ten percent opacity on white reported 21:1 and passed AAA against its true composited 1.25:1; `Color.primary`, which resolves to black at 84.7% opacity, did the same. Use `contrastResult(with:)` or `accessibilityResult(against:targetLevel:)` to measure a translucent foreground over an explicit opaque background. See [the migration guide](MIGRATION.md#translucent-contrast-measurement).
- Resolve blending and RGB interpolation operands through the resolved sRGBA snapshot. A grayscale color previously failed the component check and both operations silently returned the receiver unchanged, so multiplying a gray by black returned the gray; a Display P3 color was read as though its components were sRGB.
- Replace the normalized Euclidean RGB calculation labeled as CIEDE2000 with a reference-validated CIEDE2000 implementation over resolved D65 LAB values.
- Calculate `relativeLuminance()` according to WCAG 2.1 by linearizing sRGB components before weighting them. The previous calculation weighted gamma-encoded components directly and under-reported contrast for mid-tone colors; `#595959` on white now measures 7.00:1 rather than 2.63:1. `contrastRatio(with:)`, `adjustedForAccessibility(with:minimumRatio:)`, and `highContrastColor` all inherit the correction. See [the migration guide](MIGRATION.md#wcag-relative-luminance).
- Classify `isDarkColor()` at the luminance where black and white contrast equally (approximately 0.1791) instead of at 0.5, so the black-or-white fallback is always the stronger contrasting endpoint.
- Resolve strict `relativeLuminanceValue()` inputs through the shared resolved sRGBA snapshot, so a wider-gamut color is reported as unavailable instead of read as though its components were sRGB. Keep `relativeLuminance()` lenient by resolving through `UIColor` or `NSColor` for the current appearance.

## [2.1.0] - 2026-09-02

### Added
- Add assessed accessibility results that distinguish a measured pass, best effort below the target, and unavailable measurement.
- Add result-returning enhancement, contrasting-endpoint, variant, and palette APIs while retaining existing color-returning behavior.

### Changed
- Show measured accessibility outcomes in the enhancement demos and document the strict sRGB, alpha, and background requirements.
- Correct legacy API documentation that implied every generated candidate was guaranteed to meet its requested WCAG level.

### Tooling
- Fall back to raw `xcodebuild` output when `xcpretty` is not installed.
- Add a release preflight that verifies the release version, changelog, branch, synchronization, and tag state.

## [2.0.1] - 2026-09-02

### Fixed
- Report the current 2.0.1 release from `ColorKit.version`.
- Correct documentation examples that referenced unavailable APIs and clarify the palette generator's contrast guarantees.

### Tooling
- Build DocC documentation with warnings treated as errors in pull-request CI.

## [2.0.0] - 2026-09-02

### Added
- Add a Spanish README translation and language links from the main README.

### Changed
- Isolate `ThemeManager` and `withThemeManager(_:)` to `MainActor`. Nonisolated callers must adopt actor-aware access; see [the migration guide](MIGRATION.md#theme-ownership).
- Make `switchTo(theme:)` select the canonical registered theme with the supplied name instead of installing a same-name replacement payload; see [the migration guide](MIGRATION.md#canonical-theme-selection).
- Resolve Hex and CMYK values through a fallible sRGB snapshot. Fixed grayscale, linear RGB, and Display P3 colors are converted to sRGB; unavailable, nonfinite, or out-of-range values return `nil`.
- Present only platform-supported palette export actions: Copy and Share on iOS, and Copy and Export on macOS.
- Derive color-inspector output from its current color and background inputs so reused views cannot display stale conversion or accessibility results.
- Give each animation preview its own cancellable performance-monitoring session, and keep benchmark CPU work off the main actor.
- Use exact, color-space-aware cache identities and bypass caching when a stable identity cannot be formed.
- Use one RGB-to-XYZ conversion path for LAB conversion and public color-space conversion.

### Fixed
- Preserve already-compliant colors, including opacity, in `adjustedForAccessibility` and `highContrastColor` instead of replacing them with black or white.
- Choose the stronger black-or-white contrast endpoint when neither endpoint meets the requested WCAG level.
- Return no accessible variants for nonpositive counts and avoid repeating identical fallback adjustments when distinct candidates are exhausted.
- Round RGB and alpha channels to the nearest byte when generating hexadecimal colors, preserving round trips such as `#232323FF`.
- Prepare accessible-palette export artifacts once before presentation, retain the presented payload through redraws and dismissal, and create a fresh file for each later share.
- Return `nil` from JSON palette export when a resolved RGBA component is nonfinite instead of raising a Foundation exception.
- Publish successful theme registrations and refresh the environment theme on selection changes without requiring parent observation, while preserving nested overrides.
- Cancel obsolete animation-monitor callbacks so a previous preview session cannot update current metrics.

### Tooling
- Centralize iOS and macOS test execution in `scripts/run_tests.sh`, preserve result bundles and logs on failures, and serialize shared cache and theme-manager integration tests.

## [1.6.0] - 2025-04-01

### Added
- **DocC documentation integration:** Comprehensive DocC documentation integration
  - Main documentation article with overview and features
  - Color Spaces article detailing RGB, HSL, CMYK, and LAB color spaces
  - Accessibility article covering WCAG compliance and tools
  - Theming article explaining the theme system and components
  - Utilities article documenting caching, export, gradients, and blending
- Enhanced inline documentation for all public APIs
- Code examples and usage guides for all major features
- Cross-referenced documentation between related components
- **SwiftUI Preview Catalog**: Comprehensive interactive preview components for exploring ColorKit features.
  - `MainCatalogView`: Central navigation hub with searchable feature list
  - `BlendingPreview`: Interactive color blending with custom blend modes and performance metrics
  - `GradientPreview`: Visual gradient builder with code generation
  - `ThemePreview`: Theme builder with light/dark mode preview
  - `PerformanceBenchmark`: Performance testing tool for color operations
  - `ColorDebuggerPreview`: Advanced color inspection and comparison tool with:
    - Real-time color space visualization
    - Component analysis across RGB, HSL, and LAB
    - Visual color comparison with difference metrics
    - WCAG contrast ratio calculation and compliance badges
  - `PaletteStudioPreview`: Interactive palette generation and export tool with:
    - Accessible palette generation from seed colors
    - WCAG compliance options (AA/AAA)
    - Customizable palette size and options
    - Export to multiple formats (JSON, CSS, SVG, ASE, PNG)
    - One-click copying and sharing
  - `ColorAnimationPreview`: Dynamic color animation and transition tool with:
    - Real-time color interpolation preview
    - Multiple interpolation modes (RGB, HSL, LAB)
    - Customizable animation duration and easing
    - Performance metrics and FPS monitoring
  - `AccessibilityLabPreview`: Comprehensive accessibility testing suite with:
    - Interactive contrast ratio checker
    - WCAG 2.1 compliance testing (AA/AAA)
    - Best practices and guidelines reference
  - Accessibility-focused UI with proper contrast and SwiftUI best practices
  - Real-time code generation for gradients and themes
  - Performance monitoring for blend operations
- **Color Debugging Utilities**: Comprehensive tools for inspecting and comparing colors across different color spaces.
  - `ColorSpaceConverter`: Converts colors between RGB, HSL, HSB, CMYK, LAB, and XYZ.
  - `ColorComponents`: Structured representation of color components.
  - `colorSpaceComponents()`: Extension on Color for easy access to all color space components.
  - `ColorSpaceInspectorView`: SwiftUI view for visual inspection of color properties.
- **Color Comparison Tool**: Analyze differences between colors with perceptual difference calculations and WCAG contrast ratio analysis.
  - `ColorDifference`: Structure representing differences between colors.
  - `compare(with:)`: Method to analyze color differences.
  - `ColorComparisonView`: Visual comparison view.
- **Enhanced WCAG Compliance Debugging**: Advanced color suggestion algorithms that preserve brand identity.
  - `WCAGColorSuggestions`: Generate accessible color alternatives.
  - `suggestedAccessibleColors()`: Improved method with hue preservation option.
- **Documentation**: Detailed documentation with examples for all new features.
- **SwiftLint Integration**: Added SwiftLint for consistent code style and quality.
  - Enforces consistent code formatting and best practices
  - Helps catch potential issues early in development
  - Improves code readability and maintainability
  - Integrated with GitHub Actions for automated checks
  - Custom configuration to balance strictness with practicality

### Fixed
- Platform-specific test issues for proper macOS compatibility.

## [1.5.0] - 2025-03-14

### Added
- Palette export and sharing functionality
- Support for exporting palettes in JSON, CSS, SVG, Adobe ASE, and PNG formats
- UI components for exporting and sharing palettes
- Integration with system share sheet
- Clipboard support for quick copying
- View modifiers for adding export functionality to any view
- Documentation for palette export feature
- AccessibilityEnhancer for intelligent color adjustments that preserve brand identity
- Multiple adjustment strategies (preserve hue, preserve saturation, preserve lightness, minimum change)
- Perceptually uniform color adjustments using LAB color space
- Accessible color variant suggestions that maintain harmony with original colors
- Interactive demo view for testing accessibility enhancements
- Added comprehensive migration guide for users updating to version 1.5.0
- Added detailed documentation for parameter naming conventions

### Changed
- Improved type usage consistency:
  - Using `CGFloat` for UI components and SwiftUI interfaces
  - Using `Double` for color space calculations and WCAG compliance
- Enhanced documentation clarity and examples
- Standardized parameter naming across the library for better consistency:
  - Changed `adjustedForAccessibility(against:minimumRatio:)` to `adjustedForAccessibility(with:minimumRatio:)`
  - Changed `enhanced(against:targetLevel:strategy:)` to `enhanced(with:targetLevel:strategy:)`
  - Changed `suggestAccessibleVariants(against:targetLevel:count:)` to `suggestAccessibleVariants(with:targetLevel:count:)`
  - Changed `ColorCache.getCachedContrastRatio(for:and:)` to `ColorCache.getCachedContrastRatio(for:with:)`
  - Changed `ColorCache.cacheContrastRatio(for:and:ratio:)` to `ColorCache.cacheContrastRatio(for:with:ratio:)`
  - Changed `ColorCache.getCachedBlendedColor(color1:and:)` to `ColorCache.getCachedBlendedColor(color1:with:)`
  - Changed `ColorCache.cacheBlendedColor(color1:and:)` to `ColorCache.cacheBlendedColor(color1:with:)`
  - Changed `ColorCache.getCachedInterpolatedColor(color1:and:)` to `ColorCache.getCachedInterpolatedColor(color1:with:)`
  - Changed `ColorCache.cacheInterpolatedColor(color1:and:)` to `ColorCache.cacheInterpolatedColor(color1:with:)`
  - Standardized all blending and interpolation methods to use `amount` parameter consistently
  - Standardized all gradient methods to use `amount` parameter consistently

### Documentation
- Updated all method documentation to reflect parameter name changes
- Added more comprehensive examples in README
- Improved parameter descriptions for clarity

## [1.4.3] - 2025-03-14

### Fixed
- Added proper availability check for SF Symbols on macOS to fix compilation issues
- Despite having macOS 11.0 as minimum deployment target, explicit availability checks are required for certain APIs

### Compatibility
- Requires iOS 14.0 or later
- Requires macOS 11.0 or later

## [1.4.2] - 2025-03-13

### Fixed
- Critical issue where the Accessible Palette Generator would freeze the app
- Performance issues in color palette generation algorithms

### Added
- Loading indicators during palette generation for better user feedback
- Timeout mechanisms to prevent potential infinite loops
- Fallback mechanisms to ensure palette generation always completes

### Changed
- Moved palette and theme generation to background threads
- Optimized color generation to be more efficient and deterministic
- Made color similarity detection more lenient to improve palette variety
- Simplified theme generation for better performance

## [1.4.1] - 2025-03-15

### Changed
- Improved thread safety in ColorCache by changing NSCache variable declarations to constants
- Enhanced documentation regarding thread safety

## [1.4.0] - 2025-03-12

### Added
- High-performance caching system for expensive color operations
- Caching for LAB and HSL color components
- Caching for WCAG luminance and contrast ratios
- Caching for color blending operations
- Caching for gradient interpolation
- Performance benchmark example
- Documentation for performance optimizations

### Changed
- Optimized LAB color conversion with caching
- Optimized HSL color conversion with caching
- Optimized WCAG calculations with caching
- Optimized color blending with caching
- Optimized gradient interpolation with caching

## [1.3.0] - 2025-03-10

### Added
- Improved API documentation
- String representation methods for all color types
- Enhanced parameter validation
- Better error handling

### Changed
- Standardized naming conventions across the library
- Updated test cases to reflect new API methods
- Fixed hex conversion issues

## [1.2.0] - 2025-03-05

### Added
- Color blending modes (Normal, Multiply, Screen, Overlay, etc.)
- Gradient generation utilities
- Comprehensive theming system
- Auto-generate accessible color palettes

### Changed
- Improved WCAG contrast checking
- Enhanced adaptive colors for Light/Dark mode

## [1.1.0] - 2025-02-20

### Added
- HSL color support
- CMYK color support
- LAB color support
- WCAG contrast checking for accessibility
- SwiftUI modifiers for dynamic colors

### Changed
- Enhanced HEX <-> RGB conversion
- Improved color component extraction

## [1.0.0] - 2025-02-01

### Added
- Initial release
- Basic color manipulation
- HEX <-> RGB conversion
- Adaptive colors (Light/Dark mode)
