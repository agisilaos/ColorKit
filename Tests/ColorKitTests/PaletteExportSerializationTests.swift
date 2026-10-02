import ColorKit
import Foundation
import ImageIO
import SwiftUI
import WebKit
import XCTest

final class PaletteExportSerializationTests: XCTestCase {
    private let names = [
        "Primary", "Primary Light", "A&B <accent>", "Quotes \"double\" 'single'",
        "Crème brûlée", "色 🎨", "123", "a:b; } body { color: red; } /*",
        "back\\slash", "line\nbreak", "tab\tstop", "carriage\rreturn", "]]> &amp;",
        "Primary", "PRIMARY", "primary-light", "Primary Light", "primary"
    ]

    private func palette(_ names: [String]) -> [PaletteExporter.PaletteEntry] {
        names.enumerated().map { index, name in
            .init(name: name, color: Color(.sRGB, red: index.isMultiple(of: 2) ? 1 : 0, green: 0, blue: 0))
        }
    }

    func testJSONPreservesNamesAndOrder() throws {
        let title = "Palette & <title> \"色🎨\""
        let data = try XCTUnwrap(PaletteExporter.export(palette: palette(names), to: .json, paletteName: title))
        let document = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(document["name"] as? String, title)
        let entries = try XCTUnwrap(document["colors"] as? [[String: Any]])
        XCTAssertEqual(entries.compactMap { $0["name"] as? String }, names)
        XCTAssertEqual(entries.compactMap { $0["hex"] as? String }, expectedHexValues)
    }

    func testSVGPreservesTextAndStructure() throws {
        for title in ["Ordinary Palette", "Palette & <title> \"色🎨\"", "</title><script>bad</script>", "\r\n"] {
            let data = try XCTUnwrap(PaletteExporter.export(palette: palette(names), to: .svg, paletteName: title))
            let parser = XMLParser(data: data)
            let document = SVGDocument()
            parser.delegate = document
            XCTAssertTrue(parser.parse(), "\(String(describing: parser.parserError))")
            XCTAssertEqual(document.titles, [title])
            XCTAssertEqual(document.texts, zip(names, expectedHexValues).flatMap { [$0, $1] })
            XCTAssertEqual(document.fills, expectedHexValues)
            XCTAssertEqual(document.elements.filter { $0 == "svg" }.count, 1)
            XCTAssertEqual(document.elements.count, 2 + names.count * 3)
            XCTAssertEqual(Set(document.elements), ["svg", "title", "rect", "text"])
        }
    }

    func testSVGRejectsCharactersXMLCannotRepresent() {
        for invalid in ["\u{0}", "\u{1}", "\u{B}", "\u{FFFE}", "\u{FFFF}"] {
            XCTAssertNil(PaletteExporter.export(palette: palette([invalid]), to: .svg, paletteName: "Title"))
            XCTAssertNil(PaletteExporter.export(palette: palette(["Entry"]), to: .svg, paletteName: invalid))
        }
    }

    func testCSSRejectsEmptyEntryNames() {
        XCTAssertNil(PaletteExporter.export(palette: palette([""]), to: .css, paletteName: "Title"))
    }

    @available(iOS 15.0, *)
    @MainActor
    func testCSSParsesNamesAndPreservesCascade() async throws {
        let cssNames = names + ["nul\u{0}name", "control\u{1}F\u{7F}"]
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        // Keep WebKit visible and active on CI's cloned simulators.
        #if os(macOS)
        let controller = NSViewController()
        controller.view = webView
        let window = NSWindow(contentViewController: controller)
        window.isReleasedWhenClosed = false
        window.orderFront(nil)
        defer { window.close() }
        #else
        let controller = UIViewController()
        controller.view = webView
        let window = UIWindow(frame: webView.frame)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        #endif
        defer { webView.stopLoading() }
        let loaded = expectation(description: "Local document loaded")
        let navigation = LoadedDocument(loaded)
        webView.navigationDelegate = navigation
        webView.loadHTMLString("<!doctype html><html><head></head><body></body></html>", baseURL: nil)
        await fulfillment(of: [loaded], timeout: 15)
        // XCTest records a timeout but continues execution. Do not evaluate on an unloaded page.
        try XCTUnwrap(navigation.result, "WebKit did not finish navigation").get()

        for title in ["Ordinary Palette", "色🎨 & <title>", "*/ body { color: red; } /*", "*/ /* */"] {
            let data = try XCTUnwrap(PaletteExporter.export(palette: palette(cssNames), to: .css, paletteName: title))
            let css = try XCTUnwrap(String(data: data, encoding: .utf8))
            // Pass the exported file as text, avoiding an unrelated HTML/style-tag serialization layer.
            let evaluated = expectation(description: "CSS stylesheet parsed")
            var evaluation: Result<Any, Error>?
            webView.callAsyncJavaScript("""
                const style = document.createElement('style');
                style.textContent = css;
                document.head.append(style);
                const rules = [...style.sheet.cssRules];
                const root = rules.find(rule => rule.selectorText === ':root');
                const declarations = root ? Object.fromEntries([...root.style].map(name =>
                    [name, root.style.getPropertyValue(name).trim()])) : {};
                style.remove();
                return {selectors: rules.map(rule => rule.selectorText), declarations};
                """,
                arguments: ["css": css],
                in: nil,
                in: .page) { result in
                evaluation = result
                evaluated.fulfill()
            }
            await fulfillment(of: [evaluated], timeout: 15)
            let result = try XCTUnwrap(evaluation, "WebKit did not finish CSS evaluation").get()
            let parsed = try XCTUnwrap(result as? [String: Any])
            XCTAssertEqual(parsed["selectors"] as? [String], [":root"], title)
            var expected: [String: String] = [:]
            for (name, hex) in zip(names + ["nul\u{FFFD}name", "control\u{1}F\u{7F}"], expectedHexValues + ["#FF0000FF", "#000000FF"]) {
                expected["--" + name.lowercased().replacingOccurrences(of: " ", with: "-")] = hex
            }
            XCTAssertEqual(parsed["declarations"] as? [String: String], expected, title)
        }
    }

