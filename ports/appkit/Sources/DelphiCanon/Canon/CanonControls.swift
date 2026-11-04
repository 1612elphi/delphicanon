import AppKit

extension NSImage {
    /// An SF Symbol, else an image of that name in the main bundle.
    public static func canonSymbol(_ name: String, size: CGFloat = 12, weight: NSFont.Weight = .medium) -> NSImage? {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil) ?? NSImage(named: name)
        return image?.withSymbolConfiguration(.init(pointSize: size, weight: weight))
    }
}

/// Tracks hover and press; `press()` runs on a click released inside the view or on an accessibility press.
open class CanonPressable: CanonView {
    public var action: (() -> Void)?

    public var isEnabled = true {
        didSet { if isEnabled != oldValue { stateChanged() } }
    }

    public private(set) var isHovering = false {
        didSet { if isHovering != oldValue { stateChanged() } }
    }

    public private(set) var isPressed = false {
        didSet { if isPressed != oldValue { stateChanged() } }
    }

    public override init(fill: NSColor? = nil) {
        super.init(fill: fill)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Hover, press or enabled state changed.
    open func stateChanged() {}

    open func press() {
        action?()
    }

    open override func mouseEntered(with event: NSEvent) { isHovering = true }
    open override func mouseExited(with event: NSEvent) { isHovering = false }
    open override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    open override func mouseDown(with event: NSEvent) {
        if isEnabled { isPressed = true }
    }

    open override func mouseDragged(with event: NSEvent) {
        if isEnabled { isPressed = bounds.contains(convert(event.locationInWindow, from: nil)) }
    }

    open override func mouseUp(with event: NSEvent) {
        let wasPressed = isPressed
        isPressed = false
        if isEnabled, wasPressed { press() }
    }

    open override func viewDidHide() {
        super.viewDidHide()
        isHovering = false
    }

    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil { isHovering = false }
    }

    open override func accessibilityPerformPress() -> Bool {
        guard isEnabled else { return false }
        press()
        return true
    }
}

public final class CanonButton: CanonPressable {

    public enum Kind {
        case primary
        case secondary
        /// grid draws the lines
        case cell
        case segment
    }

    public let kind: Kind

    /// Spoken in place of the title, for a button whose title is a symbol or empty.
    public var accessibilityTitle: String? {
        didSet { refresh() }
    }

    public var text: String {
        didSet { if text != oldValue { refresh() } }
    }

    public var systemImage: String? {
        didSet { if systemImage != oldValue { refresh() } }
    }

    public var isSelected = false {
        didSet { if isSelected != oldValue { refresh() } }
    }

    private let label = NSTextField.canon()
    private let image = NSImageView()
    private lazy var content = NSStackView(views: [image, label])
    private let repeats: Bool
    private var holdTimer: Timer?
    private var didRepeat = false
    private let flashRevert = CanonDebounce()
    private var beforeFlash: (text: String, systemImage: String?)?

    /// seconds: delay, interval, fast
    public static let repeatTiming = (delay: 0.4, interval: 0.09, fast: 0.04)
    public static let filledHoverMix: CGFloat = 0.12

