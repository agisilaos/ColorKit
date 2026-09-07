import SwiftUI
import Testing

@testable import ColorKit

struct BenchmarkMeasurementTests {
    @Test("Preview conversion workloads produce HSL and D65 LAB coordinates")
    func convertsFixedRed() throws {
        let red = Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 1)
        let hsl = try #require(BenchmarkConversion.hsl.components(for: red))
        #expect(abs(hsl.0) < 0.001)
        #expect(abs(hsl.1 - 1) < 0.001)
        #expect(abs(hsl.2 - 0.5) < 0.001)
        let lab = try #require(BenchmarkConversion.lab.components(for: red))
        #expect(abs(lab.0 - 53.2408) < 0.001)
        #expect(abs(lab.1 - 80.0925) < 0.001)
        #expect(abs(lab.2 - 67.2032) < 0.001)
    }

    @Test("Preview measurement executes every requested operation")
    func executesEveryRequest() {
        var requests = 0
        _ = BenchmarkMeasurement.measure(name: "Counter", iterations: 17) {
            requests += 1
            return requests
        }
        #expect(requests == 17)
    }

    @Test("Nonpositive iteration counts produce no preview measurements", arguments: [0, -1])
    func rejectsInvalidIterations(iterations: Int) {
        #expect(PerformanceBenchmark.benchmark(operation: .conversion, iterations: iterations).isEmpty)
    }
}
