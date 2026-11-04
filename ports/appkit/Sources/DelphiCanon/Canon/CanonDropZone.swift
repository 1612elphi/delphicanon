import AppKit
import UniformTypeIdentifiers

/// A drop target for files over a Choose cell. `onFiles` gets the files themselves, not copies.
public final class CanonDropZone: CanonView {
    public var onFiles: (([URL]) -> Void)?

    public let types: [UTType]
    public let allowsMultiple: Bool
    private let target = CanonView(fill: .delphiCard)
    private let icon = NSImageView()

    public init(prompt: String, systemImage: String = "photo.on.rectangle.angled", types: [UTType] = [.image], allowsMultiple: Bool = false) {
        self.types = types
        self.allowsMultiple = allowsMultiple
        super.init(fill: .delphiBorder)
        icon.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 28, weight: .light))
        let label = NSTextField.canon(prompt, size: 12, colour: .delphiMutedForeground)
        label.alignment = .center
        let text = NSStackView(views: [icon, label])
        text.orientation = .vertical
        text.spacing = 12
        text.translatesAutoresizingMaskIntoConstraints = false
        target.addSubview(text)
        NSLayoutConstraint.activate([
            text.centerXAnchor.constraint(equalTo: target.centerXAnchor),
            text.centerYAnchor.constraint(equalTo: target.centerYAnchor),
            text.leadingAnchor.constraint(greaterThanOrEqualTo: target.leadingAnchor, constant: 20),
            target.heightAnchor.constraint(greaterThanOrEqualToConstant: 140),
        ])
        target.setAccessibilityElement(true)
        target.setAccessibilityRole(.group)
        target.setAccessibilityLabel(prompt)
        highlight(false)
        let choose = CanonButton(String(localized: "Choose"), systemImage: "folder", kind: .cell) { [unowned self] in pick() }
        pin(CanonStack([target, CanonGrid([choose])]))
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func highlight(_ on: Bool) {
        target.fill = on ? .delphiAccentBG : .delphiCard
        icon.contentTintColor = on ? .delphiPrimary : .delphiPrimary.withAlphaComponent(0.5)
    }

    private func pick() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = types
        panel.allowsMultipleSelection = allowsMultiple
        let done = { [weak self] (response: NSApplication.ModalResponse) in
            if response == .OK { self?.deliver(panel.urls) }
        }
        if let window { panel.beginSheetModal(for: window, completionHandler: done) } else { done(panel.runModal()) }
    }

    private func deliver(_ urls: [URL]) {
        let urls = allowsMultiple ? urls : Array(urls.prefix(1))
        if !urls.isEmpty { onFiles?(urls) }
    }

    private func dropped(_ info: NSDraggingInfo) -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true, .urlReadingContentsConformToTypes: types.map(\.identifier),
        ]
        return info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL] ?? []
    }

    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard !dropped(sender).isEmpty else { return [] }
        highlight(true)
        return .copy
    }

    public override func draggingExited(_ sender: NSDraggingInfo?) { highlight(false) }

    public override func draggingEnded(_ sender: NSDraggingInfo) { highlight(false) }

    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = dropped(sender)
        guard !urls.isEmpty else { return false }
        deliver(urls)
        return true
    }
}

extension CanonRow {
    /// A chosen file's name and detail beside a Clear cell.
    public static func file(onClear: @escaping () -> Void) -> CanonRow {
        CanonRow(" ", detail: " ", form: .flush, control: CanonButton(String(localized: "Clear"), systemImage: "trash", kind: .cell, action: onClear))
    }
}
