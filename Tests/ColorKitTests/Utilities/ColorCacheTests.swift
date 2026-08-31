import SwiftUI
import XCTest

@testable import ColorKit

final class ColorCacheTests: XCTestCase {
    func testSupportedSpacesHaveSeparateEntriesInEveryStore() throws {
        let cache = ColorCache()
        let other = try fixedTestColor(components: [0.9, 0.1, 0.3, 1])
        let names = [
            CGColorSpace.sRGB, CGColorSpace.linearSRGB, CGColorSpace.extendedSRGB,
            CGColorSpace.extendedLinearSRGB, CGColorSpace.displayP3,
            CGColorSpace.genericGrayGamma2_2, CGColorSpace.linearGray,
            CGColorSpace.extendedGray, CGColorSpace.extendedLinearGray
        ]
        let colors = try names.map { name in
            let space = try XCTUnwrap(CGColorSpace(name: name))
            return try fixedTestColor(space: space, components: space.model == .rgb ? [0.2, 0.4, 0.6, 0.8] : [0.2, 0.8])
        }

        for (index, color) in colors.enumerated() {
            XCTAssertEqual(cachePresence(cache, color: color, other: other), Array(repeating: false, count: 6))
            populateCache(cache, color: color, other: other, marker: CGFloat(index) / 16)
        }
        for (index, color) in colors.enumerated() {
            try assertCacheMarker(cache, color: color, other: other, marker: CGFloat(index) / 16)
        }
    }

    func testGrayscaleComponentsAndAlphaAreNotAliasedToRGB() throws {
        let cache = ColorCache()
        let other = try fixedTestColor()
        let colors = try [
            fixedTestColor(space: CGColorSpace.genericGrayGamma2_2, components: [0.25, 1]),
            fixedTestColor(space: CGColorSpace.genericGrayGamma2_2, components: [0.75, 1]),
            fixedTestColor(space: CGColorSpace.genericGrayGamma2_2, components: [0.25, 0.5]),
            fixedTestColor(components: [0.25, 0.25, 0.25, 1]),
            fixedTestColor(components: [0.25, 0.25, 0.25, 0.5])
        ]
        for (index, color) in colors.enumerated() {
            XCTAssertEqual(cachePresence(cache, color: color, other: other), Array(repeating: false, count: 6))
            populateCache(cache, color: color, other: other, marker: CGFloat(index) / 8)
        }
        for (index, color) in colors.enumerated() {
            try assertCacheMarker(cache, color: color, other: other, marker: CGFloat(index) / 8)
        }
    }

    func testUnsupportedColorsMissAndCannotInsertInAnyStore() throws {
        let supported = try fixedTestColor()
        #if canImport(AppKit)
        let dynamic = Color(NSColor(name: nil) { _ in .red })
        #else
        let dynamic = Color(UIColor { _ in .red })
        #endif
        XCTAssertNil(dynamic.cgColor)
        let customSpace = try XCTUnwrap(CGColorSpace(calibratedGrayWhitePoint: [0.9505, 1, 1.089], blackPoint: nil, gamma: 1.8))
        let unsupported = try [
            Color.primary, Color.secondary, dynamic,
            fixedTestColor(space: CGColorSpace.adobeRGB1998),
            fixedTestColor(space: CGColorSpaceCreateDeviceRGB(), components: [0.2, 0.4, 0.6, 0.8]),
            fixedTestColor(space: CGColorSpaceCreateDeviceGray(), components: [0.2, 0.8]),
            fixedTestColor(space: customSpace, components: [0.2, 0.8])
        ]
        XCTAssertNil(Color.primary.cgColor)
        XCTAssertNil(Color.secondary.cgColor)
        for color in unsupported {
            let cache = ColorCache()
            populateCache(cache, color: color, other: supported)
            XCTAssertEqual(cachePresence(cache, color: color, other: supported), Array(repeating: false, count: 6))
            for other in unsupported {
                XCTAssertEqual(cachePresence(cache, color: other, other: supported), Array(repeating: false, count: 6))
            }
            populateCache(cache, color: supported, other: color)
            XCTAssertEqual(cachePresence(cache, color: supported, other: color), [true, true, true, false, false, false])
            XCTAssertEqual(cachePresence(cache, color: color, other: supported), Array(repeating: false, count: 6))
            populateCache(cache, color: supported, other: supported, marker: 0.75)
            try assertCacheMarker(cache, color: supported, other: supported, marker: 0.75)
        }
    }

