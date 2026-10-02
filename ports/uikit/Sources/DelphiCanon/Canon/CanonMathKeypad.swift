import DelphiCore
import UIKit
import UIKit.UIGestureRecognizerSubclass

// MARK: - Families

/// Key colours by family. From the Braun ET66: cream digit keys, dark umber operator keys and one yellow key, Done. The tinted
/// families keep their colour on every page, so a structure is green, calculus blue and a letter clay wherever it sits.
public enum CanonMathFamily {
    case digit, operation, structure, calculus, letter, clear, done

    public var fill: UIColor {
        switch self {
        case .digit, .clear: .delphiCard
        case .operation: .mathUmber
        case .structure: Self.tints.structure
        case .calculus: Self.tints.calculus
        case .letter: Self.tints.letter
        case .done: .mathYellow
        }
    }

    public var ink: UIColor {
        switch self {
        case .digit: .delphiForeground
        case .operation: .mathCream
        case .structure: .mathGreen
        case .calculus: .mathBlue
        case .letter: .mathClay
        case .clear: .delphiDestructive
        case .done: .mathUmber
        }
    }

    /// The family's colour against the panel background: a submenu's frame.
    public var accent: UIColor {
        switch self {
        case .digit, .operation, .clear: .delphiForeground
        case .done: .mathUmber
        default: ink
        }
    }

    /// Share of the ink mixed into the card for a tinted key, in light and dark appearance.
    public static let tintShare = (light: 0.13, dark: 0.2)
    private static let tints = (structure: tinted(.mathGreen), calculus: tinted(.mathBlue), letter: tinted(.mathClay))

    private static func tinted(_ ink: UIColor) -> UIColor {
        UIColor { traits in
            let share = traits.userInterfaceStyle == .dark ? tintShare.dark : tintShare.light
            return UIColor.delphiCard.mixed(with: ink, by: share).resolvedColor(with: traits)
        }
    }

    /// The family a key belongs to wherever it appears, for keys placed outside the keypad.
    public static func of(_ key: CanonMathExpression.Key) -> CanonMathFamily {
        switch key {
        case .symbol(let symbol) where symbol.allSatisfy { $0.isNumber || $0 == "." }: .digit
        case .symbol(let symbol) where ["+", "\u{2212}", "\u{00D7}", "=", ","].contains(symbol): .operation
        case .symbol("!"), .series, .integral, .derivative, .limit, .binomial, .permutation: .calculus
        case .symbol: .letter
        case .divide, .delete: .operation
        case .clear: .clear
        default: .structure
        }
    }
}

// MARK: - Glyphs

/// A typeset box drawn in one colour, scaled down to fit and centred.
public final class CanonMathGlyphs: UIView {
    public var box: CanonMath.Box {
        didSet { setNeedsDisplay() }
    }

    public var colour: UIColor {
        didSet { if colour != oldValue { setNeedsDisplay() } }
    }

    public init(_ box: CanonMath.Box, colour: UIColor) {
        self.box = box
        self.colour = colour
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
        contentMode = .redraw
        redrawsOnStyleChange()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), box.width > 0, box.height > 0 else { return }
        let scale = min(1, bounds.width / box.width, bounds.height / box.height)
        context.translateBy(x: (bounds.width - box.width * scale) / 2, y: (bounds.height - box.height * scale) / 2 + box.ascent * scale)
        context.scaleBy(x: scale, y: scale)
        let resolved = colour.resolvedColor(with: traitCollection)
        for atom in box.atoms {
            CanonMath.draw(atom, in: atom.frame, colour: resolved, context: context)
        }
    }
}

// MARK: - Key

/// One key: a flush cell in its family's colours with one label, set large and centred. A tap does one thing. A key that
/// opens a submenu carries a chevron after its label. Holding a repeating key (delete) repeats it.
public final class CanonMathKeyView: UIView {
    public enum Face {
        case math(CanonMath.Box)
        /// An SF Symbol.
        case symbol(String)
        /// A word in the condensed sans.
        case word(String)
    }

    public let family: CanonMathFamily
    public var onTap: (() -> Void)?
    /// Holding repeats the tap, as delete does.
    public var repeats = false

    private let face: UIView
    private let chevron: UIImageView?
    private var repeatTimer: Timer?
    private var pressed = false
    private var drift: CGFloat = 0
    private var fade: CGFloat = 1
    private var isLit = false {
        didSet { if isLit != oldValue { backgroundColor = isLit ? family.fill.mixed(with: family.ink, by: 0.14) : family.fill } }
    }

