import SwiftUI
import ColorKit

/// A simple performance benchmark to demonstrate the caching improvements in ColorKit 1.4.0
struct PerformanceBenchmark: View {
    @State private var results: [String] = []
    @State private var isRunning = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("ColorKit Performance Benchmark")
                .font(.title)
                .fontWeight(.bold)
            
            if isRunning {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
                
                Text("Running benchmark...")
                    .font(.headline)
            } else {
                Button("Run Benchmark") {
                    runBenchmark()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(results, id: \.self) { result in
                        Text(result)
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemBackground).opacity(0.8))
            .cornerRadius(10)
            .shadow(radius: 2)
            .padding()
        }
        .padding()
    }
    
    private func runBenchmark() {
        isRunning = true
        results = []
        
        // Clear all caches to ensure a fair comparison
        ColorCache.shared.clearCache()

        DispatchQueue.global(qos: .userInitiated).async {
            // Generate test colors
            let testColors = generateTestColors(count: 100)
            
            // Benchmark LAB conversion
            benchmarkLABConversion(colors: testColors)
            
            // Benchmark HSL conversion
            benchmarkHSLConversion(colors: testColors)
            
            // Benchmark WCAG calculations
            benchmarkWCAGCalculations(colors: testColors)
            
            // Benchmark color blending
            benchmarkColorBlending(colors: testColors)
            
            // Benchmark gradient interpolation
            benchmarkGradientInterpolation(colors: testColors)
            
            DispatchQueue.main.async {
                isRunning = false
            }
        }
    }
    
    private func generateTestColors(count: Int) -> [Color] {
        var colors: [Color] = []
        for _ in 0..<count {
            let red = Double.random(in: 0...1)
            let green = Double.random(in: 0...1)
            let blue = Double.random(in: 0...1)
            colors.append(Color(.sRGB, red: red, green: green, blue: blue, opacity: 1.0))
        }
        return colors
    }
    
    private func benchmarkLABConversion(colors: [Color]) {
        addResult("LAB Conversion Benchmark:")
        
        // First run (no cache)
        let startTime1 = CFAbsoluteTimeGetCurrent()
        for color in colors {
            _ = color.labComponents()
        }
        let endTime1 = CFAbsoluteTimeGetCurrent()
        let duration1 = endTime1 - startTime1
        
        addResult("  First run (no cache): \(String(format: "%.4f", duration1))s")
        
        // Second run (with cache)
        let startTime2 = CFAbsoluteTimeGetCurrent()
        for color in colors {
            _ = color.labComponents()
        }
        let endTime2 = CFAbsoluteTimeGetCurrent()
        let duration2 = endTime2 - startTime2
        
        addResult("  Second run (cached): \(String(format: "%.4f", duration2))s")
        addResult("  Speedup: \(String(format: "%.1f", duration1/duration2))x")
        addResult("")
    }
    
    private func benchmarkHSLConversion(colors: [Color]) {
        addResult("HSL Conversion Benchmark:")
        
        // First run (no cache)
        let startTime1 = CFAbsoluteTimeGetCurrent()
        for color in colors {
            _ = color.hslComponents()
        }
        let endTime1 = CFAbsoluteTimeGetCurrent()
        let duration1 = endTime1 - startTime1
        
        addResult("  First run (no cache): \(String(format: "%.4f", duration1))s")
        
        // Second run (with cache)
        let startTime2 = CFAbsoluteTimeGetCurrent()
        for color in colors {
            _ = color.hslComponents()
        }
        let endTime2 = CFAbsoluteTimeGetCurrent()
        let duration2 = endTime2 - startTime2
        
        addResult("  Second run (cached): \(String(format: "%.4f", duration2))s")
        addResult("  Speedup: \(String(format: "%.1f", duration1/duration2))x")
        addResult("")
    }
    
    private func benchmarkWCAGCalculations(colors: [Color]) {
        addResult("WCAG Calculations Benchmark:")
        
        // First run (no cache)
        let startTime1 = CFAbsoluteTimeGetCurrent()
        for i in 0..<colors.count/2 {
            _ = colors[i].wcagContrastRatio(with: colors[i + colors.count/2])
        }
        let endTime1 = CFAbsoluteTimeGetCurrent()
        let duration1 = endTime1 - startTime1
        
        addResult("  First run (no cache): \(String(format: "%.4f", duration1))s")
        
        // Second run (with cache)
        let startTime2 = CFAbsoluteTimeGetCurrent()
        for i in 0..<colors.count/2 {
            _ = colors[i].wcagContrastRatio(with: colors[i + colors.count/2])
        }
        let endTime2 = CFAbsoluteTimeGetCurrent()
        let duration2 = endTime2 - startTime2
        
        addResult("  Second run (cached): \(String(format: "%.4f", duration2))s")
        addResult("  Speedup: \(String(format: "%.1f", duration1/duration2))x")
        addResult("")
    }
    
    private func benchmarkColorBlending(colors: [Color]) {
        addResult("Color Blending Benchmark:")
        
        // First run (no cache)
        let startTime1 = CFAbsoluteTimeGetCurrent()
        for i in 0..<colors.count/2 {
            _ = colors[i].blended(with: colors[i + colors.count/2], mode: .overlay)
        }
        let endTime1 = CFAbsoluteTimeGetCurrent()
        let duration1 = endTime1 - startTime1
        
        addResult("  First run (no cache): \(String(format: "%.4f", duration1))s")
        
        // Second run (with cache)
        let startTime2 = CFAbsoluteTimeGetCurrent()
        for i in 0..<colors.count/2 {
            _ = colors[i].blended(with: colors[i + colors.count/2], mode: .overlay)
        }
        let endTime2 = CFAbsoluteTimeGetCurrent()
        let duration2 = endTime2 - startTime2
        
        addResult("  Second run (cached): \(String(format: "%.4f", duration2))s")
        addResult("  Speedup: \(String(format: "%.1f", duration1/duration2))x")
        addResult("")
    }
    
    private func benchmarkGradientInterpolation(colors: [Color]) {
        addResult("Gradient Interpolation Benchmark:")
        
        // First run (no cache)
        let startTime1 = CFAbsoluteTimeGetCurrent()
        for i in 0..<colors.count/2 {
            for amount in stride(from: 0.0, through: 1.0, by: 0.1) {
                _ = colors[i].interpolated(with: colors[i + colors.count/2], amount: amount, in: .lab)
            }
        }
        let endTime1 = CFAbsoluteTimeGetCurrent()
        let duration1 = endTime1 - startTime1
        
        addResult("  First run (no cache): \(String(format: "%.4f", duration1))s")
        
        // Second run (with cache)
        let startTime2 = CFAbsoluteTimeGetCurrent()
        for i in 0..<colors.count/2 {
            for amount in stride(from: 0.0, through: 1.0, by: 0.1) {
                _ = colors[i].interpolated(with: colors[i + colors.count/2], amount: amount, in: .lab)
            }
        }
        let endTime2 = CFAbsoluteTimeGetCurrent()
        let duration2 = endTime2 - startTime2
        
        addResult("  Second run (cached): \(String(format: "%.4f", duration2))s")
        addResult("  Speedup: \(String(format: "%.1f", duration1/duration2))x")
        addResult("")
    }
    
    private func addResult(_ result: String) {
        DispatchQueue.main.async {
            results.append(result)
        }
    }
}

#Preview {
    PerformanceBenchmark()
} 
