import AppKit

/// The checks drawn behind transparent pixels: card and muted squares of `side` points, a card square first.
public nonisolated enum CanonChecks {
    public static let side: CGFloat = 8

    public static func fill(_ context: CGContext, _ rect: CGRect, square: CGFloat = side, tones: (light: CGColor, dark: CGColor)) {
        context.saveGState()
        context.clip(to: rect)
        context.setFillColor(tones.light)
        context.fill(rect)
        context.setFillColor(tones.dark)
        let columns = Int((rect.width / square).rounded(.up)), rows = Int((rect.height / square).rounded(.up))
        for row in 0..<max(rows, 0) {
            for column in 0..<max(columns, 0) where (row + column) % 2 == 1 {
                context.fill(CGRect(x: rect.minX + CGFloat(column) * square, y: rect.minY + CGFloat(row) * square, width: square, height: square))
            }
        }
        context.restoreGState()
    }

    /// The tones under `appearance`.
    @MainActor public static func tones(_ appearance: NSAppearance) -> (light: CGColor, dark: CGColor) {
        var tones = (light: CGColor(gray: 1, alpha: 1), dark: CGColor(gray: 0.9, alpha: 1))
        appearance.performAsCurrentDrawingAppearance { tones = (NSColor.delphiCard.cgColor, NSColor.delphiMuted.cgColor) }
        return tones
    }
}

/// Checks filling the view; `alwaysLight` keeps the light tones in dark mode, for art that must stay visible.
public final class CanonChecksView: NSView {
    public var alwaysLight = false {
        didSet { needsDisplay = true }
    }

    public override var isFlipped: Bool { true }

    public override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let appearance = alwaysLight ? NSAppearance(named: .aqua) ?? effectiveAppearance : effectiveAppearance
        CanonChecks.fill(context, bounds, tones: CanonChecks.tones(appearance))
    }
}

/// A measured span: a rule with end ticks along the edge nearest the picture, the pixel figure beside it. A vertical
/// line reads bottom to top with its rule on the trailing edge.
public final class CanonDimensionLine: NSView {
    public static let height: CGFloat = 32
    /// Room a picture leaves on its top and leading sides for a pair of lines and their figures.
    public static let room: CGFloat = 44
    private static let figureFont = NSFont.delphiMono(15, weight: .bold)
    private static let unitFont = NSFont.systemFont(ofSize: 9, weight: .semibold, width: .condensed)

    public let vertical: Bool
    private var pixels: Int?

    /// Muted rule and ticks with no figure: an empty picture keeps a loaded one's frame without stale sizes.
    public var isBlank = false {
        didSet { if isBlank != oldValue { needsDisplay = true } }
    }

    public init(vertical: Bool = false) {
        self.vertical = vertical
        super.init(frame: .zero)
        setAccessibilityElement(true)
        setAccessibilityRole(.staticText)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var isFlipped: Bool { true }

    public func show(_ pixels: Int) {
        guard pixels != self.pixels else { return }
        self.pixels = pixels
        setAccessibilityLabel("\(pixels) px")
        needsDisplay = true
    }

    public override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        var length = bounds.width, depth = bounds.height
        if vertical {
            (length, depth) = (bounds.height, bounds.width)
            context.translateBy(x: 0, y: bounds.height)
            context.rotate(by: -.pi / 2)
        }
        let ink: NSColor = isBlank ? .delphiMutedForeground : .delphiPrimary
        let tick: CGFloat = 9, line = DelphiMetrics.hairline
        context.setFillColor(ink.cgColor)
        context.fill([
            CGRect(x: 0, y: depth - tick / 2 - line / 2, width: length, height: line),
            CGRect(x: 0, y: depth - tick, width: line, height: tick),
            CGRect(x: length - line, y: depth - tick, width: line, height: tick),
        ])
        guard !isBlank, let pixels else { return }
        let halo = NSShadow()
        halo.shadowColor = .delphiMuted
        halo.shadowBlurRadius = 2
        let text = NSMutableAttributedString(string: "\(pixels)", attributes: [.font: Self.figureFont, .foregroundColor: ink, .shadow: halo])
        text.append(NSAttributedString(string: " px", attributes: [.font: Self.unitFont, .foregroundColor: ink, .shadow: halo]))
        let size = text.size()
        NSGraphicsContext.saveGraphicsState()
        text.draw(at: CGPoint(x: (length - size.width) / 2, y: depth - 5 - size.height - 4))
        NSGraphicsContext.restoreGraphicsState()
    }

    /// Lays `across` over `span` and `down` along its leading side, each `gap` outside `edge` (`span` when nil).
    public static func place(across: CanonDimensionLine, down: CanonDimensionLine?, span: CGRect, edge: CGRect? = nil, gap: CGFloat = 12) {
        let edge = edge ?? span
        across.frame = CGRect(x: span.minX, y: edge.minY - gap - height, width: span.width, height: height)
        down?.frame = CGRect(x: edge.minX - gap - height, y: span.minY, width: height, height: span.height)
    }