    public init(face: Face, family: CanonMathFamily, label: String?, opensMenu: Bool = false) {
        self.family = family
        switch face {
        case .math(let box):
            self.face = CanonMathGlyphs(box, colour: family.ink)
        case .symbol(let name):
            let image = UIImageView(image: UIImage(systemName: name))
            image.tintColor = family.ink
            image.contentMode = .center
            image.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .title2)
                .applying(UIImage.SymbolConfiguration(weight: .medium))
            self.face = image
        case .word(let text):
            let word = UILabel.canon(text, .title3, weight: .semibold, colour: family.ink)
            word.textAlignment = .center
            word.numberOfLines = 1
            word.adjustsFontSizeToFitWidth = true
            word.minimumScaleFactor = 0.6
            self.face = word
        }
        if opensMenu {
            let mark = UIImageView(image: UIImage(systemName: "chevron.up"))
            mark.tintColor = family.ink.withAlphaComponent(0.6)
            mark.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
            chevron = mark
        } else {
            chevron = nil
        }
        super.init(frame: .zero)
        clipsToBounds = true
        backgroundColor = family.fill
        for view in [self.face, chevron].compactMap({ $0 }) {
            view.isUserInteractionEnabled = false
            addSubview(view)
        }
        addGestureRecognizer(CanonMathKeyStroke())
        tracksHover { [unowned self] in isLit = $0 || pressed }
        isAccessibilityElement = true
        accessibilityTraits = opensMenu ? .button : .keyboardKey
        accessibilityLabel = label
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        place()
    }

    /// The label's own offset inside the cell and its opacity, for a page sliding past.
    public func setDrift(_ x: CGFloat, fade: CGFloat) {
        guard x != drift || fade != self.fade else { return }
        drift = x
        self.fade = fade
        place()
    }

    private func place() {
        var area = bounds.insetBy(dx: 6, dy: 6)
        if let chevron {
            let size = chevron.intrinsicContentSize
            area = area.insetBy(dx: size.width + 6, dy: 0)
            let box = (face as? CanonMathGlyphs)?.box
            let label = box.map { min(area.width, $0.width * min(1, area.height / max(1, $0.height))) } ?? area.width
            chevron.frame = CGRect(x: area.midX + label / 2 + 6, y: bounds.midY - size.height / 2, width: size.width, height: size.height)
            chevron.transform = CGAffineTransform(translationX: drift, y: 0)
            chevron.alpha = fade
        }
        face.transform = .identity
        face.frame = area
        face.transform = CGAffineTransform(translationX: drift, y: 0)
        face.alpha = fade
    }

    public func strokeBegan(at point: CGPoint) {
        pressed = true
        isLit = true
        CanonMathHaptics.prepare()
        CanonMotion.press(self, at: point)
    }

    /// Starts repeating; false for a key that does not repeat.
    public func strokeHold() -> Bool {
        guard repeats else { return false }
        fire()
        scheduleRepeat(after: CanonButton.repeatTiming.interval, count: 0)
        return true
    }

    public func strokeEnded(tap: Bool, at point: CGPoint?) {
        repeatTimer?.invalidate()
        repeatTimer = nil
        if tap { fire() }
        pressed = false
        isLit = false
        CanonMotion.release(self, from: point)
    }

    public func strokeCancelled() {
        strokeEnded(tap: false, at: nil)
    }

    private func fire() {
        guard let onTap else { return }
        CanonMathHaptics.commit(family)
        onTap()
    }

    private func scheduleRepeat(after seconds: TimeInterval, count: Int) {
        repeatTimer?.invalidate()
        let timer = Timer(timeInterval: seconds, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.pressed else { return }
                self.fire()
                self.scheduleRepeat(after: count < 10 ? CanonButton.repeatTiming.interval : CanonButton.repeatTiming.fast, count: count + 1)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        repeatTimer = timer
    }

    public override func accessibilityActivate() -> Bool {
        fire()
        return onTap != nil
    }

    #if DEBUG
    /// Plays a tap with its press, for launch-argument scripts. Seconds it takes.
    public func demoTap() -> Double {
        strokeBegan(at: CGPoint(x: bounds.midX * 1.3, y: bounds.midY * 0.8))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) { [weak self] in self?.strokeEnded(tap: true, at: nil) }
        return 0.2
    }
    #endif
}

/// A key's touch: a tap, or a hold on a repeating key. Any drag fails it, so the pages swipe and the sheet closes; every
/// enclosing pan waits for it to fail.
private final class CanonMathKeyStroke: UIGestureRecognizer {
    private var repeating = false
    private var start = CGPoint.zero
    private var hold: Timer?
    private var key: CanonMathKeyView? { view as? CanonMathKeyView }
    /// Points of travel that turn a touch into a drag.
    public static let slop: CGFloat = 10

    public init() {
        super.init(target: nil, action: nil)
        cancelsTouchesInView = false
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard state == .possible, !repeating, let touch = touches.first, let key else { return }
        start = touch.location(in: key)
        key.strokeBegan(at: start)
        guard key.repeats else { return }
        let timer = Timer(timeInterval: CanonButton.repeatTiming.delay, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.held() }
        }
        RunLoop.main.add(timer, forMode: .common)
        hold = timer
    }

    private func held() {
        guard state == .possible, let key, key.strokeHold() else { return }
        repeating = true
        state = .began
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard !repeating, let touch = touches.first, let key else { return }
        let point = touch.location(in: key)
        if hypot(point.x - start.x, point.y - start.y) > Self.slop {
            hold?.invalidate()
            key.strokeCancelled()
            state = .failed
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        hold?.invalidate()
        guard let key else { return }
        key.strokeEnded(tap: !repeating, at: touches.first?.location(in: key))
        state = .ended
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        hold?.invalidate()
        key?.strokeCancelled()
        state = state == .possible ? .failed : .cancelled
    }

    public override func reset() {
        super.reset()
        hold?.invalidate()
        hold = nil
        repeating = false
    }

    public override func shouldBeRequiredToFail(by other: UIGestureRecognizer) -> Bool {
        CanonMathKeyStroke.waits(other, for: view)
    }

    /// True for a pan on a view enclosing `view`: a page scroll or a sheet's drag.
    public static func waits(_ other: UIGestureRecognizer, for view: UIView?) -> Bool {
        guard other is UIPanGestureRecognizer, let view, let owner = other.view, owner !== view else { return false }
        return view.isDescendant(of: owner)
    }
}

// MARK: - Submenu

/// A family's variants in a panel over the key that opened it, framed in the family's colour. Each item is a key of its own;
/// typing one closes the panel, and so does a touch anywhere else.
public final class CanonMathSubmenu: UIView {
    public static let frameWidth: CGFloat = 2
    public let items: [(key: CanonMathExpression.Key, view: CanonMathKeyView)]
    private let backdrop = UIControl()

