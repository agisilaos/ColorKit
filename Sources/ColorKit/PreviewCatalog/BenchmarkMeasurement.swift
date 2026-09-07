import SwiftUI

/// Internal preview workloads; the repository's Release runner owns baseline measurements.
enum BenchmarkConversion: String, CaseIterable {
    case hsl = "HSL Components (uncontrolled cache)"
    case lab = "LAB Components (uncontrolled cache)"

    func components(for color: Color) -> (CGFloat, CGFloat, CGFloat)? {
        switch self {
        case .hsl: color.hslComponents()
        case .lab: color.labComponents()
        }
    }
}

enum BenchmarkMeasurement {
    // Keep these barriers unoptimized: retaining only the final result permits
    // the compiler to eliminate earlier requests or hoist invariant work.
    @_optimize(none)
    @inline(never)
    static func input<T>(_ value: T) -> T { value }

    @_optimize(none)
    @inline(never)
    static func consume<T>(_ value: T) {
        withExtendedLifetime(value) {}
    }

    static func measure<T>(name: String, iterations: Int, operation: () -> T) -> BenchmarkResult {
        let start = DispatchTime.now().uptimeNanoseconds
        for _ in 0..<iterations {
            consume(operation())
        }
        let duration = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000
        return BenchmarkResult(
            name: name,
            duration: duration,
            operationsPerSecond: Double(iterations) / duration
        )
    }
}
