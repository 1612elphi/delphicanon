import AppKit

/// A track and its readout. A click sets the value there; a drag moves it, finer the further the pointer is pulled
/// above or below the track.
public final class CanonSlider: CanonView {
    /// Clamps the value; runs no handler.
    public var range: ClosedRange<Double> {
        didSet {
            guard range != oldValue else { return }
            value = min(max(value, range.lowerBound), range.upperBound)
        }
    }

    /// Values snap to multiples of this above the lower bound.
    public var step: Double?

    public var value: Double {
        didSet { refresh() }
    }

    /// Distance in points from the track, and the drag speed there.
    public static let fineTiers: [(distance: CGFloat, speed: Double)] = [(60, 0.5), (120, 0.25), (180, 0.1)]

    /// Runs on mouse down and on mouse up.
    public var onPress: (() -> Void)?
    public var onRelease: (() -> Void)?
    public private(set) var isDragging = false

    private let readout: (Double) -> String
    private let track = Track()
    private let label = NSTextField.canon(weight: .semibold)
    private var handlers: [(CanonSlider) -> Void] = []
    private var start = CGPoint.zero
    private var lastX: CGFloat = 0
    // unsnapped drag value
    private var dragged = 0.0

    public init(value: Double, range: ClosedRange<Double> = 0...1, step: Double? = nil,
                readout: @escaping (Double) -> String = { "\(Int(($0 * 100).rounded()))%" }) {
        self.value = value
        self.range = range
        self.step = step
        self.readout = readout
        super.init(fill: .delphiBorder)
        let ideal = track.widthAnchor.constraint(equalToConstant: 160)
        ideal.priority = .defaultLow
        ideal.isActive = true
        track.widthAnchor.constraint(greaterThanOrEqualToConstant: 96).isActive = true
        label.alignment = .center
        let cell = CanonView(fill: .delphiCard)
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 10),
            cell.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 10),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            cell.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),
        ])
        cell.setContentHuggingPriority(.required, for: .horizontal)
        pin(CanonStack([track, cell], vertical: false))
        heightAnchor.constraint(greaterThanOrEqualToConstant: DelphiMetrics.controlHeight).isActive = true
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
        setAccessibilityElement(true)
        setAccessibilityRole(.slider)
        refresh()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @discardableResult
    public func onChange(_ handler: @escaping (CanonSlider) -> Void) -> Self {
        handlers.append(handler)
        return self
    }

    private var span: Double { range.upperBound - range.lowerBound }

    private func refresh() {
        label.stringValue = readout(value)
        setAccessibilityValue(label.stringValue)
        track.fraction = span > 0 ? CGFloat((value - range.lowerBound) / span) : 0
    }

    private func set(_ raw: Double) {
        var next = min(max(raw, range.lowerBound), range.upperBound)
        if let step, step > 0 {
            next = min(range.upperBound, range.lowerBound + ((next - range.lowerBound) / step).rounded() * step)
        }
        guard next != value else { return }
        value = next
        handlers.forEach { $0(self) }
    }

    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    public override func mouseEntered(with event: NSEvent) { track.isActive = true }
    public override func mouseExited(with event: NSEvent) { if !isDragging { track.isActive = false } }

    public override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        start = point
        lastX = point.x
        isDragging = false
        track.isActive = true
        onPress?()
        let frame = track.convert(track.bounds, to: self)
        guard frame.width > 0 else { return }
        set(range.lowerBound + Double(min(max((point.x - frame.minX) / frame.width, 0), 1)) * span)
        dragged = value
    }

    public override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        isDragging = true
        let pull = abs(point.y - start.y)
        let speed = Self.fineTiers.last { pull >= $0.distance }?.speed ?? 1
        let width = max(track.bounds.width, 1)
        dragged = min(max(dragged + Double((point.x - lastX) / width) * span * speed, range.lowerBound), range.upperBound)
        lastX = point.x
        set(dragged)
    }

    public override func mouseUp(with event: NSEvent) {
        isDragging = false
        if !bounds.contains(convert(event.locationInWindow, from: nil)) { track.isActive = false }
        onRelease?()
    }

    public override func accessibilityPerformIncrement() -> Bool {
        set(value + (step ?? span / 20))
        return true
    }

    public override func accessibilityPerformDecrement() -> Bool {
        set(value - (step ?? span / 20))
        return true
    }

    private final class Track: CanonView {
        private let filled = CanonView(fill: .delphiPrimary)
        private let marker = CanonView(fill: .delphiForeground)

        var fraction: CGFloat = 0 {
            didSet { needsLayout = true }
        }

        var isActive = false {
            didSet { if isActive != oldValue { needsLayout = true } }
        }

        init() {
            super.init(fill: .delphiMuted)
            addSubview(filled)
            addSubview(marker)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func layout() {
            super.layout()
            let width = bounds.width * min(max(fraction, 0), 1)
            let thickness: CGFloat = isActive ? 6 : 2
            filled.frame = CGRect(x: 0, y: 0, width: width, height: bounds.height)
            marker.frame = CGRect(x: max(0, width - thickness), y: 0, width: thickness, height: bounds.height)
        }
    }
}
