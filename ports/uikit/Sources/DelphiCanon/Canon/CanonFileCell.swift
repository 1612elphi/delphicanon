import PhotosUI
import UIKit
import UniformTypeIdentifiers

/// File name beside a Choose cell. Delivers a copy in the temporary directory. Sends `.valueChanged`.
public final class CanonFileCell: UIControl, UIDocumentPickerDelegate, PHPickerViewControllerDelegate {
    private let types: [UTType]
    private let photos: PHPickerFilter?
    private let name = UILabel.canon(nil, .caption1)
    private let choose = CanonButton(String(localized: "Choose"), kind: .cell)

    public private(set) var url: URL? {
        didSet { refresh() }
    }

    /// - Parameter photos: when set, Choose offers the photo library beside Files.
    public init(types: [UTType], photos: PHPickerFilter? = nil) {
        self.types = types
        self.photos = photos
        super.init(frame: .zero)
        backgroundColor = .delphiBorder

        name.numberOfLines = 1
        name.lineBreakMode = .byTruncatingMiddle
        name.textAlignment = .right
        name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        name.isAccessibilityElement = false
        let cell = UIView()
        cell.backgroundColor = .delphiCard
        cell.pin(name, insets: NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
        cell.widthAnchor.constraint(greaterThanOrEqualToConstant: 64).isActive = true

        if photos == nil {
            choose.addAction(UIAction { [unowned self] _ in pickFile() }, for: .primaryActionTriggered)
        } else {
            choose.showsMenuAsPrimaryAction = true
            choose.menu = UIMenu(children: [
                UIAction(title: String(localized: "Photos"), image: UIImage(systemName: "photo.stack")) { [unowned self] _ in pickPhoto() },
                UIAction(title: String(localized: "Files"), image: UIImage(systemName: "folder")) { [unowned self] _ in pickFile() },
            ])
        }

        let stack = UIStackView(arrangedSubviews: [cell, choose])
        stack.spacing = DelphiMetrics.hairline
        pin(stack)
        refresh()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func clear() {
        url = nil
    }

    private func refresh() {
        name.text = url?.lastPathComponent ?? String(localized: "None")
        name.textColor = url == nil ? .delphiMutedForeground : .delphiForeground
        choose.accessibilityValue = name.text
    }

    private func pickFile() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = self
        owningViewController?.present(picker, animated: true)
    }

    private func pickPhoto() {
        var config = PHPickerConfiguration()
        config.filter = photos
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        owningViewController?.present(picker, animated: true)
    }

    // provider downloads during copy
    private func deliver(_ source: URL) {
        Task {
            guard let copy = await Task.detached(operation: { FileImport.copy(source) }).value else { return }
            url = copy
            sendActions(for: .valueChanged)
        }
    }

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let first = urls.first { deliver(first) }
    }

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              let type = types.first(where: { provider.hasItemConformingToTypeIdentifier($0.identifier) })?.identifier
                ?? provider.registeredTypeIdentifiers.first else { return }
        // file deleted on return
        provider.loadFileRepresentation(forTypeIdentifier: type) { [weak self] file, _ in
            guard let file, let copy = FileImport.copy(file) else { return }
            Task { @MainActor [weak self] in
                self?.url = copy
                self?.sendActions(for: .valueChanged)
            }
        }
    }
}
