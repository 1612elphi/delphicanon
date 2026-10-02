import UIKit

public final class CanonButton: UIButton {

    public enum Kind {
        case primary
        case secondary
        /// grid draws the lines
        case cell
        case segment
    }

    public enum Icon {
        case inline
        case oversized
    }

    public let kind: Kind
    private var watermark: UIImageView?

    /// narrow grids hide titles
    public var text: String {
        didSet {
            guard text != oldValue else { return }
            if !text.isEmpty { accessibilityLabel = text }
            setNeedsUpdateConfiguration()
        }
    }

    public var systemImage: String? {
        didSet { if systemImage != oldValue { setNeedsUpdateConfiguration() } }
    }

    /// set by enclosing grid
    public var isSymbolOnly = false {
        didSet { if isSymbolOnly != oldValue { setNeedsUpdateConfiguration() } }
    }

    /// asked by enclosing grid
    public func titleFits(in width: CGFloat) -> Bool {
        guard !text.isEmpty, let systemImage, watermark == nil, kind == .primary || kind == .secondary, width > 0 else { return true }
        let title = (text as NSString).size(withAttributes: [.font: UIFont.delphi(.body, weight: .semibold)]).width
        let symbol = UIImage(systemName: systemImage, withConfiguration: UIImage.SymbolConfiguration(textStyle: .footnote))?.size.width ?? 0
        // insets, padding, slack: 38
        return title + symbol + 38 <= width
    }

    private var showsTitle: Bool { !text.isEmpty && !(isSymbolOnly && systemImage != nil) }
    /// fractions of height, degrees
    public static let oversized = (side: 1.5, inset: 0.34, drop: 0.62, turn: -14.0, alpha: (plain: 0.06, filled: 0.12))
    private var isHovering = false {
        didSet { if isHovering != oldValue { setNeedsUpdateConfiguration() } }
    }

    private var copiedRevert: DispatchWorkItem?
    private var beforeCopied: (text: String, systemImage: String?)?

    public func flashCopied() {
        flash(String(localized: "Copied"), systemImage: "checkmark")
    }

