import AppKit

/// Multi-line text input: monospaced, wrapping, a fixed height with its own scrolling, and a placeholder.
/// `onChange` runs for typed edits, not for a `text` set from code.
public final class CanonTextArea: CanonView, NSTextViewDelegate {
    private let scroll = NSTextView.scrollableTextView()
    private var textView: NSTextView { scroll.documentView as! NSTextView }
    private let prompt = NSTextField.canon(colour: .delphiMutedForeground)
    private var handlers: [(CanonTextArea) -> Void] = []

    public var text: String {
        get { textView.string }
        set {
            guard newValue != textView.string else { return }
            textView.string = newValue
            prompt.isHidden = !newValue.isEmpty
        }
    }

    /// True while this area has focus: a model echo must not replace the text being typed.
    public var isEditing: Bool { window?.firstResponder === textView }

    public init(placeholder: String, height: CGFloat = 200) {
        super.init(fill: .delphiMuted)
        scroll.drawsBackground = false
        scroll.autohidesScrollers = true
        textView.font = .delphiMono(13)
        textView.textColor = .delphiForeground
        textView.insertionPointColor = .delphiPrimary
        textView.drawsBackground = false
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.textContainer?.lineFragmentPadding = 0
        textView.delegate = self
        pin(scroll)

        prompt.stringValue = placeholder
        prompt.font = textView.font
        prompt.translatesAutoresizingMaskIntoConstraints = false
        addSubview(prompt)
        NSLayoutConstraint.activate([
            prompt.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            prompt.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            prompt.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
            heightAnchor.constraint(equalToConstant: height),
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func setAccessibilityLabel(_ label: String?) {
        textView.setAccessibilityLabel(label)
    }

    @discardableResult
    public func onChange(_ handler: @escaping (CanonTextArea) -> Void) -> Self {
        handlers.append(handler)
        return self
    }

    public func textDidChange(_ notification: Notification) {
        prompt.isHidden = !textView.string.isEmpty
        handlers.forEach { $0(self) }
    }
}

/// The input block of a text tool: a text area with Paste and Clear under it. Typing reaches `onChange` once it pauses.
public final class CanonTextInput {
    public let area: CanonTextArea
    private let extra: [NSView]
    private let typing = CanonDebounce()
    public var onChange: ((String) -> Void)?

    private lazy var paste = CanonButton(String(localized: "Paste"), systemImage: "doc.on.clipboard", kind: .cell) { [unowned self] in
        if let text = ClipboardService.string { set(text) }
    }
    private lazy var clear = CanonButton(String(localized: "Clear"), systemImage: "trash", kind: .cell) { [unowned self] in set("") }

    /// - Parameter extra: rows between the text area and the Paste and Clear bar.
    public init(placeholder: String = String(localized: "Type or paste"), height: CGFloat = 128, extra: [NSView] = []) {
        area = CanonTextArea(placeholder: placeholder, height: height)
        self.extra = extra
        area.setAccessibilityLabel(String(localized: "Input"))
        area.onChange { [unowned self] area in
            clear.isEnabled = !area.text.isEmpty
            typing.after(CanonDebounce.typingDelay) { [weak self] in self?.onChange?(area.text) }
        }
        clear.isEnabled = false
    }

    public var text: String { area.text }

    public var rows: [NSView] { [area] + extra + [CanonActionBar([paste, clear])] }

    /// Text set from code reaches `onChange` at once.
    public func set(_ text: String) {
        typing.cancel()
        area.text = text
        clear.isEnabled = !text.isEmpty
        onChange?(text)
    }
}

/// Read-only output text that wraps and can be selected.
public final class CanonOutputText: CanonView {
    private let label: NSTextField

    public var text: String {
        get { label.stringValue }
        set { label.stringValue = newValue }
    }

    public var attributedText: NSAttributedString {
        get { label.attributedStringValue }
        set { label.attributedStringValue = newValue }
    }

    public init(font: NSFont) {
        label = .canon(wraps: true)
        super.init(fill: .delphiCard)
        label.font = font
        label.isSelectable = true
        label.lineBreakMode = .byCharWrapping
        pin(label, insets: canonInsets(vertical: 14, horizontal: 16))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func setAccessibilityLabel(_ text: String?) {
        label.setAccessibilityLabel(text)
    }
}

/// The output block of a text tool: a heading, the converted text, and Save beside Copy.
public final class CanonTextOutput {
    public let block = CanonRows(framed: true)
    public let heading = CanonHeading(" ")
    public let text: CanonOutputText
    private let empty = CanonEmptyRow(String(localized: "None"))
    private let fileName: String
    private lazy var copy: CanonButton = CanonButton(String(localized: "Copy"), systemImage: "doc.on.doc", kind: .primary) { [unowned self] in
        ClipboardService.copy(text.text)
        copy.flashCopied()
    }
    private lazy var save: CanonButton = CanonButton(String(localized: "Save"), systemImage: "square.and.arrow.down", kind: .cell) { [unowned self] in
        FileExportService.save(data: Data(text.text.utf8), filename: fileName, from: save)
    }

    /// - Parameter extra: rows between the text and the actions.
    public init(font: NSFont, fileName: String, extra: [NSView] = []) {
        text = CanonOutputText(font: font)
        self.fileName = fileName
        text.setAccessibilityLabel(String(localized: "Output"))
        block.setRows([heading, text, empty] + extra + [CanonActionBar([save, copy])])
    }

    /// - Parameters:
    ///   - styled: the output with its marks, shown in place of `output`.
    ///   - busy: the output is still to come; the empty row stays away.
    public func show(_ output: String, styled: NSAttributedString? = nil, heading title: String, busy: Bool = false) {
        heading.text = title
        if let styled {
            if text.attributedText != styled { text.attributedText = styled }
        } else if text.text != output {
            text.text = output
        }
        let blank = output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        text.isHidden = blank
        empty.isHidden = !blank || busy
        copy.isEnabled = !blank
        save.isEnabled = !blank
    }
}

/// A horizontal level: `share` of the width filled.
public final class CanonBar: CanonView {
    private let filled: CanonView

    public var share: CGFloat = 0 {
        didSet { needsLayout = true }
    }

    public var fillColour: NSColor? {
        get { filled.fill }
        set { filled.fill = newValue }
    }

    public init(fill colour: NSColor = .delphiPrimary, track: NSColor? = .delphiMuted) {
        filled = CanonView(fill: colour)
        super.init(fill: track)
        addSubview(filled)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layout() {
        super.layout()
        filled.frame = CGRect(x: 0, y: 0, width: bounds.width * min(max(share, 0), 1), height: bounds.height)
    }
}

/// Read-only values as a hairline grid of tiles: label over value. As many columns as fit, at least two.
/// An item that carries a `level` gets a bar along the tile's bottom edge.
public final class CanonTiles: CanonView {
    public struct Item {
        public var label: String
        public var value: String
        /// Share of a level bar, 0...1. `nil` draws no bar.
        public var level: Double?

        public init(label: String, value: String, level: Double? = nil) {
            self.label = label
            self.value = value
            self.level = level
        }
    }

    /// Least width of a tile.
    private static let tileWidth: CGFloat = 168

    private var items: [Item]
    private var grid: CanonGrid?
    private var columns = 0
    private var tiles: [(view: NSView, value: NSTextField, bar: CanonBar?)] = []

    public init(_ items: [Item]) {
        self.items = items
        super.init()
        build(columns: 2)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var fittingColumns: Int { max(2, Int(bounds.width / Self.tileWidth)) }

    public override func layout() {
        super.layout()
        build(columns: fittingColumns)
    }

    /// New values for the same labels update the tiles in place; a different shape rebuilds.
    public func show(_ next: [Item]) {
        let sameShape = next.map(\.label) == items.map(\.label) && next.map { $0.level == nil } == items.map { $0.level == nil }
        items = next
        guard sameShape else {
            columns = 0
            build(columns: fittingColumns)
            return
        }
        for (item, tile) in zip(next, tiles) {
            if tile.value.stringValue != item.value { tile.value.stringValue = item.value }
            tile.view.setAccessibilityValue(item.value)
            if let level = item.level { tile.bar?.share = CGFloat(level) }
        }
    }

    private func build(columns: Int) {
        guard columns != self.columns else { return }
        self.columns = columns
        grid?.removeFromSuperview()
        tiles = []
        let grid = CanonGrid(columns: columns, items.map(tile))
        pin(grid)
        self.grid = grid
    }

    private func tile(_ item: Item) -> NSView {
        let label = NSTextField.canon(item.label, size: 11, weight: .semibold, colour: .delphiMutedForeground)
        let value = NSTextField.canon(item.value)
        value.font = .delphiMono(13)
        value.lineBreakMode = .byTruncatingMiddle
        let text = NSStackView(views: [label, value])
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 2
        let tile = CanonView(fill: .delphiCard)
        tile.pin(text, insets: NSEdgeInsets(top: 10, left: DelphiMetrics.panelPadding, bottom: 12, right: 12))
        tile.setAccessibilityElement(true)
        tile.setAccessibilityLabel(item.label)
        tile.setAccessibilityValue(item.value)

        guard let level = item.level else {
            tiles.append((tile, value, nil))
            return tile
        }
        let bar = CanonBar()
        tiles.append((tile, value, bar))
        bar.share = CGFloat(level)
        bar.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: tile.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: tile.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: tile.bottomAnchor),
            bar.heightAnchor.constraint(equalToConstant: 4),
        ])
        return tile
    }
}
