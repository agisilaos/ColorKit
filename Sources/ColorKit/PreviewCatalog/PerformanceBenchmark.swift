//
//  PerformanceBenchmark.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 20.03.25.
//
//  Description:
//  Performance benchmarking tool for ColorKit operations.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A preview view for benchmarking ColorKit performance
public struct PerformanceBenchmark: View {
    /// Creates the interactive preview with its default configuration.
    public init() {}

    // MARK: - State

    @State private var isRunningBenchmark = false
    @State private var benchmarkResults: [BenchmarkResult] = []
    @State private var selectedOperation: BenchmarkOperation = .blending
    @State private var iterationCount: Int = 1_000

    // MARK: - Properties

    private let operations: [BenchmarkOperation] = [
        .blending,
        .conversion,
        .gradient,
        .accessibility,
        .comparison
    ]

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Configuration
                configurationSection

                // Results
                resultsSection
            }
            .padding()
        }
        .navigationTitle("Performance Insights")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        await runBenchmark()
                    }
                } label: {
                    if isRunningBenchmark {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Label("Run Benchmark", systemImage: "play.fill")
                    }
                }
                .disabled(isRunningBenchmark)
            }
        }
    }

    // MARK: - View Components

    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuration")
                .font(.headline)

            Picker("Operation", selection: $selectedOperation) {
                ForEach(operations, id: \.self) { operation in
                    Text(operation.name).tag(operation)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                Text("Iterations: \(iterationCount)")
                    .font(.subheadline)

                Slider(
                    value: Binding(
                        get: { Double(iterationCount) },
                        set: { iterationCount = Int($0) }
                    ),
                    in: 100...10_000,
                    step: 100
                )
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Results")
                .font(.headline)

            Text("Exploratory timings include measurement overhead and uncontrolled cache state. Gradients measure value construction only.")
                .font(.caption)
                .foregroundColor(.secondary)

            if benchmarkResults.isEmpty {
                Text("Run a benchmark to see results")
                    .foregroundColor(.secondary)
            } else {
                ForEach(benchmarkResults) { result in
                    BenchmarkResultView(result: result)
                }
            }
        }
    }

    // MARK: - Actions

    @MainActor
    private func runBenchmark() async {
        guard !isRunningBenchmark else { return }

        isRunningBenchmark = true
        benchmarkResults.removeAll()

        let operation = selectedOperation
        let iterations = iterationCount

        // This detached boundary intentionally keeps synchronous CPU loops off MainActor.
        // Keep its closure limited to Sendable captured inputs and returned results.
        let results = await Task.detached(priority: .userInitiated) { [operation, iterations] in
            Self.benchmark(operation: operation, iterations: iterations)
        }.value

        benchmarkResults = results
        isRunningBenchmark = false
    }

    // MARK: - Benchmark Methods

    nonisolated static func benchmark(
        operation: BenchmarkOperation,
        iterations: Int
    ) -> [BenchmarkResult] {
        guard iterations > 0 else { return [] }
        return switch operation {
        case .blending:
            benchmarkBlending(iterations: iterations)
        case .conversion:
            benchmarkConversion(iterations: iterations)
        case .gradient:
            benchmarkGradient(iterations: iterations)
        case .accessibility:
            benchmarkAccessibility(iterations: iterations)
        case .comparison:
            benchmarkComparison(iterations: iterations)
        }
    }

    nonisolated private static func benchmarkBlending(iterations: Int) -> [BenchmarkResult] {
        let first = Color(.sRGB, red: 0, green: 0, blue: 1, opacity: 1)
        let second = Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 1)
        let blendModes: [BlendMode] = [
            .normal, .multiply, .screen, .overlay,
            .darken, .lighten, .colorDodge, .colorBurn,
            .softLight, .hardLight, .difference, .exclusion
        ]
        return blendModes.map { mode in
            BenchmarkMeasurement.measure(name: "Blend Mode: \(mode)", iterations: iterations) {
                BenchmarkMeasurement.input(first).blended(with: second, mode: mode)
            }
        }
    }

    nonisolated private static func benchmarkConversion(iterations: Int) -> [BenchmarkResult] {
        let color = Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 1)
        return BenchmarkConversion.allCases.map { conversion in
            BenchmarkMeasurement.measure(name: conversion.rawValue, iterations: iterations) {
                conversion.components(for: BenchmarkMeasurement.input(color))
            }
        }
    }

    nonisolated private static func benchmarkGradient(iterations: Int) -> [BenchmarkResult] {
        let colors = [
            Color(.sRGB, red: 0, green: 0, blue: 1, opacity: 1),
            Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 1)
        ]
        return [
            BenchmarkMeasurement.measure(name: "Linear Gradient Construction", iterations: iterations) {
                LinearGradient(
                    colors: BenchmarkMeasurement.input(colors),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            },
            BenchmarkMeasurement.measure(name: "Radial Gradient Construction", iterations: iterations) {
                RadialGradient(
                    colors: BenchmarkMeasurement.input(colors),
                    center: .center,
                    startRadius: 0,
                    endRadius: 100
                )
            }
        ]
    }

    nonisolated private static func benchmarkAccessibility(iterations: Int) -> [BenchmarkResult] {
        let first = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
        let second = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
        return [BenchmarkMeasurement.measure(name: "Contrast Ratio", iterations: iterations) {
            BenchmarkMeasurement.input(first).contrastRatio(with: second)
        }]
    }

    nonisolated private static func benchmarkComparison(iterations: Int) -> [BenchmarkResult] {
        let first = Color(.sRGB, red: 0.85, green: 0.2, blue: 0.35, opacity: 1)
        let second = Color(.sRGB, red: 0.15, green: 0.55, blue: 0.8, opacity: 1)
        return [BenchmarkMeasurement.measure(name: "CIEDE2000 Color Comparison", iterations: iterations) {
            BenchmarkMeasurement.input(first).comparisonResult(with: second)
        }]
    }
}

// MARK: - Supporting Types

enum BenchmarkOperation: String, CaseIterable, Sendable {
    case blending
    case conversion
    case gradient
    case accessibility
    case comparison

    var name: String {
        rawValue.capitalized
    }
}

struct BenchmarkResult: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let duration: TimeInterval
    let operationsPerSecond: Double
}

// MARK: - Supporting Views

private struct BenchmarkResultView: View {
    let result: BenchmarkResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.name)
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.3f ms", result.duration * 1_000))
                        .font(.system(.body, design: .monospaced))
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Operations/sec")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f", result.operationsPerSecond))
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        PerformanceBenchmark()
    }
}