    /// reverts after 1.5 s
    public func flash(_ title: String, systemImage symbol: String) {
        if beforeCopied == nil { beforeCopied = (text, systemImage) }
        text = title
        systemImage = symbol
        copiedRevert?.cancel()
        let revert = DispatchWorkItem { [weak self] in
            guard let self, let before = beforeCopied else { return }
            (text, systemImage, beforeCopied) = (before.text, before.systemImage, nil)
        }
        copiedRevert = revert
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: revert)
    }

    /// seconds: delay, interval, fast
    public static let repeatTiming = (delay: 0.4, interval: 0.09, fast: 0.04)
    private var holdTimer: Timer?
    private var didRepeat = false

    /// repeats: hold repeats action
    public init(_ title: String, systemImage: String? = nil, icon: Icon = .inline, kind: Kind = .secondary, repeats: Bool = false, action: (() -> Void)? = nil) {
        self.kind = kind
        text = title
        self.systemImage = systemImage
        super.init(frame: .zero)
        if !title.isEmpty { accessibilityLabel = title }
        if icon == .oversized, let systemImage,
           let symbol = UIImage(systemName: systemImage, withConfiguration: UIImage.SymbolConfiguration(pointSize: 96, weight: .bold)) {
            let watermark = UIImageView(image: symbol)
            watermark.contentMode = .scaleAspectFit
            clipsToBounds = true
            addSubview(watermark)
            self.watermark = watermark
        }

        var config = UIButton.Configuration.plain()
        config.imagePadding = 6
        config.titleLineBreakMode = .byTruncatingTail
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        config.background.cornerRadius = 0
        configuration = config

        configurationUpdateHandler = { button in
            guard let button = button as? CanonButton, var config = button.configuration else { return }
            let titled = button.showsTitle
            config.title = titled ? button.text : nil
            config.image = button.watermark == nil ? button.systemImage.flatMap { UIImage(systemName: $0) } : nil
            config.preferredSymbolConfigurationForImage = titled
                ? UIImage.SymbolConfiguration(textStyle: .footnote)
                : UIImage.SymbolConfiguration(textStyle: .body, scale: .medium).applying(UIImage.SymbolConfiguration(weight: .semibold))
            let filled = button.kind == .primary || (button.isSelected && (button.kind == .segment || button.kind == .secondary))
            let style: UIFont.TextStyle = button.kind == .segment ? .subheadline : .body
            let weight: UIFont.Weight = filled ? .semibold : .medium
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var attributes = attributes
                attributes.font = UIFont.delphi(style, weight: weight)
                return attributes
            }
            let ink: UIColor = !filled ? .delphiForeground : button.isEnabled ? .delphiPrimaryForeground : .delphiMutedForeground
            config.baseForegroundColor = button.isEnabled || filled ? ink : ink.withAlphaComponent(0.4)
            let hovering = button.isHovering && button.isEnabled
            config.background.backgroundColor = if filled && !button.isEnabled {
                .delphiMuted
            } else if filled {
                hovering ? .delphiPrimary.mixed(with: .delphiPrimaryForeground, by: CanonMotion.filledHoverMix) : .delphiPrimary
            } else {
                hovering ? .delphiAccentBG : .delphiCard
            }
            button.configuration = config
            button.alpha = button.isHighlighted ? 0.75 : 1
            button.watermark?.tintColor = ink
            button.watermark?.alpha = filled ? CanonButton.oversized.alpha.filled : CanonButton.oversized.alpha.plain
        }

        let fills = kind == .primary || kind == .secondary
        // hugging below compression resistance
        setContentHuggingPriority(fills ? .defaultLow : .init(260), for: .horizontal)
        let minimum: CGFloat = switch kind {
        case .primary: DelphiMetrics.primaryHeight
        case .secondary: DelphiMetrics.secondaryHeight
        case .cell, .segment: DelphiMetrics.controlHeight
        }
        let height = heightAnchor.constraint(greaterThanOrEqualToConstant: minimum)
        height.priority = .init(999)
        height.isActive = true

        if let action {
            addAction(UIAction { [unowned self] _ in
                // hold release: no step
                if !didRepeat { action() }
                didRepeat = false
            }, for: .primaryActionTriggered)
            if repeats { repeatWhileHeld(action) }
        }
        animatesPress()
        tracksHover { [unowned self] in isHovering = $0 }
        if systemImage?.hasPrefix("square.and.arrow.up") == true { followsWorkflow() }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var shareLook: (text: String, systemImage: String?)?
    private var isFollowingWorkflow = false

    /// On a workflow step, exports are captured and handed on, so the button says so. Share buttons call this
    /// themselves; call it on any other button whose action exports the tool's file.
    public func followsWorkflow() {
        guard !isFollowingWorkflow else { return }
        isFollowingWorkflow = true
        canonObserve(self) { [weak self] in
            guard let self else { return }
            let passes = CanonHost.capturesFiles()
            if passes, shareLook == nil {
                shareLook = (text, systemImage)
                if !text.isEmpty { text = String(localized: "Pass along") }
                systemImage = "arrow.right"
            } else if !passes, let look = shareLook {
                (text, systemImage, shareLook) = (look.text, look.systemImage, nil)
            } else {
                return
            }
            watermark?.image = systemImage.flatMap { UIImage(systemName: $0, withConfiguration: UIImage.SymbolConfiguration(pointSize: 96, weight: .bold)) }
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let watermark else { return }
        // configuration reorders subviews
        if let titleLabel, let title = subviews.firstIndex(of: titleLabel), let mark = subviews.firstIndex(of: watermark), mark > title {
            insertSubview(watermark, belowSubview: titleLabel)
        }
        let tuning = Self.oversized
        let side = bounds.height * tuning.side
        let mirrored = effectiveUserInterfaceLayoutDirection == .rightToLeft
        watermark.bounds = CGRect(x: 0, y: 0, width: side, height: side)
        watermark.center = CGPoint(x: mirrored ? side * tuning.inset : bounds.width - side * tuning.inset, y: bounds.height * tuning.drop)
        watermark.transform = CGAffineTransform(rotationAngle: (mirrored ? -1 : 1) * tuning.turn * .pi / 180)
    }

    // MARK: Menu as primary action

    /// menu steals press touches
    private var isMenuShown = false
    private var showsMenu: Bool { showsMenuAsPrimaryAction && menu != nil }

    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if showsMenu { CanonMotion.press(self, at: touch.location(in: self)) }
        return super.beginTracking(touch, with: event)
    }

    public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        if showsMenu, !isMenuShown { CanonMotion.release(self, from: touch?.location(in: self)) }
    }

    public override func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        if showsMenu, !isMenuShown { CanonMotion.release(self, from: nil) }
    }

    public override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: (any UIContextMenuInteractionAnimating)?) {
        super.contextMenuInteraction(interaction, willDisplayMenuFor: configuration, animator: animator)
        guard showsMenu else { return }
        isMenuShown = true
        CanonMotion.press(self, at: nil)
    }

    public override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: (any UIContextMenuInteractionAnimating)?) {
        super.contextMenuInteraction(interaction, willEndFor: configuration, animator: animator)
        guard isMenuShown else { return }
        isMenuShown = false
        CanonMotion.release(self, from: nil)
    }

    private func repeatWhileHeld(_ action: @escaping () -> Void) {
        addAction(UIAction { [unowned self] _ in
            didRepeat = false
            schedule(after: Self.repeatTiming.delay, count: 0, action)
        }, for: .touchDown)
        addAction(UIAction { [unowned self] _ in holdTimer?.invalidate() }, for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
    }

    private func schedule(after seconds: TimeInterval, count: Int, _ action: @escaping () -> Void) {
        holdTimer?.invalidate()
        let timer = Timer(timeInterval: seconds, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.isEnabled, self.isTracking else { return }
                self.didRepeat = true
                action()
                self.schedule(after: count < 10 ? Self.repeatTiming.interval : Self.repeatTiming.fast, count: count + 1, action)
            }
        }
        // default mode pauses scrolling
        RunLoop.main.add(timer, forMode: .common)
        holdTimer = timer
    }

}

