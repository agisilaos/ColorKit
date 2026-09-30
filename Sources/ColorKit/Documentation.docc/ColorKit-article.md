# ``ColorKit``

ColorKit is a Swift package for color manipulation, accessibility checking, and theming. It includes utilities for working with RGB, HSL, CMYK, LAB, and more, optimized for SwiftUI.

## Overview

Start with result-bearing workflows to distinguish available measurements and computed colors from unavailable input. Check enhancement and palette outcomes before using candidates: best effort is not a guaranteed contrast pass. Themes and legacy APIs remain available in the guides below.

- [Convert colors](<doc:Color-Spaces-article#Component-conversion-results>) with independent availability for each representation.
- [Measure foreground/background contrast](<doc:Accessibility-article#Contrast-Checking>) and handle unavailable input separately from measured contrast.
- [Enhance within a perceptual distance budget](<doc:Accessibility-article#Verifiable-Results>) and inspect the candidate's outcome.
- [Blend with explicit outcomes](<doc:Utilities-article#Color-Blending>) to distinguish a computed color from an unavailable operation.
- [Generate assessed palettes](<doc:Accessibility-article#Assessed-Palettes>) against an explicit background and retain below-target outcomes.

## Topics

### Essentials
- <doc:Color-Spaces-article>
- <doc:Accessibility-article>
- <doc:Utilities-article>

### Color Spaces
- <doc:Color-Spaces-article>
- ``ColorSpaceConverter``

### Accessibility
- <doc:Accessibility-article>
- ``WCAGContrastLevel``
- ``AccessibilityEnhancer``
- ``ColorVisionDeficiency``

### Theming
- <doc:Theming-article>
- ``ColorTheme``
- ``ThemeManager``

### Utilities
- <doc:Utilities-article>
- ``ColorCache``
- ``PaletteExporter``

### Preview Catalog
- ``MainCatalogView``
- ``BlendingPreview``
- ``GradientPreview``
- ``ThemePreview``
- ``AccessibilityLabPreview``
