import SwiftUI
import UniformTypeIdentifiers

/// Handles exporting files to the share sheet or Files app.
public enum FileExportService {

    /// Save data as a temporary file and present the share sheet. The file sits in its own folder, removed when the
    /// sheet closes.
    public static func share(
        data: Data,
        filename: String,
        from view: UIView? = nil
    ) {
        if CanonHost.captureExport(data, filename, view) { return }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = folder.appendingPathComponent(safeFilename(filename))
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try data.write(to: url)
        } catch {
            try? FileManager.default.removeItem(at: folder)
            return
        }
        let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        sheet.completionWithItemsHandler = { _, _, _, _ in try? FileManager.default.removeItem(at: folder) }
        present(sheet, from: view)
    }

    /// `name` with path separators and control characters replaced, so it stays one file name.
    public nonisolated static func safeFilename(_ name: String) -> String {
        let banned = CharacterSet(charactersIn: "/\\:").union(.controlCharacters).union(.newlines)
        let cleaned = String(String.UnicodeScalarView(name.unicodeScalars.map { banned.contains($0) ? "-" : $0 }))
        return cleaned.trimmingCharacters(in: .whitespaces).isEmpty ? "export" : cleaned
    }

    /// Share a UIImage directly.
    public static func share(image: UIImage, from view: UIView? = nil) {
        if CanonHost.capturesFiles(), let png = image.pngData(), CanonHost.captureExport(png, "image.png", view) { return }
        present(UIActivityViewController(activityItems: [image], applicationActivities: nil), from: view)
    }

    /// Share a string.
    public static func share(text: String, from view: UIView? = nil) {
        present(UIActivityViewController(activityItems: [text], applicationActivities: nil), from: view)
    }

    /// Clean up old temp files.
    public static func cleanTemp() {
        let tempDir = FileManager.default.temporaryDirectory
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: tempDir, includingPropertiesForKeys: nil
        )) ?? []
        for url in contents {
            try? FileManager.default.removeItem(at: url)
        }
    }

    #if DEBUG
    public static func selfCheck() {
        assert(safeFilename("Warm / Cozy.ase") == "Warm - Cozy.ase")
        assert(safeFilename("a:b\\c\nd.png") == "a-b-c-d.png")
        assert(safeFilename("/") == "-")
        assert(safeFilename("") == "export")
    }
    #endif

    // MARK: - Private

    private static func present(_ activityVC: UIActivityViewController, from view: UIView?) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view ?? root.view
            popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
        }
        root.present(activityVC, animated: true)
    }
}
