import AppKit

/// Flush row of buttons divided by hairlines: a `CanonGrid` whose cells are `CanonButton`s.
public typealias CanonActionBar = CanonGrid

/// A name and a value in a flush cell; a click copies the value and runs `action`. `show` with a nil value shows a
/// dash and disables the line. `isLit` marks the chosen line of a list; `tint` colours the value character by character.
public final class CanonValueLine: CanonPressable {
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

    /// Colours characters by kind; nil sets the whole value in one colour.
    public var tint: ((Character) -> NSColor)? {
        didSet { paintValue() }
    }

    private let layout: Layout
    private let format = NSTextField.canon(size: 11, weight: .semibold, colour: .delphiMutedForeground)
    private let value = NSTextField.canon()
    private let glyph = NSImageView()
    private var text = ""
    private let copiedRevert = CanonDebounce()

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

    public override func stateChanged() {
        glyph.isHidden = !isEnabled
        paint()
    }

    public override func press() {
        ClipboardService.copy(text)
        showGlyph(copied: true)
        copiedRevert.after(1.5) { [weak self] in self?.showGlyph(copied: false) }
        action?()
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

        copyButton.accessibilityTitle = String(localized: "Copy code")
        copyButton.setContentHuggingPriority(.required, for: .horizontal)
        let title = NSTextField.canonHeading(language?.uppercased() ?? "")
        let spacer = NSView()
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)
        let bar = NSStackView(views: [title, spacer, copyButton])
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

/// A calculated figure, monospaced and bold, with an optional smaller unit after it. A changed figure slides in, up
/// when the number grew and down when it shrank.
public final class CanonFigure: NSStackView {
    private let figure = NSTextField.canon()
    private let unitLabel = NSTextField.canon()
    private let halo: NSColor?
    private var value = 0.0
    private var colour: NSColor

    /// - Parameter halo: outline in this colour, for a figure that sits over a picture.
    public init(size: CGFloat = 40, colour: NSColor = .delphiPrimary, halo: NSColor? = nil) {
        self.colour = colour
        self.halo = halo
        super.init(frame: .zero)
        figure.font = .delphiMono(size, weight: .bold)
        unitLabel.font = .systemFont(ofSize: size * 0.55, weight: .semibold, width: .condensed)
        figure.wantsLayer = true
        orientation = .horizontal
        alignment = .firstBaseline
        spacing = size * 0.08
        setViews([figure, unitLabel], in: .leading)
        setAccessibilityElement(true)
        setAccessibilityRole(.staticText)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func setColour(_ colour: NSColor) {
        self.colour = colour
        paint()
    }

    public func show(_ text: String, unit: String = "", animated: Bool = true) {
        guard text != figure.stringValue || unit != unitLabel.stringValue else { return }
        let next = Double(text.prefix { $0.isNumber || $0 == "." || $0 == "-" }) ?? 0
        if animated, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion, text != figure.stringValue {
            let slide = CATransition()
            slide.type = .push
            slide.subtype = next >= value ? .fromTop : .fromBottom
            slide.duration = 0.25
            figure.layer?.add(slide, forKey: "slide")
        }
        value = next
        figure.stringValue = text
        unitLabel.stringValue = unit
        unitLabel.isHidden = unit.isEmpty
        setAccessibilityLabel(text + unit)
        paint()
    }

    private func paint() {
        var attributes: [NSAttributedString.Key: Any] = [.foregroundColor: colour]
        if let halo {
            let shadow = NSShadow()
            shadow.shadowColor = halo
            shadow.shadowBlurRadius = 2
            attributes[.shadow] = shadow
        }
        for label in [figure, unitLabel] {
            attributes[.font] = label.font
            label.attributedStringValue = NSAttributedString(string: label.stringValue, attributes: attributes)
        }
    }
}
