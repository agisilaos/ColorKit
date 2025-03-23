# ``ColorKit``

A lightweight Swift package for color manipulation, adaptive themes, and accessibility compliance in SwiftUI.

## Overview

ColorKit is a comprehensive color utility library that makes working with colors in SwiftUI simple and powerful. It provides tools for color conversion, manipulation, theming, and accessibility compliance.

![ColorKit logo showing a paint palette](colorkit-header)

## Features

- Convert between color spaces (HEX, RGB, HSL, CMYK, LAB)
- Create adaptive colors for light/dark mode
- Ensure WCAG contrast compliance for accessibility
- Generate accessible color palettes
- Build comprehensive theme systems
- Utilize advanced color blending modes
- Optimize performance with color caching
- Debug and inspect colors with detailed tools
- Export & share color palettes

## Topics

### Essentials

- <doc:GettingStarted>
- ``Color``

### Color Spaces

- <doc:color-spaces>
- ``Color/hexValue()``
- ``Color/hslComponents()``
- ``Color/cmykComponents()``
- ``Color/labComponents()``

### Accessibility

- <doc:accessibility>
- ``WCAG``
- ``WCAGContrastLevel``
- ``Color/generateAccessiblePalette(targetLevel:paletteSize:includeBlackAndWhite:)``
- ``Color/generateAccessibleTheme(name:targetLevel:)``

### Theming System

- <doc:theming>
- ``ColorTheme``
- ``ThemeManager``
- ``Color/themed(_:)``

### Tutorials

- <doc:ColorBasics>
- <doc:AccessibilityGuide>
- <doc:ThemingSystem>

### Preview Catalog

- ``MainCatalogView``
- ``ColorSpacePreview``
- ``ThemePreview``
- ``AccessibilityLabPreview``
- ``BlendingPreview``
- ``GradientPreview``
- ``PaletteStudioPreview``
- ``ColorAnimationPreview``
- ``ColorDebuggerPreview``
- ``PerformanceBenchmark`` 