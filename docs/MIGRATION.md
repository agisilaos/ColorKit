# Migration Guide

This guide helps you migrate your code to the latest version of ColorKit.

## Version 1.5.0

### Parameter Name Changes

#### Blending Methods
The `alpha` parameter has been renamed to `amount` in all blending methods for better consistency:

```swift
// Old
color.blended(with: otherColor, mode: .normal, alpha: 0.5)
color.multiply(with: otherColor, alpha: 0.5)

// New
color.blended(with: otherColor, mode: .normal, amount: 0.5)
color.multiply(with: otherColor, amount: 0.5)
```

#### Interpolation Methods
The `fraction` parameter has been renamed to `amount` in all interpolation methods:

```swift
// Old
color.interpolated(with: otherColor, fraction: 0.5, in: .rgb)

// New
color.interpolated(with: otherColor, amount: 0.5, in: .rgb)
```

### Type Usage Guidelines

ColorKit now follows these type usage guidelines:

- Use `CGFloat` for:
  - UI components (views, frames, sizes)
  - SwiftUI/AppKit/UIKit interfaces
  - Visual properties (alpha, opacity)
  - User-facing values

- Use `Double` for:
  - Color space calculations (LAB, HSL, RGB conversions)
  - WCAG compliance calculations
  - Mathematical operations
  - Precision-critical calculations
  - Cache values for calculations

### Example Updates

Here's a complete example showing the changes:

```swift
// Old code
let gradient = color.linearGradient(to: otherColor, steps: 5)
let blended = color.blended(with: otherColor, mode: .normal, alpha: 0.5)
let interpolated = color.interpolated(with: otherColor, fraction: 0.5, in: .rgb)

// New code
let gradient = color.linearGradient(to: otherColor, steps: 5)
let blended = color.blended(with: otherColor, mode: .normal, amount: 0.5)
let interpolated = color.interpolated(with: otherColor, amount: 0.5, in: .rgb)
```

### Benefits

These changes provide several benefits:
1. More consistent parameter naming across the library
2. Clearer distinction between UI-related and calculation-related types
3. Better alignment with SwiftUI conventions
4. Improved code readability and maintainability

### Need Help?

If you encounter any issues during migration or have questions, please:
1. Check the [documentation](README.md)
2. Open an issue on GitHub
3. Contact the maintainers 