extension CanonButton {
    /// Whether the button shows its workflow look and hands the export on.
    public var passesAlong: Bool { shareLook != nil }
}

/// sends .valueChanged
public final class CanonSegmented: UIControl {
    private let cells: [CanonButton]

    public var selectedIndex: Int {
        didSet { if selectedIndex != oldValue { cells.enumerated().forEach { $1.isSelected = $0 == selectedIndex } } }
    }

    public init(_ titles: [String], selected: Int = 0, columns: Int? = nil, boxed: Bool = false) {
        selectedIndex = selected
        cells = titles.map { CanonButton($0, kind: .segment) }
        super.init(frame: .zero)
        for (index, cell) in cells.enumerated() {
            cell.isSelected = index == selected
            cell.addAction(UIAction { [unowned self] _ in
                guard selectedIndex != index else { return }
                selectedIndex = index
                sendActions(for: .valueChanged)
            }, for: .primaryActionTriggered)
        }
        pin(CanonGrid(columns: columns, boxed: boxed, cells))
    }

    /// labels: voiceover text
    public convenience init(symbols: [String], labels: [String], selected: Int = 0, columns: Int? = nil) {
        precondition(symbols.count == labels.count)
        self.init(labels, selected: selected, columns: columns)
        for (cell, (symbol, label)) in zip(cells, zip(symbols, labels)) {
            cell.text = ""
            cell.systemImage = symbol
            cell.accessibilityLabel = label
        }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private lazy var cellEnabled = Array(repeating: true, count: cells.count)

    public override var isEnabled: Bool {
        didSet { applyEnabled() }
    }

    public func setEnabled(_ enabled: Bool, at index: Int) {
        guard cells.indices.contains(index) else { return }
        cellEnabled[index] = enabled
        applyEnabled()
    }

    private func applyEnabled() {
        for (cell, enabled) in zip(cells, cellEnabled) { cell.isEnabled = isEnabled && enabled }
    }
}

public final class CanonSwitch: UISwitch {
    public init(isOn: Bool = false) {
        super.init(frame: .zero)
        self.isOn = isOn
        onTintColor = .delphiPrimary
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

extension CanonGrid {
    public static func switches(
        _ options: [(title: String, isOn: Bool)],
        columns: Int? = nil,
        onChange: @escaping (Int, Bool) -> Void
    ) -> CanonGrid {
        let longest = options.map(\.title).max { $0.count < $1.count }
        return CanonGrid(columns: columns, options.enumerated().map { index, option in
            let row = CanonRow(option.title, control: CanonSwitch(isOn: option.isOn).onChange { onChange(index, $0.isOn) })
            row.sizingTitle = longest
            return row
        })
    }
}

public final class CanonStatus: UILabel {
    public enum Tone { case ok, warn, muted }

    public var tone: Tone {
        didSet { textColor = Self.colour(tone) }
    }

    public init(_ text: String, _ tone: Tone) {
        self.tone = tone
        super.init(frame: .zero)
        self.text = text
        font = .delphi(.caption1)
        adjustsFontForContentSizeCategory = true
        textColor = Self.colour(tone)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public static func row(_ text: String, _ tone: Tone) -> UIView {
        row(CanonStatus(text, tone))
    }

    public static func row(_ status: CanonStatus) -> UIView {
        let row = UIView()
        row.backgroundColor = .delphiCard
        let padding = DelphiMetrics.panelPadding
        row.pin(status, insets: NSDirectionalEdgeInsets(top: 10, leading: padding, bottom: 10, trailing: padding))
        return row
    }

    private static func colour(_ tone: Tone) -> UIColor {
        switch tone {
        case .ok: .delphiPrimary
        case .warn: .delphiDestructive
        case .muted: .delphiMutedForeground
        }
    }
}

/// sends .valueChanged per edit
open class CanonTextCell: UITextField, UITextFieldDelegate {
    private let idealWidth: CGFloat

    public init(text: String = "", placeholder: String = "", width: CGFloat = 180) {
        idealWidth = width
        super.init(frame: .zero)
        self.text = text
        self.placeholder = placeholder
        backgroundColor = .delphiCard
        textColor = .delphiForeground
        tintColor = .delphiPrimary
        font = .delphi(.body)
        adjustsFontForContentSizeCategory = true
        returnKeyType = .done
        delegate = self
        addAction(UIAction { [unowned self] _ in sendActions(for: .valueChanged) }, for: .editingChanged)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: idealWidth, height: DelphiMetrics.controlHeight)
    }

    public override func textRect(forBounds bounds: CGRect) -> CGRect { bounds.insetBy(dx: 10, dy: 0) }
    public override func editingRect(forBounds bounds: CGRect) -> CGRect { bounds.insetBy(dx: 10, dy: 0) }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        resignFirstResponder()
        return true
    }
}

/// middle tap focuses field
public final class CanonStepper: UIView {
    /// nil insets: centred
    public init(centre: UIView, field: UITextField, insets: NSDirectionalEdgeInsets? = nil, onStep: @escaping (Int) -> Void) {
        super.init(frame: .zero)
        backgroundColor = .delphiBorder
        let cell = UIControl()
        cell.backgroundColor = .delphiCard
        cell.addAction(UIAction { [weak field] _ in field?.becomeFirstResponder() }, for: .touchUpInside)
        if let insets {
            cell.pin(centre, insets: insets)
        } else {
            centre.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(centre)
            NSLayoutConstraint.activate([
                centre.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 10),
                cell.trailingAnchor.constraint(equalTo: centre.trailingAnchor, constant: 10),
                centre.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            ])
        }
        let minus = CanonButton("", systemImage: "minus", kind: .cell, repeats: true) { onStep(-1) }
        minus.accessibilityLabel = String(localized: "Decrease")
        let plus = CanonButton("", systemImage: "plus", kind: .cell, repeats: true) { onStep(1) }
        plus.accessibilityLabel = String(localized: "Increase")
        let stack = UIStackView(arrangedSubviews: [minus, cell, plus])
        stack.spacing = DelphiMetrics.hairline
        pin(stack)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// sends .valueChanged
public final class CanonNumberField: UIControl, UITextFieldDelegate {
    public var range: ClosedRange<Int> {
        didSet { value = min(max(value, range.lowerBound), range.upperBound) }
    }
    private let field = UITextField()

