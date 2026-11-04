import AppKit
import UniformTypeIdentifiers

/// File name beside a Choose cell; a file dropped on it counts as chosen. `url` is the file itself, not a copy.
public final class CanonFileCell: CanonView {
    private let types: [UTType]
    private let name = NSTextField.canon(size: 12)
    private lazy var choose = CanonButton(String(localized: "Choose"), kind: .cell) { [unowned self] in pick() }
    private var handlers: [(CanonFileCell) -> Void] = []

    public private(set) var url: URL? {
        didSet { refresh() }
    }

    public init(types: [UTType]) {
        self.types = types
        super.init(fill: .delphiBorder)
        name.lineBreakMode = .byTruncatingMiddle
        name.alignment = .right
        name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let cell = CanonView(fill: .delphiCard)
        name.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(name)
        NSLayoutConstraint.activate([
            name.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 10),
            cell.trailingAnchor.constraint(equalTo: name.trailingAnchor, constant: 10),
            name.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        cell.widthAnchor.constraint(greaterThanOrEqualToConstant: 64).isActive = true
        pin(CanonStack([cell, choose], vertical: false))
        registerForDraggedTypes([.fileURL])
        refresh()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @discardableResult
    public func onChange(_ handler: @escaping (CanonFileCell) -> Void) -> Self {
        handlers.append(handler)
        return self
    }

    public func clear() {
        url = nil
    }

    /// Shows `chosen` as the file without running the change handlers, for a file that came from elsewhere.
    public func show(_ chosen: URL) {
        url = chosen
    }

    private func refresh() {
        name.stringValue = url?.lastPathComponent ?? String(localized: "None")
        name.textColor = url == nil ? .delphiMutedForeground : .delphiForeground
        choose.setAccessibilityValue(name.stringValue)
    }

    private func deliver(_ chosen: URL) {
        url = chosen
        handlers.forEach { $0(self) }
    }

    private func pick() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = types
        let done = { [weak self] (response: NSApplication.ModalResponse) in
            if response == .OK, let chosen = panel.url { self?.deliver(chosen) }
        }
        if let window { panel.beginSheetModal(for: window, completionHandler: done) } else { done(panel.runModal()) }
    }

    private func dropped(_ info: NSDraggingInfo) -> URL? {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true, .urlReadingContentsConformToTypes: types.map(\.identifier),
        ]
        return (info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL])?.first
    }

    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        dropped(sender) == nil ? [] : .copy
    }

    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let chosen = dropped(sender) else { return false }
        deliver(chosen)
        return true
    }
}
