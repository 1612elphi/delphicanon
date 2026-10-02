import UIKit
import UniformTypeIdentifiers

/// Picks a text file from Files and delivers its text, read off the main thread. Keep it for as long as its host.
public final class CanonTextFilePicker: NSObject, UIDocumentPickerDelegate {
    private let types: [UTType]
    private let onText: (String) -> Void
    public private(set) var fileName: String?

    public init(types: [UTType], onText: @escaping (String) -> Void) {
        self.types = types
        self.onText = onText
    }

    public func present(from host: UIViewController) {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = self
        host.present(picker, animated: true)
    }

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        Task {
            let text = await Task.detached {
                var encoding = String.Encoding.utf8
                defer { try? FileManager.default.removeItem(at: url) }
                return try? String(contentsOf: url, usedEncoding: &encoding)
            }.value
            guard let text else { return }
            fileName = url.lastPathComponent
            onText(text)
        }
    }
}
