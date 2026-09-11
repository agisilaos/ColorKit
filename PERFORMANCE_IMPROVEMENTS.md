# ColorKit Performance Measurement

## Overview

ColorKit caches selected repeated color operations. The repository's macOS Release
runner provides reproducible reference measurements; actual costs depend on the
operation, inputs, cache preparation, machine, and toolchain.

## Key Performance Enhancements

### Caching System

ColorKit includes a thread-safe caching system for repeated color operations. The caching system:

- Uses `NSCache` for automatic memory management
- Is thread-safe for use in concurrent environments
- Requires zero configuration from users
- Automatically clears memory when system resources are low

### Performance Metrics

The historical speedup ratios previously listed here did not include reproducible
supporting measurements and should not be used as expectations. The new baseline
measures complete public conversion, comparison, enhancement, and palette requests.
It does not establish rendering, battery-life, or application-level improvements.

See [the benchmark runner](Benchmarks/README.md) for fixtures, cache preparation,
result-consumption overhead, raw samples, and reproduction commands. Treat empty
and primed cache timings as different workloads, not a before/after library speedup.

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

Use the [maintained standalone runner](Benchmarks/README.md) for reference data.
Run `python3 Benchmarks/run.py --output .build/benchmark-results/first`
from the repository root. It builds the separate macOS runner in Release mode and
saves repeated timings and environment metadata in a new output directory.

Open the public `PerformanceBenchmark` SwiftUI view and use its Run Benchmark
button for exploratory timings. Conversion runs actual HSL and LAB requests with
uncontrolled cache state. Gradient cases construct SwiftUI values; they do not
render pixels. There is no public programmatic `runAllBenchmarks()` API.

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
