import UIKit

/// 3 x 3 cell loader, a port of the web `nds-loader.css`.
public final class CanonLoader: UIView {

    public enum Mode {
        case snake, comet, dot, twin, thinking

        // css keyframes as tables
        fileprivate var trail: [Double] {
            switch self {
            case .snake, .thinking: [1, 1, 1, 1, 1]
            case .comet: [1, 0.65, 0.4, 0.22, 0.1]
            case .dot: [1]
            case .twin: [1, 1, 1, 0, 1, 1, 1]
            }
        }
    }

    // clockwise, nil is centre
    private static let order: [Int?] = [0, 1, 2, 7, nil, 3, 6, 5, 4]
    private static let dim = 0.2

    private let mode: Mode
    private let reverse: Bool
    private let cell: CGFloat
    private let gap: CGFloat
    private let cells: [CALayer] = (0..<9).map { _ in CALayer() }
    private var timer: Timer?
    private var step = 0

    public init(mode: Mode = .snake, reverse: Bool = false, cell: CGFloat = 8, gap: CGFloat = 2, colour: UIColor = .delphiForeground) {
        self.mode = mode
        self.reverse = reverse
        self.cell = cell
        self.gap = gap
        super.init(frame: .zero)
        tintColor = colour
        for (index, layer) in cells.enumerated() {
            layer.frame = CGRect(x: CGFloat(index % 3) * (cell + gap), y: CGFloat(index / 3) * (cell + gap), width: cell, height: cell)
            self.layer.addSublayer(layer)
        }
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        isAccessibilityElement = true
        accessibilityLabel = String(localized: "Loading")
        draw()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var intrinsicContentSize: CGSize {
        let side = cell * 3 + gap * 2
        return CGSize(width: side, height: side)
    }

    public override var isHidden: Bool {
        didSet { if isHidden != oldValue { restart() } }
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        restart()
    }

    // ticks only while visible
    private func restart() {
        timer?.invalidate()
        guard window != nil, !isHidden else { return }
        let tick = UIAccessibility.isReduceMotionEnabled ? 0.5 : 0.1
        let timer = Timer(timeInterval: tick, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                // run loop retains timer
                guard let self else { return timer.invalidate() }
                self.step += 1
                self.draw()
            }
        }
        // default mode pauses scrolling
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    public override func tintColorDidChange() {
        super.tintColorDidChange()
        draw()
    }

    private func draw() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (index, layer) in cells.enumerated() {
            let opacity = Self.order[index].map { max(Self.dim, lit($0, at: step)) } ?? 1
            layer.backgroundColor = tintColor.withAlphaComponent(opacity).cgColor
        }
        CATransaction.commit()
    }

    public func lit(_ index: Int, at step: Int) -> Double {
        let trail = mode.trail
        func since(_ visit: Int, cycle: Int) -> Double {
            let phase = ((step - visit) % cycle + cycle) % cycle
            return phase < trail.count ? trail[phase] : 0
        }
        // pendulum: visits i, 15-i
        if mode == .thinking { return max(since(index, cycle: 16), since(15 - index, cycle: 16)) }
        return since(reverse ? -index : index, cycle: 8)
    }
}
