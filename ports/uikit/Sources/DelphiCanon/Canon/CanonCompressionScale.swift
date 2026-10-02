import UIKit

/// Two bars to one scale: the original's bytes and the result's, with the saving as a figure.
public final class CanonCompressionScale: UIView {
    private let figure = CanonFigure()
    private let loader = CanonLoader(cell: 5, gap: 1, colour: .delphiMutedForeground)
    private let original = Bar(fill: .delphiMuted, ink: .delphiForeground)
    private let result = Bar(fill: .delphiPrimary, ink: .delphiPrimaryForeground)

    public init() {
        super.init(frame: .zero)
        backgroundColor = .delphiCard
        figure.show("—", animated: false)
        loader.isHidden = true

        let top = UIStackView(arrangedSubviews: [loader, figure])
        top.spacing = 12
        top.alignment = .center
        [top, original, result].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        let padding = DelphiMetrics.panelPadding
        let safe = safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            top.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -padding),
            top.bottomAnchor.constraint(equalTo: original.topAnchor, constant: -10),
            original.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: padding),
            original.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -padding),
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
        let bytes = { (count: Int) in ByteCountFormatter.string(fromByteCount: Int64(count), countStyle: .file) }
        original.show(label: String(localized: "Original"), size: before > 0 ? bytes(before) : nil, share: 1, animated: animated)

        let known = before > 0 && after > 0
        let grew = after > before
        result.tint(grew ? .delphiDestructive : .delphiPrimary)
        result.show(
            label: format, size: known ? bytes(after) : nil,
            share: known ? min(1, CGFloat(after) / CGFloat(before)) : 0, animated: animated
        )

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

    private final class Bar: CanonBar {
        private let label = UILabel.canon(nil, .footnote, weight: .semibold)
        private let ink: UIColor

        public init(fill colour: UIColor, ink: UIColor) {
            self.ink = ink
            super.init(fill: colour, track: nil)
            label.numberOfLines = 1
            addSubview(label)
        }

        public func tint(_ colour: UIColor) {
            fillColour = colour
        }

        public func show(label text: String, size: String?, share: CGFloat, animated: Bool) {
            label.text = [text, size].compactMap { $0 }.joined(separator: "  ")
            guard share != self.share else { return setNeedsLayout() }
            self.share = share
            guard animated, !UIAccessibility.isReduceMotionEnabled else { return }
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .beginFromCurrentState) {
                self.layoutIfNeeded()
            }
        }

        public override func layoutSubviews() {
            super.layoutSubviews()
            let flipped = effectiveUserInterfaceLayoutDirection == .rightToLeft
            let text = label.intrinsicContentSize.width
            let inside = filledWidth >= text + 20
            label.textColor = inside ? ink : .delphiForeground
            let x = inside ? 10 : filledWidth + 10
            label.frame = CGRect(x: flipped ? bounds.width - x - text : x, y: 0, width: text, height: bounds.height)
        }
    }
}
