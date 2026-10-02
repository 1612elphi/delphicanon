import UIKit

/// tap moves divider
public final class CanonImageCompare: UIView {
    private let before = UIImageView()
    private let after = UIImageView()
    private let afterClip = UIView()
    private let divider = UIView()
    private let grip = UIImageView(image: UIImage(systemName: "arrow.left.and.right"))
    private let beforeTag = CanonImageCompare.tag(String(localized: "Before"))
    private let afterTag = CanonImageCompare.tag(String(localized: "After"))
    private let failure = UILabel.canon(String(localized: "This format couldn't encode this image"), .subheadline, colour: .delphiMutedForeground)
    /// original's width fraction
    private var split: CGFloat = 0.5

    public init() {
        super.init(frame: .zero)
        clipsToBounds = true
        for view in [before, after] {
            view.contentMode = .scaleAspectFit
        }
        afterClip.clipsToBounds = true
        afterClip.addSubview(after)
        divider.backgroundColor = .delphiForeground
        grip.backgroundColor = .delphiCard
        grip.tintColor = .delphiForeground
        grip.contentMode = .center
        grip.layer.borderWidth = DelphiMetrics.frame
        failure.textAlignment = .center
        [before, afterClip, divider, grip, beforeTag, afterTag, failure].forEach(addSubview)

        let pan = CanonSidewaysPan(target: self, action: #selector(dragged))
        addGestureRecognizer(pan)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dragged)))

        isAccessibilityElement = true
        accessibilityTraits = .adjustable
        accessibilityLabel = "\(String(localized: "Before")), \(String(localized: "After"))"
        redrawsOnStyleChange(layout: true)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func setTitles(before: String, after: String) {
        (beforeTag.subviews.first as? UILabel)?.text = before
        (afterTag.subviews.first as? UILabel)?.text = after
        accessibilityLabel = "\(before), \(after)"
        setNeedsLayout()
    }

    public func show(before image: UIImage?, after result: UIImage?, failed: Bool) {
        before.image = image
        after.image = result
        let comparing = image != nil && result != nil
        [afterClip, divider, grip, beforeTag, afterTag].forEach { $0.isHidden = !comparing }
        failure.isHidden = !failed
        before.alpha = failed ? 0.25 : 1
    }

    @objc private func dragged(_ recognizer: UIGestureRecognizer) {
        guard bounds.width > 0, !divider.isHidden else { return }
        var share = recognizer.location(in: self).x / bounds.width
        if effectiveUserInterfaceLayoutDirection == .rightToLeft { share = 1 - share }
        split = min(max(share, 0), 1)
        setNeedsLayout()
        if recognizer is UITapGestureRecognizer, !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0) { self.layoutIfNeeded() }
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let flipped = effectiveUserInterfaceLayoutDirection == .rightToLeft
        let x = bounds.width * (flipped ? 1 - split : split)
        before.frame = bounds
        afterClip.frame = flipped
            ? CGRect(x: 0, y: 0, width: x, height: bounds.height)
            : CGRect(x: x, y: 0, width: bounds.width - x, height: bounds.height)
        after.frame = convert(bounds, to: afterClip)
        divider.frame = CGRect(x: x - 1, y: 0, width: 2, height: bounds.height)
        grip.frame = CGRect(x: x - 22, y: bounds.midY - 22, width: 44, height: 44)
        grip.layer.borderColor = UIColor.delphiForeground.resolvedColor(with: traitCollection).cgColor

        let inset = bounds.inset(by: safeAreaInsets).insetBy(dx: 10, dy: 10)
        let leading = beforeTag.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let trailing = afterTag.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let left = CGRect(origin: CGPoint(x: inset.minX, y: inset.minY), size: flipped ? trailing : leading)
        let right = CGRect(origin: CGPoint(x: inset.maxX - (flipped ? leading : trailing).width, y: inset.minY), size: flipped ? leading : trailing)
        beforeTag.frame = flipped ? right : left
        afterTag.frame = flipped ? left : right
        failure.frame = bounds.insetBy(dx: 24, dy: 24)
    }

    public override func accessibilityIncrement() { nudge(0.1) }
    public override func accessibilityDecrement() { nudge(-0.1) }

    private func nudge(_ delta: CGFloat) {
        split = min(max(split + delta, 0), 1)
        accessibilityValue = "\(Int(split * 100))%"
        setNeedsLayout()
    }

    private static func tag(_ text: String) -> UIView {
        let view = UIView()
        view.backgroundColor = .delphiCard
        let label = UILabel.canonHeading(text)
        // wrapping label keeps width
        label.numberOfLines = 1
        view.pin(label, insets: NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        return view
    }
}
