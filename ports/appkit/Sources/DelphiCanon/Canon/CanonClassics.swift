import AppKit

/// Flush row of buttons divided by hairlines: a `CanonGrid` whose cells are `CanonButton`s.
public typealias CanonActionBar = CanonGrid

/// A name and a value in a flush cell; a click copies the value and runs `action`. `show` with a nil value shows a
/// dash and turns copying off. `isLit` marks the chosen line of a list; `tint` colours the value character by character.
public final class CanonValueLine: CanonView {
    public enum Layout {
        /// The name in a column `labelWidth` wide, the value on one line beside it.
        case beside(labelWidth: CGFloat)
        /// The name above the value.
        case above
        /// The name as wide as it is, the value beside it wrapping by character.
        case wrapping
        /// A list index as the name; `wraps` breaks a long value by character instead of truncating it.
        case numbered(wraps: Bool)
    }

    public var isLit = false {
        didSet { if isLit != oldValue { paintValue() } }
    }

    public var isEnabled = true {
        didSet {
            glyph.isHidden = !isEnabled
            paint()
        }
    }

    /// Colours characters by kind; nil sets the whole value in one colour.
    public var tint: ((Character) -> NSColor)? {
        didSet { paintValue() }
    }

    /// Runs after the copy, on a click.
    public var action: (() -> Void)?

    private let layout: Layout
    private let format = NSTextField.canon(size: 11, weight: .semibold, colour: .delphiMutedForeground)
    private let value = NSTextField.canon()
    private let glyph = NSImageView()
    private var text = ""
    private var copiedRevert: DispatchWorkItem?
    private var isHovering = false {
        didSet { if isHovering != oldValue { paint() } }
    }

    public convenience init(labelWidth: CGFloat = 48) {
        self.init(layout: .beside(labelWidth: labelWidth))
    }

    public init(layout: Layout) {
        self.layout = layout
        super.init(fill: .delphiCard)
        value.font = .delphiMono(13)
        value.wantsLayer = true
        showGlyph(copied: false)
        glyph.setContentHuggingPriority(.required, for: .horizontal)
        glyph.setContentCompressionResistancePriority(.required, for: .horizontal)
        format.setContentHuggingPriority(.required, for: .horizontal)
        format.setContentCompressionResistancePriority(.required, for: .horizontal)
        value.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let stack: NSStackView
        var inset: CGFloat = 0
        var height = DelphiMetrics.controlHeight
        switch layout {
        case .beside(let labelWidth):
            format.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
            stack = NSStackView(views: [format, value, glyph])
            stack.spacing = 8
        case .above:
            let text = NSStackView(views: [format, value])
            text.orientation = .vertical
            text.alignment = .leading
            text.spacing = 2
            stack = NSStackView(views: [text, glyph])
            stack.spacing = 12
            inset = 8
            height = DelphiMetrics.rowHeight
        case .wrapping:
            Self.wrap(value)
            stack = NSStackView(views: [format, value, glyph])
            stack.spacing = 12
            stack.alignment = .firstBaseline
            inset = 10
        case .numbered(let wraps):
            format.font = .delphiMono(11, weight: .semibold)
            format.widthAnchor.constraint(greaterThanOrEqualToConstant: 24).isActive = true
            if wraps { Self.wrap(value) }
            stack = NSStackView(views: [format, value, glyph])
            stack.spacing = 10
            inset = wraps ? 8 : 0
        }
        if stack.alignment != .firstBaseline { stack.alignment = .centerY }
        stack.distribution = .fill
        value.setContentHuggingPriority(.defaultLow, for: .horizontal)
        pin(stack, insets: canonInsets(vertical: inset, horizontal: DelphiMetrics.panelPadding))
        heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        paint()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private static func wrap(_ label: NSTextField) {
        label.maximumNumberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        label.cell?.wraps = true
        label.cell?.isScrollable = false
    }

    /// - Parameter fadeDelay: fades a changed value in after this many seconds; nil changes it at once.
    public func show(_ label: String, _ text: String?, fadeDelay: Double? = nil) {
        let shown = text ?? "\u{2014}"
        if format.stringValue != label { format.stringValue = label }
        let changed = shown != self.text
        if let fadeDelay, changed {
            let fade = CATransition()
            fade.type = .fade
            fade.duration = 0.25
            fade.beginTime = CACurrentMediaTime() + fadeDelay
            fade.fillMode = .backwards
            value.layer?.add(fade, forKey: "fade")
        }
        self.text = shown
        if changed { paintValue() }
        if isEnabled != (text != nil) { isEnabled = text != nil }
        if case .numbered = layout {
            setAccessibilityLabel(shown)
        } else {
            setAccessibilityLabel(label)
            setAccessibilityValue(shown)
        }
    }

    private func paintValue() {
        setAccessibilitySelected(isLit)
        paint()
        guard let tint else {
            value.stringValue = text
            value.textColor = isLit ? .delphiPrimary : .delphiForeground
            return
        }
        let font = value.font ?? .delphiMono(13)
        value.attributedStringValue = text.reduce(into: NSMutableAttributedString()) { out, character in
            out.append(NSAttributedString(string: String(character), attributes: [.font: font, .foregroundColor: tint(character)]))
        }
    }

    private func paint() {
        fill = isLit || isHovering && isEnabled ? .delphiAccentBG : .delphiCard
    }

    private func showGlyph(copied: Bool) {
        glyph.image = .canonSymbol(copied ? "checkmark" : "doc.on.doc", size: 11)
        glyph.contentTintColor = copied ? .systemGreen : .delphiMutedForeground
    }

    private func press() {
        if isEnabled {
            ClipboardService.copy(text)
            showGlyph(copied: true)
            copiedRevert?.cancel()
            let revert = DispatchWorkItem { [weak self] in self?.showGlyph(copied: false) }
            copiedRevert = revert
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: revert)
        }
        action?()
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
    }

