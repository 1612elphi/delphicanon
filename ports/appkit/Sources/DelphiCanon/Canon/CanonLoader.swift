import AppKit

/// 3 x 3 cell loader, a port of the web `nds-loader.css` snake.
public final class CanonLoader: NSView {
    // clockwise, nil is centre
    private static let order: [Int?] = [0, 1, 2, 7, nil, 3, 6, 5, 4]
    private static let trail: [Double] = [1, 1, 1, 1, 1]
    private static let dim = 0.2

    private let cell: CGFloat
    private let gap: CGFloat
    private let colour: NSColor
    private let cells: [CALayer] = (0..<9).map { _ in CALayer() }
    private var timer: Timer?
    private var step = 0

    public init(cell: CGFloat = 8, gap: CGFloat = 2, colour: NSColor = .delphiForeground) {
        self.cell = cell
        self.gap = gap
        self.colour = colour
        super.init(frame: .zero)
        wantsLayer = true
        for (index, layer) in cells.enumerated() {
            layer.frame = CGRect(x: CGFloat(index % 3) * (cell + gap), y: CGFloat(index / 3) * (cell + gap), width: cell, height: cell)
            self.layer?.addSublayer(layer)
        }
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setAccessibilityElement(true)
        setAccessibilityRole(.progressIndicator)
        setAccessibilityLabel(String(localized: "Loading"))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var isFlipped: Bool { true }

    public override var intrinsicContentSize: NSSize {
        let side = cell * 3 + gap * 2
        return NSSize(width: side, height: side)
    }

    public override var isHidden: Bool {
        didSet { if isHidden != oldValue { restart() } }
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        restart()
    }

    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        paint()
    }

    // ticks only while visible
    private func restart() {
        timer?.invalidate()
        timer = nil
        paint()
        guard window != nil, !isHidden else { return }
        let tick = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0.5 : 0.1
        let timer = Timer(timeInterval: tick, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.step += 1
                self.paint()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func paint() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        effectiveAppearance.performAsCurrentDrawingAppearance {
            for (index, layer) in cells.enumerated() {
                let opacity = Self.order[index].map { max(Self.dim, Self.lit($0, at: step)) } ?? 1
                layer.backgroundColor = colour.withAlphaComponent(opacity).cgColor
            }
        }
        CATransaction.commit()
    }

    static func lit(_ index: Int, at step: Int) -> Double {
        let phase = ((step - index) % 8 + 8) % 8
        return phase < trail.count ? trail[phase] : 0
    }
}
