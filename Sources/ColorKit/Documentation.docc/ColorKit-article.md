# ``ColorKit``

ColorKit is a Swift package for color manipulation, accessibility checking, and theming. It includes utilities for working with RGB, HSL, CMYK, LAB, and more, optimized for SwiftUI.

## Overview

ColorKit provides a comprehensive set of tools for working with colors in your SwiftUI applications. From basic color space conversions to advanced accessibility features, ColorKit helps you create visually appealing and accessible user interfaces.

## Topics

### Essentials
- ``Color``
- ``ColorTheme``
- ``ThemeManager``

### Color Spaces
- <doc:Color-Spaces>
- ``ColorSpaceConverter``
- ``Color/init(L: CGFloat, a: CGFloat, b: CGFloat)``
- ``Color/init(hue: CGFloat, saturation: CGFloat, lightness: CGFloat)``
- ``Color/init?(hex: String)``
- ``Color/init(cyan: CGFloat, magenta: CGFloat, yellow: CGFloat, key: CGFloat)``

### Accessibility
- <doc:Accessibility-article>
- ``WCAGContrastLevel``
- ``AccessibilityEnhancer``

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