    func testPatternColorCannotUseAnOrdinaryColorEntry() throws {
        let color = try patternTestColor()
        let cache = ColorCache()
        let other = try fixedTestColor()
        populateCache(cache, color: other, other: other)
        populateCache(cache, color: color, other: other)
        XCTAssertEqual(cachePresence(cache, color: color, other: other), Array(repeating: false, count: 6))
        populateCache(cache, color: other, other: color)
        XCTAssertEqual(cachePresence(cache, color: other, other: color), [true, true, true, false, false, false])
        try assertCacheMarker(cache, color: other, other: other, marker: 0.25)
    }

    func testFiniteComponentBitsRemainDistinct() throws {
        let cache = ColorCache()
        let other = try fixedTestColor()
        let values: [CGFloat] = [-0.0, 0.0, 0.5001, 0.5004, -0.25, 1.25]
        let colors = try values.map { value in
            try fixedTestColor(space: CGColorSpace.extendedSRGB, components: [value, 0.2, 0.3, 1])
        }
        for (index, color) in colors.enumerated() {
            XCTAssertEqual(cachePresence(cache, color: color, other: other), Array(repeating: false, count: 6))
            populateCache(cache, color: color, other: other, marker: CGFloat(index) / 8)
        }
        for (index, color) in colors.enumerated() {
            try assertCacheMarker(cache, color: color, other: other, marker: CGFloat(index) / 8)
        }
    }

    func testNonfiniteComponentsBypassEveryStore() throws {
        let other = try fixedTestColor()
        for value: CGFloat in [.nan, .infinity, -.infinity] {
            let color = try fixedTestColor(space: CGColorSpace.extendedSRGB, components: [value, 0.2, 0.3, 1])
            let cache = ColorCache()
            populateCache(cache, color: color, other: other)
            XCTAssertEqual(cachePresence(cache, color: color, other: other), Array(repeating: false, count: 6))
            populateCache(cache, color: other, other: color)
            XCTAssertEqual(cachePresence(cache, color: other, other: color), [true, true, true, false, false, false])
        }
    }

    func testContrastIsSymmetricButBlendAndInterpolationAreOrdered() throws {
        let cache = ColorCache()
        let first = try fixedTestColor(components: [0.8, 0.1, 0.2, 1])
        let second = try fixedTestColor(components: [0.2, 0.6, 0.9, 0.5])
        populateCache(cache, color: first, other: second)
        XCTAssertEqual(cache.getCachedContrastRatio(for: second, with: first), 0.25)
        XCTAssertNil(cache.getCachedBlendedColor(color1: second, with: first, blendMode: "normal"))
        XCTAssertNil(cache.getCachedInterpolatedColor(color1: second, with: first, amount: 0.5, colorSpace: "rgb"))

        cache.cacheBlendedColor(color1: second, with: first, blendMode: "normal", result: second)
        cache.cacheInterpolatedColor(color1: second, with: first, amount: 0.5, colorSpace: "rgb", result: second)
        try assertCacheMarker(cache, color: first, other: second, marker: 0.25)
        try assertCacheColorEqual(cache.getCachedBlendedColor(color1: second, with: first, blendMode: "normal"), second)
        try assertCacheColorEqual(cache.getCachedInterpolatedColor(color1: second, with: first, amount: 0.5, colorSpace: "rgb"), second)
    }

