import UIKit

/// A row of a `CanonDetentWheel`. `focus` is 1 on the centre line and 0 a row or more away.
public protocol CanonDetentWheelRow: UIView {
    func setFocus(_ focus: CGFloat)
}

/// Rows on a drum, turned by a vertical drag, with inertia; it comes to rest on a row, and the centred row is the
/// selection. A row crossing the centre ticks, the rest clacks. Rows flatten and fade with their angle from the
/// centre. It loops when there are more rows than fit; otherwise the ends pull back like rubber.
public final class CanonDetentWheel: UIView {
    /// 1/s, exponential decay of a fling.
    public static let friction: CGFloat = 4.5
    /// Share of the finger's speed a release keeps, and its cap in rows per second.
    public static let flingCarry: CGFloat = 0.85
    public static let flingLimit: CGFloat = 36
    /// Rows per second below which the nearest row catches the wheel.
    public static let catchSpeed: CGFloat = 2.5
    /// Seconds of travel looked ahead when choosing the row to catch.
    public static let catchLead: CGFloat = 0.12
    /// Detent spring; about 2 % overshoot.
    public static let stiffness: CGFloat = 320
    public static let damping: CGFloat = 28
    /// Share of a drag that moves the wheel past its ends.
    public static let rubber: CGFloat = 0.3
    /// Furthest angle a row is drawn at, radians from the centre.
    public static let reach: CGFloat = .pi / 2 * 0.94

    public struct Motion: Equatable {
        public var position: CGFloat
        public var velocity: CGFloat = 0
        public var target: CGFloat?

        public var isSettled: Bool { target == position && velocity == 0 }

        public init(position: CGFloat, velocity: CGFloat = 0, target: CGFloat? = nil) {
            self.position = position
            self.velocity = velocity
            self.target = target
        }
    }

    public let rowHeight: CGFloat
    private let makeRow: () -> CanonDetentWheelRow
    private let configure: (CanonDetentWheelRow, Int) -> Void

    /// The centred row changed, by a drag, a fling, a tap or `select`; not during a `reload` spin.
    public var onSelect: ((Int) -> Void)?
    /// VoiceOver's reading of a row.
    public var accessibilityText: ((Int) -> String)?

    public private(set) var count = 0
    public private(set) var selected = 0
    private var motion = Motion(position: 0)
    private var isDragging = false
    /// Haptics only for motion the user started.
    private var isUserDriven = false
    private var isSpinning = false
    private var live: [Int: CanonDetentWheelRow] = [:]
    private var spare: [CanonDetentWheelRow] = []
    private var link: CADisplayLink?
    private var lastTick: CFTimeInterval = 0
    private let tick = UISelectionFeedbackGenerator()
    private let clack = UIImpactFeedbackGenerator(style: .rigid)

