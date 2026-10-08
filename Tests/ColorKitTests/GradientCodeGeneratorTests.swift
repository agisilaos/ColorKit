@testable import ColorKit
import SwiftUI
import Testing

@MainActor
struct GradientCodeGeneratorTests {
    @Test
    func rejectsUnavailableColorInsteadOfExportingFallback() {
        let invalid = Color(.sRGB, red: .nan, green: 0, blue: 0)
        #expect(GradientCodeGenerator.source(
            colors: [invalid, .blue], type: .linear, startPoint: .leading, endPoint: .trailing
        ) == nil)
    }

    #if os(macOS)
    @Test
    func generatedGradientsCompileForDefaultAndSelectedColors() throws {
        let selections: [[Color]] = [
            [.blue, .purple],
            [Color(.sRGB, red: 0.2, green: 0.4, blue: 0.6, opacity: 0.5), .black]
        ]
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        var declarations = ["import SwiftUI"]
        for (index, colors) in selections.enumerated() {
            for type in GradientType.allCases {
                let source = try #require(GradientCodeGenerator.source(
                    colors: colors, type: type, startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                declarations.append("let gradient\(index)\(type.rawValue) = \(source)")
            }
        }
        let file = directory.appendingPathComponent("Gradients.swift")
        try declarations.joined(separator: "\n").write(to: file, atomically: true, encoding: .utf8)
        let errors = Pipe()
        let compiler = Process()
        compiler.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        compiler.arguments = ["swiftc", "-typecheck", file.path]
        compiler.standardError = errors
        try compiler.run()
        let diagnostics = try #require(String(data: errors.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8))
        compiler.waitUntilExit()
        #expect(compiler.terminationStatus == 0, Comment(rawValue: diagnostics))
    }
    #endif
}
