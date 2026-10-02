import UIKit

/// Edge-to-edge band for a picture, a preview or a drawing surface, ruled above and below.
///
/// - As a section of a `CanonPage` (so also of a `CanonSplit` pane) it spans that column.
/// - As the `banner` of a `CanonSplit` it spans every column.
///
/// Both stop at the safe area, which keeps the band clear of the iPhone Duo vertical bar.
/// Put it between blocks of `CanonRows`, not inside one. With `boxing = .unlessWide` it is a band only beside a
/// sidebar, and a framed box the width of the other sections everywhere else.
public final class CanonCanvas: UIView {

    public enum Size: Equatable {
        case fixed(CGFloat)
        /// Width over height.
        case aspect(CGFloat)
        /// The content's own height (`CanonCanvasContent.canvasFittingHeight`) plus the frame, asked again when the
        /// content's width changes and on `refit(animated:)`.
        case fitting
    }

    public var size: Size {
        didSet {
            guard size != oldValue else { return }
            remakeHeight()
        }
    }

    private func remakeHeight() {
        height.isActive = false
        height = makeHeight()
        height.isActive = !fillsPane
    }

    /// A `.fitting` band's height, frame included, and the content width it was asked at.
    private var fitted: CGFloat = DelphiMetrics.frame * 2
    private var fittedWidth: CGFloat?

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard size == .fitting else { return }
        let width = content.bounds.inset(by: content.safeAreaInsets).width
        guard width != fittedWidth else { return }
        fittedWidth = width
        refit(animated: false)
        content.setNeedsDisplay()
    }

    /// Asks a `.fitting` canvas's content for its height again, after the content changed.
    public func refit(animated: Bool) {
        guard size == .fitting, let content = content as? CanonCanvasContent else { return }
        let band = Self.band(fitting: content.canvasFittingHeight)
        guard band > 0, band != fitted else { return }
        fitted = band
        remakeHeight()
        superview?.setNeedsLayout()
        if animated { UIView.animate(withDuration: 0.3) { self.owningViewController?.view.layoutIfNeeded() } }
    }

    /// The band for content of `height`: zero while the content has nothing to show, else the height and the frame.
    public static func band(fitting height: CGFloat) -> CGFloat {
        height > 0 ? height + DelphiMetrics.frame * 2 : 0
    }

    private var height: NSLayoutConstraint!
    private var contentTop: NSLayoutConstraint!
    private var sides: [NSLayoutConstraint] = []

    public enum Boxing {
        /// Always an edge-to-edge band.
        case never
        /// A band beside a sidebar; a framed, padded box everywhere else.
        case unlessWide
    }

    public var boxing = Boxing.never

    /// Set by `CanonSplit` before it builds its pages; a boxed canvas is padded like any other section.
    public var isBoxed = false {
        didSet {
            sides.forEach { $0.constant = isBoxed ? DelphiMetrics.frame : 0 }
            if isBoxed { bleedTop = 0 }
        }
    }

    /// Extra height above the band, set by the page or split when the canvas is the first thing on screen:
    /// the band then reaches the top of the screen and drops its top rule.
    /// Content that must stay readable belongs inside the canvas's `safeAreaLayoutGuide`.
    public var bleedTop: CGFloat = 0 {
        didSet {
            guard bleedTop != oldValue else { return }
            contentTop.constant = bleedTop > 0 ? 0 : DelphiMetrics.frame
            height.constant = baseConstant + bleedTop
            pushTopInset()
        }
    }

    /// Points a pull-down stretches the band past its full height; content that re-flows by height holds its resting layout meanwhile.
    public var overscroll: CGFloat = 0 {
        didSet { if overscroll != oldValue { pushOverscroll(into: content) } }
    }

    /// Reaches every `CanonCanvasContent` inside, not only the content itself: a readout band or a wrapper holds a glyph
    /// flow that does not pass the value on.
    private func pushOverscroll(into view: UIView) {
        (view as? CanonCanvasContent)?.canvasOverscroll = overscroll
        view.subviews.forEach(pushOverscroll)
    }

    /// Room a drawn picture leaves at its top. Inside a scrolling page the content's own `safeAreaInsets` are zero,
    /// because the scroll view takes them, so the canvas passes its own down to a `CanonCanvasContent`.
    private var topInset: CGFloat { max(bleedTop, safeAreaInsets.top) }

    private func pushTopInset() {
        (content as? CanonCanvasContent)?.canvasTopInset = topInset
    }

    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        pushTopInset()
        if size == .fitting { setNeedsLayout() }
    }

    private var baseConstant: CGFloat {
        switch size {
        case .fixed(let points): points
        case .aspect: DelphiMetrics.frame * 2
        case .fitting: fitted
        }
    }

    private let content: UIView
    private let plainBackground: UIColor

    /// Tiles the tool's symbol (`CanonPatternSymbol`) faintly into the content's background, as the menu does.
    /// `CanonSplit` turns it on for its banner. It sits under anything the content draws.
    public var showsPattern = false {
        didSet { if showsPattern != oldValue { applyPattern() } }
    }

    public init(_ content: UIView, size: Size, background: UIColor = .delphiCard) {
        self.size = size
        self.content = content
        plainBackground = content.backgroundColor ?? background
        super.init(frame: .zero)
        backgroundColor = .delphiBorder
        clipsToBounds = true
        content.backgroundColor = plainBackground
        registerForTraitChanges(UITraitCollection.delphiColourTraits + [CanonPatternSymbol.self]) { (canvas: Self, _) in canvas.applyPattern() }
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        contentTop = content.topAnchor.constraint(equalTo: topAnchor, constant: DelphiMetrics.frame)

        // split clamps its banner
        height = makeHeight()
        sides = [content.leadingAnchor.constraint(equalTo: leadingAnchor), trailingAnchor.constraint(equalTo: content.trailingAnchor)]
        NSLayoutConstraint.activate(sides + [
            contentTop, height,
            bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: DelphiMetrics.frame),
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func applyPattern() {
        guard showsPattern, let symbol = traitCollection[CanonPatternSymbol.self] else {
            content.backgroundColor = plainBackground
            return
        }
        content.backgroundColor = UIColor(patternImage: CanonPattern.tile(
            symbol: symbol, base: plainBackground.resolvedColor(with: traitCollection),
            ink: UIColor.delphiForeground.resolvedColor(with: traitCollection)
        ))
    }

    public override var canonSpansColumn: Bool { !isBoxed }

    /// Caps an `.aspect` canvas in a wide column; the content then letterboxes itself.
    public var maxHeight: CGFloat? {
        didSet {
            cap?.isActive = false
            cap = maxHeight.map { heightAnchor.constraint(lessThanOrEqualToConstant: $0) }
            cap?.isActive = !fillsPane
        }
    }

    /// Set by `CanonSplit` when the canvas is a whole pane: the pane gives its size, and `size` and `maxHeight` wait.
    public var fillsPane = false {
        didSet {
            height.isActive = !fillsPane
            cap?.isActive = !fillsPane
        }
    }

    private var cap: NSLayoutConstraint?

    private func makeHeight() -> NSLayoutConstraint {
        let height = switch size {
        case .fixed, .fitting: heightAnchor.constraint(equalToConstant: baseConstant + bleedTop)
        case .aspect(let ratio): heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1 / ratio, constant: baseConstant + bleedTop)
        }
        height.priority = .init(999)
        return height
    }

    /// Height of the band itself, without `bleedTop`.
    public func height(for width: CGFloat) -> CGFloat {
        switch size {
        case .fixed(let points): points
        case .aspect(let ratio): min(width / ratio + DelphiMetrics.frame * 2, maxHeight ?? .greatestFiniteMagnitude)
        case .fitting: fitted
        }
    }
}

