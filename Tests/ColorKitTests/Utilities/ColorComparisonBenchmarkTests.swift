import Testing

@testable import ColorKit

struct ColorComparisonBenchmarkTests {
    @Test("Comparison benchmark reports valid throughput")
    func reportsComparisonThroughput() throws {
        let iterations = 10_000
        let results = PerformanceBenchmark.benchmark(
            operation: .comparison,
            iterations: iterations
        )
        #expect(results.count == 1)
        let result = try #require(results.first)

        #expect(result.name == "CIEDE2000 Color Comparison")
        #expect(result.duration > 0)
        #expect(result.duration.isFinite)
        #expect(result.operationsPerSecond > 0)
        #expect(result.operationsPerSecond.isFinite)
        #expect(result.operationsPerSecond == Double(iterations) / result.duration)
    }
}