    public init(items: [(key: CanonMathExpression.Key, view: CanonMathKeyView)], family: CanonMathFamily, columns: Int, cell: CGSize) {
        self.items = items
        let rows = (items.count + columns - 1) / columns
        let hairline = DelphiMetrics.hairline
        super.init(frame: CGRect(
            x: 0, y: 0,
            width: CGFloat(columns) * cell.width + CGFloat(columns - 1) * hairline + Self.frameWidth * 2,
            height: CGFloat(rows) * cell.height + CGFloat(rows - 1) * hairline + Self.frameWidth * 2
        ))
        backgroundColor = family.accent
        let seams = UIView(frame: bounds.insetBy(dx: Self.frameWidth, dy: Self.frameWidth))
        seams.backgroundColor = .delphiBorder
        addSubview(seams)
        for (index, item) in items.enumerated() {
            item.view.frame = CGRect(
                x: CGFloat(index % columns) * (cell.width + hairline), y: CGFloat(index / columns) * (cell.height + hairline),
                width: cell.width, height: cell.height
            )
            seams.addSubview(item.view)
        }
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 6)
        accessibilityViewIsModal = true
        backdrop.addAction(UIAction { [unowned self] _ in close() }, for: .touchDown)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Opens over `key`, inside `host`, growing out of the key's top edge.
    public func open(over key: UIView, in host: UIView) {
        backdrop.frame = host.bounds
        backdrop.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.addSubview(backdrop)
        host.addSubview(self)
        let anchor = key.convert(key.bounds, to: host)
        let limits = host.bounds.inset(by: host.safeAreaInsets).insetBy(dx: 6, dy: 4)
        var frame = CGRect(origin: CGPoint(x: anchor.midX - bounds.width / 2, y: anchor.minY - bounds.height - 6), size: bounds.size)
        frame.origin.x = min(max(frame.minX, limits.minX), limits.maxX - frame.width)
        frame.origin.y = max(frame.minY, limits.minY)
        self.frame = frame
        UIAccessibility.post(notification: .screenChanged, argument: self)
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let origin = convert(CGPoint(x: anchor.midX, y: anchor.minY), from: host)
        transform = CGAffineTransform(translationX: (origin.x - bounds.midX) * 0.6, y: (origin.y - bounds.midY) * 0.6).scaledBy(x: 0.4, y: 0.4)
        alpha = 0
        UIView.animate(withDuration: 0.34, delay: 0, usingSpringWithDamping: 0.74, initialSpringVelocity: 0, options: [.allowUserInteraction]) {
            self.transform = .identity
            self.alpha = 1
        }
    }

    public func close() {
        backdrop.removeFromSuperview()
        isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.14, delay: 0.04, options: [.allowUserInteraction]) {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        } completion: { _ in
            self.removeFromSuperview()
        }
    }

    public override func accessibilityPerformEscape() -> Bool {
        close()
        return true
    }
}

// MARK: - Haptics

/// Feedback by key role: a light tap for digits and letters, a firmer one for operators, a rigid click for a structure,
/// a warning for clear, success for Done.
@MainActor
public enum CanonMathHaptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let selection = UISelectionFeedbackGenerator()
    private static let notice = UINotificationFeedbackGenerator()

    public static func prepare() {
        light.prepare()
        rigid.prepare()
    }

    public static func commit(_ family: CanonMathFamily) {
        switch family {
        case .digit, .letter: light.impactOccurred()
        case .operation: medium.impactOccurred(intensity: 0.8)
        case .structure, .calculus: rigid.impactOccurred(intensity: 0.9)
        case .clear: notice.notificationOccurred(.warning)
        case .done: notice.notificationOccurred(.success)
        }
    }

    public static func select() { selection.selectionChanged() }
    public static func bump() { rigid.impactOccurred(intensity: 0.35) }
}

// MARK: - Rail

/// The caret's controls, under the expression: ribs that slide with a sideways drag, one caret place per stride, then the four
/// arrow keys.
public final class CanonMathRail: UIView {
    public typealias Key = CanonMathExpression.Key
    /// Moves the caret; false when it could not move.
    public var onStep: ((Key) -> Bool)?
    public static let heights = (regular: CGFloat(44), short: CGFloat(38))
    /// Sideways drag, in points, per caret place.
    public static let stride: CGFloat = 16
    public static let arrowWidth: CGFloat = 50
    private let ribs = CanonMathRibs()
    private var lastX: CGFloat = 0
    private var stepped: CGFloat = 0

    public init(height: CGFloat) {
        super.init(frame: .zero)
        backgroundColor = .delphiBorder
        let arrows: [(String, Key, String)] = [
            ("chevron.left", .left, String(localized: "Left")), ("chevron.up", .up, String(localized: "Up")),
            ("chevron.down", .down, String(localized: "Down")), ("chevron.right", .right, String(localized: "Right")),
        ]
        let buttons = arrows.map { symbol, key, spoken in
            let button = CanonButton("", systemImage: symbol, kind: .cell, repeats: true) { [unowned self] in _ = step(key) }
            button.accessibilityLabel = spoken
            button.widthAnchor.constraint(equalToConstant: Self.arrowWidth).isActive = true
            return button
        }
        let stack = UIStackView(arrangedSubviews: [ribs] + buttons)
        stack.spacing = DelphiMetrics.hairline
        pin(stack)
        heightAnchor.constraint(equalToConstant: height).isActive = true
        ribs.addGestureRecognizer(CanonMathRailPan(target: self, action: #selector(dragged)))
        ribs.onAdjust = { [unowned self] in _ = step($0 ? .right : .left) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func step(_ key: Key) -> Bool {
        let moved = onStep?(key) ?? false
        if moved { CanonMathHaptics.select() } else { CanonMathHaptics.bump() }
        return moved
    }

    @objc private func dragged(_ drag: UIPanGestureRecognizer) {
        let x = drag.translation(in: ribs).x
        switch drag.state {
        case .began:
            lastX = 0
            stepped = 0
        case .changed:
            ribs.phase += x - lastX
            lastX = x
            while x - stepped > Self.stride { stepped += Self.stride; _ = step(.right) }
            while x - stepped < -Self.stride { stepped -= Self.stride; _ = step(.left) }
        default:
            break
        }
    }

    #if DEBUG
    /// Slides the ribs `steps` places, negative to the left. Seconds it takes.
    public func glide(steps: Int) -> Double {
        let interval = 0.12
        for index in 0..<abs(steps) {
            for frame in 1...6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + interval * (Double(index) + Double(frame) / 6)) { [weak self] in
                    self?.ribs.phase += CGFloat(steps.signum()) * Self.stride / 6
                    if frame == 6 { _ = self?.step(steps > 0 ? .right : .left) }
                }
            }
        }
        return interval * Double(abs(steps)) + 0.2
    }
    #endif
}

/// Hairline ribs fading towards both ends, sliding with the drag.
private final class CanonMathRibs: UIView {
    public var onAdjust: ((Bool) -> Void)?
    public var phase: CGFloat = 0 {
        didSet { setNeedsDisplay() }
    }

    public static let spacing: CGFloat = 7

    public init() {
        super.init(frame: .zero)
        backgroundColor = .delphiCard
        contentMode = .redraw
        redrawsOnStyleChange()
        isAccessibilityElement = true
        accessibilityLabel = String(localized: "Cursor")
        accessibilityTraits = .adjustable
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func accessibilityIncrement() { onAdjust?(true) }
    public override func accessibilityDecrement() { onAdjust?(false) }

    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), bounds.width > 0 else { return }
        let rib = UIColor.delphiMutedForeground.resolvedColor(with: traitCollection)
        let height = bounds.height * 0.42
        var x = phase.truncatingRemainder(dividingBy: Self.spacing)
        if x < 0 { x += Self.spacing }
        while x < bounds.width {
            let alpha = pow(sin(.pi * x / bounds.width), 1.6) * 0.55
            context.setFillColor(rib.withAlphaComponent(alpha).cgColor)
            context.fill(CGRect(x: x, y: bounds.midY - height / 2, width: 1, height: height))
            x += Self.spacing
        }
    }
}

private final class CanonMathRailPan: UIPanGestureRecognizer {
    public override func shouldBeRequiredToFail(by other: UIGestureRecognizer) -> Bool {
        CanonMathKeyStroke.waits(other, for: view)
    }
}

// MARK: - Tabs

/// The pages' names as maths, each lit in its page's colour as the page comes into view, over a lamp that slides and
/// changes colour with the swipe.
public final class CanonMathTabs: UIView {
    public var onSelect: ((Int) -> Void)?
    private let cells: [UIControl]
    private let glyphs: [CanonMathGlyphs]
    private let accents: [UIColor]
    private let lamp = UIView()
    private var progress: CGFloat = 0
    public static let lampHeight: CGFloat = 3

