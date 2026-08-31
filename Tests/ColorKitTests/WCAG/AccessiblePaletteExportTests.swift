import SwiftUI
import XCTest

@testable import ColorKit

@MainActor
final class AccessiblePaletteExportTests: XCTestCase {
    // MARK: - Sharing and File Lifetime

    func testSharePreparesOnceAndIgnoresActionsUntilDismissal() throws {
        try withTemporaryRoot { root in
            var preparations = 0
            let export = AccessiblePaletteExport(files: AccessiblePaletteExportFiles(root: root)) { snapshot in
                preparations += 1
                return Data(snapshot.name.utf8)
            }

            export.share(snapshot(name: "First"))
            let first = try XCTUnwrap(export.shareItem)
            export.share(snapshot(name: "Second", format: .css))

            XCTAssertEqual(preparations, 1)
            XCTAssertEqual(export.shareItem?.id, first.id)
            XCTAssertEqual(try Data(contentsOf: first.url), Data("First".utf8))
            XCTAssertEqual(first.url.lastPathComponent, "First.json")
            XCTAssertFalse(export.showResult)
        }
    }

    func testSnapshotAndPreparedPayloadSurviveInputChanges() throws {
        try withTemporaryRoot { root in
            var entries = PaletteExporter.createPalette(from: [Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 1)])
            var name = "Original"
            var format = PaletteExportFormat.json
            let captured = AccessiblePaletteExport.Snapshot(entries: entries, name: name, format: format)
            entries = PaletteExporter.createPalette(from: [Color.blue, .green])
            name = "Replacement"
            format = .css
            let export = AccessiblePaletteExport(files: AccessiblePaletteExportFiles(root: root))

            export.share(captured)
            let item = try XCTUnwrap(export.shareItem)
            let bytes = try Data(contentsOf: item.url)
            export.share(AccessiblePaletteExport.Snapshot(entries: entries, name: name, format: format))

            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
            let colors = try XCTUnwrap(json["colors"] as? [[String: Any]])
            XCTAssertEqual(json["name"] as? String, "Original")
            XCTAssertEqual(colors.count, 1)
            XCTAssertEqual(colors.first?["hex"] as? String, "#FF0000FF")
            XCTAssertEqual(item.url.pathExtension, "json")
            XCTAssertEqual(try Data(contentsOf: item.url), bytes)
        }
    }

    func testSerializationFailureDoesNotPresentOrCreateRequestFiles() throws {
        try withTemporaryRoot { root in
            var preparations = 0
            let export = AccessiblePaletteExport(files: AccessiblePaletteExportFiles(root: root)) { _ in
                preparations += 1
                return nil
            }

            export.share(snapshot())

            XCTAssertEqual(preparations, 1)
            XCTAssertNil(export.shareItem)
            XCTAssertTrue(export.showResult)
            XCTAssertEqual(export.resultMessage, "Failed to prepare data for export")
            XCTAssertFalse(FileManager.default.fileExists(atPath: root.path))
        }
    }

    func testWriteFailureRemovesRequestDirectoryAndAllowsRetry() throws {
        try withTemporaryRoot { root in
            let runID = UUID()
            let files = AccessiblePaletteExportFiles(root: root, runID: runID)
            let export = AccessiblePaletteExport(files: files)

            // The missing intermediate directory makes the file write fail after request creation.
            export.share(snapshot(name: "missing/Palette"))

            XCTAssertNil(export.shareItem)
            XCTAssertTrue(export.showResult)
            XCTAssertTrue(export.resultMessage.hasPrefix("Failed to create temporary file:"))
            let runDirectory = root.appendingPathComponent(runID.uuidString)
            XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: runDirectory.path).isEmpty)

            export.share(snapshot())
            XCTAssertNotNil(export.shareItem)
            XCTAssertFalse(export.showResult)
        }
    }

    func testDirectoryCreationFailureDoesNotPresent() throws {
        try withTemporaryRoot { root in
            let sentinel = Data("existing file".utf8)
            try sentinel.write(to: root)
            let export = AccessiblePaletteExport(files: AccessiblePaletteExportFiles(root: root))

            export.share(snapshot())

            XCTAssertNil(export.shareItem)
            XCTAssertTrue(export.showResult)
            XCTAssertEqual(try Data(contentsOf: root), sentinel)
        }
    }

    func testRepeatedSharingAndOwnerReleaseKeepEarlierArtifacts() throws {
        try withTemporaryRoot { root in
            let firstURL: URL
            let secondURL: URL
            let firstBytes: Data
            let secondBytes: Data
            do {
                let export = AccessiblePaletteExport(files: AccessiblePaletteExportFiles(root: root))
                export.share(snapshot())
                let first = try XCTUnwrap(export.shareItem)
                firstURL = first.url
                firstBytes = try Data(contentsOf: firstURL)
                export.shareItem = nil

                export.share(snapshot())
                let second = try XCTUnwrap(export.shareItem)
                secondURL = second.url
                secondBytes = try Data(contentsOf: secondURL)
                XCTAssertNotEqual(first.id, second.id)
                XCTAssertNotEqual(firstURL.deletingLastPathComponent(), secondURL.deletingLastPathComponent())
                XCTAssertEqual(firstURL.lastPathComponent, secondURL.lastPathComponent)
            }

            XCTAssertFalse(firstBytes.isEmpty)
            XCTAssertFalse(secondBytes.isEmpty)
            XCTAssertEqual(try Data(contentsOf: firstURL), firstBytes)
            XCTAssertEqual(try Data(contentsOf: secondURL), secondBytes)
        }
    }

    func testFailedLaterExportDoesNotRemoveAnEarlierArtifact() throws {
        try withTemporaryRoot { root in
            let export = AccessiblePaletteExport(files: AccessiblePaletteExportFiles(root: root))
            export.share(snapshot())
            let first = try XCTUnwrap(export.shareItem)
            let bytes = try Data(contentsOf: first.url)
            export.shareItem = nil

            export.share(snapshot(name: "missing/Palette"))

            XCTAssertNil(export.shareItem)
            XCTAssertTrue(export.showResult)
            XCTAssertEqual(try Data(contentsOf: first.url), bytes)
        }
    }

    func testLaterRunCleansOldRunsOnlyOnceAndPreservesCurrentAndUnrelatedFiles() throws {
        try withTemporaryRoot { root in
            let firstRun = AccessiblePaletteExportFiles(root: root)
            let firstDemo = AccessiblePaletteExport(files: firstRun)
            firstDemo.share(snapshot())
            let oldURL = try XCTUnwrap(firstDemo.shareItem?.url)
            let secondDemo = AccessiblePaletteExport(files: firstRun)
            secondDemo.share(snapshot())
            XCTAssertTrue(FileManager.default.fileExists(atPath: oldURL.path))

            let sentinel = root.appendingPathComponent("unrelated.txt")
            try Data("keep".utf8).write(to: sentinel)
            let uuidFile = root.appendingPathComponent(UUID().uuidString)
            try Data("also keep".utf8).write(to: uuidFile)
            let nextRun = AccessiblePaletteExportFiles(root: root)
            let currentURL = try nextRun.write(Data("current".utf8), filename: "current.json")
            let nextDemo = AccessiblePaletteExport(files: nextRun)

            nextDemo.share(snapshot())

            XCTAssertFalse(FileManager.default.fileExists(atPath: oldURL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: currentURL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: sentinel.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: uuidFile.path))

            let lateDirectory = root.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: lateDirectory, withIntermediateDirectories: true)
            nextDemo.shareItem = nil
            nextDemo.share(snapshot())
            XCTAssertTrue(FileManager.default.fileExists(atPath: lateDirectory.path))
        }
    }

    // MARK: - Saving

    func testSaveCancellationPreparesOnceWithoutWritingOrReporting() throws {
        try withTemporaryRoot { root in
            var preparations = 0
            var panelPresentations = 0
            let export = AccessiblePaletteExport(files: AccessiblePaletteExportFiles(root: root)) { _ in
                preparations += 1
                return Data("prepared".utf8)
            }
            export.showResult = true

            export.save(snapshot()) {
                panelPresentations += 1
                XCTAssertEqual(preparations, 1)
                return nil
            }

            XCTAssertEqual(preparations, 1)
            XCTAssertEqual(panelPresentations, 1)
            XCTAssertFalse(export.showResult)
            XCTAssertNil(export.shareItem)
            XCTAssertFalse(FileManager.default.fileExists(atPath: root.path))
        }
    }

    func testSerializationFailureDoesNotOpenSavePanel() throws {
        try withTemporaryRoot { root in
            let export = AccessiblePaletteExport(files: AccessiblePaletteExportFiles(root: root), serialize: { _ in nil })

            export.save(snapshot()) {
                XCTFail("Preparation failure must not open the save panel")
                return root
            }

            XCTAssertTrue(export.showResult)
            XCTAssertEqual(export.resultMessage, "Failed to prepare data for export")
        }
    }

    func testSaveUsesPreparedBytesAfterInputsChangeInPanel() throws {
        try withTemporaryRoot { root in
            var name = "Original"
            var preparations = 0
            let export = AccessiblePaletteExport(files: AccessiblePaletteExportFiles(root: root)) { snapshot in
                preparations += 1
                return Data(snapshot.name.utf8)
            }

            export.save(snapshot(name: name)) {
                name = "Changed while choosing a destination"
                return root
            }

            XCTAssertEqual(preparations, 1)
            XCTAssertEqual(try Data(contentsOf: root), Data("Original".utf8))
            XCTAssertTrue(export.showResult)
            XCTAssertEqual(export.resultMessage, "Palette exported successfully")
        }
    }

    func testSaveWriteFailureReportsError() throws {
        try withTemporaryRoot { root in
            let export = AccessiblePaletteExport(files: AccessiblePaletteExportFiles(root: root))

            export.save(snapshot()) { root.appendingPathComponent("missing/file.json") }

            XCTAssertTrue(export.showResult)
            XCTAssertTrue(export.resultMessage.hasPrefix("Failed to save file:"))
            XCTAssertNil(export.shareItem)
        }
    }

    // MARK: - Fixtures

    private func snapshot(name: String = "Accessible Palette", format: PaletteExportFormat = .json) -> AccessiblePaletteExport.Snapshot {
        AccessiblePaletteExport.Snapshot(entries: PaletteExporter.createPalette(from: [Color.red]), name: name, format: format)
    }

    private func withTemporaryRoot(_ body: (URL) throws -> Void) throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try body(root)
    }
}