    func testASEPreservesNamesAndBlockBoundaries() throws {
        let data = try XCTUnwrap(PaletteExporter.export(palette: palette(names), to: .ase, paletteName: "Title"))
        var offset = 0
        func read(_ count: Int) throws -> Data {
            XCTAssertLessThanOrEqual(offset + count, data.count)
            guard offset + count <= data.count else { throw CocoaError(.fileReadCorruptFile) }
            defer { offset += count }
            return data.subdata(in: offset..<(offset + count))
        }
        func integer(_ count: Int) throws -> Int {
            try read(count).reduce(0) { ($0 << 8) | Int($1) }
        }
        XCTAssertEqual(try read(4), Data("ASEF".utf8))
        XCTAssertEqual(try integer(2), 1)
        XCTAssertEqual(try integer(2), 0)
        XCTAssertEqual(try integer(4), names.count)
        for (index, name) in names.enumerated() {
            XCTAssertEqual(try integer(2), 1)
            let length = try integer(4)
            let end = offset + length
            let nameLength = try integer(2)
            XCTAssertEqual(String(data: try read((nameLength - 1) * 2), encoding: .utf16BigEndian), name)
            XCTAssertEqual(try integer(2), 0)
            XCTAssertEqual(try read(4), Data("RGB ".utf8))
            XCTAssertEqual(Float(bitPattern: UInt32(try integer(4))), index.isMultiple(of: 2) ? 1 : 0)
            XCTAssertEqual(try integer(4), 0)
            XCTAssertEqual(try integer(4), 0)
            XCTAssertEqual(try integer(2), 0)
            XCTAssertEqual(offset, end)
        }
        XCTAssertEqual(offset, data.count)
    }

    @MainActor
    func testPNGDecodesWithNamedEntries() throws {
        let data = try XCTUnwrap(PaletteExporter.export(palette: palette(names), to: .png, paletteName: "色 & <palette>"))
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        XCTAssertEqual(CGImageSourceGetType(source) as String?, "public.png")
        XCTAssertEqual(CGImageSourceGetCount(source), 1)
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        XCTAssertGreaterThan(image.width, 0)
        XCTAssertGreaterThan(image.height, 0)
    }

    private var expectedHexValues: [String] {
        names.indices.map { $0.isMultiple(of: 2) ? "#FF0000FF" : "#000000FF" }
    }
}

private final class SVGDocument: NSObject, XMLParserDelegate {
    var titles: [String] = []
    var texts: [String] = []
    var fills: [String] = []
    var elements: [String] = []
    private var text = ""

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        elements.append(elementName)
        text = ""
        if elementName == "rect", let fill = attributeDict["fill"] { fills.append(fill) }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "title" { titles.append(text) }
        if elementName == "text" { texts.append(text) }
    }
}

@MainActor
private final class LoadedDocument: NSObject, WKNavigationDelegate {
    let loaded: XCTestExpectation
    private(set) var result: Result<Void, Error>?

    init(_ loaded: XCTestExpectation) { self.loaded = loaded }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finish(.success(()))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finish(.failure(error))
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish(.failure(error))
    }

    private func finish(_ result: Result<Void, Error>) {
        guard self.result == nil else { return }
        self.result = result
        loaded.fulfill()
    }
}
