# Changelog

All notable changes to ColorKit will be documented in this file.

## [1.5.0] - 2024-03-14

### Changed
- Standardized parameter naming across the library for better consistency:
  - Changed `adjustedForAccessibility(against:minimumRatio:)` to `adjustedForAccessibility(with:minimumRatio:)`
  - Changed `ColorCache.getCachedContrastRatio(for:and:)` to `ColorCache.getCachedContrastRatio(for:with:)`
  - Changed `ColorCache.cacheContrastRatio(for:and:ratio:)` to `ColorCache.cacheContrastRatio(for:with:ratio:)`
  - Changed `enhanced(against:targetLevel:strategy:)` to `enhanced(with:targetLevel:strategy:)`
  - Changed `suggestAccessibleVariants(against:targetLevel:count:)` to `suggestAccessibleVariants(with:targetLevel:count:)`
  - Standardized all blending and interpolation methods to use `amount` parameter consistently
  - Standardized all gradient methods to use `amount` parameter consistently

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

## [1.1.0] - 2024-03-15

### Changed
- Standardized parameter naming across the library for better consistency:
  - Renamed `adjustedForAccessibility(against:minimumRatio:)` to `adjustedForAccessibility(with:minimumRatio:)`
  - Renamed `getCachedContrastRatio(for:and:)` to `getCachedContrastRatio(for:with:)`
  - Renamed `cacheContrastRatio(for:and:ratio:)` to `cacheContrastRatio(for:with:ratio:)`

### Added
- Added migration guide for users updating to version 1.1.0

## [1.0.0] - 2025-02-01

### Added
- Initial release
- Basic color manipulation
- HEX <-> RGB conversion
- Adaptive colors (Light/Dark mode) 