    /// Frame for a picture of `size` fitted into `area`, leaving `room` for the lines on the leading and top sides.
    public static func sheet(for size: CGSize, in area: CGRect) -> CGRect {
        let room = CGSize(width: area.width - Self.room, height: area.height - Self.room)
        guard size.width > 0, size.height > 0, room.width > 0, room.height > 0 else { return .zero }
        let scale = min(room.width / size.width, room.height / size.height)
        // keep degenerate sizes visible
        let fitted = CGSize(width: max(1, size.width * scale), height: max(1, size.height * scale))
        let group = CGSize(width: fitted.width + Self.room, height: fitted.height + Self.room)
        let origin = CGPoint(x: area.midX - group.width / 2, y: area.midY - group.height / 2)
        return CGRect(x: origin.x + Self.room, y: origin.y + Self.room, width: fitted.width, height: fitted.height)
    }

    #if DEBUG
    public static func selfCheck() {
        let (across, down) = (CanonDimensionLine(), CanonDimensionLine(vertical: true))
        let span = CGRect(x: 44, y: 44, width: 200, height: 100)
        place(across: across, down: down, span: span)
        assert(across.frame == CGRect(x: 44, y: 0, width: 200, height: 32), "\(across.frame)")
        assert(down.frame == CGRect(x: 0, y: 44, width: 32, height: 100), "\(down.frame)")
        place(across: across, down: nil, span: span.insetBy(dx: 50, dy: 20), edge: span, gap: 8)
        assert(across.frame == CGRect(x: 94, y: 4, width: 100, height: 32), "\(across.frame)")
        assert(sheet(for: CGSize(width: 2, height: 1), in: CGRect(x: 0, y: 0, width: 244, height: 144)) == CGRect(x: 44, y: 44, width: 200, height: 100))
    }
    #endif
}

/// Two bars to one scale: the original's bytes and the result's, with the saving as a figure.
public final class CanonCompressionScale: CanonView {
    private let figure = CanonFigure()
    private let loader = CanonLoader(cell: 5, gap: 1, colour: .delphiMutedForeground)
    private let original = Bar(fill: .delphiMuted, ink: .delphiForeground)
    private let result = Bar(fill: .delphiPrimary, ink: .delphiPrimaryForeground)

    public init() {
        super.init(fill: .delphiCard)
        figure.show("—", animated: false)
        loader.isHidden = true
        let top = NSStackView(views: [loader, figure])
        top.spacing = 12
        top.alignment = .centerY
        [top, original, result].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        let padding = DelphiMetrics.panelPadding
        NSLayoutConstraint.activate([
            top.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            top.bottomAnchor.constraint(equalTo: original.topAnchor, constant: -10),
            original.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            original.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            original.heightAnchor.constraint(equalToConstant: 32),
            result.topAnchor.constraint(equalTo: original.bottomAnchor, constant: DelphiMetrics.hairline),
            result.leadingAnchor.constraint(equalTo: original.leadingAnchor),
            result.trailingAnchor.constraint(equalTo: original.trailingAnchor),
            result.heightAnchor.constraint(equalToConstant: 32),
            result.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
        ])
        original.show(label: String(localized: "Original"), size: nil, share: 1, animated: false)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func show(before: Int, after: Int, format: String, isWorking: Bool, animated: Bool) {
        let animated = animated && canonAnimates
        let bytes = { (count: Int) in ByteCountFormatter.string(fromByteCount: Int64(count), countStyle: .file) }
        original.show(label: String(localized: "Original"), size: before > 0 ? bytes(before) : nil, share: 1, animated: animated)
        let known = before > 0 && after > 0
        let grew = after > before
        result.filled.fill = grew ? .delphiDestructive : .delphiPrimary
        result.show(label: format, size: known ? bytes(after) : nil,
                    share: known ? min(1, CGFloat(after) / CGFloat(before)) : 0, animated: animated)
        if known {
            let saving = Self.savingsPercent(before: before, after: after)
            figure.show(saving == 0 ? "±0" : "\(saving < 0 ? "−" : "+")\(abs(saving))", unit: "%", animated: animated)
        } else {
            figure.show("—", animated: animated)
        }
        figure.setColour(grew ? .delphiDestructive : .delphiPrimary)
        if loader.isHidden == isWorking { loader.isHidden = !isWorking }
    }

    /// Size change as a whole percentage of `before`: negative is smaller.
    public nonisolated static func savingsPercent(before: Int, after: Int) -> Int {
        guard before > 0 else { return 0 }
        return Int((Double(after - before) / Double(before) * 100).rounded())
    }

    private final class Bar: CanonView {
        let filled: CanonView
        private let label = NSTextField.canon(size: 11, weight: .semibold)
        private let ink: NSColor
        private var share: CGFloat = 0

        init(fill colour: NSColor, ink: NSColor) {
            self.ink = ink
            filled = CanonView(fill: colour)
            super.init()
            addSubview(filled)
            addSubview(label)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func show(label text: String, size: String?, share: CGFloat, animated: Bool) {
            label.stringValue = [text, size].compactMap { $0 }.joined(separator: "  ")
            guard share != self.share else { return needsLayout = true }
            self.share = share
            guard animated else { return needsLayout = true }
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.45
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                context.allowsImplicitAnimation = true
                layoutFill()
            }
        }

        override func layout() {
            super.layout()
            layoutFill()
        }

        private func layoutFill() {
            let width = bounds.width * min(max(share, 0), 1)
            filled.frame = CGRect(x: 0, y: 0, width: width, height: bounds.height)
            let text = label.cell?.cellSize ?? label.intrinsicContentSize
            let inside = width >= text.width + 20
            label.textColor = inside ? ink : .delphiForeground
            label.frame = CGRect(x: inside ? 10 : width + 10, y: (bounds.height - text.height) / 2, width: text.width, height: text.height)
        }
    }
}

/// Before and after, one over the other, split by a divider a click or drag moves.
public final class CanonImageCompare: CanonView {
    private let before = NSImageView()
    private let after = NSImageView()
    private let afterClip = NSView()
    private let divider = CanonView(fill: .delphiForeground)
    private let grip = NSImageView()
    private let beforeTag = CanonImageCompare.tag(String(localized: "Before"))
    private let afterTag = CanonImageCompare.tag(String(localized: "After"))
    private let failure: NSTextField
    /// original's width fraction
    private var split: CGFloat = 0.5