    public override func mouseEntered(with event: NSEvent) { isHovering = true }
    public override func mouseExited(with event: NSEvent) { isHovering = false }
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    public override func mouseDown(with event: NSEvent) {}

    public override func mouseUp(with event: NSEvent) {
        if bounds.contains(convert(event.locationInWindow, from: nil)) { press() }
    }

    public override func accessibilityPerformPress() -> Bool {
        press()
        return true
    }
}

/// Monospaced, selectable code with a copy button. Lines do not wrap; the block scrolls sideways.
public final class CanonCodeBlock: CanonView {
    /// What the copy button copies in place of `code`, for a block that shows the code shortened.
    public var copyText: String?

    public var code: String {
        didSet {
            guard code != oldValue else { return }
            textView.string = code
            resize()
        }
    }

    private let textView = NSTextView()
    private let scroll = NSScrollView()
    private let maxHeight: CGFloat?
    private var height: NSLayoutConstraint!
    private lazy var copyButton: CanonButton = CanonButton("", systemImage: "doc.on.doc", kind: .cell) { [unowned self] in
        ClipboardService.copy(copyText ?? code)
        copyButton.flash("", systemImage: "checkmark")
    }

    /// - Parameter maxHeight: taller code scrolls inside the block.
    public init(_ code: String, language: String? = nil, maxHeight: CGFloat? = nil) {
        self.code = code
        self.maxHeight = maxHeight
        super.init(fill: .delphiCard)

        textView.string = code
        textView.font = .delphiMono(12)
        textView.textColor = .delphiForeground
        textView.drawsBackground = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        textView.isHorizontallyResizable = true
        textView.isVerticallyResizable = true
        textView.autoresizingMask = []
        scroll.documentView = textView
        scroll.drawsBackground = false
        scroll.hasHorizontalScroller = true
        scroll.hasVerticalScroller = maxHeight != nil
        scroll.autohidesScrollers = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        height = scroll.heightAnchor.constraint(equalToConstant: DelphiMetrics.rowHeight)
        height.isActive = true

        copyButton.setAccessibilityLabel(String(localized: "Copy code"))
        copyButton.setContentHuggingPriority(.required, for: .horizontal)
        let title = NSTextField.canonHeading(language?.uppercased() ?? "")
        let bar = NSStackView(views: [title, NSView(), copyButton])
        bar.distribution = .fill
        bar.edgeInsets = NSEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        let header = CanonView(fill: language == nil ? nil : .delphiMuted)
        header.pin(bar)

        pin(CanonStack(language == nil ? [scroll, header] : [header, scroll], spacing: 0))
        resize()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // unwrapped monospace: arithmetic size
    private func resize() {
        guard let font = textView.font else { return }
        let lines = code.split(separator: "\n", omittingEmptySubsequences: false)
        let longest = lines.max { $0.utf16.count < $1.utf16.count } ?? ""
        let inset = textView.textContainerInset
        let width = (String(longest) as NSString).size(withAttributes: [.font: font]).width.rounded(.up) + inset.width * 2 + 1
        let full = CGFloat(max(lines.count, 1)) * font.lineHeight + inset.height * 2
        textView.minSize = NSSize(width: width, height: full)
        textView.frame.size = NSSize(width: max(width, scroll.contentSize.width), height: full)
        height.constant = min(full, maxHeight ?? full)
    }
}
