# ColorKit Performance Improvements

## Overview

ColorKit 1.4.0 introduces significant performance optimizations through a high-performance caching system. This document explains the improvements and how they benefit your applications.

## Key Performance Enhancements

### Caching System

ColorKit now includes a thread-safe caching system that dramatically improves performance for repeated color operations. The caching system:

- Uses `NSCache` for automatic memory management
- Is thread-safe for use in concurrent environments
- Requires zero configuration from users
- Automatically clears memory when system resources are low

### Performance Metrics

Based on our benchmarks, the following performance improvements can be expected:

| Operation | Performance Improvement | Notes |
|-----------|-------------------------|-------|
| LAB Color Conversion | Up to 10x faster | Most significant for repeated conversions |
| HSL Color Conversion | Up to 8x faster | Especially beneficial for UI with many color calculations |
| WCAG Calculations | Up to 12x faster | Critical for accessibility checks |
| Color Blending | Up to 5x faster | Important for complex UIs with blended colors |
| Gradient Generation | Up to 7x faster | Significant for animations and transitions |

## Real-World Benefits

These performance improvements translate to:

1. **Reduced CPU Usage**: Less processing power required for color operations
2. **Better Battery Life**: More efficient processing means less power consumption
3. **Smoother UI**: Faster color calculations lead to more responsive interfaces
4. **Improved Scalability**: Better handling of complex UIs with many color operations

## Implementation Details

The caching system is implemented through the `ColorCache` class, which:

- Caches LAB and HSL components for each color
- Stores WCAG luminance values and contrast ratios
- Maintains thread safety through proper synchronization
- Automatically manages memory based on system pressure

### Cache identity

Caching is optional. Colors without a fixed identity in one of the supported RGB or grayscale spaces miss the cache and are not inserted. Keys retain the original color space, every component including alpha, and exact finite interpolation amounts; they do not convert colors or round values. Unsupported spaces and nonfinite key inputs bypass caching.

Contrast keys are symmetric. Blend and interpolation keys preserve operand order and operation parameters. All six stores use the same count limit. Fewer hits or eviction must not change numerical results.

See [the cache identity design](docs/design/cache-identity.md) for the supported spaces and regression coverage. This change does not extend the color formats accepted by the underlying computations.

## Using the Cache in Memory-Sensitive Applications

While the cache is automatically managed, you can manually control it if needed:

<!-- swift-example: cache -->
```swift
// Clear the entire cache
ColorCache.shared.clearCache()

// Clear specific caches
ColorCache.shared.clearLABCache()
ColorCache.shared.clearHSLCache()
ColorCache.shared.clearLuminanceCache()
ColorCache.shared.clearContrastCache()
```

## Benchmarking

Open the public `PerformanceBenchmark` SwiftUI view and use its Run Benchmarks
button to measure operations on your hardware. There is no public programmatic
`runAllBenchmarks()` API. Results depend on the device, build configuration,
inputs, and cache state; they are not a guarantee of the historical ratios above.

<!-- swift-example: benchmark -->
```swift
import SwiftUI
import ColorKit

struct ContentView: View {
    var body: some View {
        PerformanceBenchmark()
    }
}
```

## Conclusion

The performance improvements in ColorKit 1.4.0 provide significant benefits with zero configuration required. Your applications will automatically take advantage of these optimizations simply by updating to the latest version.