    /// - Parameter failure: shown over the dimmed original when the result could not be made.
    public init(failure text: String) {
        failure = .canon(text, size: 12, colour: .delphiMutedForeground, wraps: true)
        super.init()
        layer?.masksToBounds = true
        for view in [before, after] {
            view.imageScaling = .scaleProportionallyUpOrDown
        }
        afterClip.clipsToBounds = true
        afterClip.addSubview(after)
        grip.image = NSImage(systemSymbolName: "arrow.left.and.right", accessibilityDescription: nil)
        grip.contentTintColor = .delphiForeground
        grip.wantsLayer = true
        grip.layer?.borderWidth = DelphiMetrics.frame
        failure.alignment = .center
        [before, afterClip, divider, grip, beforeTag, afterTag, failure].forEach(addSubview)
        setAccessibilityElement(true)
        setAccessibilityRole(.slider)
        setAccessibilityLabel("\(String(localized: "Before")), \(String(localized: "After"))")
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var isFlipped: Bool { true }

    public func show(before image: NSImage?, after result: NSImage?, failed: Bool) {
        before.image = image
        after.image = result
        let comparing = image != nil && result != nil
        [afterClip, divider, grip, beforeTag, afterTag].forEach { $0.isHidden = !comparing }
        failure.isHidden = !failed
        before.alphaValue = failed ? 0.25 : 1
    }

    public override func mouseDown(with event: NSEvent) { moveDivider(event) }
    public override func mouseDragged(with event: NSEvent) { moveDivider(event) }

    private func moveDivider(_ event: NSEvent) {
        guard bounds.width > 0, !divider.isHidden else { return }
        split = min(max(convert(event.locationInWindow, from: nil).x / bounds.width, 0), 1)
        setAccessibilityValue("\(Int(split * 100))%")
        needsLayout = true
    }

    public override func accessibilityPerformIncrement() -> Bool { nudge(0.1) }
    public override func accessibilityPerformDecrement() -> Bool { nudge(-0.1) }

    private func nudge(_ delta: CGFloat) -> Bool {
        split = min(max(split + delta, 0), 1)
        setAccessibilityValue("\(Int(split * 100))%")
        needsLayout = true
        return true
    }

    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsLayout = true
    }

    public override func layout() {
        super.layout()
        let x = bounds.width * split
        before.frame = bounds
        afterClip.frame = CGRect(x: x, y: 0, width: bounds.width - x, height: bounds.height)
        after.frame = CGRect(x: -x, y: 0, width: bounds.width, height: bounds.height)
        divider.frame = CGRect(x: x - 1, y: 0, width: 2, height: bounds.height)
        grip.frame = CGRect(x: x - 16, y: bounds.midY - 16, width: 32, height: 32)
        effectiveAppearance.performAsCurrentDrawingAppearance {
            grip.layer?.backgroundColor = NSColor.delphiCard.cgColor
            grip.layer?.borderColor = NSColor.delphiForeground.cgColor
        }
        // insetBy past zero is null, origin infinite
        let inset = bounds.width > 20 && bounds.height > 20 ? bounds.insetBy(dx: 10, dy: 10) : bounds
        let leading = beforeTag.fittingSize, trailing = afterTag.fittingSize
        beforeTag.frame = CGRect(origin: CGPoint(x: inset.minX, y: inset.minY), size: leading)
        afterTag.frame = CGRect(origin: CGPoint(x: inset.maxX - trailing.width, y: inset.minY), size: trailing)
        let width = max(0, bounds.width - 48)
        let height = width > 0 ? failure.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height : 0
        failure.frame = CGRect(x: 24, y: (bounds.height - height) / 2, width: width, height: height)
    }

    private static func tag(_ text: String) -> NSView {
        let view = CanonView(fill: .delphiCard)
        view.pin(NSTextField.canonHeading(text), insets: NSEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
        return view
    }
}
