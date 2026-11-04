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
    private var contentWidth: CGFloat = 0
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

    /// - Parameter remeasure: false for hover, press and enabled changes, which keep the width.
    private func refresh(remeasure: Bool = true) {
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
        guard remeasure else { return }
        let width = content.fittingSize.width + sideInset * 2
        if width != contentWidth {
            contentWidth = width
            invalidateIntrinsicContentSize()
        }
    }

    public override var intrinsicContentSize: NSSize {
        NSSize(width: contentWidth, height: NSView.noIntrinsicMetric)
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
        refresh(remeasure: false)
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

/// A decimal to type or step, kept in a range and rounded to `decimals`. Typing commits once it pauses.
public final class CanonDecimalField: CanonView {
    public private(set) var value = 0.0
    private var range = 0.0...0.0
    private let field = CanonTextCell(width: 72)
    private let typing = CanonDebounce()
    private let step: Double
    private let decimals: Int
    private var handlers: [(CanonDecimalField) -> Void] = []

    public init(unit: String, step: Double = 0.1, decimals: Int = 3) {
        self.step = step
        self.decimals = decimals
        super.init(fill: .delphiBorder)
        field.font = .delphiMono(13, weight: .semibold)
        field.alignment = .right
        field.onChange { [unowned self] _ in typing.after(CanonDebounce.typingDelay) { [weak self] in self?.commit() } }
        field.onEndEditing = { [unowned self] in
            commit()
            $0.stringValue = format(value)
        }
        let label = NSTextField.canon(unit, size: 11, colour: .delphiMutedForeground)
        label.setContentHuggingPriority(.required, for: .horizontal)
        let inner = NSStackView(views: [field, label])
        inner.spacing = 4
        let middle = CanonView(fill: .delphiCard)
        middle.pin(inner, insets: NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        let minus = CanonButton("−", kind: .cell, repeats: true) { [unowned self] in set(value - self.step) }
        minus.accessibilityTitle = String(localized: "Decrease")
        let plus = CanonButton("+", kind: .cell, repeats: true) { [unowned self] in set(value + self.step) }
        plus.accessibilityTitle = String(localized: "Increase")
        pin(CanonStack([minus, middle, plus], vertical: false))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func setAccessibilityLabel(_ label: String?) {
        field.setAccessibilityLabel(label)
    }

    @discardableResult
    public func onChange(_ handler: @escaping (CanonDecimalField) -> Void) -> Self {
        handlers.append(handler)
        return self
    }

    /// Shows a value set from code; no handler runs.
    public func show(_ value: Double, range: ClosedRange<Double>) {
        self.value = value
        self.range = range
        if !field.isEditing { field.stringValue = format(value) }
    }

    private func set(_ next: Double) {
        let grain = pow(10, Double(decimals))
        let clamped = min(max((next * grain).rounded() / grain, range.lowerBound), range.upperBound)
        guard clamped != value else { return }
        value = clamped
        if !field.isEditing { field.stringValue = format(value) }
        handlers.forEach { $0(self) }
    }

    private func commit() {
        typing.cancel()
        if let typed = Double(field.stringValue.replacingOccurrences(of: ",", with: ".")) { set(typed) }
    }

    private static let posix = Locale(identifier: "en_US_POSIX")

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...decimals)).grouping(.never).locale(Self.posix))
    }
}

/// A large centred number to type, its unit under it, and step cells either side; the caller reads and steps the text.
public final class CanonBigNumberField: CanonView {
    public let field = CanonTextCell(width: 0)
    public let unit = NSTextField.canon(size: 11, weight: .bold, colour: .delphiMutedForeground)
    public var onEndEditing: (() -> Void)?

    /// - Parameter onStep: called with -1 or 1.
    public init(placeholder: String, unit text: String? = nil, onStep: @escaping (Int) -> Void) {
        super.init(fill: .delphiBorder)
        field.placeholderString = placeholder
        field.font = .delphiMono(32, weight: .bold)
        field.alignment = .center
        field.onEndEditing = { [unowned self] _ in onEndEditing?() }
        unit.stringValue = text ?? ""
        unit.alignment = .center
        let middle = CanonView(fill: .delphiCard)
        middle.pin(CanonStack([field, unit], spacing: 4), insets: NSEdgeInsets(top: 16, left: 0, bottom: 12, right: 0))
        let minus = CanonButton("−", kind: .cell, repeats: true) { onStep(-1) }
        minus.accessibilityTitle = String(localized: "Decrease")
        let plus = CanonButton("+", kind: .cell, repeats: true) { onStep(1) }
        plus.accessibilityTitle = String(localized: "Increase")
        for cell in [minus, plus] { cell.widthAnchor.constraint(equalToConstant: DelphiMetrics.rowHeight).isActive = true }
        pin(CanonStack([minus, middle, plus], vertical: false))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// A card row with a symbol, a text cell and, with `clears`, a clear cell that shows while there is text. Typing
/// reaches `onChange` once it pauses; Clear and `set` reach it at once.
public final class CanonSearchField: CanonView {
    public let field: CanonTextCell
    public var onChange: ((String) -> Void)?
    private let typing = CanonDebounce()
    private lazy var clear: CanonButton = CanonButton("", systemImage: "xmark.circle.fill", kind: .cell) { [unowned self] in set("") }

    public init(placeholder: String, symbol: String = "magnifyingglass", clears: Bool = true, width: CGFloat = 240) {
        field = CanonTextCell(placeholder: placeholder, width: width)
        super.init(fill: .delphiCard)
        let icon = NSImageView(image: .canonSymbol(symbol, size: 12) ?? NSImage())
        icon.contentTintColor = .delphiMutedForeground
        icon.setContentHuggingPriority(.required, for: .horizontal)
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let row = NSStackView(views: clears ? [icon, field, clear] : [icon, field])
        row.distribution = .fill
        row.spacing = 0
        row.edgeInsets = NSEdgeInsets(top: 0, left: DelphiMetrics.panelPadding, bottom: 0, right: 0)
        pin(row)
        clear.accessibilityTitle = String(localized: "Clear")
        clear.isHidden = true
        field.onChange { [unowned self] field in
            clear.isHidden = field.stringValue.isEmpty
            typing.after(CanonDebounce.typingDelay) { [weak self] in self?.onChange?(field.stringValue) }
        }
    }

    public var text: String { field.stringValue }

    public func set(_ text: String) {
        typing.cancel()
        field.stringValue = text
        clear.isHidden = text.isEmpty
        onChange?(text)
    }
}
