# Changelog

All notable changes to ColorKit will be documented in this file.

## [1.6.0] - TBR

### Added
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

## [1.5.0] - 2024-03-14

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

## [1.4.3] - 2024-03-14

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