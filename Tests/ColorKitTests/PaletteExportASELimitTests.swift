import ColorKit
import Foundation
import SwiftUI
import XCTest

final class PaletteExportASELimitTests: XCTestCase {
    func testASERejectsNamesExceedingUTF16LengthLimit() {
        for name in [String(repeating: "a", count: 65_535), String(repeating: "😀", count: 32_768)] {
            XCTAssertNil(PaletteExporter.export(
                palette: [entry(named: name)], to: .ase, paletteName: "Length limit"
            ))
        }
    }

    func testASEPreservesMaximumLengthASCIIAndSupplementaryNames() throws {
        for name in [String(repeating: "a", count: 65_534), String(repeating: "😀", count: 32_767)] {
            let data = try XCTUnwrap(PaletteExporter.export(
                palette: [entry(named: name)], to: .ase, paletteName: "Length limit"
            ))
            var offset = 0
            func read(_ count: Int) throws -> Data {
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
            XCTAssertEqual(try integer(4), 1)
            XCTAssertEqual(try integer(2), 1)
            let blockLength = try integer(4)
            let blockEnd = offset + blockLength
            let nameLength = try integer(2)
            XCTAssertEqual(nameLength, 65_535)
            XCTAssertEqual(String(data: try read((nameLength - 1) * 2), encoding: .utf16BigEndian), name)
            XCTAssertEqual(try integer(2), 0)
            XCTAssertEqual(try read(4), Data("RGB ".utf8))
            XCTAssertEqual(Float(bitPattern: UInt32(try integer(4))), 1)
            XCTAssertEqual(Float(bitPattern: UInt32(try integer(4))), 0)
            XCTAssertEqual(Float(bitPattern: UInt32(try integer(4))), 0)
            XCTAssertEqual(try integer(2), 0)
            XCTAssertEqual(offset, blockEnd)
            XCTAssertEqual(offset, data.count)
        }
    }

    private func entry(named name: String) -> PaletteExporter.PaletteEntry {
        PaletteExporter.PaletteEntry(name: name, color: Color(.sRGB, red: 1, green: 0, blue: 0))
    }
}