    /// - Parameters:
    ///   - boxed: draws a hairline around the button; leave false inside a grid.
    ///   - repeats: holding the button repeats the action.
    public init(_ title: String, systemImage: String? = nil, kind: Kind = .secondary, boxed: Bool = false,
                repeats: Bool = false, action: (() -> Void)? = nil) {
        self.kind = kind
        text = title
        self.systemImage = systemImage
        self.repeats = repeats
        super.init()
        self.action = action
        if boxed { border = (.delphiBorder, DelphiMetrics.hairline) }
        label.alignment = .center
        label.setContentCompressionResistancePriority(.init(700), for: .horizontal)
        content.spacing = 6
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.centerXAnchor.constraint(equalTo: centerXAnchor),
            content.centerYAnchor.constraint(equalTo: centerYAnchor),
            content.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: sideInset),
            content.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 6),
        ])
        let fills = kind == .primary || kind == .secondary
        setContentHuggingPriority(fills ? .defaultLow : .init(260), for: .horizontal)
        let height = heightAnchor.constraint(greaterThanOrEqualToConstant: DelphiMetrics.controlHeight)
        height.priority = .init(999)
        height.isActive = true
        refresh()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var sideInset: CGFloat { kind == .segment ? 6 : 12 }

    private var isFilled: Bool {
        kind == .primary || (isSelected && (kind == .segment || kind == .secondary))
    }

    private func refresh() {
        let filled = isFilled
        let size: CGFloat = kind == .segment ? 11 : 13
        label.font = .delphi(size, weight: filled ? .semibold : .medium)
        label.stringValue = text
        label.isHidden = text.isEmpty
        image.image = systemImage.flatMap { NSImage.canonSymbol($0, size: size) }
        image.isHidden = image.image == nil
        let ink: NSColor = filled ? (isEnabled ? .delphiPrimaryForeground : .delphiMutedForeground) : .delphiForeground
        let shown = isEnabled || filled ? ink : ink.withAlphaComponent(0.4)
        label.textColor = shown
        image.contentTintColor = shown
        let hovering = isHovering && isEnabled
        fill = if filled && !isEnabled {
            .delphiMuted
        } else if filled {
            hovering ? .delphiPrimary.blended(withFraction: Self.filledHoverMix, of: .delphiPrimaryForeground) : .delphiPrimary
        } else {
            hovering ? .delphiAccentBG : .delphiCard
        }
        alphaValue = isPressed ? 0.75 : 1
        setAccessibilityLabel(accessibilityTitle ?? (text.isEmpty ? systemImage : text))
        setAccessibilityEnabled(isEnabled)
        invalidateIntrinsicContentSize()
    }

    public override var intrinsicContentSize: NSSize {
        NSSize(width: content.fittingSize.width + sideInset * 2, height: NSView.noIntrinsicMetric)
    }

    public func flashCopied() {
        flash(String(localized: "Copied"), systemImage: "checkmark")
    }

    /// reverts after 1.5 s
    public func flash(_ title: String, systemImage symbol: String) {
        if beforeFlash == nil { beforeFlash = (text, systemImage) }
        text = title
        systemImage = symbol
        flashRevert.after(1.5) { [weak self] in
            guard let self, let before = beforeFlash else { return }
            (text, systemImage, beforeFlash) = (before.text, before.systemImage, nil)
        }
    }

    public override func stateChanged() {
        refresh()
    }

    public override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        didRepeat = false
        if repeats, isPressed { schedule(after: Self.repeatTiming.delay, count: 0) }
    }

    public override func mouseUp(with event: NSEvent) {
        holdTimer?.invalidate()
        super.mouseUp(with: event)
    }

    public override func press() {
        // hold release: no step
        if !didRepeat { action?() }
        didRepeat = false
    }

    private func schedule(after seconds: TimeInterval, count: Int) {
        holdTimer?.invalidate()
        let timer = Timer(timeInterval: seconds, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.isEnabled, self.isPressed else { return }
                self.didRepeat = true
                self.action?()
                self.schedule(after: count < 10 ? Self.repeatTiming.interval : Self.repeatTiming.fast, count: count + 1)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        holdTimer = timer
    }
}

public final class CanonSegmented: CanonView {
    private let cells: [CanonButton]
    private var handlers: [(CanonSegmented) -> Void] = []

    public var selectedIndex: Int {
        didSet { if selectedIndex != oldValue { cells.enumerated().forEach { $1.isSelected = $0 == selectedIndex } } }
    }

