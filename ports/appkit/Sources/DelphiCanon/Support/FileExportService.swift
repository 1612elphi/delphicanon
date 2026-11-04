import AppKit

public enum FileExportService {
    /// Asks where to save `data`, starting from `filename`, and writes it there.
    public static func save(data: Data, filename: String, from view: NSView? = nil) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = safeFilename(filename)
        let write = { (response: NSApplication.ModalResponse) in
            guard response == .OK, let url = panel.url else { return }
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                NSAlert(error: error).runModal()
            }
        }
        if let window = view?.window {
            panel.beginSheetModal(for: window, completionHandler: write)
        } else {
            write(panel.runModal())
        }
    }

    /// Asks where to save a copy of the file at `source`, starting from its name; the source stays where it is.
    public static func save(file source: URL, from view: NSView? = nil) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = safeFilename(source.lastPathComponent)
        let write = { (response: NSApplication.ModalResponse) in
            guard response == .OK, let url = panel.url else { return }
            do {
                guard url.resolvingSymlinksInPath().standardizedFileURL != source.resolvingSymlinksInPath().standardizedFileURL else { return }
                let files = FileManager.default
                // the original stays until the copy is whole
                let staging = try files.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: url, create: true)
                defer { try? files.removeItem(at: staging) }
                let copy = staging.appendingPathComponent(url.lastPathComponent)
                try files.copyItem(at: source, to: copy)
                if files.fileExists(atPath: url.path) {
                    _ = try files.replaceItemAt(url, withItemAt: copy)
                } else {
                    try files.moveItem(at: copy, to: url)
                }
            } catch {
                NSAlert(error: error).runModal()
            }
        }
        if let window = view?.window {
            panel.beginSheetModal(for: window, completionHandler: write)
        } else {
            write(panel.runModal())
        }
    }

    /// The share menu for `items`, under `view`.
    public static func share(_ items: [Any], from view: NSView) {
        NSSharingServicePicker(items: items).show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }

    public static func share(text: String, from view: NSView) {
        share([text], from: view)
    }

    /// `name` with path separators and control characters replaced, so it stays one file name.
    public nonisolated static func safeFilename(_ name: String) -> String {
        let banned = CharacterSet(charactersIn: "/\\:").union(.controlCharacters).union(.newlines)
        let cleaned = String(String.UnicodeScalarView(name.unicodeScalars.map { banned.contains($0) ? "-" : $0 }))
        return cleaned.trimmingCharacters(in: .whitespaces).isEmpty ? "export" : cleaned
    }

    #if DEBUG
    public static func selfCheck() {
        assert(safeFilename("Warm / Cozy.ase") == "Warm - Cozy.ase")
        assert(safeFilename("a:b\\c\nd.png") == "a-b-c-d.png")
        assert(safeFilename("/") == "-")
        assert(safeFilename("") == "export")
    }
    #endif
}
