import ColorKit
import struct SwiftUI.Color
import XCTest

final class BlendEndpointTests: XCTestCase {
    func testColorDodgePreservesBlackChannelsAgainstWhite() throws {
        let base = Color(.sRGB, red: 0, green: 0.25, blue: 0.75, opacity: 0.4)
        for alpha in [0.5, 1.0] {
            let blend = Color(.sRGB, red: 1, green: 0.5, blue: 0, opacity: alpha)
            for amount: CGFloat in [0.5, 1] {
                let expectedGreen = 0.25 + 0.25 * amount * alpha
                for color in [
                    try base.blendResult(with: blend, mode: .colorDodge, amount: amount).get(),
                    base.blended(with: blend, mode: .colorDodge, amount: amount),
                    base.colorDodge(with: blend, amount: amount)
                ] {
                    try assertComponents(color, red: 0, green: expectedGreen, blue: 0.75, alpha: 0.4)
                }
            }
        }
    }

    func testColorBurnPreservesWhiteChannelsAgainstBlack() throws {
        let base = Color(.sRGB, red: 1, green: 0.75, blue: 0.25, opacity: 0.4)
        for alpha in [0.5, 1.0] {
            let blend = Color(.sRGB, red: 0, green: 0.5, blue: 1, opacity: alpha)
            for amount: CGFloat in [0.5, 1] {
                let expectedGreen = 0.75 - 0.25 * amount * alpha
                for color in [
                    try base.blendResult(with: blend, mode: .colorBurn, amount: amount).get(),
                    base.blended(with: blend, mode: .colorBurn, amount: amount),
                    base.colorBurn(with: blend, amount: amount)
                ] {
                    try assertComponents(color, red: 1, green: expectedGreen, blue: 0.25, alpha: 0.4)
                }
            }
        }
    }

    private func assertComponents(
        _ color: Color, red: Double, green: Double, blue: Double, alpha: Double,
        file: StaticString = #filePath, line: UInt = #line
    ) throws {
        let components = try color.componentConversionResults().srgba.get()
        XCTAssertEqual(components.red, red, accuracy: 1e-6, file: file, line: line)
        XCTAssertEqual(components.green, green, accuracy: 1e-6, file: file, line: line)
        XCTAssertEqual(components.blue, blue, accuracy: 1e-6, file: file, line: line)
        XCTAssertEqual(components.alpha, alpha, accuracy: 1e-6, file: file, line: line)
    }
}