/// A view that draws itself and must keep clear of the status bar when its canvas is the first thing on screen.
public protocol CanonCanvasContent: UIView {
    /// Set by the canvas; the content redraws when it changes.
    var canvasTopInset: CGFloat { get set }
    /// Height the content needs at its current width, without the canvas frame, for a `.fitting` canvas; zero keeps
    /// the band as it is.
    var canvasFittingHeight: CGFloat { get }
    /// Set by the canvas: points a pull stretches it past its resting height.
    var canvasOverscroll: CGFloat { get set }
}

extension CanonCanvasContent {
    public var canvasFittingHeight: CGFloat { 0 }

    public var canvasOverscroll: CGFloat {
        get { 0 }
        set {}
    }
}

/// The open tool's SF Symbol, for banner patterns. The tool's host sets it.
public struct CanonPatternSymbol: UITraitDefinition {
    public static let defaultValue: String? = nil
}

/// The menu's tile: two symbols on the diagonal of a 92 pt square, faint on the base colour.
public enum CanonPattern {
    public static let tile: CGFloat = 92
    public static let symbolSize: CGFloat = 24
    public static let inkAlpha: CGFloat = 0.04
    private static var cache: [String: UIImage] = [:]

    public static func tile(symbol: String, base: UIColor, ink: UIColor) -> UIImage {
        let key = "\(symbol)|\(base)|\(ink)"
        if let cached = cache[key] { return cached }
        let glyph = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .medium))?
            .withTintColor(ink.withAlphaComponent(inkAlpha), renderingMode: .alwaysOriginal)
        let image = UIGraphicsImageRenderer(size: CGSize(width: tile, height: tile)).image { context in
            base.setFill()
            context.fill(CGRect(x: 0, y: 0, width: tile, height: tile))
            guard let glyph else { return }
            for centre in [CGPoint(x: tile * 0.25, y: tile * 0.25), CGPoint(x: tile * 0.75, y: tile * 0.75)] {
                glyph.draw(at: CGPoint(x: centre.x - glyph.size.width / 2, y: centre.y - glyph.size.height / 2))
            }
        }
        cache[key] = image
        return image
    }
}

#if DEBUG
extension CanonCanvas {
    /// Content half as tall as it is wide.
    private final class HalfHeight: UIView, CanonCanvasContent {
        public var canvasTopInset: CGFloat = 0
        public var canvasFittingHeight: CGFloat { bounds.width / 2 }
    }

    public static func selfCheck() {
        assert(band(fitting: 0) == 0 && band(fitting: 100) == 100 + DelphiMetrics.frame * 2)
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 1000))
        let canvas = CanonCanvas(HalfHeight(), size: .fitting)
        canvas.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(canvas)
        NSLayoutConstraint.activate([
            canvas.topAnchor.constraint(equalTo: host.topAnchor),
            canvas.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            canvas.trailingAnchor.constraint(equalTo: host.trailingAnchor),
        ])
        host.layoutIfNeeded()
        host.layoutIfNeeded()
        assert(canvas.height(for: 200) == 100 + DelphiMetrics.frame * 2 && canvas.bounds.height == 100 + DelphiMetrics.frame * 2, "fits its content")
        host.frame.size.width = 300
        host.layoutIfNeeded()
        host.layoutIfNeeded()
        assert(canvas.bounds.height == 150 + DelphiMetrics.frame * 2, "refits on a width change")
    }
}
#endif