    public init(faces: [CanonMath.Box], accents: [UIColor], labels: [String]) {
        self.accents = accents
        glyphs = faces.map { CanonMathGlyphs($0, colour: .delphiMutedForeground) }
        cells = glyphs.enumerated().map { index, glyph in
            let cell = UIControl()
            cell.backgroundColor = .delphiCard
            glyph.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(glyph)
            NSLayoutConstraint.activate([
                glyph.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
                glyph.centerYAnchor.constraint(equalTo: cell.centerYAnchor, constant: -1),
                glyph.widthAnchor.constraint(equalTo: cell.widthAnchor, constant: -8),
                glyph.heightAnchor.constraint(equalTo: cell.heightAnchor, constant: -12),
            ])
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = labels[index]
            cell.accessibilityTraits = .button
            return cell
        }
        super.init(frame: .zero)
        backgroundColor = .delphiBorder
        let row = UIStackView(arrangedSubviews: cells)
        row.spacing = DelphiMetrics.hairline
        row.distribution = .fillEqually
        pin(row)
        addSubview(lamp)
        for (index, cell) in cells.enumerated() {
            cell.addAction(UIAction { [unowned self] _ in onSelect?(index) }, for: .touchUpInside)
            cell.animatesPress()
            cell.tracksHover { [unowned cell] in cell.backgroundColor = $0 ? .delphiAccentBG : .delphiCard }
        }
        setProgress(0)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        placeLamp()
    }

    /// `progress` is the page position, fractional mid-swipe.
    public func setProgress(_ progress: CGFloat) {
        self.progress = min(max(progress, 0), CGFloat(cells.count - 1))
        for (index, glyph) in glyphs.enumerated() {
            let near = max(0, 1 - abs(self.progress - CGFloat(index)))
            glyph.colour = near == 0 ? .delphiMutedForeground : UIColor.delphiMutedForeground.mixed(with: accents[index], by: near)
            cells[index].accessibilityTraits = near > 0.5 ? [.button, .selected] : .button
        }
        let low = Int(self.progress.rounded(.down))
        let high = min(low + 1, cells.count - 1)
        let share = self.progress - CGFloat(low)
        lamp.backgroundColor = share == 0 ? accents[low] : accents[low].mixed(with: accents[high], by: share)
        placeLamp()
    }

    private func placeLamp() {
        let count = CGFloat(cells.count)
        let cell = (bounds.width - DelphiMetrics.hairline * (count - 1)) / count
        guard cell > 0 else { return }
        let share = progress - progress.rounded(.down)
        // lamp narrows mid-swipe
        let width = cell * 0.62 * (1 - 0.35 * sin(.pi * share))
        let midX = progress * (cell + DelphiMetrics.hairline) + cell / 2
        lamp.frame = CGRect(x: midX - width / 2, y: bounds.maxY - Self.lampHeight, width: width, height: Self.lampHeight)
    }
}

// MARK: - Pages

/// One page of keys on a grid of six columns and four rows, keys spanning cells, hairline seams between them.
private final class CanonMathPage: UIView {
    public static let columns = 6
    public static let rows = 4
    public let keys: [(spec: CanonMathKeypad.Spec, view: CanonMathKeyView)]

    public init(_ keys: [(spec: CanonMathKeypad.Spec, view: CanonMathKeyView)]) {
        self.keys = keys
        super.init(frame: .zero)
        backgroundColor = .delphiBorder
        keys.forEach { addSubview($0.view) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let hairline = DelphiMetrics.hairline
        let width = (bounds.width - hairline * CGFloat(Self.columns - 1)) / CGFloat(Self.columns)
        let height = (bounds.height - hairline * CGFloat(Self.rows - 1)) / CGFloat(Self.rows)
        for (spec, view) in keys {
            let cell = spec.cell
            let frame = CGRect(
                x: CGFloat(cell.x) * (width + hairline), y: CGFloat(cell.y) * (height + hairline),
                width: CGFloat(cell.w) * width + CGFloat(cell.w - 1) * hairline, height: CGFloat(cell.h) * height + CGFloat(cell.h - 1) * hairline
            )
            // pressed key keeps tilt
            if view.bounds.size != frame.size || view.center != CGPoint(x: frame.midX, y: frame.midY) {
                view.bounds = CGRect(origin: .zero, size: frame.size)
                view.center = CGPoint(x: frame.midX, y: frame.midY)
            }
        }
    }

    /// `offset` is this page's distance from the centre of the pager in page widths: labels trail their cells, the columns
    /// furthest from the edge that leads trailing most, and fade.
    public func setOffset(_ offset: CGFloat, width: CGFloat) {
        let distance = min(1, abs(offset))
        for (spec, view) in keys {
            let column = CGFloat(offset > 0 ? spec.cell.x : Self.columns - spec.cell.x - spec.cell.w)
            view.setDrift(offset * width * (0.05 + 0.035 * column), fade: 1 - 0.7 * distance)
        }
    }
}

// MARK: - Keypad

/// Maths keys on four swipeable pages (numbers and operators, functions, calculus, letters and constants), with delete,
/// clear and Done beside every page. Hyperbolic and reciprocal trig sit in submenus. A slot key typed on a later page
/// returns to the numbers, since the slot usually takes a number next.
public final class CanonMathKeypad: UIView, UIScrollViewDelegate {
    public typealias Key = CanonMathExpression.Key

