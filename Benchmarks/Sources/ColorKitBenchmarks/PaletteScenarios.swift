import AppKit
import ColorKit
import SwiftUI

// The app-owned SplitMix64 generator from the public replay example.
struct PaletteRandomNumberGenerator: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}

// Count only in the untimed diagnostic request; the timed generator has no counter.
private struct CountingPaletteRandomNumberGenerator: RandomNumberGenerator {
    var random: PaletteRandomNumberGenerator
    var draws = 0

    mutating func next() -> UInt64 {
        draws += 1
        return random.next()
    }
}

struct PaletteEntry: Codable, Equatable {
    let components: [Double]
    let componentResolution: String
    let status: String
    let contrastRatio: Double?
}

struct PaletteDiagnostics: Codable, Equatable {
    let randomSeed: UInt64
    let randomDraws: Int
    let finalRandomState: UInt64
    let requestedCount: Int
    let appearance: String
    let entries: [PaletteEntry]
}

private func paletteEntries(_ values: [ColorAccessibilityResult]) throws -> [PaletteEntry] {
    try values.map { value in
        let components: [Double]
        let resolution: String
        switch value.color.componentConversionResults().srgba {
        case let .success(rgba):
            components = [rgba.red, rgba.green, rgba.blue, rgba.alpha]
            resolution = "fixed sRGBA"
        case .failure:
            guard let native = NSColor(value.color).usingColorSpace(.sRGB) else {
                throw BenchmarkError.invalidFixture("Cannot capture palette color for current appearance")
            }
            components = [native.redComponent, native.greenComponent, native.blueComponent, native.alphaComponent].map(Double.init)
            resolution = "AppKit appearance-resolved sRGB"
        }
        return PaletteEntry(
            components: components,
            componentResolution: resolution,
            status: String(describing: value.status),
            contrastRatio: value.contrastRatio
        )
    }
}

func paletteScenarios() -> [Scenario] {
    let red = Color(.sRGB, red: 1, green: 0, blue: 0)
    let blue = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.7)
    let white = Color(.sRGB, red: 1, green: 1, blue: 1)
    let black = Color(.sRGB, red: 0, green: 0, blue: 0)
    var cases: [Scenario] = []
    for (name, color, background, inputs) in [
        ("red-white", red, white, "seed (1, 0, 0, 1), background (1, 1, 1, 1)"),
        ("blue-white", blue, white, "seed (0.2, 0.4, 0.7, 1), background (1, 1, 1, 1)"),
        ("blue-black", blue, black, "seed (0.2, 0.4, 0.7, 1), background (0, 0, 0, 1)")
    ] {
        for size in [5, 8] {
            for seed: UInt64 in [0, 42, 2_026] {
                cases.append(paletteScenario(
                    name: name,
                    color: color,
                    background: background,
                    inputs: inputs,
                    size: size,
                    seed: seed
                ))
            }
        }
    }
    return cases
}

private func paletteScenario(
    name: String, color: Color, background: Color, inputs: String, size: Int, seed: UInt64
) -> Scenario {
    let generator = AccessiblePaletteGenerator(configuration: .init(
        targetLevel: .AA, paletteSize: size, includeBlackAndWhite: true
    ))
    var random = PaletteRandomNumberGenerator(state: seed)
    // Establish an untimed empty-cache reference, never a cross-version golden output.
    ColorCache.shared.clearCache()
    let reference = generator.generateAssessedPalette(from: color, against: background, using: &random)
    let finalState = random.state
    ColorCache.shared.clearCache()
    return Scenario(
        description: ScenarioDescription(
            id: "palette-\(name)-\(size)-seed-\(seed)",
            purpose: "Complete repeatable assessed palette for interactive regeneration",
            inputs: "opaque sRGB RGBA \(inputs)",
            settings: "AA, paletteSize \(size), includeBlackAndWhite true; SplitMix64 seed \(seed); reset outside each request; identical replay for priming",
            expected: "Seed, black, white first; ordered replay and equal final RNG state; partial count permitted; each assessment matches its explicit background",
            unit: "palette",
            modes: [.empty, .primed]
        ),
        input: (color, background),
        operation: { generator.generateAssessedPalette(from: $0.0, against: $0.1, using: &random) },
        prepareOperation: { random = PaletteRandomNumberGenerator(state: seed) },
        diagnostics: {
            ColorCache.shared.clearCache()
            defer { ColorCache.shared.clearCache() }
            var counted = CountingPaletteRandomNumberGenerator(random: .init(state: seed))
            let values = generator.generateAssessedPalette(from: color, against: background, using: &counted)
            try requireFixture(
                counted.random.state == finalState && paletteEntries(values) == paletteEntries(reference),
                "Diagnostic request differs from timed fixture"
            )
            return try PaletteDiagnostics(
                randomSeed: seed,
                randomDraws: counted.draws,
                finalRandomState: finalState,
                requestedCount: size,
                appearance: NSAppearance.current.name.rawValue,
                entries: paletteEntries(values)
            )
        },
        validate: { values in
            try requireFixture(
                values.count >= 3 && values.count <= size
                    && values.prefix(3).map(\.color) == [color, .black, .white],
                "Incorrect palette count or initial order"
            )
            try requireFixture(
                random.state == finalState && values.map(\.color) == reference.map(\.color)
                    && paletteEntries(values) == paletteEntries(reference),
                "Palette replay or final RNG state differs"
            )
            for value in values {
                let assessment = value.color.accessibilityResult(against: background, targetLevel: .AA)
                try requireFixture(
                    value.contrastRatio == assessment.contrastRatio && value.status == assessment.status
                        && value.targetLevel == .AA && value.perceptualDistance == nil
                        && value.maximumPerceptualDistance == nil,
                    "Incorrect palette assessment"
                )
            }
        }
    )
}