    public init(_ titles: [String], selected: Int = 0, columns: Int? = nil, boxed: Bool = false) {
        selectedIndex = selected
        cells = titles.map { CanonButton($0, kind: .segment) }
        super.init()
        for (index, cell) in cells.enumerated() {
            cell.isSelected = index == selected
            cell.action = { [unowned self] in
                guard selectedIndex != index else { return }
                selectedIndex = index
                handlers.forEach { $0(self) }
            }
        }
        pin(CanonGrid(columns: columns, boxed: boxed, cells))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @discardableResult
    public func onChange(_ handler: @escaping (CanonSegmented) -> Void) -> Self {
        handlers.append(handler)
        return self
    }

    public func setEnabled(_ enabled: Bool, at index: Int) {
        guard cells.indices.contains(index) else { return }
        cells[index].isEnabled = enabled
    }

    public var isEnabled: Bool {
        get { cells.contains(where: \.isEnabled) }
        set { cells.forEach { $0.isEnabled = newValue } }
    }
}

public final class CanonSwitch: NSSwitch {
    private var handlers: [(CanonSwitch) -> Void] = []

    public var isOn: Bool {
        get { state == .on }
        set { state = newValue ? .on : .off }
    }

    public init(isOn: Bool = false) {
        super.init(frame: .zero)
        controlSize = .small
        self.isOn = isOn
        target = self
        action = #selector(changed)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func changed() {
        handlers.forEach { $0(self) }
    }

    @discardableResult
    public func onChange(_ handler: @escaping (CanonSwitch) -> Void) -> Self {
        handlers.append(handler)
        return self
    }
}

extension CanonGrid {
    public static func switches(
        _ options: [(title: String, isOn: Bool)],
        columns: Int? = nil,
        onChange: @escaping (Int, Bool) -> Void
    ) -> CanonGrid {
        CanonGrid(columns: columns, options.enumerated().map { index, option in
            CanonRow(option.title, control: CanonSwitch(isOn: option.isOn).onChange { onChange(index, $0.isOn) })
        })
    }
}

public final class CanonStatus: NSTextField {
    public enum Tone { case ok, warn, muted }

    public var tone: Tone {
        didSet { textColor = Self.colour(tone) }
    }

    public init(_ text: String, _ tone: Tone) {
        self.tone = tone
        super.init(frame: .zero)
        stringValue = text
        isEditable = false
        isSelectable = false
        isBezeled = false
        drawsBackground = false
        font = .delphiCaption
        textColor = Self.colour(tone)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// A status that wraps onto as many lines as it needs.
    public static func wrapping(_ text: String, _ tone: Tone) -> CanonStatus {
        let status = CanonStatus(text, tone)
        status.maximumNumberOfLines = 0
        status.lineBreakMode = .byWordWrapping
        status.cell?.wraps = true
        status.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return status
    }

    public static func row(_ text: String, _ tone: Tone) -> NSView {
        row(CanonStatus(text, tone))
    }

    public static func row(_ status: CanonStatus) -> NSView {
        let row = CanonView(fill: .delphiCard)
        row.pin(status, insets: canonInsets(vertical: 10, horizontal: DelphiMetrics.panelPadding))
        return row
    }

    private static func colour(_ tone: Tone) -> NSColor {
        switch tone {
        case .ok: .delphiPrimary
        case .warn: .delphiDestructive
        case .muted: .delphiMutedForeground
        }
    }
}

// 10 pt inset, centred
final class CanonTextFieldCell: NSTextFieldCell {
    private func inset(_ rect: NSRect) -> NSRect {
        let height = cellSize(forBounds: rect).height
        return NSRect(x: rect.minX + 10, y: rect.midY - height / 2, width: rect.width - 20, height: height)
    }

    override func drawingRect(forBounds rect: NSRect) -> NSRect { inset(super.drawingRect(forBounds: rect)) }

    // background spans the inset
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        if drawsBackground, let backgroundColor {
            backgroundColor.setFill()
            cellFrame.fill()
        }
        drawInterior(withFrame: cellFrame, in: controlView)
    }

    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        super.edit(withFrame: inset(rect), in: controlView, editor: textObj, delegate: delegate, event: event)
    }

    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        super.select(withFrame: inset(rect), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }
}