    public struct Spec {
        public let key: Key
        public let family: CanonMathFamily
        /// Column, row, and width and height in cells.
        public let cell: (x: Int, y: Int, w: Int, h: Int)
        public var scale: CGFloat = 1
        /// A submenu key: its label, and the keys it offers.
        public var menu: (title: String, keys: [Key])?

        public init(key: Key, family: CanonMathFamily, cell: (x: Int, y: Int, w: Int, h: Int), scale: CGFloat = 1, menu: (title: String, keys: [Key])? = nil) {
            self.key = key
            self.family = family
            self.cell = cell
            self.scale = scale
            self.menu = menu
        }
    }

    public var onKey: ((Key) -> Void)?
    public var onDone: (() -> Void)?
    public private(set) var page = 0

    /// Key height, and the height on a short screen.
    public static let keyHeights = (regular: CGFloat(54), short: CGFloat(44))
    public static let tabHeights = (regular: CGFloat(40), short: CGFloat(34))
    /// Label size as a share of the key height.
    public static let labelShare: CGFloat = 0.44
    /// Label scale for names and function keys, so a row of names shares one size: sin⁻¹ fits a narrow cell at it.
    public static let nameScale: CGFloat = 0.82
    /// Label scale for a submenu key's title.
    public static let menuScale: CGFloat = 0.72
    /// Width of the spine column (delete, clear, Done), in page columns.
    public static let spineWeight: CGFloat = 1.15
    /// Page spring: seconds per swing and damping ratio.
    public static let glideSpring = (response: 0.46, damping: 0.84)
    /// Seconds before a slot key typed on a later page returns to the numbers.
    public static let returnDelay = 0.22

    private let keyHeight: CGFloat
    private let tabHeight: CGFloat
    private let variable: String
    private let tabs: CanonMathTabs
    private let pager = UIScrollView()
    private let pages: [CanonMathPage]
    private let delete: CanonMathKeyView
    private let clear: CanonMathKeyView
    private let done: CanonMathKeyView
    private weak var submenu: CanonMathSubmenu?
    private var detent = 0
    private var glide: (link: CADisplayLink, from: CGFloat, to: CGFloat, start: CFTimeInterval)?

    public static func height(isShort: Bool) -> CGFloat {
        let key = isShort ? keyHeights.short : keyHeights.regular
        return (isShort ? tabHeights.short : tabHeights.regular) + DelphiMetrics.hairline * CGFloat(CanonMathPage.rows) + key * CGFloat(CanonMathPage.rows)
    }

    /// Letters offered, the variable first.
    public static func letters(variable: String) -> [String] {
        Array(([variable] + ["x", "y", "z", "t", "n", "k", "a", "b", "c", "m", "p", "r", "s"].filter { $0 != variable }).prefix(12))
    }

    /// The four pages. `x`, `y`, `w` and `h` place a key on the page's six by four grid.
    public static func pages(variable: String) -> [[Spec]] {
        let letters = letters(variable: variable)
        func key(_ key: Key, _ family: CanonMathFamily, _ x: Int, _ y: Int, w: Int = 1, h: Int = 1, scale: CGFloat = 1) -> Spec {
            Spec(key: key, family: family, cell: (x, y, w, h), scale: scale)
        }
        func digit(_ digit: Int, _ x: Int, _ y: Int, w: Int = 1) -> Spec { key(.symbol(String(digit)), .digit, x, y, w: w, scale: 1.1) }
        func sign(_ symbol: String, _ x: Int, _ y: Int, w: Int = 1) -> Spec { key(.symbol(symbol), .operation, x, y, w: w, scale: 1.2) }
        func name(_ key: Key, _ family: CanonMathFamily, _ x: Int, _ y: Int) -> Spec { Spec(key: key, family: family, cell: (x, y, 1, 1), scale: nameScale) }
        func function(_ name: String, _ x: Int, _ y: Int, arity: Int = 1, family: CanonMathFamily = .structure, w: Int = 1) -> Spec {
            key(.function(name, arity: arity), family, x, y, w: w, scale: nameScale)
        }
        func menu(_ title: String, _ names: [String], _ x: Int, _ y: Int) -> Spec {
            let keys = names.map { Key.function($0, arity: 1) }
            return Spec(key: keys[0], family: .structure, cell: (x, y, 3, 1), menu: (title, keys))
        }
        let pi = "\u{03C0}", infinity = "\u{221E}"
        let numbers = [
            key(.fraction, .structure, 0, 0), digit(7, 1, 0), digit(8, 2, 0), digit(9, 3, 0), key(.divide, .operation, 4, 0, scale: 1.2),
            key(.open, .structure, 5, 0),
            key(.square, .structure, 0, 1), digit(4, 1, 1), digit(5, 2, 1), digit(6, 3, 1), sign("\u{00D7}", 4, 1), key(.symbol(letters[0]), .letter, 5, 1, scale: 1.1),
            key(.root, .structure, 0, 2), digit(1, 1, 2), digit(2, 2, 2), digit(3, 3, 2), sign("\u{2212}", 4, 2), key(.symbol(pi), .letter, 5, 2, scale: 1.1),
            key(.power, .structure, 0, 3), digit(0, 1, 3, w: 2), key(.symbol("."), .digit, 3, 3, scale: 1.1), sign("+", 4, 3), sign("=", 5, 3),
        ]
        let functions = [
            function("sin", 0, 0), function("cos", 1, 0), function("tan", 2, 0),
            function("log", 3, 0), function("log10", 4, 0), name(.logBase, .structure, 5, 0),
            function("asin", 0, 1), function("acos", 1, 1), function("atan", 2, 1),
            name(.exponential("e"), .structure, 3, 1), name(.exponential("10"), .structure, 4, 1), name(.inverse, .structure, 5, 1),
            name(.cube, .structure, 0, 2), name(.cubeRoot, .structure, 1, 2), name(.nthRoot, .structure, 2, 2),
            name(.fence(.abs), .structure, 3, 2), name(.fence(.floor), .structure, 4, 2), name(.fence(.ceil), .structure, 5, 2),
            menu("sinh cosh tanh", ["sinh", "cosh", "tanh", "asinh", "acosh", "atanh"], 0, 3),
            menu("sec csc cot", ["sec", "csc", "cot", "asec", "acsc", "acot"], 3, 3),
        ]
        let calculus = [
            key(.derivative, .calculus, 0, 0, h: 2, scale: 1.3), key(.integral(bounded: false), .calculus, 1, 0, h: 2, scale: 1.3),
            key(.integral(bounded: true), .calculus, 2, 0, h: 2, scale: 1.3), key(.limit, .calculus, 3, 0, h: 2, scale: 1.3),
            key(.series(product: false), .calculus, 4, 0, h: 2, scale: 1.3), key(.series(product: true), .calculus, 5, 0, h: 2, scale: 1.3),
            name(.symbol("!"), .calculus, 0, 2), name(.binomial, .calculus, 1, 2), name(.permutation, .calculus, 2, 2),
            function("mod", 3, 2, arity: 2, family: .calculus), function("gcd", 4, 2, arity: 2, family: .calculus),
            function("lcm", 5, 2, arity: 2, family: .calculus),
            function("min", 0, 3, arity: 2, family: .calculus), function("max", 1, 3, arity: 2, family: .calculus),
            function("round", 2, 3, family: .calculus, w: 2), key(.symbol(infinity), .calculus, 4, 3, w: 2, scale: 1.2),
        ]
        let greek = ["theta", "alpha", "beta", "lambda", "mu", "omega"]
        let variables = letters.enumerated().map { index, letter in key(.symbol(letter), .letter, index % 6, index / 6, scale: 1.1) }
            + greek.enumerated().map { index, name in key(.symbol(name), .letter, index, 2, scale: 1.1) }
            + [
                key(.symbol(pi), .letter, 0, 3, scale: 1.1), key(.symbol("e"), .letter, 1, 3, scale: 1.1), key(.symbol("i"), .letter, 2, 3, scale: 1.1),
                key(.symbol(infinity), .letter, 3, 3, scale: 1.1), sign("=", 4, 3, w: 2),
            ]
        return [numbers, functions, calculus, variables]
    }

