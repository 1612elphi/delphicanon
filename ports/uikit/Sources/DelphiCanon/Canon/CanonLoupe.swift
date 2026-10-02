import DelphiCore
import UIKit

/// The pixels around the sample point, magnified without smoothing, framed in the sampled colour.
public final class CanonLoupe: UIView {
    private let pixels = UIImageView()
    private let centrePixel = UIView()
    public static let border: CGFloat = 6

    /// Where a loupe of `side` goes near `centre` in a view of `size`: up and to the left, `gap` away, turned
    /// to the other side where it would come within 8 pt of the edge or above `top`, then kept inside.
    /// `sides` keeps the side it was on (left of and above the point), so a dragged loupe does not jump.
    public static func frame(near centre: CGPoint, side: CGFloat, gap: CGFloat, in size: CGSize, top: CGFloat,
                      sides: (left: Bool, above: Bool)? = nil) -> CGRect {
        let left = sides?.left ?? (centre.x - gap - side >= 8)
        let above = sides?.above ?? (centre.y - gap - side >= top)
        var x = left ? centre.x - gap - side : centre.x + gap
        var y = above ? centre.y - gap - side : centre.y + gap
        x = min(max(x, 8), size.width - side - 8)
        y = min(max(y, top), size.height - side - 8)
        return CGRect(x: x, y: y, width: side, height: side)
    }

    public init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        layer.borderWidth = Self.border
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 3)
        pixels.layer.magnificationFilter = .nearest
        pixels.contentMode = .scaleToFill
        pixels.clipsToBounds = true
        addSubview(pixels)
        centrePixel.layer.borderColor = UIColor.white.cgColor
        centrePixel.layer.borderWidth = 1
        addSubview(centrePixel)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func show(_ image: CGImage?, colour: DelphiColour) {
        if pixels.image?.cgImage !== image { pixels.image = image.map { UIImage(cgImage: $0) } }
        pixels.backgroundColor = colour.uiColor
        layer.borderColor = colour.uiColor.cgColor
        centrePixel.layer.borderColor = (colour.takesBlackInk ? UIColor.black : UIColor.white).cgColor
        setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        pixels.frame = bounds.insetBy(dx: Self.border, dy: Self.border)
        let count = CGFloat(pixels.image?.cgImage?.width ?? 31)
        let side = pixels.frame.width / max(count, 1)
        centrePixel.frame = CGRect(x: bounds.midX - side / 2 - 1, y: bounds.midY - side / 2 - 1, width: side + 2, height: side + 2)
    }
}
