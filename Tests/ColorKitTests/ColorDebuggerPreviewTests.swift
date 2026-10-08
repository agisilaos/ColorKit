@testable import ColorKit
import SwiftUI
import Testing

@MainActor
struct ColorDebuggerPreviewTests {
    @Test
    func identicalColorsHaveNoLABDifferences() {
        let components = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.6).colorSpaceComponents()
        #expect(ColorDebuggerPreview.labDifferences(components.lab, components.lab) == [0, 0, 0])
    }

    @Test
    func labDifferencesAreNormalizedDistancesRegardlessOfOrder() {
        let first = (l: 0.0, a: -128.0, b: 127.0)
        let second = (l: 100.0, a: 127.0, b: -128.0)
        let expected = [1.0, 255.0 / 256, 255.0 / 256]
        #expect(ColorDebuggerPreview.labDifferences(first, second) == expected)
        #expect(ColorDebuggerPreview.labDifferences(second, first) == expected)
    }
}