    /// A key cell outside the keypad, for insert keys beside a field: the key's label in its family's colours.
    public static func cell(_ key: Key, variable: String = "x", action: @escaping () -> Void) -> UIView {
        let view = CanonMathKeyView(
            face: .math(label(key, variable: variable, size: keyHeights.regular * labelShare)), family: CanonMathFamily.of(key),
            label: spoken(key, variable: variable)
        )
        view.onTap = action
        view.heightAnchor.constraint(equalToConstant: keyHeights.regular).isActive = true
        return view
    }

    /// A key's one label at `size`: its symbol or its name, with letters where the key opens slots.
    public static func label(_ key: Key, variable: String, size: CGFloat) -> CanonMath.Box {
        let setter = CanonMath.Typesetter(size: size, ink: .result)
        func row(_ items: [CanonMathItem]) -> CanonMath.Box { setter.layout(CanonMathRow(items), caret: nil, variable: variable) }
        func letters(_ text: String) -> CanonMathRow { CanonMathRow(text.map { .symbol(String($0)) }) }
        func italic(_ text: String) -> CanonMath.Box { setter.text(text, italic: true) }
        switch key {
        case .symbol("!"): return row([.symbol("n"), .symbol("!")])
        case .symbol(let symbol): return row([.symbol(symbol)])
        case .fraction: return row([.fraction(letters("a"), letters("b"))])
        case .divide: return setter.text("\u{00F7}")
        case .power: return row([.symbol("x"), .power(letters("y"))])
        case .square: return row([.symbol("x"), .power(letters("2"))])
        case .cube: return row([.symbol("x"), .power(letters("3"))])
        case .inverse: return row([.symbol("x"), .power(CanonMathRow([.symbol("\u{2212}"), .symbol("1")]))])
        case .root: return row([.root(letters("x"))])
        case .cubeRoot: return row([.nthRoot(index: letters("3"), radicand: letters("x"))])
        case .nthRoot: return row([.nthRoot(index: letters("n"), radicand: letters("x"))])
        case .logBase: return setter.logBase(setter.text("b", italic: true, level: 2), 0)
        case .exponential(let base): return row(base.map { .symbol(String($0)) } + [.power(letters("x"))])
        case .scientific:
            var box = setter.text("\u{00D7}10")
            box.append(setter.raised(setter.text("n", italic: true, level: 2), over: box.ascent, 0), gap: size * 0.04)
            return box
        case .open: return setter.text("( )")
        case .close: return setter.text(")")
        case .fence(let kind): return row([.fence(kind, letters("x"))])
        case .function(let name, _): return setter.functionName(name, 0)
        case .series(let product): return setter.text(product ? "\u{03A0}" : "\u{03A3}", scale: 1.1)
        case .integral(let bounded):
            let bound = { (letter: String) in bounded ? setter.text(letter, italic: true, level: 2) : nil }
            return setter.integralSign(lower: bound("a"), upper: bound("b"), 0)
        case .derivative: return setter.derivativeOperator(setter.text(variable, italic: CanonMath.isItalic(variable), level: 1), 0)
        case .limit: return setter.text("lim")
        case .binomial, .permutation:
            var box = italic("n")
            box.append(setter.text(key == .binomial ? "C" : "P"), gap: size * 0.03)
            box.append(italic("r"), gap: size * 0.03)
            return box
        case .clear: return setter.text("AC")
        default: return CanonMath.Box()
        }
    }

    /// What VoiceOver reads for a key.
    public static func spoken(_ key: Key, variable: String) -> String {
        switch key {
        case .symbol("\u{00D7}"): return String(localized: "Multiply")
        case .divide: return String(localized: "Divide")
        case .symbol("!"): return String(localized: "Factorial")
        case .symbol("\u{03C0}"): return String(localized: "Pi")
        case .fraction: return String(localized: "Fraction")
        case .open: return String(localized: "Brackets")
        case .power: return String(localized: "Power")
        case .square: return String(localized: "Square")
        case .root: return String(localized: "Square root")
        case .fence(.abs): return String(localized: "Absolute value")
        case .clear: return String(localized: "Clear")
        default:
            let typed = CanonMathExpression(text: "", variable: variable)
            typed.apply(key)
            return typed.text.replacingOccurrences(of: "()", with: "").replacingOccurrences(of: "(,)", with: "")
        }
    }