    public init(rowHeight: CGFloat, makeRow: @escaping () -> CanonDetentWheelRow, configure: @escaping (CanonDetentWheelRow, Int) -> Void) {
        self.rowHeight = rowHeight
        self.makeRow = makeRow
        self.configure = configure
        super.init(frame: .zero)
        clipsToBounds = true
        let pan = CanonGrabPan(target: self, action: #selector(dragged(_:)))
        pan.grabs = { [unowned self] _ in count > 0 }
        addGestureRecognizer(pan)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
        isAccessibilityElement = true
        accessibilityTraits = .adjustable
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Geometry

    private var radius: CGFloat { max(bounds.height / 2, rowHeight) }
    private var step: CGFloat { rowHeight / radius }

    /// Rows that fit on the visible half-turn; with more than this the wheel loops.
    public var fitting: Int { 2 * Int(Self.reach / step) + 1 }
    public var loops: Bool { count > fitting }

    private var range: ClosedRange<CGFloat>? { loops ? nil : 0...CGFloat(max(count - 1, 0)) }

    private func wrapped(_ index: Int) -> Int {
        count == 0 ? 0 : ((index % count) + count) % count
    }

    // MARK: Content

    /// New rows, centred on `selecting`. `spin` rows of travel roll the wheel in from above, without ticks or `onSelect`.
    public func reload(count: Int, selecting: Int, spin: CGFloat = 0) {
        self.count = count
        for (_, row) in live {
            row.isHidden = true
            spare.append(row)
        }
        live = [:]
        let index = count == 0 ? 0 : min(max(selecting, 0), count - 1)
        selected = index
        isUserDriven = false
        let animated = spin != 0 && !UIAccessibility.isReduceMotionEnabled && window != nil
        isSpinning = animated
        motion = Motion(position: CGFloat(index) - (animated ? spin : 0), target: CGFloat(index))
        if animated { run() } else { motion.position = CGFloat(index) }
        layoutRows()
        refreshAccessibility()
    }

    /// Re-reads the rows in view, for content that changed in place.
    public func reconfigure() {
        for (index, row) in live { configure(row, wrapped(index)) }
        refreshAccessibility()
    }

    /// Turns to `index` by the shorter way round, ticking past the rows between.
    public func select(_ index: Int, animated: Bool) {
        guard count > 0 else { return }
        var goal = CGFloat(index)
        if loops {
            let here = motion.position.rounded()
            let ahead = CGFloat(wrapped(index - Int(here)))
            goal = here + (ahead > CGFloat(count) / 2 ? ahead - CGFloat(count) : ahead)
        }
        if animated && !UIAccessibility.isReduceMotionEnabled {
            isUserDriven = true
            isSpinning = false
            motion.target = goal
            run()
        } else {
            motion = Motion(position: goal, target: goal)
            layoutRows()
        }
    }

    /// Starts a fling as a release at this speed would, in rows per second; for DEBUG recordings.
    public func fling(rowsPerSecond speed: CGFloat) {
        isUserDriven = true
        isSpinning = false
        motion.target = nil
        motion.velocity = speed
        run()
    }

    // MARK: Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutRows()
    }

    private func layoutRows() {
        guard count > 0, bounds.height > 0 else {
            live.values.forEach { $0.isHidden = true }
            return
        }
        let half = Int(Self.reach / step) + 1
        let centre = Int(motion.position.rounded())
        var wanted = Set<Int>()
        for index in (centre - half)...(centre + half) where loops || (0..<count).contains(index) {
            if abs(CGFloat(index) - motion.position) * step <= Self.reach { wanted.insert(index) }
        }
        for (index, row) in live where !wanted.contains(index) {
            row.isHidden = true
            spare.append(row)
            live[index] = nil
        }
        for index in wanted {
            let row: CanonDetentWheelRow
            if let existing = live[index] {
                row = existing
            } else {
                row = spare.popLast() ?? makeRow()
                if row.superview == nil { addSubview(row) }
                row.isHidden = false
                configure(row, wrapped(index))
                live[index] = row
            }
            let offset = CGFloat(index) - motion.position
            let angle = offset * step
            let lean = cos(angle)
            row.bounds = CGRect(x: 0, y: 0, width: bounds.width, height: rowHeight)
            row.center = CGPoint(x: bounds.midX, y: bounds.midY + radius * sin(angle))
            row.transform = CGAffineTransform(scaleX: 1, y: max(lean, 0.01))
            row.alpha = pow(max(lean, 0), 1.4)
            row.setFocus(max(0, 1 - abs(offset)))
        }

        let nearest = wrapped(centre)
        if nearest != selected, !isSpinning {
            selected = nearest
            if isUserDriven { tick.selectionChanged() }
            onSelect?(nearest)
            refreshAccessibility()
        }
    }

    // MARK: Touch

    @objc private func dragged(_ pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            link?.invalidate()
            link = nil
            isDragging = true
            isUserDriven = true
            isSpinning = false
            motion.velocity = 0
            motion.target = nil
            tick.prepare()
            clack.prepare()
        case .changed:
            var rows = -pan.translation(in: self).y / rowHeight
            pan.setTranslation(.zero, in: self)
            if let range, !range.contains(motion.position) { rows *= Self.rubber }
            motion.position += rows
            layoutRows()
        case .ended, .cancelled, .failed:
            isDragging = false
            let speed = -pan.velocity(in: self).y / rowHeight * Self.flingCarry
            motion.velocity = min(max(speed, -Self.flingLimit), Self.flingLimit)
            run()
        default:
            break
        }
    }

