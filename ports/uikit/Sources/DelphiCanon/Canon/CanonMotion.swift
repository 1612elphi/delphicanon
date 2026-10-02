import UIKit
import UIKit.UIGestureRecognizerSubclass

/// Press and hover behaviour shared by every canon control. Tune the feel here.
///
/// The press is a tilt: the control sinks a little and leans away under the finger, and follows it while held.
public enum CanonMotion {
    /// Uniform shrink while pressed; also keeps the raised edge inside the cell.
    public static let pressScale: CGFloat = 0.97
    /// Sink, in points, at the edge of a square control of the same area. Larger controls tilt by a smaller angle.
    public static let tiltDepth: CGFloat = 11
    /// Upper bound on the tilt, in degrees, for small controls.
    public static let maxTilt: CGFloat = 22
    /// Eye distance in points; smaller exaggerates the perspective.
    public static let perspective: CGFloat = 600
    public static let pressDuration: TimeInterval = 0.08
    public static let releaseDuration: TimeInterval = 0.45
    /// Lower is bouncier.
    public static let releaseDamping: CGFloat = 0.45
    /// Share of the ink colour mixed into a filled cell under the pointer.
    public static let filledHoverMix: CGFloat = 0.15

    private static let options: UIView.AnimationOptions = [.beginFromCurrentState, .allowUserInteraction]

    /// - Parameter point: touch location in `view`'s bounds; nil presses the centre, with no lean.
    public static func pressed(_ view: UIView, at point: CGPoint?) -> CATransform3D {
        var transform = CATransform3DIdentity
        transform.m34 = -1 / perspective
        let half = CGSize(width: max(view.bounds.width / 2, 1), height: max(view.bounds.height / 2, 1))
        if let point {
            // -1...1 from the centre
            let x = min(max((point.x - half.width) / half.width, -1), 1)
            let y = min(max((point.y - half.height) / half.height, -1), 1)
            // one angle, both axes:
            // convergence scales with area
            let angle = min(maxTilt * .pi / 180, asin(min(1, tiltDepth / sqrt(half.width * half.height))))
            // rotation signs sink edges
            transform = CATransform3DRotate(transform, x * angle, 0, 1, 0)
            transform = CATransform3DRotate(transform, -y * angle, 1, 0, 0)
        }
        return CATransform3DScale(transform, pressScale, pressScale, 1)
    }

    public static func press(_ view: UIView, at point: CGPoint?, duration: TimeInterval = pressDuration) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            view.transform3D = pressed(view, at: point)
        }
    }

    // fast tap reaches pose
    public static func release(_ view: UIView, from point: CGPoint?) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        UIView.animate(withDuration: pressDuration, delay: 0, options: options) {
            view.transform3D = pressed(view, at: point)
        } completion: { _ in
            UIView.animate(
                withDuration: releaseDuration, delay: 0,
                usingSpringWithDamping: releaseDamping, initialSpringVelocity: 0, options: options
            ) { view.transform3D = CATransform3DIdentity }
        }
    }
}

extension UIControl {
    /// Tilts `target` (default: the control) under the finger and springs it back on release.
    public func animatesPress(of target: UIView? = nil) {
        let recognizer = PressRecognizer(target: target ?? self)
        addGestureRecognizer(recognizer)
        // page took the touch
        addAction(UIAction { [weak recognizer] _ in
            recognizer?.isEnabled = false
            recognizer?.isEnabled = true
        }, for: .touchCancel)
    }
}

// zero-delay press: touch point
private final class PressRecognizer: UILongPressGestureRecognizer, UIGestureRecognizerDelegate {
    private weak var pressedView: UIView?
    private var isDown = false

