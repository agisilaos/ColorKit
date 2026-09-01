//
//  PerformanceBenchmarkTests.swift
//  ColorKitTests
//
//  Created by Agisilaos Tsaraboulidis on 01.09.2026.
//
//  Description:
//  Tests for the performance benchmark result contract.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import XCTest

@testable import ColorKit

final class PerformanceBenchmarkTests: XCTestCase {
    func testBlendingResultsPreserveOrderAndMeasurements() async {
        let iterations = 100

        let results = await benchmark(.blending, iterations: iterations)

        XCTAssertEqual(results.map(\.name), [
            "Blend Mode: normal",
            "Blend Mode: multiply",
            "Blend Mode: screen",
            "Blend Mode: overlay",
            "Blend Mode: darken",
            "Blend Mode: lighten",
            "Blend Mode: colorDodge",
            "Blend Mode: colorBurn",
            "Blend Mode: softLight",
            "Blend Mode: hardLight",
            "Blend Mode: difference",
            "Blend Mode: exclusion"
        ])
        assertValidMeasurements(results, iterations: iterations)
    }

    func testConversionResultsPreservePresentationAndMeasurements() async {
        let iterations = 100

        let results = await benchmark(.conversion, iterations: iterations)

        XCTAssertEqual(results.map(\.name), ["Color Space Conversion"])
        assertValidMeasurements(results, iterations: iterations)
    }

    func testGradientResultsPreserveOrderAndMeasurements() async {
        let iterations = 100

        let results = await benchmark(.gradient, iterations: iterations)

        XCTAssertEqual(results.map(\.name), ["Linear Gradient", "Radial Gradient"])
        assertValidMeasurements(results, iterations: iterations)
    }

    func testAccessibilityResultsPreservePresentationAndMeasurements() async {
        let iterations = 100

        let results = await benchmark(.accessibility, iterations: iterations)

        XCTAssertEqual(results.map(\.name), ["Contrast Ratio"])
        assertValidMeasurements(results, iterations: iterations)
    }

    private func benchmark(
        _ operation: BenchmarkOperation,
        iterations: Int
    ) async -> [BenchmarkResult] {
        await Task.detached { [operation, iterations] in
            PerformanceBenchmark.benchmark(operation: operation, iterations: iterations)
        }.value
    }

    private func assertValidMeasurements(
        _ results: [BenchmarkResult],
        iterations: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for result in results {
            XCTAssertGreaterThan(result.duration, 0, file: file, line: line)
            XCTAssertTrue(result.duration.isFinite, file: file, line: line)
            XCTAssertGreaterThan(result.operationsPerSecond, 0, file: file, line: line)
            XCTAssertTrue(result.operationsPerSecond.isFinite, file: file, line: line)
            XCTAssertEqual(
                result.operationsPerSecond,
                Double(iterations) / result.duration,
                file: file,
                line: line
            )
        }
    }
}
