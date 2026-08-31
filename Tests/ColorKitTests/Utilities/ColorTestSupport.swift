import SwiftUI
import XCTest

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
