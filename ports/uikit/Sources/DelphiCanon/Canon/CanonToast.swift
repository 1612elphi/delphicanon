import UIKit

/// A short confirmation ("Copied", with the copied value beside it) that fades in near the bottom of the column
/// the last touch was in, stays a moment and fades out. VoiceOver reads it. Above a `CanonSplit` footer or the
/// shell's bottom band, and inside one pane, so it never sits on a crease.
public final class CanonToast: UIView {
    /// Seconds on screen after the last `show`.
    public static let hold: TimeInterval = 1.4

    private static weak var current: CanonToast?
    private static var lastTouch: (point: CGPoint, window: Weak<UIWindow>)?

    private let title = UILabel.canon(String(localized: "Copied"), .subheadline, weight: .semibold, colour: .delphiBackground)
    private let detail = UILabel.canon(nil, .footnote, colour: .delphiBackground)
    private var hiding: DispatchWorkItem?

    /// - Parameter detail: the copied value, shown in mono after the title when it is one short line.
    public static func show(_ detail: String? = nil) {
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Copied"))
        let touched = lastTouch?.window.value.flatMap { isActive($0) ? $0 : nil }
        guard let window = touched ?? keyWindow else { return }
        let toast = current?.window === window ? current! : CanonToast()
        if toast.superview == nil { window.addSubview(toast) }
        current = toast
        let short = detail.flatMap { $0.contains("\n") || $0.count > 48 ? nil : $0 }
        toast.detail.text = short
        toast.detail.isHidden = short == nil
        toast.place(in: window, near: touched === window ? lastTouch?.point : nil)
        toast.present()
    }

    /// Records where touches land in `window`, so the toast can find the column that was touched. Idempotent.
    public static func watchTouches(in window: UIWindow) {
        guard !(window.gestureRecognizers ?? []).contains(where: { $0 is TouchWatch }) else { return }
        window.addGestureRecognizer(TouchWatch())
    }

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first { isActive($0) }
    }

    private static func isActive(_ window: UIWindow) -> Bool {
        window.windowScene?.activationState == .foregroundActive
    }

    private struct Weak<Object: AnyObject> {
        public weak var value: Object?
    }

    private init() {
        super.init(frame: .zero)
        backgroundColor = .delphiForeground
        alpha = 0
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 3)
        detail.font = .delphiMono(13, relativeTo: .footnote)
        detail.alpha = 0.7
        detail.lineBreakMode = .byTruncatingMiddle
        let check = UIImageView(image: UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(textStyle: .subheadline, scale: .medium)))
        check.tintColor = .delphiBackground
        for view in [check, title] {
            view.setContentHuggingPriority(.required, for: .horizontal)
            view.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        for label in [title, detail] { label.numberOfLines = 1 }
        let stack = UIStackView(arrangedSubviews: [check, title, detail])
        stack.spacing = 8
        stack.alignment = .center
        stack.setCustomSpacing(12, after: title)
        pin(stack, insets: NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 16))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Place

    private func place(in window: UIWindow, near touch: CGPoint?) {
        let band = Self.band(in: window, near: touch)
        let fitting = systemLayoutSizeFitting(CGSize(width: band.width - 32, height: 0),
                                              withHorizontalFittingPriority: .fittingSizeLevel, verticalFittingPriority: .fittingSizeLevel)
        let size = CGSize(width: min(fitting.width, band.width - 32), height: fitting.height)
        var bottom = band.maxY
        // stay above the touch
        if let touch, touch.y > bottom - size.height - 28, touch.y < band.maxY + 28, band.minX...band.maxX ~= touch.x {
            bottom = touch.y - 36
        }
        bounds = CGRect(origin: .zero, size: size)
        center = CGPoint(x: band.midX, y: bottom - size.height / 2)
        layer.shadowPath = CGPath(rect: bounds, transform: nil)
    }

    /// The column the toast belongs in, in window coordinates; the toast sits centred on it at its bottom edge.
    private static func band(in window: UIWindow, near touch: CGPoint?) -> CGRect {
        let point = touch ?? CGPoint(x: window.bounds.midX, y: window.bounds.midY)
        let hit = window.hitTest(point, with: nil)
        let split = hit.flatMap { sequence(first: $0, next: \.superview).lazy.compactMap { $0 as? CanonSplit }.first }
            ?? visibleSplits(in: window).first { $0.convert($0.bounds, to: window).contains(point) }
        if let split {
            return split.convert(split.toastBand(near: split.convert(point, from: window)), to: window)
        }
        let host = hit?.owningViewController?.view ?? window
        let safe = host.bounds.inset(by: host.safeAreaInsets)
        return host.convert(CGRect(x: safe.minX, y: safe.minY, width: safe.width, height: safe.height - DelphiMetrics.panelPadding), to: window)
    }

    private static func visibleSplits(in view: UIView) -> [CanonSplit] {
        guard !view.isHidden else { return [] }
        if let split = view as? CanonSplit { return [split] }
        return view.subviews.reversed().flatMap(visibleSplits)
    }

    // MARK: Motion

    private func present() {
        superview?.bringSubviewToFront(self)
        hiding?.cancel()
        let still = UIAccessibility.isReduceMotionEnabled
        if alpha < 1 {
            if alpha == 0 { transform = still ? .identity : CGAffineTransform(translationX: 0, y: 10) }
            UIView.animate(withDuration: 0.22, delay: 0, options: [.beginFromCurrentState, .curveEaseOut]) {
                self.alpha = 1
                self.transform = .identity
            }
        } else if !still {
            // repeat copy: bump
            transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: .beginFromCurrentState) {
                self.transform = .identity
            }
        }
        let hide = DispatchWorkItem { [weak self] in
            guard let self else { return }
            UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState, .curveEaseIn]) {
                self.alpha = 0
                if !still { self.transform = CGAffineTransform(translationX: 0, y: 6) }
            } completion: { finished in
                if finished, self.alpha == 0 { self.removeFromSuperview() }
            }
        }
        hiding = hide
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.hold, execute: hide)
    }

    /// Notes where each touch begins and fails at once, so it never takes a touch from anything.
    private final class TouchWatch: UIGestureRecognizer {
        public init() {
            super.init(target: nil, action: nil)
            cancelsTouchesInView = false
            delaysTouchesBegan = false
            delaysTouchesEnded = false
        }

        public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            if let touch = touches.first, let window = view as? UIWindow {
                CanonToast.lastTouch = (touch.location(in: window), Weak(value: window))
            }
            state = .failed
        }
    }
}