    public init(variable: String = "x", isShort: Bool = false) {
        self.variable = variable
        keyHeight = isShort ? Self.keyHeights.short : Self.keyHeights.regular
        tabHeight = isShort ? Self.tabHeights.short : Self.tabHeights.regular
        let size = (keyHeight * Self.labelShare).rounded()
        var typing: ((Key, Int) -> Void)?
        var opening: ((Spec, CanonMathKeyView) -> Void)?
        pages = Self.pages(variable: variable).enumerated().map { index, specs in
            CanonMathPage(specs.map { spec in
                let face: CanonMath.Box = if let menu = spec.menu {
                    CanonMath.Typesetter(size: size * Self.menuScale, ink: .result).text(menu.title)
                } else {
                    Self.label(spec.key, variable: variable, size: size * spec.scale)
                }
                let view = CanonMathKeyView(
                    face: .math(face), family: spec.family, label: spec.menu?.title ?? Self.spoken(spec.key, variable: variable),
                    opensMenu: spec.menu != nil
                )
                if spec.menu == nil {
                    view.onTap = { typing?(spec.key, index) }
                } else {
                    view.onTap = { [unowned view] in opening?(spec, view) }
                }
                return (spec, view)
            })
        }
        delete = CanonMathKeyView(face: .symbol("delete.left"), family: .operation, label: String(localized: "Delete"))
        delete.repeats = true
        clear = CanonMathKeyView(face: .math(Self.label(.clear, variable: variable, size: size * 0.9)), family: .clear, label: String(localized: "Clear"))
        done = CanonMathKeyView(face: .word(String(localized: "Done")), family: .done, label: String(localized: "Done"))
        let setter = CanonMath.Typesetter(size: 18, ink: .result)
        var functions = setter.text("f", italic: true)
        functions.append(setter.parens(setter.text("x", italic: true), 0), gap: 1)
        var calculus = setter.text("\u{222B}")
        calculus.append(setter.text("\u{03A3}"), gap: 3)
        tabs = CanonMathTabs(
            faces: [setter.text("123"), functions, calculus, setter.text("xyz", italic: true)],
            accents: [.delphiForeground, .mathGreen, .mathBlue, .mathClay],
            labels: [String(localized: "Numbers"), String(localized: "Functions"), String(localized: "Calculus"), String(localized: "Letters")]
        )
        super.init(frame: .zero)
        backgroundColor = .delphiBorder
        typing = { [unowned self] key, page in type(key, from: page) }
        opening = { [unowned self] spec, view in openMenu(spec, over: view) }
        delete.onTap = { [unowned self] in onKey?(.delete) }
        clear.onTap = { [unowned self] in onKey?(.clear) }
        done.onTap = { [unowned self] in onDone?() }
        tabs.onSelect = { [unowned self] in show(page: $0, animated: true) }

        pager.isPagingEnabled = true
        pager.showsHorizontalScrollIndicator = false
        pager.delaysContentTouches = false
        pager.alwaysBounceVertical = false
        pager.contentInsetAdjustmentBehavior = .never
        pager.backgroundColor = .delphiBorder
        pager.delegate = self
        pages.forEach(pager.addSubview)
        for view in [tabs, pager, delete, clear, done] as [UIView] { addSubview(view) }
        heightAnchor.constraint(equalToConstant: Self.height(isShort: isShort)).isActive = true
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let hairline = DelphiMetrics.hairline
        tabs.frame = CGRect(x: 0, y: 0, width: bounds.width, height: tabHeight)
        let top = tabHeight + hairline
        let body = bounds.height - top
        let columns = CGFloat(CanonMathPage.columns)
        let unit = (bounds.width - hairline * columns) / (columns + Self.spineWeight)
        let pageWidth = (unit * columns + hairline * (columns - 1)).rounded()
        pager.frame = CGRect(x: 0, y: top, width: pageWidth, height: body)
        let size = CGSize(width: pageWidth * CGFloat(pages.count), height: body)
        if pager.contentSize != size {
            pager.contentSize = size
            for (index, page) in pages.enumerated() {
                page.frame = CGRect(x: pageWidth * CGFloat(index), y: 0, width: pageWidth, height: body)
            }
            pager.contentOffset.x = pageWidth * CGFloat(page)
        }
        let spine = pageWidth + hairline
        let width = bounds.width - spine
        let midX = (spine + bounds.width) / 2
        let row = (body - hairline * CGFloat(CanonMathPage.rows - 1)) / CGFloat(CanonMathPage.rows)
        for (index, key) in [delete, clear].enumerated() where key.bounds.width != width || key.bounds.height != row {
            key.bounds.size = CGSize(width: width, height: row)
            key.center = CGPoint(x: midX, y: top + (row + hairline) * CGFloat(index) + row / 2)
        }
        let doneSize = CGSize(width: width, height: body - (row + hairline) * 2)
        if done.bounds.size != doneSize {
            done.bounds.size = doneSize
            done.center = CGPoint(x: midX, y: bounds.maxY - doneSize.height / 2)
        }
        scrollViewDidScroll(pager)
    }

    private func type(_ key: Key, from index: Int) {
        submenu?.close()
        onKey?(key)
        guard index != 0, key.opensSlot else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.returnDelay) { [weak self] in
            guard let self, page == index, glide == nil, !pager.isTracking else { return }
            show(page: 0, animated: true)
        }
    }

    private func openMenu(_ spec: Spec, over key: CanonMathKeyView) {
        guard let menu = spec.menu, let host = owningViewController?.view else { return }
        let index = pages.firstIndex { $0.keys.contains { $0.view === key } } ?? 0
        let cell = CGSize(width: max(64, key.bounds.width / 3 + 12), height: keyHeight)
        let size = (keyHeight * Self.labelShare).rounded()
        let items = menu.keys.map { item in
            let view = CanonMathKeyView(
                face: .math(Self.label(item, variable: variable, size: size * Self.nameScale)), family: spec.family, label: Self.spoken(item, variable: variable)
            )
            view.onTap = { [unowned self] in type(item, from: index) }
            return (key: item, view: view)
        }
        let panel = CanonMathSubmenu(items: items, family: spec.family, columns: 3, cell: cell)
        panel.open(over: key, in: host)
        submenu = panel
    }

