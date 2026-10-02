import Foundation

/// Copies imported files into the temporary directory, so the URL needs no security scope.
public enum FileImport {

    public nonisolated static let importsFolder = FileManager.default.temporaryDirectory
        .appendingPathComponent("imports", isDirectory: true)

    public nonisolated static func copy(_ url: URL) -> URL? {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let folder = importsFolder.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let copy = folder.appendingPathComponent(url.lastPathComponent)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: url, to: copy)
            return copy
        } catch {
            return nil
        }
    }
}
