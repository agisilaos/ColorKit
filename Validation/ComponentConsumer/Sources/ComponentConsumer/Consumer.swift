import AppKit
import ColorKit
import SwiftUI

// A separate consuming app: one aggregate per inspection, with independent display decisions.
private struct Inspection: View {
    let result: ColorComponentConversionResults

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consumer color inspection").font(.headline)
            row("sRGBA", result.srgba)
            row("HSL (turns, fractions)", result.hsl)
            row("HSB (turns, fractions)", result.hsb)
            row("CMYK (fractions)", result.cmyk)
            row("XYZ (D65, Y = 100)", result.xyz)
            row("LAB (D65)", result.lab)
            row("Hex", result.hex)
        }.padding()
    }

    private func row<Value>(_ title: String, _ value: Result<Value, ColorConversionIssue>) -> some View {
        let text: String
        switch value {
        case .success(let coordinates): text = String(describing: coordinates)
        case .failure(let issue): text = "Unavailable: \(issue)"
        }
        return Text("\(title): \(text)")
    }
}

@main
private enum Consumer {
    @MainActor static func main() throws {
        let app = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 500),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        let samples: [(String, Color, Int)] = [
            ("fixed black", Color(.sRGB, red: 0, green: 0, blue: 0), 7),
            ("P3 red", Color(.displayP3, red: 1, green: 0, blue: 0), 3),
            ("dynamic primary", .primary, 0)
        ]
        for (name, color, expected) in samples {
            let result = color.componentConversionResults()
            func available<Value>(_ value: Result<Value, ColorConversionIssue>) -> Int {
                if case .success = value { return 1 }
                return 0
            }
            let count = available(result.srgba) + available(result.hsl) + available(result.hsb)
                + available(result.cmyk) + available(result.xyz) + available(result.lab) + available(result.hex)
            precondition(count == expected, "Unexpected availability for \(name)")
            window.contentView = NSHostingView(rootView: Inspection(result: result))
            window.makeKeyAndOrderFront(nil)
            window.contentView?.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
            print("PASS consumer hosted \(name): \(count)/7 available")
        }
        // Exercise the documented caller-side AppKit appearance capture recipe.
        for name in [NSAppearance.Name.aqua, .darkAqua] {
            var fixed: CGColor?
            NSAppearance(named: name)?.performAsCurrentDrawingAppearance {
                fixed = NSColor(Color.primary).usingColorSpace(.extendedSRGB)?.cgColor
            }
            guard let fixed else { fatalError("Appearance capture unavailable") }
            let result = Color(fixed).componentConversionResults()
            _ = try result.srgba.get()
            _ = try result.lab.get()
            window.contentView = NSHostingView(rootView: Inspection(result: result))
            window.contentView?.layoutSubtreeIfNeeded()
            print("PASS consumer capture \(name.rawValue)")
        }
        if CommandLine.arguments.contains("--interactive") { app.run() }
        window.orderOut(nil)
    }
}