    public var value: Int {
        didSet {
            value = min(max(value, range.lowerBound), range.upperBound)
            if !field.isEditing { field.text = String(value) }
        }
    }

    public init(value: Int, range: ClosedRange<Int> = 0...Int.max, step: Int = 1, unit: String? = nil) {
        self.range = range
        self.value = min(max(value, range.lowerBound), range.upperBound)
        super.init(frame: .zero)

        field.text = String(self.value)
        field.font = .delphi(.body, weight: .semibold)
        field.adjustsFontForContentSizeCategory = true
        field.textColor = .delphiForeground
        field.tintColor = .delphiPrimary
        field.textAlignment = .right
        field.keyboardType = range.lowerBound < 0 ? .numbersAndPunctuation : .numberPad
        field.delegate = self
        field.widthAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        field.addAction(UIAction { [unowned self] _ in
            guard let typed = Int(field.text ?? ""), range.contains(typed), typed != self.value else { return }
            self.value = typed
            sendActions(for: .valueChanged)
        }, for: .editingChanged)

        let middle = UIStackView(arrangedSubviews: [field])
        middle.spacing = 4
        middle.alignment = .firstBaseline
        if let unit {
            let label = UILabel.canon(unit, .caption1, colour: .delphiMutedForeground)
            label.setContentHuggingPriority(.required, for: .horizontal)
            middle.addArrangedSubview(label)
        }
        pin(CanonStepper(centre: middle, field: field) { [unowned self] direction in nudge(direction * step) })
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func nudge(_ delta: Int) {
        let (sum, overflow) = value.addingReportingOverflow(delta)
        let next = overflow ? (delta > 0 ? range.upperBound : range.lowerBound) : sum
        let before = value
        value = next
        field.text = String(value)
        if value != before { sendActions(for: .valueChanged) }
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        field.text = String(value)
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

/// pull away: finer drag
public final class CanonSlider: UIControl {
    /// clamps, sends no action
    public var range: ClosedRange<Double> {
        didSet {
            guard range != oldValue else { return }
            value = min(max(value, range.lowerBound), range.upperBound)
        }
    }

    /// multiples above lower bound
    public var step: Double?

    /// distances in points
    public static let fineTiers: [(distance: CGFloat, speed: Double)] = [(60, 0.5), (120, 0.25), (180, 0.1)]
    private let readout: (Double) -> String
    private let track = Track()

    public var fillsFromTrailing = false {
        didSet { track.isReversed = fillsFromTrailing }
    }
    private let label = UILabel.canon(nil, .body, weight: .semibold)

    public var value: Double {
        didSet { refresh() }
    }

    public init(
        value: Double,
        range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        readout: @escaping (Double) -> String = { "\(Int(($0 * 100).rounded()))%" }
    ) {
        self.value = value
        self.range = range
        self.step = step
        self.readout = readout
        super.init(frame: .zero)
        backgroundColor = .delphiBorder

        track.backgroundColor = .delphiMuted
        track.isUserInteractionEnabled = false
        track.clipsToBounds = true
        let ideal = track.widthAnchor.constraint(equalToConstant: 160)
        ideal.priority = .defaultLow
        ideal.isActive = true
        track.widthAnchor.constraint(greaterThanOrEqualToConstant: 96).isActive = true

        label.textAlignment = .center
        label.numberOfLines = 1
        let cell = UIView()
        cell.backgroundColor = .delphiCard
        cell.isUserInteractionEnabled = false
        cell.pin(label, insets: NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
        cell.widthAnchor.constraint(greaterThanOrEqualToConstant: 64).isActive = true
        cell.setContentHuggingPriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [track, cell])
        stack.spacing = DelphiMetrics.hairline
        stack.isUserInteractionEnabled = false
        pin(stack)
        heightAnchor.constraint(greaterThanOrEqualToConstant: DelphiMetrics.controlHeight).isActive = true

        isAccessibilityElement = true
        accessibilityTraits = .adjustable
        tracksHover { [unowned self] in isHovering = $0 }
        refresh()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var fraction: CGFloat {
        span > 0 ? CGFloat((value - range.lowerBound) / span) : 0
    }

    private var isRightToLeft: Bool { effectiveUserInterfaceLayoutDirection == .rightToLeft }

    private func refresh() {
        label.text = readout(value)
        accessibilityValue = label.text
        track.fraction = fraction
    }

    private final class Track: UIView {
        private let fill = UIView()
        private let marker = UIView()

        public var fraction: CGFloat = 0 {
            didSet { setNeedsLayout() }
        }

        public var isReversed = false {
            didSet { setNeedsLayout() }
        }

        public var isActive = false {
            didSet {
                guard isActive != oldValue else { return }
                setNeedsLayout()
                UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) { self.layoutIfNeeded() }
            }
        }

        public override init(frame: CGRect) {
            super.init(frame: frame)
            fill.backgroundColor = .delphiPrimary
            marker.backgroundColor = .delphiForeground
            addSubview(fill)
            addSubview(marker)
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        public override func layoutSubviews() {
            super.layoutSubviews()
            let width = bounds.width * fraction
            let thickness: CGFloat = isActive ? 6 : 2
            let edge = max(0, width - thickness)
            let flipped = (effectiveUserInterfaceLayoutDirection == .rightToLeft) != isReversed
            fill.frame = CGRect(x: flipped ? bounds.width - width : 0, y: 0, width: width, height: bounds.height)
            marker.frame = CGRect(x: flipped ? bounds.width - edge - thickness : edge, y: 0, width: thickness, height: bounds.height)
        }
    }

    private func set(_ raw: Double) {
        var next = min(max(raw, range.lowerBound), range.upperBound)
        if let step, step > 0 {
            next = min(range.upperBound, range.lowerBound + ((next - range.lowerBound) / step).rounded() * step)
        }
        guard next != value else { return }
        value = next
        sendActions(for: .valueChanged)
    }

    private var span: Double { range.upperBound - range.lowerBound }
    // rtl xor trailing fill
    private var runsBackwards: Bool { isRightToLeft != fillsFromTrailing }

    private func position(of touch: UITouch) -> Double? {
        let frame = track.convert(track.bounds, to: self)
        guard frame.width > 0 else { return nil }
        var unit = (touch.location(in: self).x - frame.minX) / frame.width
        if runsBackwards { unit = 1 - unit }
        return range.lowerBound + Double(min(max(unit, 0), 1)) * span
    }

    private func follow(_ touch: UITouch) {
        if let position = position(of: touch) { set(position) }
    }

    private var isHovering = false {
        didSet { track.isActive = isHovering || isTracking }
    }

    /// until then, page scrolls
    public private(set) var isDragging = false
    public override var canonKeepsTouch: Bool { isDragging }
    private var touchStart = CGPoint.zero
    private var lastX: CGFloat = 0
    // unsnapped drag accumulator
    private var dragged = 0.0
    private var speed = 1.0
    private let tick = UISelectionFeedbackGenerator()

    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        touchStart = touch.location(in: self)
        isDragging = false
        speed = 1
        track.isActive = true
        return true
    }

    public override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let point = touch.location(in: self)
        if !isDragging {
            let dx = abs(point.x - touchStart.x)
            guard dx > 4, dx > abs(point.y - touchStart.y), let position = position(of: touch) else { return true }
            // absolute first, then relative
            isDragging = true
            dragged = position
            lastX = point.x
            tick.prepare()
            set(dragged)
            return true
        }

        let distance = abs(point.y - bounds.midY)
        let next = Self.fineTiers.last { distance >= $0.distance }?.speed ?? 1
        if next != speed {
            speed = next
            tick.selectionChanged()
        }
        let width = max(1, track.bounds.width)
        let delta = Double((point.x - lastX) / width) * span * speed
        lastX = point.x
        dragged = min(max(dragged + (runsBackwards ? -delta : delta), range.lowerBound), range.upperBound)
        set(dragged)
        return true
    }

    public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if !isDragging, let touch, track.convert(track.bounds, to: self).contains(touch.location(in: self)) { follow(touch) }
        isDragging = false
        track.isActive = isHovering
    }

    public override func cancelTracking(with event: UIEvent?) {
        isDragging = false
        track.isActive = isHovering
    }

    private var accessibilityStep: Double { step ?? (range.upperBound - range.lowerBound) / 20 }
    public override func accessibilityIncrement() { set(value + accessibilityStep) }
    public override func accessibilityDecrement() { set(value - accessibilityStep) }
}

#if DEBUG
public enum CanonSelfCheck {
    public static func selfCheck() {
        assert(CanonGrid.balanced(5, perRow: 3) == [3, 2])
        assert(CanonGrid.balanced(7, perRow: 3) == [3, 2, 2])
        assert(CanonGrid.balanced(4, perRow: 9) == [4])
        assert(CanonGrid.balanced(0, perRow: 3).isEmpty)

        assert(CanonNumberField(value: 9000, range: 0...5000).value == 5000)
        let field = CanonNumberField(value: 1, range: 0...Int.max, step: 50)
        field.value = Int.max
        assert(field.value == Int.max)

        let slider = CanonSlider(value: 99.4, range: 1...100, step: 1)
        slider.accessibilityIncrement()
        assert(slider.value == 100)
        slider.accessibilityIncrement()
        assert(slider.value == 100)

        let ranged = CanonSlider(value: 8, range: 0...10)
        ranged.range = 0...5
        assert(ranged.value == 5)

        let loader = CanonLoader(mode: .thinking)
        assert(loader.lit(0, at: 0) == 1 && loader.lit(0, at: 15) == 1 && loader.lit(0, at: 8) == 0)

        let named = CanonSlider(value: 0)
        let row = CanonRow("Hue", control: named)
        assert(named.accessibilityLabel == "Hue" && !row.titleLabel.isAccessibilityElement)
        row.setText(title: "Tone")
        assert(named.accessibilityLabel == "Tone")
        named.accessibilityLabel = "Own"
        row.setText(title: "Hue")
        assert(named.accessibilityLabel == "Own")
        let button = CanonButton("Hue", kind: .cell)
        CanonRow("Hue", control: button).setText(title: "Tone")
        assert(button.accessibilityLabel == "Hue")
    }
}
#endif
