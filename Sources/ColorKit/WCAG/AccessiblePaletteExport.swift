import SwiftUI

@MainActor
final class AccessiblePaletteExport: ObservableObject {
    // MARK: - Export Values

    struct Snapshot {
        let entries: [PaletteExporter.PaletteEntry]
        let name: String
        let format: PaletteExportFormat

        var filename: String { "\(name).\(format.fileExtension)" }
    }

    struct ShareItem: Identifiable {
        let id = UUID()
        let url: URL
    }

    // MARK: - Presentation State

    @Published var shareItem: ShareItem?
    @Published var showResult = false
    @Published private(set) var resultMessage = ""

    init(
        files: AccessiblePaletteExportFiles = .shared,
        serialize: @escaping (Snapshot) -> Data? = {
            PaletteExporter.export(palette: $0.entries, to: $0.format, paletteName: $0.name)
        }
    ) {
        self.files = files
        self.serialize = serialize
    }

    // MARK: - Export Actions

    func share(_ snapshot: Snapshot) {
        guard shareItem == nil else { return }
        files.removePreviousRunsIfNeeded()
        guard let data = prepare(snapshot) else { return }

        do {
            let url = try files.write(data, filename: snapshot.filename)
            shareItem = ShareItem(url: url)
        } catch {
            report("Failed to create temporary file: \(error.localizedDescription)")
        }
    }

    func save(_ snapshot: Snapshot, chooseDestination: () -> URL?) {
        guard let data = prepare(snapshot), let url = chooseDestination() else { return }

        do {
            try data.write(to: url)
            report("Palette exported successfully")
        } catch {
            report("Failed to save file: \(error.localizedDescription)")
        }
    }

    // MARK: - Preparation and Results

    private let files: AccessiblePaletteExportFiles
    private let serialize: (Snapshot) -> Data?

    private func prepare(_ snapshot: Snapshot) -> Data? {
        showResult = false
        guard let data = serialize(snapshot) else {
            report("Failed to prepare data for export")
            return nil
        }
        return data
    }

    private func report(_ message: String) {
        resultMessage = message
        showResult = true
    }
}