    public init(target view: UIView) {
        pressedView = view
        super.init(target: nil, action: nil)
        minimumPressDuration = 0
        cancelsTouchesInView = false
        delaysTouchesEnded = false
        delegate = self
        addTarget(self, action: #selector(changed))
    }

    @objc private func changed() {
        guard let pressedView else { return }
        let point = location(in: pressedView)
        let inside = pressedView.bounds.insetBy(dx: -20, dy: -20).contains(point)
        switch state {
        case .began:
            isDown = true
            CanonMotion.press(pressedView, at: point)
        case .changed where inside:
            // follows the finger
            CanonMotion.press(pressedView, at: point, duration: isDown ? 0.05 : CanonMotion.pressDuration)
            isDown = true
        case .changed, .ended, .cancelled, .failed:
            guard isDown else { return }
            isDown = false
            CanonMotion.release(pressedView, from: state == .ended ? point : nil)
        default:
            break
        }
    }

    // the page still scrolls
    public func gestureRecognizer(_ recognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    public func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
        (view as? UIControl)?.isEnabled ?? true
    }
}

extension UIView {
    /// Reports pointer hover. Touch input never calls the handler.
    public func tracksHover(_ handler: @escaping (Bool) -> Void) {
        addGestureRecognizer(HoverRecognizer(handler))
    }
}

private final class HoverRecognizer: UIHoverGestureRecognizer {
    private let handler: (Bool) -> Void

    public init(_ handler: @escaping (Bool) -> Void) {
        self.handler = handler
        super.init(target: nil, action: nil)
        addTarget(self, action: #selector(changed))
    }

    @objc private func changed() {
        switch state {
        case .began, .changed: handler(true)
        case .ended, .cancelled, .failed: handler(false)
        default: break
        }
    }
}

extension UIColor {
    /// Dynamic mix, resolved per trait collection.
    public func mixed(with other: UIColor, by share: CGFloat) -> UIColor {
        UIColor { traits in
            var a: (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            var b = a
            self.resolvedColor(with: traits).getRed(&a.0, green: &a.1, blue: &a.2, alpha: &a.3)
            other.resolvedColor(with: traits).getRed(&b.0, green: &b.1, blue: &b.2, alpha: &b.3)
            func mix(_ x: CGFloat, _ y: CGFloat) -> CGFloat { x + (y - x) * share }
            return UIColor(red: mix(a.0, b.0), green: mix(a.1, b.1), blue: mix(a.2, b.2), alpha: mix(a.3, b.3))
        }
    }
}

/// Pan that begins only where `grabs` says a handle is, in any direction; every enclosing scroll view waits for it
/// to fail, so the page scrolls from anywhere else.
public final class CanonGrabPan: UIPanGestureRecognizer {
    public var grabs: (CGPoint) -> Bool = { _ in false }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        if state == .possible, let touch = touches.first, !grabs(touch.location(in: view)) { state = .failed }
    }

    public override func shouldBeRequiredToFail(by other: UIGestureRecognizer) -> Bool {
        guard let scroll = other.view as? UIScrollView, other === scroll.panGestureRecognizer, let view else { return false }
        return view.isDescendant(of: scroll)
    }
}

/// Pan for a sideways drag inside a scrolling page. It fails as soon as the drag is not clearly sideways, so the page scrolls.
public final class CanonSidewaysPan: UIPanGestureRecognizer {
    /// Points of travel before the direction is judged, and how many times the sideways travel must exceed the vertical.
    public static let judgement = (travel: 6.0, ratio: 2.0)
    // second finger: another origin
    private var first: UITouch?
    private var origin: CGPoint?

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        if first == nil, let touch = touches.first {
            first = touch
            origin = touch.location(in: view)
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .possible, let first, let origin, touches.contains(first) {
            let point = first.location(in: view)
            let across = abs(point.x - origin.x)
            let down = abs(point.y - origin.y)
            if max(across, down) >= Self.judgement.travel, across < down * Self.judgement.ratio {
                state = .failed
                return
            }
        }
        super.touchesMoved(touches, with: event)
    }

    public override func reset() {
        super.reset()
        first = nil
        origin = nil
    }
}