/// Calls its change handlers on every edit.
open class CanonTextCell: NSTextField {
    private let idealWidth: CGFloat
    private var handlers: [(CanonTextCell) -> Void] = []
    public var onBeginEditing: ((CanonTextCell) -> Void)?
    /// Runs when editing ends: return, tab or focus moving away.
    public var onEndEditing: ((CanonTextCell) -> Void)?

    public init(text: String = "", placeholder: String = "", width: CGFloat = 180) {
        idealWidth = width
        super.init(frame: .zero)
        cell = CanonTextFieldCell(textCell: text)
        isEditable = true
        isSelectable = true
        isBezeled = false
        isBordered = false
        drawsBackground = true
        backgroundColor = .delphiCard
        textColor = .delphiForeground
        font = .delphiBody
        focusRingType = .none
        usesSingleLineMode = true
        cell?.isScrollable = true
        placeholderString = placeholder
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    open override var intrinsicContentSize: NSSize {
        NSSize(width: idealWidth, height: DelphiMetrics.controlHeight)
    }

    open override func textDidBeginEditing(_ notification: Notification) {
        super.textDidBeginEditing(notification)
        onBeginEditing?(self)
    }

    public var isEditing: Bool { currentEditor() != nil }

    open override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        onEndEditing?(self)
    }

    open override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        handlers.forEach { $0(self) }
    }

    @discardableResult
    public func onChange(_ handler: @escaping (CanonTextCell) -> Void) -> Self {
        handlers.append(handler)
        return self
    }
}

public final class CanonNumberField: CanonView {
    private let field = CanonTextCell(width: 48)
    private let step: Int
    private var handlers: [(CanonNumberField) -> Void] = []

    public var range: ClosedRange<Int> {
        didSet { value = min(max(value, range.lowerBound), range.upperBound) }
    }

    public var value: Int {
        didSet {
            value = min(max(value, range.lowerBound), range.upperBound)
            if field.currentEditor() == nil { field.stringValue = String(value) }
        }
    }

    public init(value: Int, range: ClosedRange<Int> = 0...Int.max, step: Int = 1, unit: String? = nil) {
        self.range = range
        self.value = min(max(value, range.lowerBound), range.upperBound)
        self.step = step
        super.init(fill: .delphiBorder)
        field.stringValue = String(self.value)
        field.font = .delphi(13, weight: .semibold)
        field.alignment = .right
        // invalid input reverts
        field.onEndEditing = { [unowned self] in $0.stringValue = String(self.value) }
        field.onChange { [unowned self] field in
            guard let typed = Int(field.stringValue), self.range.contains(typed), typed != self.value else { return }
            self.value = typed
            handlers.forEach { $0(self) }
        }

        let middle = CanonView(fill: .delphiCard)
        let inner = NSStackView(views: [field])
        inner.spacing = 4
        if let unit {
            let label = NSTextField.canon(unit, size: 11, colour: .delphiMutedForeground)
            label.setContentHuggingPriority(.required, for: .horizontal)
            inner.addArrangedSubview(label)
        }
        middle.pin(inner, insets: NSEdgeInsets(top: 0, left: 0, bottom: 0, right: unit == nil ? 0 : 10))
        let minus = CanonButton("−", kind: .cell, repeats: true) { [unowned self] in nudge(-step) }
        minus.accessibilityTitle = String(localized: "Decrease")
        let plus = CanonButton("+", kind: .cell, repeats: true) { [unowned self] in nudge(step) }
        plus.accessibilityTitle = String(localized: "Increase")
        pin(CanonStack([minus, middle, plus], vertical: false))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @discardableResult
    public func onChange(_ handler: @escaping (CanonNumberField) -> Void) -> Self {
        handlers.append(handler)
        return self
    }

    private func nudge(_ delta: Int) {
        let (sum, overflow) = value.addingReportingOverflow(delta)
        let before = value
        value = overflow ? (delta > 0 ? range.upperBound : range.lowerBound) : sum
        field.stringValue = String(value)
        if value != before { handlers.forEach { $0(self) } }
    }
}
