import UIKit

/// A measured span: a rule with end ticks along its bottom edge, the pixel figure centred above it.
public final class CanonDimensionLine: UIView {
    public static let height: CGFloat = 32
    /// Room a picture leaves on its top and leading sides for a pair of lines and their figures.
    public static let room: CGFloat = 44
    private let rule = UIView()
    private let ticks = [UIView(), UIView()]
    private let figure = CanonFigure(size: 17, relativeTo: .footnote, halo: .delphiMuted)

    /// Muted rule and ticks with no figure: an empty picture keeps a loaded one's frame without stale sizes.
    public var isBlank = false {
        didSet {
            guard isBlank != oldValue else { return }
            figure.isHidden = isBlank
            ([rule] + ticks).forEach { $0.backgroundColor = isBlank ? .delphiMutedForeground : .delphiPrimary }
        }
    }

    public init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        ([rule] + ticks).forEach {
            $0.backgroundColor = .delphiPrimary
            addSubview($0)
        }
        figure.translatesAutoresizingMaskIntoConstraints = false
        addSubview(figure)
        NSLayoutConstraint.activate([
            figure.centerXAnchor.constraint(equalTo: centerXAnchor),
            figure.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func show(_ pixels: Int, animated: Bool) {
        figure.show("\(pixels)", unit: "px", animated: animated)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let tick: CGFloat = 9
        let line = DelphiMetrics.hairline
        rule.frame = CGRect(x: 0, y: bounds.height - tick / 2 - line / 2, width: bounds.width, height: line)
        ticks[0].frame = CGRect(x: 0, y: bounds.height - tick, width: line, height: tick)
        ticks[1].frame = CGRect(x: bounds.width - line, y: bounds.height - tick, width: line, height: tick)
    }

    /// Lays `across` over `span` and `down`, turned, along its leading side, each `gap` outside `edge` (`span` when nil).
    public static func place(across: CanonDimensionLine, down: CanonDimensionLine?, span: CGRect, edge: CGRect? = nil, gap: CGFloat = 12, rightToLeft: Bool) {
        let edge = edge ?? span
        across.bounds = CGRect(x: 0, y: 0, width: span.width, height: height)
        across.center = CGPoint(x: span.midX, y: edge.minY - gap - height / 2)
        guard let down else { return }
        down.bounds = CGRect(x: 0, y: 0, width: span.height, height: height)
        down.center = CGPoint(x: rightToLeft ? edge.maxX + gap + height / 2 : edge.minX - gap - height / 2, y: span.midY)
        down.transform = CGAffineTransform(rotationAngle: rightToLeft ? .pi / 2 : -.pi / 2)
    }

    /// Frame for a picture of `size` fitted into `area`, leaving `room` for the lines on the leading and top sides.
    public static func sheet(for size: CGSize, in area: CGRect, rightToLeft: Bool) -> CGRect {
        let room = CGSize(width: area.width - Self.room, height: area.height - Self.room)
        guard size.width > 0, size.height > 0, room.width > 0, room.height > 0 else { return .zero }
        let scale = min(room.width / size.width, room.height / size.height)
        // keep degenerate sizes visible
        let fitted = CGSize(width: max(1, size.width * scale), height: max(1, size.height * scale))
        let group = CGSize(width: fitted.width + Self.room, height: fitted.height + Self.room)
        let origin = CGPoint(x: area.midX - group.width / 2, y: area.midY - group.height / 2)
        return CGRect(x: rightToLeft ? origin.x : origin.x + Self.room, y: origin.y + Self.room, width: fitted.width, height: fitted.height)
    }
}

#if DEBUG
extension CanonDimensionLine {
    public static func selfCheck() {
        let (across, down) = (CanonDimensionLine(), CanonDimensionLine())
        let span = CGRect(x: 44, y: 44, width: 200, height: 100)
        place(across: across, down: down, span: span, rightToLeft: false)
        assert(across.frame == CGRect(x: 44, y: 0, width: 200, height: 32), "\(across.frame)")
        assert(down.center == CGPoint(x: 16, y: 94) && down.bounds.size == CGSize(width: 100, height: 32), "\(down.frame)")
        place(across: across, down: down, span: span, rightToLeft: true)
        assert(down.center == CGPoint(x: 272, y: 94), "\(down.frame)")
        place(across: across, down: nil, span: span.insetBy(dx: 50, dy: 20), edge: span, gap: 8, rightToLeft: false)
        assert(across.frame == CGRect(x: 94, y: 4, width: 100, height: 32), "\(across.frame)")
        across.isBlank = true
        assert(across.subviews.contains { $0 is CanonFigure && $0.isHidden })
    }
}
#endif
