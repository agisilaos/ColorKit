import SwiftUI
import XCTest

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A color the platform types cannot resolve to sRGB components.
///
/// Pattern colors have no single component value, so they exercise the failure path that
/// named and grayscale colors no longer take. SwiftUI still exposes a `cgColor` for one,
/// so this fixture fails the platform resolution without failing every conversion.
func unresolvableTestColor() -> Color {
    // The image must actually carry more than one color. A blank one resolves on UIKit.
    #if canImport(UIKit)
    let image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { context in
        UIColor.red.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        UIColor.blue.setFill()
        context.fill(CGRect(x: 1, y: 1, width: 1, height: 1))
    }
    return Color(UIColor(patternImage: image))
    #elseif canImport(AppKit)
    let image = NSImage(size: NSSize(width: 2, height: 2))
    image.lockFocus()
    NSColor.red.setFill()
    NSRect(x: 0, y: 0, width: 1, height: 1).fill()
    NSColor.blue.setFill()
    NSRect(x: 1, y: 1, width: 1, height: 1).fill()
    image.unlockFocus()
    return Color(nsColor: NSColor(patternImage: image))
    #endif
}

func fixedTestColor(
    space name: CFString = CGColorSpace.sRGB,
    components: [CGFloat] = [0.2, 0.4, 0.6, 0.8],
    file: StaticString = #filePath,
    line: UInt = #line
) throws -> Color {
    let space = try XCTUnwrap(CGColorSpace(name: name), file: file, line: line)
    return try fixedTestColor(space: space, components: components, file: file, line: line)
}

func fixedTestColor(
    space: CGColorSpace,
    components: [CGFloat],
    file: StaticString = #filePath,
    line: UInt = #line
) throws -> Color {
    let source = try XCTUnwrap(CGColor(colorSpace: space, components: components), file: file, line: line)
    let color = Color(source)
    let represented = try XCTUnwrap(color.cgColor, file: file, line: line)
    XCTAssertTrue(CFEqual(try XCTUnwrap(represented.colorSpace, file: file, line: line), space), file: file, line: line)
    let actual = try XCTUnwrap(represented.components, file: file, line: line)
    XCTAssertEqual(actual.map { Double($0).bitPattern }, components.map { Double($0).bitPattern }, file: file, line: line)
    return color
}

func patternTestColor(file: StaticString = #filePath, line: UInt = #line) throws -> Color {
    var callbacks = CGPatternCallbacks(
        version: 0,
        drawPattern: { _, context in
            context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        },
        releaseInfo: nil
    )
    let pattern = try XCTUnwrap(
        CGPattern(
            info: nil,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            matrix: .identity,
            xStep: 1,
            yStep: 1,
            tiling: .constantSpacing,
            isColored: true,
            callbacks: &callbacks
        ),
        file: file,
        line: line
    )
    let space = try XCTUnwrap(CGColorSpace(patternBaseSpace: nil), file: file, line: line)
    let source = try XCTUnwrap(CGColor(patternSpace: space, pattern: pattern, components: [1]), file: file, line: line)
    let color = Color(source)
    XCTAssertEqual(color.cgColor?.colorSpace?.model, .pattern, file: file, line: line)
    return color
}
