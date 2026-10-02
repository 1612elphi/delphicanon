import PhotosUI
import UIKit
import UniformTypeIdentifiers

/// onImages adds paste
public final class CanonDropZone: UIView, UIDropInteractionDelegate, UIDocumentPickerDelegate, PHPickerViewControllerDelegate {
    public var onImages: (([UIImage]) -> Void)?
    public var onFiles: (([URL]) -> Void)?
    /// empty after a paste
    public private(set) var imageNames: [String] = []

    public let types: [UTType]
    private let photos: PHPickerFilter?
    public let allowsMultiple: Bool
    private let target = UIView()
    private let icon = UIImageView()

    /// nil photos: no library
    public init(
        prompt: String,
        systemImage: String = "photo.on.rectangle.angled",
        types: [UTType] = [.image],
        photos: PHPickerFilter? = .images,
        allowsMultiple: Bool = false,
        paste: Bool = true
    ) {
        self.types = types
        self.photos = photos
        self.allowsMultiple = allowsMultiple
        super.init(frame: .zero)
        backgroundColor = .delphiBorder

        icon.image = UIImage(systemName: systemImage, withConfiguration: UIImage.SymbolConfiguration(textStyle: .largeTitle))
        icon.contentMode = .center
        let label = UILabel.canon(prompt, .subheadline, colour: .delphiMutedForeground)
        label.textAlignment = .center
        let text = UIStackView(arrangedSubviews: [icon, label])
        text.axis = .vertical
        text.spacing = 12
        text.translatesAutoresizingMaskIntoConstraints = false
        target.addSubview(text)
        NSLayoutConstraint.activate([
            text.centerYAnchor.constraint(equalTo: target.centerYAnchor),
            text.topAnchor.constraint(greaterThanOrEqualTo: target.topAnchor, constant: 24),
            text.leadingAnchor.constraint(equalTo: target.leadingAnchor, constant: 20),
            target.trailingAnchor.constraint(equalTo: text.trailingAnchor, constant: 20),
            target.heightAnchor.constraint(greaterThanOrEqualToConstant: 140),
        ])
        target.addInteraction(UIDropInteraction(delegate: self))
        target.isAccessibilityElement = true
        target.accessibilityLabel = prompt
        target.accessibilityDropPointDescriptors = [UIAccessibilityLocationDescriptor(name: prompt, view: target)]
        highlight(false)

        var sources: [CanonButton] = []
        if photos != nil {
            sources.append(CanonButton(String(localized: "Photos"), systemImage: "photo.stack", kind: .cell) { [unowned self] in pickPhotos() })
        }
        sources.append(CanonButton(String(localized: "Files"), systemImage: "folder", kind: .cell) { [unowned self] in pickFiles() })
        if paste {
            sources.append(CanonButton(String(localized: "Paste"), systemImage: "doc.on.clipboard", kind: .cell) { [unowned self] in pasteImages() })
        }

        let stack = UIStackView(arrangedSubviews: [target, CanonGrid(sources)])
        stack.axis = .vertical
        stack.spacing = DelphiMetrics.hairline
        pin(stack)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func highlight(_ on: Bool) {
        target.backgroundColor = on ? .delphiAccentBG : .delphiCard
        icon.tintColor = on ? .delphiPrimary : .delphiPrimary.withAlphaComponent(0.5)
    }

    // MARK: Sources

    private func pickFiles() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.allowsMultipleSelection = allowsMultiple
        picker.delegate = self
        owningViewController?.present(picker, animated: true)
    }

    private func pickPhotos() {
        var config = PHPickerConfiguration()
        config.filter = photos
        config.selectionLimit = allowsMultiple ? 0 : 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        owningViewController?.present(picker, animated: true)
    }

    private func pasteImages() {
        let board = UIPasteboard.general
        let images = allowsMultiple ? board.images ?? [] : [board.image].compactMap { $0 }
        guard !images.isEmpty else { return }
        imageNames = []
        onImages?(images)
    }

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        Task {
            // provider downloads during copy
            let copies = await Task.detached { urls.compactMap(FileImport.copy) }.value
            deliver(copies)
        }
    }

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        load(results.map(\.itemProvider))
    }

    // MARK: Drop

    public func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        session.hasItemsConforming(toTypeIdentifiers: types.map(\.identifier))
    }

    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        UIDropProposal(operation: .copy)
    }

    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) { highlight(true) }
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) { highlight(false) }
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) { highlight(false) }

    public func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        load(session.items.map(\.itemProvider))
    }

    // MARK: Delivery

    private func load(_ providers: [NSItemProvider]) {
        let providers = allowsMultiple ? providers : Array(providers.prefix(1))
        Task {
            var copies: [URL] = []
            for provider in providers {
                guard let type = types.first(where: { provider.hasItemConformingToTypeIdentifier($0.identifier) }) else { continue }
                if let copy = await Self.copy(from: provider, type: type) { copies.append(copy) }
            }
            deliver(copies)
        }
    }

    // file deleted on return
    public nonisolated static func copy(from provider: NSItemProvider, type: UTType) async -> URL? {
        await withCheckedContinuation { continuation in
            _ = provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { file, _ in
                continuation.resume(returning: file.flatMap(FileImport.copy))
            }
        }
    }

    public func deliver(_ copies: [URL]) {
        let copies = allowsMultiple ? copies : Array(copies.prefix(1))
        guard !copies.isEmpty else { return }
        guard let onImages else {
            onFiles?(copies)
            return
        }
        Task {
            // decode applies exif orientation
            let decoded = await Task.detached(priority: .userInitiated) {
                // decoded here: a lazy image decodes on its first draw, on the main thread
                let decoded = copies.compactMap { url in
                    (try? Data(contentsOf: url)).flatMap(UIImage.init(data:)).map {
                        ($0.preparingForDisplay() ?? $0, url.deletingPathExtension().lastPathComponent)
                    }
                }
                copies.forEach { try? FileManager.default.removeItem(at: $0.deletingLastPathComponent()) }
                return decoded
            }.value
            guard !decoded.isEmpty else { return }
            imageNames = decoded.map(\.1)
            onImages(decoded.map(\.0))
        }
    }
}
