import AppKit

// UIBezierPath names, so drawing code ported from UIKit reads the same
extension NSBezierPath {
    public convenience init(roundedRect rect: CGRect, cornerRadius radius: CGFloat) {
        self.init(roundedRect: rect, xRadius: radius, yRadius: radius)
    }

    /// Angles in radians; `clockwise` as seen in a flipped view.
    public convenience init(arcCenter centre: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) {
        self.init()
        addArc(withCenter: centre, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
    }

    /// Angles in radians; `clockwise` as seen in a flipped view.
    public func addArc(withCenter centre: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) {
        appendArc(withCenter: centre, radius: radius, startAngle: startAngle * 180 / .pi, endAngle: endAngle * 180 / .pi, clockwise: !clockwise)
    }

    public var usesEvenOddFillRule: Bool {
        get { windingRule == .evenOdd }
        set { windingRule = newValue ? .evenOdd : .nonZero }
    }

    public func addLine(to point: CGPoint) { line(to: point) }
    public func addQuadCurve(to point: CGPoint, controlPoint: CGPoint) { curve(to: point, controlPoint: controlPoint) }
    public func addCurve(to point: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint) {
        curve(to: point, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
    }

    public func apply(_ transform: CGAffineTransform) {
        self.transform(using: AffineTransform(m11: transform.a, m12: transform.b, m21: transform.c, m22: transform.d, tX: transform.tx, tY: transform.ty))
    }
}