    @objc private func tapped(_ tap: UITapGestureRecognizer) {
        guard count > 0 else { return }
        let lift = (tap.location(in: self).y - bounds.midY) / radius
        let rows = (asin(min(max(lift, -1), 1)) / step).rounded()
        guard rows != 0 else { return }
        var goal = motion.position.rounded() + rows
        if let range { goal = min(max(goal, range.lowerBound), range.upperBound) }
        isUserDriven = true
        isSpinning = false
        motion.target = goal
        clack.prepare()
        run()
    }

    // MARK: Motion

    /// One frame of a released wheel: coast under friction, then a spring onto the caught row. `range` is nil when it loops.
    public static func advance(_ motion: Motion, by seconds: CGFloat, range: ClosedRange<CGFloat>?) -> Motion {
        var next = motion
        func clamped(_ value: CGFloat) -> CGFloat {
            guard let range else { return value }
            return min(max(value, range.lowerBound), range.upperBound)
        }
        if let target = next.target {
            let pull = -stiffness * (next.position - target) - damping * next.velocity
            next.velocity += pull * seconds
            next.position += next.velocity * seconds
            if abs(next.position - target) < 0.001, abs(next.velocity) < 0.02 {
                next.position = target
                next.velocity = 0
            }
        } else {
            next.position += next.velocity * seconds
            next.velocity *= exp(-friction * seconds)
            if let range, !range.contains(next.position) {
                next.target = clamped(next.position.rounded())
            } else if abs(next.velocity) < catchSpeed {
                next.target = clamped((next.position + next.velocity * catchLead).rounded())
            }
        }
        return next
    }

    private func run() {
        guard link == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(frame(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
        lastTick = CACurrentMediaTime()
    }

    @objc private func frame(_ link: CADisplayLink) {
        let now = CACurrentMediaTime()
        let seconds = CGFloat(min(now - lastTick, 1.0 / 30))
        lastTick = now
        guard !isDragging else { return }
        motion = Self.advance(motion, by: seconds, range: range)
        layoutRows()
        guard motion.isSettled else { return }
        link.invalidate()
        self.link = nil
        if isUserDriven { clack.impactOccurred(intensity: 0.55) }
        isUserDriven = false
        isSpinning = false
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window == nil else { return }
        link?.invalidate()
        link = nil
        if let target = motion.target {
            motion = Motion(position: target, target: target)
            isSpinning = false
        }
    }

    // MARK: Accessibility

    private func refreshAccessibility() {
        accessibilityValue = count > 0 ? accessibilityText?(selected) : nil
    }

    public override func accessibilityIncrement() {
        guard count > 0, loops || selected < count - 1 else { return }
        select(wrapped(selected + 1), animated: false)
    }

    public override func accessibilityDecrement() {
        guard count > 0, loops || selected > 0 else { return }
        select(wrapped(selected - 1), animated: false)
    }
}

#if DEBUG
extension CanonDetentWheel {
    public static func selfCheck() {
        func settle(_ start: Motion, range: ClosedRange<CGFloat>?) -> (Motion, CGFloat) {
            var motion = start
            var time: CGFloat = 0
            while !motion.isSettled, time < 10 {
                motion = advance(motion, by: 1.0 / 60, range: range)
                time += 1.0 / 60
            }
            return (motion, time)
        }
        let (flung, time) = settle(Motion(position: 0.3, velocity: 30), range: nil)
        assert(flung.isSettled && flung.position == flung.position.rounded() && flung.position > 4 && time < 3)
        let (pulled, _) = settle(Motion(position: 4.6, velocity: 12), range: 0...4)
        assert(pulled.position == 4)
        let (backwards, _) = settle(Motion(position: -0.8, velocity: -5), range: 0...4)
        assert(backwards.position == 0)
        let (caught, _) = settle(Motion(position: 2.45, velocity: 2), range: nil)
        assert(caught.position == 3)
    }
}
#endif
