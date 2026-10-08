import ColorKit
import Foundation
import ImageIO
import SwiftUI
import XCTest

final class PaletteExportLayoutTests: XCTestCase {
    func testSVGSwatchesFillCanvasForUnevenAndLargePalettes() throws {
        for count in [3, 7, 401, 801] {
            let data = try XCTUnwrap(PaletteExporter.export(
                palette: palette(count: count), to: .svg, paletteName: "Layout"
            ))
            let document = SwatchDocument()
            let parser = XMLParser(data: data)
            parser.delegate = document
            XCTAssertTrue(parser.parse(), "\(String(describing: parser.parserError))")
            XCTAssertEqual(document.rects.count, count)
            let canvasWidth = try XCTUnwrap(document.width)
            var previousEdge = 0.0
            for rect in document.rects {
                XCTAssertGreaterThan(rect.width, 0, "Palette count: \(count)")
                XCTAssertEqual(rect.x, previousEdge, accuracy: 1e-9)
                previousEdge = rect.x + rect.width
            }
            XCTAssertEqual(previousEdge, canvasWidth, accuracy: 1e-9, "Palette count: \(count)")
        }
    }

    @MainActor
    func testPNGSwatchesReachBothCanvasEdges() throws {
        for count in [3, 7, 401, 801] {
            let data = try XCTUnwrap(PaletteExporter.export(
                palette: palette(count: count), to: .png, paletteName: "Layout"
            ))
            let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
            let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
            let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
            let context = try XCTUnwrap(CGContext(
                data: nil,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: image.width * 4,
                space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            let pixels = try XCTUnwrap(context.data).assumingMemoryBound(to: UInt8.self)
            var minimumAlpha: UInt8 = 255
            var minimumRed: UInt8 = 255
            for x in 0..<image.width {
                let offset = (image.height / 2 * image.width + x) * 4
                minimumAlpha = min(minimumAlpha, pixels[offset + 3])
                minimumRed = min(minimumRed, pixels[offset])
            }
            XCTAssertEqual(minimumAlpha, 255, "Opaque swatches must have no transparent seams, count: \(count)")
            XCTAssertGreaterThan(minimumRed, 250, "Swatch boundaries must not expose the backing, count: \(count)")
            for x in [0, image.width - 1] {
                let offset = (image.height / 2 * image.width + x) * 4
                // Permit small RGB shifts from the platform image's color profile.
                XCTAssertGreaterThan(pixels[offset], 250, "Red at edge \(x), palette count: \(count)")
                XCTAssertLessThan(pixels[offset + 1], 10)
                XCTAssertLessThan(pixels[offset + 2], 10)
                XCTAssertEqual(pixels[offset + 3], 255, "Alpha at edge \(x), palette count: \(count)")
            }
        }
    }

    private func palette(count: Int) -> [PaletteExporter.PaletteEntry] {
        (0..<count).map {
            PaletteExporter.PaletteEntry(name: "Color \($0)", color: Color(.sRGB, red: 1, green: 0, blue: 0))
        }
    }
}

private final class SwatchDocument: NSObject, XMLParserDelegate {
    var width: Double?
    var rects: [(x: Double, width: Double)] = []

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "svg" { width = attributeDict["width"].flatMap(Double.init) }
        if elementName == "rect",
           let x = attributeDict["x"].flatMap(Double.init),
           let width = attributeDict["width"].flatMap(Double.init) {
            rects.append((x, width))
        }
    }
}
