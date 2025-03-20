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
        .accessibility
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
                Button(action: runBenchmark) {
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
    private func runBenchmark() {
        guard !isRunningBenchmark else { return }

        isRunningBenchmark = true
        benchmarkResults.removeAll()

        let operation = selectedOperation
        let iterations = iterationCount

        // Run benchmark in background
        Task.detached {
            var results: [BenchmarkResult] = []

            switch operation {
            case .blending:
                results = await self.benchmarkBlending(iterations: iterations)
            case .conversion:
                results = await self.benchmarkConversion(iterations: iterations)
            case .gradient:
                results = await self.benchmarkGradient(iterations: iterations)
            case .accessibility:
                results = await self.benchmarkAccessibility(iterations: iterations)
            }

            // Update UI on main thread
            await MainActor.run {
                benchmarkResults = results
                isRunningBenchmark = false
            }
        }
    }

    // MARK: - Benchmark Methods
    private func benchmarkBlending(iterations: Int) async -> [BenchmarkResult] {
        let color1 = Color.blue
        let color2 = Color.red
        var results: [BenchmarkResult] = []

        // Test each blend mode
        let blendModes: [BlendMode] = [
            .normal, .multiply, .screen, .overlay,
            .darken, .lighten, .colorDodge, .colorBurn,
            .softLight, .hardLight, .difference, .exclusion
        ]

        for mode in blendModes {
            let start = CFAbsoluteTimeGetCurrent()

            for _ in 0..<iterations {
                _ = color1.blended(with: color2, mode: mode)
            }

            let end = CFAbsoluteTimeGetCurrent()
            let duration = end - start

            results.append(BenchmarkResult(
                name: "Blend Mode: \(String(describing: mode))",
                duration: duration,
                operationsPerSecond: Double(iterations) / duration
            ))
        }

        return results
    }

    private func benchmarkConversion(iterations: Int) async -> [BenchmarkResult] {
        let color = Color.blue
        var results: [BenchmarkResult] = []

        // Color Space Conversion
        do {
            let start = CFAbsoluteTimeGetCurrent()

            for _ in 0..<iterations {
                _ = color.opacity(1.0) // Simple color operation
            }

            let end = CFAbsoluteTimeGetCurrent()
            let duration = end - start

            results.append(BenchmarkResult(
                name: "Color Space Conversion",
                duration: duration,
                operationsPerSecond: Double(iterations) / duration
            ))
        }

        return results
    }

    private func benchmarkGradient(iterations: Int) async -> [BenchmarkResult] {
        let colors = [Color.blue, Color.purple, Color.red]
        var results: [BenchmarkResult] = []

        // Linear Gradient
        do {
            let start = CFAbsoluteTimeGetCurrent()

            for _ in 0..<iterations {
                _ = LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }

            let end = CFAbsoluteTimeGetCurrent()
            let duration = end - start

            results.append(BenchmarkResult(
                name: "Linear Gradient",
                duration: duration,
                operationsPerSecond: Double(iterations) / duration
            ))
        }

        // Radial Gradient
        do {
            let start = CFAbsoluteTimeGetCurrent()

            for _ in 0..<iterations {
                _ = RadialGradient(
                    colors: colors,
                    center: .center,
                    startRadius: 0,
                    endRadius: 100
                )
            }

            let end = CFAbsoluteTimeGetCurrent()
            let duration = end - start

            results.append(BenchmarkResult(
                name: "Radial Gradient",
                duration: duration,
                operationsPerSecond: Double(iterations) / duration
            ))
        }

        return results
    }

    private func benchmarkAccessibility(iterations: Int) async -> [BenchmarkResult] {
        let color1 = Color.white
        let color2 = Color.black
        var results: [BenchmarkResult] = []

        // Contrast Ratio
        do {
            let start = CFAbsoluteTimeGetCurrent()

            for _ in 0..<iterations {
                _ = color1.contrastRatio(with: color2)
            }

            let end = CFAbsoluteTimeGetCurrent()
            let duration = end - start

            results.append(BenchmarkResult(
                name: "Contrast Ratio",
                duration: duration,
                operationsPerSecond: Double(iterations) / duration
            ))
        }

        return results
    }
}

// MARK: - Supporting Types

enum BenchmarkOperation: String, CaseIterable {
    case blending
    case conversion
    case gradient
    case accessibility

    var name: String {
        rawValue.capitalized
    }
}

struct BenchmarkResult: Identifiable {
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
