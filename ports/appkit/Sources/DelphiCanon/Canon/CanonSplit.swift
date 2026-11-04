import AppKit

/// Sidebar beside a main pane, each scrolling on its own; one column below `stackingWidth`, sidebar first.
///
/// - `banner`: a canvas across both panes, above them; in one column it is the first section.
/// - `halves`: the panes split at `pictureShare` of the width, and a sidebar of one canvas fills its pane.
///
/// Sections that are an unboxed `CanonCanvas` span their column; the rest keep the panel padding.
public final class CanonSplit: CanonView {
    public enum Layout: Equatable {
        case stacked
        case sidebar
    }

    /// Narrower than this, the panes stack.
    public static let stackingWidth: CGFloat = 640
    /// Share of the height a banner may take.
    public static let bannerLimit: CGFloat = 0.45

    public private(set) var arrangement: Layout?

    private let sidebar: [NSView]
    private let main: [NSView]
    private let banner: CanonCanvas?
    private let sidebarWidth: CGFloat
    private let mainLeadsStacked: Bool
    private let halves: Bool
    private let pictureShare: CGFloat
    private let rule = CanonView(fill: .delphiBorder)
    private var leading: NSView?
    private var trailing: NSView?

    /// - Parameter mainLeadsStacked: in one column the main sections come before the sidebar's.
    public init(
        sidebar: [NSView],
        main: [NSView],
        banner: CanonCanvas? = nil,
        sidebarWidth: CGFloat = 340,
        mainLeadsStacked: Bool = false,
        halves: Bool = false,
        pictureShare: CGFloat = 0.5
    ) {
        self.sidebar = sidebar
        self.main = main
        self.banner = banner
        self.sidebarWidth = sidebarWidth
        self.mainLeadsStacked = mainLeadsStacked
        self.halves = halves
        self.pictureShare = pictureShare
        super.init(fill: .delphiBackground)
        addSubview(rule)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // halves sidebar canvas
    private var picture: CanonCanvas? {
        halves && sidebar.count == 1 ? sidebar[0] as? CanonCanvas : nil
    }

    public static func layout(width: CGFloat) -> Layout {
        width < stackingWidth ? .stacked : .sidebar
    }

    public override func layout() {
        super.layout()
        guard bounds.width > 0, bounds.height > 0 else { return }
        let layout = Self.layout(width: bounds.width)
        if layout != arrangement {
            arrangement = layout
            rebuild(layout)
        }
        rule.isHidden = layout == .stacked
        guard layout == .sidebar else {
            leading?.frame = bounds
            return
        }

        var top: CGFloat = 0
        if let banner {
            let height = min(banner.height(for: bounds.width), bounds.height * Self.bannerLimit)
            banner.frame = CGRect(x: 0, y: 0, width: bounds.width, height: height)
            top = banner.frame.maxY
        }
        let hairline = DelphiMetrics.hairline
        let seam = halves
            ? ((bounds.width - hairline) * pictureShare).rounded()
            : min(sidebarWidth, bounds.width * 0.4).rounded()
        let frames = Self.paneFrames(in: bounds, top: top, seam: seam)
        leading?.frame = frames.leading
        trailing?.frame = frames.trailing
        rule.frame = CGRect(x: seam, y: top, width: hairline, height: bounds.height - top)
    }

    /// Pane frames either side of a hairline at `seam`.
    public static func paneFrames(in bounds: CGRect, top: CGFloat, seam: CGFloat) -> (leading: CGRect, trailing: CGRect) {
        let right = seam + DelphiMetrics.hairline
        return (
            CGRect(x: 0, y: top, width: seam, height: bounds.height - top),
            CGRect(x: right, y: top, width: bounds.width - right, height: bounds.height - top)
        )
    }

    private func rebuild(_ layout: Layout) {
        // restore edited field
        let responder = window?.firstResponder
        let editing = ((responder as? NSText)?.delegate as? NSView) ?? responder as? NSView
        for view in [leading, trailing, banner] { view?.removeFromSuperview() }
        (sidebar + main).forEach { $0.removeFromSuperview() }
        picture?.fillsPane = false
        leading = nil
        trailing = nil

        switch layout {
        case .stacked:
            let sections = mainLeadsStacked ? main + sidebar : sidebar + main
            leading = CanonPage(sections: (banner.map { [$0] } ?? []) + sections, maxWidth: 720)
        case .sidebar:
            if let banner {
                banner.dropsTopRule = true
                banner.translatesAutoresizingMaskIntoConstraints = true
                addSubview(banner)
            }
            if let picture {
                picture.fillsPane = true
                leading = picture
            } else {
                leading = CanonPage(sections: sidebar)
            }
            trailing = CanonPage(sections: main)
        }
        for pane in [leading, trailing].compactMap(\.self) {
            pane.translatesAutoresizingMaskIntoConstraints = true
            addSubview(pane, positioned: .below, relativeTo: rule)
        }
        if let editing, editing.isDescendant(of: self) { window?.makeFirstResponder(editing) }
    }
}

/// Band for a picture, a preview or a drawing surface, framed above and below. As a section of a `CanonPage` it
/// spans the column unless `isBoxed`; as the `banner` of a `CanonSplit` it spans both panes.
public final class CanonCanvas: CanonView {
    public enum Size: Equatable {
        case fixed(CGFloat)
        /// Width over height.
        case aspect(CGFloat)
        /// The content's `canvasFittingHeight` plus the frame, asked again when the width changes and on `refit`.
        case fitting
    }

