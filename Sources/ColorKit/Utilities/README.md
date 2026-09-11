# ColorKit Utilities

This directory contains utility classes and functions that support the core functionality of ColorKit.

## Color comparison

`Color.comparisonResult(with:)` is the authoritative comparison API. It resolves each input once, then derives RGB and HSL component differences, CIEDE2000, contrast, and WCAG levels from those snapshots. It accepts fixed, finite, opaque colors inside the standard sRGB gamut; other inputs return per-color issues without partial or fabricated measurements.

The internal CIEDE2000 calculator uses D65 LAB and the reference weighting factors. Its implementation is validated against all 34 [published supplementary pairs](https://hajim.rochester.edu/ece/sites/gsharma/ciede2000/dataNprograms/ciede2000testdata.txt). The deprecated `compare(with:)` method exists only as a ColorKit 2.x adapter and labels unavailable-input fallback values as legacy RGB distance.

## ColorCache

`ColorCache` is a high-performance caching system introduced in ColorKit 1.4.0 to optimize expensive color operations.

### Overview

The `ColorCache` class provides thread-safe caching for:

- LAB color components
- HSL color components
- WCAG luminance values
- WCAG contrast ratios

### Implementation Details

- Uses `NSCache` for automatic memory management
- Thread-safe for use in concurrent environments
- Singleton pattern for global access
- Available on iOS 14.0+ and macOS 12.0+

### Usage

The cache is automatically used by ColorKit methods. No changes to your code are required to benefit from these performance improvements.

```swift
// Example: First call calculates and caches
let lab1 = color.labComponents()

// Repeated calls can reuse cached results for eligible fixed inputs
let lab2 = color.labComponents()
```

### Manual Cache Management

If needed, you can manually clear the cache:

```swift
// Clear all caches
ColorCache.shared.clearCache()

// Or clear specific caches
ColorCache.shared.clearLABCache()
ColorCache.shared.clearHSLCache()
ColorCache.shared.clearLuminanceCache()
ColorCache.shared.clearContrastCache()

// Get cached contrast ratio between two colors
if let ratio = ColorCache.shared.getCachedContrastRatio(for: color1, with: color2) {
    print("Cached contrast ratio: \(ratio)")
}

// Cache a contrast ratio
ColorCache.shared.cacheContrastRatio(for: color1, with: color2, ratio: 4.5)
```

### When to Clear the Cache

Consider clearing the cache in memory-sensitive situations:

- When your app receives a memory warning
- Before performing memory-intensive operations
- When transitioning between major sections of your app

### Performance measurement

Cache benefits depend on the operation, input identity, cache state, and environment. Unsupported identities bypass caching. Historical speedup ratios are not supported by reproducible measurements and should not be used as expectations.

See [performance guidance](../../../PERFORMANCE_IMPROVEMENTS.md) and the [Release benchmark runner](../../../Benchmarks/README.md) for workloads, cache preparation, and reproduction commands.
