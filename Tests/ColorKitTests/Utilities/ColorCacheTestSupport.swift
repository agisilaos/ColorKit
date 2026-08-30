import SwiftUI
import XCTest

@testable import ColorKit

func cacheTestColor(
    space name: CFString = CGColorSpace.sRGB,
    components: [CGFloat] = [0.2, 0.4, 0.6, 0.8]
) throws -> Color {
    let space = try XCTUnwrap(CGColorSpace(name: name))
    return try cacheTestColor(space: space, components: components)
}

func cacheTestColor(space: CGColorSpace, components: [CGFloat]) throws -> Color {
    let cgColor = try XCTUnwrap(CGColor(colorSpace: space, components: components))
    let color = Color(cgColor)
    let represented = try XCTUnwrap(color.cgColor)
    XCTAssertTrue(CFEqual(try XCTUnwrap(represented.colorSpace), space))
    let representedBits = try XCTUnwrap(represented.components).map { Double($0).bitPattern }
    XCTAssertEqual(representedBits, components.map { Double($0).bitPattern })
    return color
}

func assertCacheColorEqual(
    _ actual: Color?, _ expected: Color,
    file: StaticString = #filePath, line: UInt = #line
) throws {
    let actualCG = try XCTUnwrap(actual?.cgColor, file: file, line: line)
    let expectedCG = try XCTUnwrap(expected.cgColor, file: file, line: line)
    XCTAssertTrue(CFEqual(try XCTUnwrap(actualCG.colorSpace), try XCTUnwrap(expectedCG.colorSpace)), file: file, line: line)
    XCTAssertEqual(actualCG.components, expectedCG.components, file: file, line: line)
}

func populateCache(_ cache: ColorCache, color: Color, other: Color, marker: CGFloat = 0.25) {
    cache.cacheLABComponents(for: color, L: marker, a: marker + 1, b: marker + 2)
    cache.cacheHSLComponents(for: color, hue: marker, saturation: marker + 1, lightness: marker + 2)
    cache.cacheLuminance(for: color, luminance: Double(marker))
    cache.cacheContrastRatio(for: color, with: other, ratio: Double(marker))
    let result = Color(.sRGB, red: Double(marker), green: 0.25, blue: 0.75)
    cache.cacheBlendedColor(color1: color, with: other, blendMode: "normal", result: result)
    cache.cacheInterpolatedColor(color1: color, with: other, amount: 0.5, colorSpace: "rgb", result: result)
}

func cachePresence(_ cache: ColorCache, color: Color, other: Color) -> [Bool] {
    [
        cache.getCachedLABComponents(for: color) != nil,
        cache.getCachedHSLComponents(for: color) != nil,
        cache.getCachedLuminance(for: color) != nil,
        cache.getCachedContrastRatio(for: color, with: other) != nil,
        cache.getCachedBlendedColor(color1: color, with: other, blendMode: "normal") != nil,
        cache.getCachedInterpolatedColor(color1: color, with: other, amount: 0.5, colorSpace: "rgb") != nil
    ]
}

func assertCacheMarker(
    _ cache: ColorCache, color: Color, other: Color, marker: CGFloat,
    file: StaticString = #filePath, line: UInt = #line
) throws {
    let lab = try XCTUnwrap(cache.getCachedLABComponents(for: color), file: file, line: line)
    XCTAssertEqual([lab.L, lab.a, lab.b], [marker, marker + 1, marker + 2], file: file, line: line)
    let hsl = try XCTUnwrap(cache.getCachedHSLComponents(for: color), file: file, line: line)
    XCTAssertEqual([hsl.hue, hsl.saturation, hsl.lightness], [marker, marker + 1, marker + 2], file: file, line: line)
    XCTAssertEqual(cache.getCachedLuminance(for: color), Double(marker), file: file, line: line)
    XCTAssertEqual(cache.getCachedContrastRatio(for: color, with: other), Double(marker), file: file, line: line)
    let result = Color(.sRGB, red: Double(marker), green: 0.25, blue: 0.75)
    try assertCacheColorEqual(cache.getCachedBlendedColor(color1: color, with: other, blendMode: "normal"), result, file: file, line: line)
    try assertCacheColorEqual(cache.getCachedInterpolatedColor(color1: color, with: other, amount: 0.5, colorSpace: "rgb"), result, file: file, line: line)
}
