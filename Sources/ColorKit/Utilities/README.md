# ColorKit Utilities

This directory contains utility classes and functions that support the core functionality of ColorKit.

## ColorCache

`ColorCache` is a performance optimization utility that caches expensive color calculations to improve the efficiency of ColorKit operations.

### Features

- Thread-safe caching using `NSCache`
- Caches LAB and HSL color components
- Caches WCAG luminance and contrast ratios
- Caches blended colors
- Caches interpolated colors for gradients

### Usage

The `ColorCache` class is designed as a singleton and is used internally by ColorKit. You typically don't need to interact with it directly, as the relevant ColorKit methods will automatically use the cache when appropriate.

```swift
// The cache is automatically used by ColorKit methods
let color1 = Color.red
let color2 = Color.blue

// First call calculates and caches
let lab1 = color1.labComponents()

// Second call retrieves from cache
let lab1Again = color1.labComponents() // Much faster!

// Blending with caching
let blended = color1.blended(with: color2, mode: .overlay)

// Gradient interpolation with caching
let interpolated = color1.interpolated(with: color2, fraction: 0.5, in: .lab)
```

### Manual Cache Management

If needed, you can manually clear the cache:

```swift
// Clear all caches
ColorCache.shared.clearAllCaches()

// Or clear specific caches
ColorCache.shared.clearBlendedColorCache()
ColorCache.shared.clearInterpolatedColorCache()
```

### Implementation Details

- The cache uses color component values as keys
- For performance reasons, interpolation values are rounded to 3 decimal places
- The cache is available on iOS 14.0+ and macOS 11.0+
- Thread-safe implementation using `NSCache` 