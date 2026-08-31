import Foundation

@MainActor
final class AccessiblePaletteExportFiles {
    // MARK: - App Run Lifetime

    // All demo instances retain files under the same app-run directory.
    static let shared = AccessiblePaletteExportFiles()

    init(
        root: URL = FileManager.default.temporaryDirectory.appendingPathComponent("ColorKitAccessiblePaletteExports", isDirectory: true),
        runID: UUID = UUID()
    ) {
        self.root = root
        runDirectory = root.appendingPathComponent(runID.uuidString, isDirectory: true)
    }

    func removePreviousRunsIfNeeded() {
        guard !hasRemovedPreviousRuns else { return }
        hasRemovedPreviousRuns = true

        // Cleanup is best effort; a stale file must not prevent a new export.
        let directories = (try? FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey]
        )) ?? []
        for directory in directories where directory.lastPathComponent != runDirectory.lastPathComponent {
            guard UUID(uuidString: directory.lastPathComponent) != nil,
                  let values = try? directory.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]),
                  values.isDirectory == true, values.isSymbolicLink != true else { continue }
            try? FileManager.default.removeItem(at: directory)
        }
    }

    // MARK: - Request Files

    func write(_ data: Data, filename: String) throws -> URL {
        let requestDirectory = runDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = requestDirectory.appendingPathComponent(filename)

        do {
            try FileManager.default.createDirectory(at: requestDirectory, withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
            // Successful files outlive sheets and views. A later app run cleans them up.
            return url
        } catch {
            try? FileManager.default.removeItem(at: requestDirectory)
            throw error
        }
    }

    // MARK: - Private State

    private let root: URL
    private let runDirectory: URL
    private var hasRemovedPreviousRuns = false
}