    public var size: Size {
        didSet { if size != oldValue { remakeHeight() } }
    }

    /// A framed box the width of the other sections, where it would otherwise span the column.
    public var isBoxed = false {
        didSet { sides.forEach { $0.constant = isBoxed ? DelphiMetrics.frame : 0 } }
    }

    /// Drops the top frame, for a canvas directly under another rule: the first section of a page, a split banner.
    public var dropsTopRule = false {
        didSet { contentTop.constant = dropsTopRule ? 0 : DelphiMetrics.frame }
    }

    /// Caps the height, in a page and as a split banner.
    public var maxHeight: CGFloat? {
        didSet {
            cap?.isActive = false
            cap = maxHeight.map { heightAnchor.constraint(lessThanOrEqualToConstant: $0) }
            cap?.isActive = !fillsPane
        }
    }

    /// Set by `CanonSplit` when the canvas is a whole pane: the pane gives its size.
    public var fillsPane = false {
        didSet {
            height.isActive = !fillsPane
            cap?.isActive = !fillsPane
        }
    }

    private let content: NSView
    private var contentTop: NSLayoutConstraint!
    private var height: NSLayoutConstraint!
    private var cap: NSLayoutConstraint?
    private var sides: [NSLayoutConstraint] = []
    private var fitted: CGFloat = DelphiMetrics.frame * 2
    private var fittedWidth: CGFloat?

    public init(_ content: NSView, size: Size, background: NSColor = .delphiCard) {
        self.size = size
        self.content = content
        super.init(fill: .delphiBorder)
        if let content = content as? CanonView, content.fill == nil { content.fill = background }
        layer?.masksToBounds = true
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        contentTop = content.topAnchor.constraint(equalTo: topAnchor, constant: DelphiMetrics.frame)
        height = makeHeight()
        sides = [content.leadingAnchor.constraint(equalTo: leadingAnchor), trailingAnchor.constraint(equalTo: content.trailingAnchor)]
        NSLayoutConstraint.activate(sides + [
            contentTop,
            bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: DelphiMetrics.frame),
            height,
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layout() {
        super.layout()
        guard size == .fitting, content.bounds.width > 0, content.bounds.width != fittedWidth else { return }
        fittedWidth = content.bounds.width
        refit(animated: false)
        content.needsDisplay = true
    }

    /// Asks a `.fitting` canvas's content for its height again, after the content changed.
    public func refit(animated: Bool) {
        guard size == .fitting, let content = content as? CanonCanvasContent, content.bounds.width > 0 else { return }
        let band = Self.band(fitting: content.canvasFittingHeight)
        guard band > 0, band != fitted else { return }
        fitted = band
        remakeHeight()
        superview?.needsLayout = true
        guard animated, let window else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            window.contentView?.layoutSubtreeIfNeeded()
        }
    }

    /// Zero while the content has nothing to show, else its height and the frame.
    public static func band(fitting height: CGFloat) -> CGFloat {
        height > 0 ? height + DelphiMetrics.frame * 2 : 0
    }

    /// Height of the band at `width`.
    public func height(for width: CGFloat) -> CGFloat {
        let height = switch size {
        case .fixed(let points): points
        case .aspect(let ratio): width / ratio + DelphiMetrics.frame * 2
        case .fitting: fitted
        }
        return min(height, maxHeight ?? height)
    }

    private func remakeHeight() {
        height.isActive = false
        height = makeHeight()
        height.isActive = !fillsPane
    }

    private func makeHeight() -> NSLayoutConstraint {
        let height = switch size {
        case .fixed(let points): heightAnchor.constraint(equalToConstant: points)
        case .fitting: heightAnchor.constraint(equalToConstant: fitted)
        case .aspect(let ratio): heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1 / ratio, constant: DelphiMetrics.frame * 2)
        }
        height.priority = .init(999)
        return height
    }
}

/// A view that draws itself inside a `.fitting` canvas.
public protocol CanonCanvasContent: NSView {
    /// Height the content needs at its current width, without the canvas frame; zero keeps the band as it is.
    /// The canvas asks only once the content has a width.
    var canvasFittingHeight: CGFloat { get }
}

#if DEBUG
extension CanonSplit {
    public static func selfCheck() {
        let frames = paneFrames(in: CGRect(x: 0, y: 0, width: 1000, height: 600), top: 100, seam: 340)
        assert(frames.leading == CGRect(x: 0, y: 100, width: 340, height: 500))
        assert(frames.trailing == CGRect(x: 341, y: 100, width: 659, height: 500))
        assert(layout(width: 639) == .stacked && layout(width: 640) == .sidebar)
        assert(CanonCanvas.band(fitting: 0) == 0 && CanonCanvas.band(fitting: 100) == 100 + DelphiMetrics.frame * 2)
    }
}
#endif