    // MARK: Paging

    public func show(page index: Int, animated: Bool) {
        submenu?.close()
        let width = pager.bounds.width
        let target = CGFloat(min(max(index, 0), pages.count - 1)) * width
        stopGlide()
        guard animated, width > 0, window != nil, !UIAccessibility.isReduceMotionEnabled else {
            pager.contentOffset.x = target
            return
        }
        let link = CADisplayLink(target: self, selector: #selector(glided))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        glide = (link, pager.contentOffset.x, target, CACurrentMediaTime())
    }

    @objc private func glided() {
        guard let glide else { return }
        let t = CACurrentMediaTime() - glide.start
        let omega = 2 * .pi / Self.glideSpring.response
        let zeta = Self.glideSpring.damping
        let damped = omega * sqrt(1 - zeta * zeta)
        let envelope = exp(-zeta * omega * t)
        let x = glide.to + (glide.from - glide.to) * envelope * (cos(damped * t) + zeta * omega / damped * sin(damped * t))
        if t > 1.2 || (t > 0.2 && abs(x - glide.to) < 0.3) {
            stopGlide()
            pager.contentOffset.x = glide.to
        } else {
            pager.contentOffset.x = x
        }
    }

    private func stopGlide() {
        glide?.link.invalidate()
        glide = nil
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopGlide()
        submenu?.close()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = pager.bounds.width
        guard width > 0 else { return }
        let progress = pager.contentOffset.x / width
        tabs.setProgress(progress)
        let nearest = min(max(Int(progress.rounded()), 0), pages.count - 1)
        for (index, page) in pages.enumerated() {
            page.setOffset(CGFloat(index) - progress, width: width)
            page.accessibilityElementsHidden = index != nearest
        }
        if nearest != detent {
            detent = nearest
            CanonMathHaptics.select()
        }
        page = nearest
    }

    #if DEBUG
    /// Launch-argument name of a key.
    public static func key(named token: String) -> Key? {
        let named: [String: Key] = [
            "frac": .fraction, "div": .divide, "pow": .power, "sq": .square, "cube": .cube, "inv": .inverse, "sqrt": .root,
            "cbrt": .cubeRoot, "nroot": .nthRoot, "logb": .logBase, "10x": .exponential("10"), "ex": .exponential("e"), "E": .scientific,
            "(": .open, ")": .close, "abs": .fence(.abs), "floor": .fence(.floor), "ceil": .fence(.ceil), "sum": .series(product: false),
            "prod": .series(product: true), "int": .integral(bounded: false), "defint": .integral(bounded: true), "ddx": .derivative,
            "lim": .limit, "ncr": .binomial, "npr": .permutation, "left": .left, "right": .right, "up": .up,
            "down": .down, "del": .delete, "clear": .clear, "*": .symbol("\u{00D7}"), "-": .symbol("\u{2212}"),
            "pi": .symbol("\u{03C0}"), "inf": .symbol("\u{221E}"), "log": .function("log10", arity: 1), "ln": .function("log", arity: 1),
            "fact": .symbol("!"),
        ]
        if let key = named[token] { return key }
        if ["min", "max", "gcd", "lcm", "mod"].contains(token) { return .function(token, arity: 2) }
        if ["theta", "alpha", "beta", "lambda", "mu", "omega"].contains(token) { return .symbol(token) }
        if token.count > 1, token.allSatisfy(\.isLetter) { return .function(token, arity: 1) }
        return token.count == 1 ? .symbol(token) : nil
    }

    /// Plays a script token on the keys in view: `page1` … `page4` pick a page, and a key name presses that key when the open
    /// submenu, the spine or the page in view has it; a submenu key (`sinh`, `sec`) opens its submenu. Returns the seconds
    /// it takes, or nil when no key in view answers.
    public func perform(_ token: String) -> Double? {
        if token.hasPrefix("page"), let number = Int(token.dropFirst(4)) {
            show(page: number - 1, animated: true)
            return 0.9
        }
        guard let wanted = Self.key(named: token) else { return nil }
        let spine: CanonMathKeyView? = wanted == .delete ? delete : wanted == .clear ? clear : nil
        let view = spine ?? submenu?.items.first { $0.key == wanted }?.view ?? pages[page].keys.first { $0.spec.key == wanted }?.view
        guard let view else { return nil }
        let opensMenu = submenu == nil && pages[page].keys.contains { $0.view === view && $0.spec.menu != nil }
        let tap = view.demoTap()
        return opensMenu ? 0.8 : tap
    }

    /// Every page's keys cover its grid once, and every key has a label and types something.
    public static func selfCheck() {
        for (index, specs) in pages(variable: "t").enumerated() {
            var covered = Set<Int>()
            for spec in specs {
                let cell = spec.cell
                for x in cell.x..<cell.x + cell.w {
                    for y in cell.y..<cell.y + cell.h {
                        assert(x < CanonMathPage.columns && y < CanonMathPage.rows, "page \(index) key off the grid")
                        assert(covered.insert(y * CanonMathPage.columns + x).inserted, "page \(index) cell \(x),\(y) twice")
                    }
                }
                for key in spec.menu?.keys ?? [spec.key] {
                    assert(label(key, variable: "t", size: 20).width > 0, "page \(index) key without a label")
                    let typed = CanonMathExpression(text: "", variable: "t")
                    typed.apply(key)
                    assert(!typed.text.isEmpty, "page \(index) key types nothing")
                }
            }
            assert(covered.count == CanonMathPage.columns * CanonMathPage.rows, "page \(index) has gaps")
        }
        assert(letters(variable: "t").first == "t" && letters(variable: "t").count == 12)
        assert(CanonMathFamily.of(.symbol("7")) == .digit && CanonMathFamily.of(.integral(bounded: true)) == .calculus)
    }
    #endif
}

extension CanonMathExpression.Key {
    /// True when the key opens an empty slot for what is typed next.
    public var opensSlot: Bool {
        switch self {
        case .fraction, .divide, .power, .root, .cubeRoot, .nthRoot, .logBase, .exponential, .scientific, .open, .fence, .function,
             .series, .integral, .derivative, .limit, .binomial, .permutation:
            true
        default:
            false
        }
    }
}
