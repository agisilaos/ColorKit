import ColorKit
import Foundation

enum BenchmarkError: Error {
    case invalidArguments
    case debugBuild
    case invalidFixture(String)
    case invalidClock
}

enum CacheMode: String, Codable, CaseIterable {
    case empty
    case primed
    case unused

    func prepare(clear: () -> Void, prime: () -> Void) {
        switch self {
        case .empty: clear()
        case .primed:
            clear()
            prime()
        case .unused: break
        }
    }
}

/// An unoptimized boundary for both inputs and complete results. Verify its call
/// sites in the Release executable when changing the harness or Swift toolchain.
@_optimize(none)
@inline(never)
func opaqueInput<T>(_ value: T) -> T {
    value
}

@_optimize(none)
@inline(never)
func consume(_ value: some Any) {
    withExtendedLifetime(value) {}
}

struct Sample: Codable {
    let requestCount: Int
    let requestNanoseconds: UInt64
    let controlNanoseconds: UInt64
}

struct ScenarioDescription: Codable {
    let id: String
    let purpose: String
    let inputs: String
    let settings: String
    let expected: String
    let unit: String
    let modes: [CacheMode]
}

struct Scenario {
    let description: ScenarioDescription
    let validate: (CacheMode) throws -> Void
    let run: (CacheMode, Int, Int) throws -> [Sample]

    init<Input, Output>(
        description: ScenarioDescription,
        input: Input,
        operation: @escaping (Input) -> Output,
        validate: @escaping (Output) throws -> Void
    ) {
        self.description = description
        self.validate = { mode in
            guard description.modes.contains(mode) else { throw BenchmarkError.invalidArguments }
            ColorCache.shared.clearCache()
            defer { ColorCache.shared.clearCache() }
            mode.prepare(clear: { ColorCache.shared.clearCache() }, prime: { consume(operation(input)) })
            try validate(operation(input))
        }
        self.run = { mode, samples, iterations in
            guard description.modes.contains(mode), (1 ... 1_000).contains(samples),
                  (1 ... 100_000).contains(iterations) else { throw BenchmarkError.invalidArguments }
            ColorCache.shared.clearCache()
            defer { ColorCache.shared.clearCache() }
            let reference = operation(input)
            try validate(reference)
            // Untimed warm-up; each timed request still receives its own cache preparation.
            for _ in 0 ..< 10 {
                consume(operation(opaqueInput(input)))
            }
            var measurements: [Sample] = []
            for index in 0 ..< samples {
                let request: () throws -> UInt64 = {
                    try measureRequests(
                        iterations: iterations,
                        prepare: {
                            mode.prepare(clear: { ColorCache.shared.clearCache() }, prime: {
                                consume(operation(opaqueInput(input)))
                            })
                        },
                        request: { operation(opaqueInput(input)) }
                    )
                }
                let control: () throws -> UInt64 = {
                    try measureRequests(
                        iterations: iterations,
                        prepare: {
                            mode.prepare(clear: { ColorCache.shared.clearCache() }, prime: {
                                consume(operation(opaqueInput(input)))
                            })
                        },
                        request: {
                            // Same input barrier and full result type, with a precomputed result.
                            consume(opaqueInput(input))
                            return reference
                        }
                    )
                }
                let requestTime: UInt64
                let controlTime: UInt64
                if index.isMultiple(of: 2) {
                    requestTime = try request()
                    controlTime = try control()
                } else {
                    controlTime = try control()
                    requestTime = try request()
                }
                measurements.append(Sample(
                    requestCount: iterations,
                    requestNanoseconds: requestTime,
                    controlNanoseconds: controlTime
                ))
            }
            try validate(operation(input))
            return measurements
        }
    }
}

/// Sum individually timed requests; cache preparation and sample storage are excluded.
func measureRequests(
    iterations: Int,
    prepare: () -> Void,
    now: () -> UInt64 = { DispatchTime.now().uptimeNanoseconds },
    request: () -> some Any
) throws -> UInt64 {
    guard iterations > 0 else { throw BenchmarkError.invalidArguments }
    var total: UInt64 = 0
    for _ in 0 ..< iterations {
        prepare()
        let start = now()
        consume(request())
        let end = now()
        guard end >= start else { throw BenchmarkError.invalidClock }
        let (next, overflow) = total.addingReportingOverflow(end - start)
        guard !overflow else { throw BenchmarkError.invalidClock }
        total = next
    }
    guard total > 0 else { throw BenchmarkError.invalidClock }
    return total
}

func requireFixture(_ condition: Bool, _ explanation: String) throws {
    guard condition else { throw BenchmarkError.invalidFixture(explanation) }
}