    func testOperationNamesAreKeptExact() throws {
        let cache = ColorCache()
        let first = try fixedTestColor()
        let second = try fixedTestColor(components: [0.8, 0.7, 0.1, 1])
        let names = ["rgb", "RGB", "rgb|hsl", "", "normal"]
        for (index, name) in names.enumerated() {
            let result = index.isMultiple(of: 2) ? first : second
            XCTAssertNil(cache.getCachedBlendedColor(color1: first, with: second, blendMode: name))
            XCTAssertNil(cache.getCachedInterpolatedColor(color1: first, with: second, amount: 0.5, colorSpace: name))
            cache.cacheBlendedColor(color1: first, with: second, blendMode: name, result: result)
            cache.cacheInterpolatedColor(color1: first, with: second, amount: 0.5, colorSpace: name, result: result)
        }
        for (index, name) in names.enumerated() {
            let result = index.isMultiple(of: 2) ? first : second
            try assertCacheColorEqual(cache.getCachedBlendedColor(color1: first, with: second, blendMode: name), result)
            try assertCacheColorEqual(cache.getCachedInterpolatedColor(color1: first, with: second, amount: 0.5, colorSpace: name), result)
        }
    }

    func testInterpolationAmountsAreExactInBothInsertionOrders() throws {
        let first = try fixedTestColor()
        let second = try fixedTestColor(components: [0.8, 0.7, 0.1, 1])
        let amounts: [CGFloat] = [0.5001, 0.5004, -0.0, 0.0, -0.25, 1.25]
        for order in [amounts, amounts.reversed().map { $0 }] {
            let cache = ColorCache()
            for (index, amount) in order.enumerated() {
                XCTAssertNil(cache.getCachedInterpolatedColor(color1: first, with: second, amount: amount, colorSpace: "rgb"))
                cache.cacheInterpolatedColor(color1: first, with: second, amount: amount, colorSpace: "rgb", result: index.isMultiple(of: 2) ? first : second)
            }
            for (index, amount) in order.enumerated() {
                try assertCacheColorEqual(cache.getCachedInterpolatedColor(color1: first, with: second, amount: amount, colorSpace: "rgb"), index.isMultiple(of: 2) ? first : second)
            }
        }
    }

    func testNonfiniteInterpolationAmountsCannotInsert() throws {
        let cache = ColorCache()
        let color = try fixedTestColor()
        for amount: CGFloat in [.nan, .infinity, -.infinity] {
            cache.cacheInterpolatedColor(color1: color, with: color, amount: amount, colorSpace: "rgb", result: color)
            XCTAssertNil(cache.getCachedInterpolatedColor(color1: color, with: color, amount: amount, colorSpace: "rgb"))
        }
        XCTAssertNil(cache.getCachedInterpolatedColor(color1: color, with: color, amount: 0, colorSpace: "rgb"))
        XCTAssertNil(cache.getCachedInterpolatedColor(color1: color, with: color, amount: 1, colorSpace: "rgb"))
    }

    func testEachClearOnlyRemovesItsOwnStore() throws {
        let color = try fixedTestColor()
        let clearOperations: [(ColorCache) -> Void] = [
            { $0.clearLABCache() }, { $0.clearHSLCache() }, { $0.clearLuminanceCache() },
            { $0.clearContrastCache() }, { $0.clearBlendedColorCache() }, { $0.clearInterpolatedColorCache() }
        ]
        for (index, clear) in clearOperations.enumerated() {
            let cache = ColorCache()
            populateCache(cache, color: color, other: color)
            XCTAssertEqual(cachePresence(cache, color: color, other: color), Array(repeating: true, count: 6))
            clear(cache)
            var expected = Array(repeating: true, count: 6)
            expected[index] = false
            XCTAssertEqual(cachePresence(cache, color: color, other: color), expected)
        }
    }

    func testGlobalClearRemovesEveryStoreWithoutAffectingOtherInstances() throws {
        let color = try fixedTestColor()
        let first = ColorCache()
        let second = ColorCache()
        populateCache(first, color: color, other: color)
        populateCache(second, color: color, other: color)
        first.clearCache()
        XCTAssertEqual(cachePresence(first, color: color, other: color), Array(repeating: false, count: 6))
        try assertCacheMarker(second, color: color, other: color, marker: 0.25)
    }
}
