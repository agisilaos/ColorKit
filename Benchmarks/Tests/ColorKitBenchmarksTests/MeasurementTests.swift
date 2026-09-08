@testable import ColorKitBenchmarks
import Testing

struct MeasurementTests {
    @Test("Preparation precedes each individually timed request")
    func timingBoundaries() throws {
        var events: [String] = []
        var tick: UInt64 = 0
        let duration = try measureRequests(
            iterations: 3,
            prepare: { events.append("prepare") },
            now: {
                events.append("clock")
                tick += 7
                return tick
            },
            request: { events.append("request") }
        )
        #expect(duration == 21)
        #expect(events == Array(repeating: ["prepare", "clock", "request", "clock"], count: 3).flatMap(\.self))
    }

    @Test("Cache modes apply exactly the documented preparation", arguments: CacheMode.allCases)
    func preparation(mode: CacheMode) {
        var events: [String] = []
        mode.prepare(clear: { events.append("clear") }, prime: { events.append("prime") })
        switch mode {
        case .empty: #expect(events == ["clear"])
        case .primed: #expect(events == ["clear", "prime"])
        case .unused: #expect(events.isEmpty)
        }
    }

    @Test("Invalid clocks and iteration counts cannot produce timings")
    func invalidMeasurements() {
        #expect(throws: BenchmarkError.self) {
            try measureRequests(iterations: 1, prepare: {}, now: { 0 }, request: { 1 })
        }
        #expect(throws: BenchmarkError.self) {
            try measureRequests(iterations: 0, prepare: {}, request: { 1 })
        }
    }
}

/// Own the shared cache for the entire suite. These are fixture correctness checks,
/// not duration assertions or performance regression gates.
@Suite(.serialized)
struct ScenarioTests {
    @Test("Every named fixture validates in all supported cache modes")
    func fixtures() throws {
        let cases = scenarios()
        #expect(cases.count == 8)
        #expect(Set(cases.map(\.description.id)).count == cases.count)
        for scenario in cases {
            for mode in scenario.description.modes {
                try scenario.validate(mode)
            }
        }
    }

    @Test("Invalid counts and unsupported cache modes are rejected")
    func invalidArguments() throws {
        let comparison = try #require(scenarios().first { $0.description.id == "comparison-black-white" })
        #expect(throws: BenchmarkError.self) { try comparison.run(.empty, 1, 1) }
        #expect(throws: BenchmarkError.self) { try comparison.run(.unused, 0, 1) }
        #expect(throws: BenchmarkError.self) { try comparison.run(.unused, 1, -1) }
    }
}
