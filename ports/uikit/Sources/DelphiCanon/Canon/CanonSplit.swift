import UIKit

/// Sidebar beside a main pane.
///
/// - Wide, no hinge: fixed-width sidebar on the leading side.
/// - Hinge, landscape: the panes meet at the crease, so the split is equal. `halves` splits equally without one too,
///   and a sidebar of one canvas then fills its half: the tool's picture beside its controls.
/// - Narrow or portrait: one column, sidebar first.
/// - Hinge across the middle, partly folded (Duo in portrait): a `halves` picture fills the top screen down to the rule on the crease,
///   and the rest scrolls on the bottom screen.
/// - `banner`: a canvas across every column, above the panes; in one column it is the first section.
/// - `footer`: a framed strip that floats above the bottom of the page. Beside a sidebar it floats over the main pane only.
/// - `oneColumn`: one column at every width, for a tool whose page is one wide grid; sections that span their column get the full width.
/// - `collapsesTo`: in one column the picture (the banner, or a `halves` sidebar canvas) stays at the top and shrinks as the page
///   scrolls, down to this band height, then the page scrolls under it.
///
/// Sections that are a `CanonCanvas` span their column; the rest keep the panel padding.
public final class CanonSplit: UIView {
    private let sidebar: [UIView]
    private let main: [UIView]
    private let banner: CanonCanvas?
    private let sidebarWidth: CGFloat
    private let bannerSticks: Bool
    private let mainLeadsStacked: Bool
    private let halves: Bool
    private let pictureShare: CGFloat
    private let collapsesTo: CGFloat?
    private let oneColumn: Bool
    private let footer: UIView?
    private let footerFrame = UIView()

    /// Takes the footer off screen and gives its room back to the page.
    public var isFooterHidden = false {
        didSet { if isFooterHidden != oldValue { setNeedsLayout() } }
    }

    /// Footer shadow: opacity, blur radius, drop.
    public static let footerShadow = (opacity: Float(0.1), radius: 8.0, drop: 2.0)
    /// Footer: widest it gets, and its inset from the column's edges.
    public static let footerSize = (maxWidth: 480.0, inset: 32.0)

    private let leadingPane = Pane()
    private let trailingPane = Pane()
    private let rule = UIView()
    private var hasHinge = false
    private var isPartlyFolded = false
    public enum Layout: Equatable {
        /// One column.
        case stacked
        /// Fixed sidebar beside a flexible main pane.
        case sidebar
        /// Panes meet at the crease.
        case equal
        /// Picture above a horizontal crease, page below it.
        case laptop
    }

    public private(set) var layout: Layout?

    /// Follows the main sections, on whichever page holds them: the shell puts the tool's sticker here.
    public var endPiece: UIView? {
        didSet {
            layout = nil
            setNeedsLayout()
        }
    }
    private var mainAndEnd: [UIView] { main + (endPiece.map { [$0] } ?? []) }

    /// Narrower than this, the panes stack.
    public static let stackingWidth: CGFloat = 640

    /// Share of the height a banner may take.
    public static let bannerLimit: CGFloat = 0.45
    /// Share of the height a collapsing picture may take before it has shrunk.
    public static let collapseLimit: CGFloat = 0.6

    /// The picture that shrinks in one column.
    private var collapsing: CanonCanvas? {
        guard collapsesTo != nil, layout == .stacked else { return nil }
        return banner ?? picture
    }

    private var fullBand: CGFloat = 0

    /// - Parameter bannerSticks: in one column the banner stays at the top and the page scrolls under it, as it does beside panes.
    /// - Parameter mainLeadsStacked: in one column the main sections come before the sidebar's, for a sidebar that holds reference material.
    /// - Parameter halves: beside each other the panes are always equal, meeting at the middle when there is no crease, and a sidebar
    ///   of one canvas fills its whole pane. In one column that canvas is an ordinary first section.
    /// - Parameter pictureShare: with `halves` and no crease, the share of the width the sidebar takes; a crease still splits equally.
    /// - Parameter collapsesTo: band height a one-column picture shrinks to before the page scrolls under it.
    /// - Parameter oneColumn: never splits: the sections stack at every width, sidebar first.
    public init(
        sidebar: [UIView],
        main: [UIView],
        banner: CanonCanvas? = nil,
        sidebarWidth: CGFloat = 340,
        bannerSticks: Bool = false,
        mainLeadsStacked: Bool = false,
        halves: Bool = false,
        pictureShare: CGFloat = 0.5,
        collapsesTo: CGFloat? = nil,
        oneColumn: Bool = false,
        footer: UIView? = nil
    ) {
        self.sidebar = sidebar
        self.main = main
        self.banner = banner
        banner?.showsPattern = true
        self.sidebarWidth = sidebarWidth
        self.bannerSticks = bannerSticks
        self.mainLeadsStacked = mainLeadsStacked
        self.halves = halves
        self.pictureShare = pictureShare
        self.collapsesTo = collapsesTo
        self.oneColumn = oneColumn
        self.footer = footer
        super.init(frame: .zero)
        backgroundColor = .delphiBackground
        rule.backgroundColor = .delphiBorder
        [leadingPane, trailingPane, rule].forEach(addSubview)
        leadingPane.onScroll = { [weak self] in self?.collapse() }
        if let footer {
            footerFrame.backgroundColor = .delphiBorder
            footerFrame.layer.shadowOpacity = Self.footerShadow.opacity
            footerFrame.layer.shadowRadius = Self.footerShadow.radius
            footerFrame.layer.shadowOffset = CGSize(width: 0, height: Self.footerShadow.drop)
            footerFrame.addSubview(footer)
            addSubview(footerFrame)
        }

        if #available(iOS 27.1, *) {
            // nil without a hinge
            addInteraction(UIHingeInteraction { [weak self] _, update in
                self?.hasHinge = update.hinge != nil
                self?.isPartlyFolded = update.hinge?.status == .partiallyOpen
                self?.setNeedsLayout()
            })
        }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public var creaseBeside: CGRect? {
        Self.creases(hinge, in: bounds.size).beside
    }

    private var hinge: CGRect? {
        // outer display: no crease
        guard #available(iOS 27.1, *), traitCollection.horizontalSizeClass == .regular else { return nil }
        return crease(hasHinge: hasHinge)
    }

    /// The hinge split into a crease the panes meet at side by side (`beside`) or one above the other (`across`).
    /// Outside the middle half of the view, a split-view window, it is neither.
    public static func creases(_ hinge: CGRect?, in size: CGSize) -> (beside: CGRect?, across: CGRect?) {
        guard let hinge else { return (nil, nil) }
        return hinge.height >= hinge.width
            ? ((0.25...0.75).contains(hinge.midX / size.width) ? hinge : nil, nil)
            : (nil, (0.25...0.75).contains(hinge.midY / size.height) ? hinge : nil)
    }

    /// `across` counts only for a partly folded hinge and a split that has a picture to put above it.
    public static func layout(in size: CGSize, beside: CGRect?, across: CGRect?, isCompact: Bool, halves: Bool) -> Layout {
        if across != nil { return .laptop }
        let stacks = size.height > size.width || beside == nil && (size.width < stackingWidth || isCompact)
        return stacks ? .stacked : beside == nil && !halves ? .sidebar : .equal
    }

    /// The `halves` sidebar that is one canvas.
    private var picture: CanonCanvas? {
        halves && sidebar.count == 1 ? sidebar[0] as? CanonCanvas : nil
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }
        // ignore keyboard-shortened height
        let screenHeight = window.map { max(bounds.height, convert($0.bounds, from: $0).maxY) } ?? bounds.height
        let screen = CGSize(width: bounds.width, height: screenHeight)
        let creases = Self.creases(hinge, in: screen)
        let crease = creases.beside
        let across = isPartlyFolded && picture != nil && banner == nil ? creases.across : nil
        let layout = oneColumn ? .stacked : Self.layout(
            in: screen, beside: crease, across: across, isCompact: traitCollection.horizontalSizeClass == .compact, halves: halves
        )
        let stacks = layout == .stacked
        if layout != self.layout {
            self.layout = layout
            // band needs a sidebar
            let bleeds = layout == .sidebar
            for case let canvas as CanonCanvas in sidebar + main where canvas.boxing == .unlessWide {
                canvas.isBoxed = !bleeds
            }
            banner?.removeFromSuperview()
            let collapsing = collapsing
            let floats = !stacks || bannerSticks || collapsesTo != nil
            if stacks {
                let rest = sidebar.filter { $0 !== collapsing }
                leadingPane.show((floats ? [] : banner.map { [$0] } ?? []) + (mainLeadsStacked ? main + rest : rest + main) + (endPiece.map { [$0] } ?? []), maxWidth: 720)
                trailingPane.show([])
            } else if let picture {
                leadingPane.fill(picture)
                trailingPane.show(mainAndEnd)
            } else {
                leadingPane.show(sidebar)
                trailingPane.show(mainAndEnd)
            }
            if let banner, floats {
                banner.translatesAutoresizingMaskIntoConstraints = true
                addSubview(banner)
            }
            if let collapsing, collapsing !== banner {
                collapsing.removeFromSuperview()
                // sized by its frame
                collapsing.fillsPane = true
                collapsing.isBoxed = false
                collapsing.translatesAutoresizingMaskIntoConstraints = true
                addSubview(collapsing)
            }
        }
        trailingPane.isHidden = stacks
        rule.isHidden = stacks

        let hairline = DelphiMetrics.hairline
        if collapsing == nil { leadingPane.topClearance = 0 }
        // clear of vertical bar
        var top: CGFloat = 0
        if let collapsing {
            let safe = bounds.inset(by: safeAreaInsets)
            fullBand = min(collapsing.height(for: safe.width), (bounds.height - safe.minY) * Self.collapseLimit)
            // page starts under it
            leadingPane.topClearance = fullBand
            collapse()
        } else if !stacks || bannerSticks, let banner {
            let safe = bounds.inset(by: safeAreaInsets)
            let room = bounds.height - safe.minY
            let height = min(banner.height(for: safe.width), room * Self.bannerLimit)
            // under the status bar
            banner.bleedTop = safe.minY
            banner.frame = CGRect(x: safe.minX, y: 0, width: safe.width, height: safe.minY + height)
            top = banner.frame.maxY
        }
        if let across, layout == .laptop {
            let frames = Self.laptopFrames(in: bounds, seam: (y: across.midY - hairline / 2, height: hairline))
            leadingPane.frame = frames.picture
            trailingPane.frame = frames.page
            rule.frame = frames.rule
            leadingPane.bottomClearance = 0
            float(over: trailingPane)
        } else if stacks {
            leadingPane.frame = CGRect(x: 0, y: top, width: bounds.width, height: bounds.height - top)
            trailingPane.bottomClearance = 0
            float(over: leadingPane)
        } else {
            let flipped = effectiveUserInterfaceLayoutDirection == .rightToLeft
            let seam: (x: CGFloat, width: CGFloat)
            if let crease {
                seam = (crease.midX - hairline / 2, hairline)
            } else if halves {
                let leading = ((bounds.width - hairline) * pictureShare).rounded()
                seam = (flipped ? bounds.width - hairline - leading : leading, hairline)
            } else {
                let width = min(sidebarWidth, bounds.width * 0.4)
                seam = (flipped ? bounds.width - width - hairline : width, hairline)
            }
            let frames = Self.paneFrames(in: bounds, top: top, seam: seam, flipped: flipped)
            leadingPane.frame = frames.leading
            trailingPane.frame = frames.trailing
            leadingPane.bottomClearance = 0
            float(over: trailingPane)
            // rule centred on fold
            rule.frame = CGRect(x: seam.x + (seam.width - hairline) / 2, y: top, width: hairline, height: bounds.height - top)
        }
    }

    /// Pane frames either side of a seam.
    public static func paneFrames(
        in bounds: CGRect, top: CGFloat, seam: (x: CGFloat, width: CGFloat), flipped: Bool
    ) -> (leading: CGRect, trailing: CGRect) {
        let left = CGRect(x: 0, y: top, width: seam.x, height: bounds.height - top)
        let right = CGRect(x: seam.x + seam.width, y: top, width: bounds.width - seam.x - seam.width, height: bounds.height - top)
        return flipped ? (right, left) : (left, right)
    }

    /// Picture above a horizontal seam, page below it, rule on the seam's centre.
    public static func laptopFrames(
        in bounds: CGRect, seam: (y: CGFloat, height: CGFloat)
    ) -> (picture: CGRect, page: CGRect, rule: CGRect) {
        let hairline = DelphiMetrics.hairline
        let pageY = seam.y + seam.height
        return (
            CGRect(x: 0, y: 0, width: bounds.width, height: seam.y),
            CGRect(x: 0, y: pageY, width: bounds.width, height: max(0, bounds.height - pageY)),
            CGRect(x: 0, y: seam.y + (seam.height - hairline) / 2, width: bounds.width, height: hairline)
        )
    }

    /// Sizes the one-column picture to what the page has scrolled, from its full band down to `collapsesTo`.
    private func collapse() {
        guard let collapsing, let collapsesTo, let page = leadingPane.page else { return }
        let safe = bounds.inset(by: safeAreaInsets)
        let scrolled = page.contentOffset.y + page.adjustedContentInset.top
        // stretches when pulled down
        let band = max(min(collapsesTo, fullBand), fullBand - scrolled)
        collapsing.bleedTop = safe.minY
        collapsing.overscroll = max(0, band - fullBand)
        let frame = CGRect(x: safe.minX, y: 0, width: safe.width, height: safe.minY + band)
        if collapsing.frame != frame { collapsing.frame = frame }
    }

    /// Room between the bottom edge and anything floating over the page: above the shell's band and its fade, else the home indicator.
    private var floatingGap: CGFloat {
        let below = safeAreaInsets.bottom
        guard let band = CanonHost.bandHeight(owningViewController, traitCollection) else { return max(DelphiMetrics.panelPadding, below * 0.6) }
        return below + band
    }

    /// Where a `CanonToast` about a touch at `point` goes: the pane holding the point, its bottom above the footer or the band.
    public func toastBand(near point: CGPoint) -> CGRect {
        let panes = [leadingPane, trailingPane].filter { !$0.isHidden && $0.frame.width > 0 }
        let pane = panes.first { $0.frame.contains(point) } ?? panes.first { $0.frame.minX...$0.frame.maxX ~= point.x } ?? leadingPane
        let column = pane.frame.intersection(bounds.inset(by: safeAreaInsets))
        guard !column.isNull else { return bounds.inset(by: safeAreaInsets) }
        var bottom = bounds.maxY - floatingGap
        if footer != nil, !footerFrame.isHidden, footerFrame.frame.minX < column.maxX, footerFrame.frame.maxX > column.minX {
            bottom = footerFrame.frame.minY - 10
        }
        return CGRect(x: column.minX, y: column.minY, width: column.width, height: max(0, bottom - column.minY))
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if let window { CanonToast.watchTouches(in: window) }
    }

    /// Puts the footer over the bottom of `pane`, in line with the page's framed blocks, and lets the page scroll clear of it.
    private func float(over pane: Pane) {
        footerFrame.isHidden = isFooterHidden
        guard let footer, !isFooterHidden else { return pane.bottomClearance = 0 }
        let padding = DelphiMetrics.panelPadding
        let below = safeAreaInsets.bottom
        let gap = floatingGap
        let column = pane.frame.intersection(bounds.inset(by: safeAreaInsets)).insetBy(dx: Self.footerSize.inset, dy: 0)
        // narrow pane: null rect
        guard !column.isNull, column.width > 0 else {
            footerFrame.isHidden = true
            return pane.bottomClearance = 0
        }
        let width = min(column.width, Self.footerSize.maxWidth)
        let edge = DelphiMetrics.frame
        let height = footer.systemLayoutSizeFitting(
            CGSize(width: width - edge * 2, height: 0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel
        ).height + edge * 2
        footerFrame.frame = CGRect(x: column.midX - width / 2, y: bounds.maxY - gap - height, width: width, height: height)
        footer.frame = footerFrame.bounds.insetBy(dx: edge, dy: edge)
        footerFrame.layer.shadowPath = CGPath(rect: footerFrame.bounds, transform: nil)
        pane.bottomClearance = height + gap - below + padding
    }

    private final class Pane: UIView {
        public private(set) var page: CanonPage?
        private var scrolling: NSKeyValueObservation?
        public var onScroll: (() -> Void)?

        /// Room at the top of the page for a picture floating over it.
        public var topClearance: CGFloat = 0 {
            didSet { if topClearance != oldValue { applyClearance() } }
        }

        /// Room at the end of the page for something floating over its bottom.
        public var bottomClearance: CGFloat = 0 {
            didSet { if bottomClearance != oldValue { applyClearance() } }
        }

        private func applyClearance() {
            page?.contentInset.bottom = bottomClearance
            page?.verticalScrollIndicatorInsets.bottom = bottomClearance
            guard let page, page.contentInset.top != topClearance else { return }
            // content keeps its place
            let fromTop = page.contentOffset.y + page.adjustedContentInset.top
            page.contentInset.top = topClearance
            page.verticalScrollIndicatorInsets.top = topClearance
            page.contentOffset.y = fromTop - page.adjustedContentInset.top
        }

        /// One canvas as the whole pane, under the status bar.
        public func fill(_ canvas: CanonCanvas) {
            page?.removeFromSuperview()
            page = nil
            canvas.removeFromSuperview()
            canvas.fillsPane = true
            canvas.isBoxed = false
            pin(canvas)
            canvas.bleedTop = safeAreaInsets.top
            filled = canvas
        }

        private var filled: CanonCanvas?
        public var isFilled: Bool { filled != nil }

        public override func safeAreaInsetsDidChange() {
            super.safeAreaInsetsDidChange()
            filled?.bleedTop = safeAreaInsets.top
        }

        public func show(_ views: [UIView], maxWidth: CGFloat? = nil) {
            if let filled {
                filled.removeFromSuperview()
                filled.fillsPane = false
                filled.bleedTop = 0
                self.filled = nil
            }
            // keep place and focus
            let fromTop = page.map { $0.contentOffset.y + $0.adjustedContentInset.top }
            let editing = views.lazy.compactMap(\.firstResponderInside).first
            page?.removeFromSuperview()
            page = nil
            guard !views.isEmpty else { return }
            let page = CanonPage(sections: views, maxWidth: maxWidth)
            pin(page)
            self.page = page
            scrolling = page.observe(\.contentOffset) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.onScroll?() }
            }
            applyClearance()
            if let fromTop {
                page.layoutIfNeeded()
                page.scroll(fromTop: fromTop)
            }
            editing?.becomeFirstResponder()
        }
    }
}

private extension UIView {
    public var firstResponderInside: UIView? {
        isFirstResponder ? self : subviews.lazy.compactMap(\.firstResponderInside).first
    }
}

#if DEBUG
extension CanonSplit {
    public static func selfCheck() {
        let bounds = CGRect(x: 0, y: 0, width: 1030, height: 700)
        let seam = (x: CGFloat(514.5), width: CGFloat(1))
        let apart = paneFrames(in: bounds, top: 0, seam: seam, flipped: false)
        assert(apart.leading.maxX == 514.5 && apart.trailing.minX == 515.5 && apart.trailing.maxX == 1030)
        let rtl = paneFrames(in: bounds, top: 20, seam: seam, flipped: true)
        assert(rtl.leading.minX == 515.5 && rtl.trailing.maxX == 514.5 && rtl.leading.minY == 20)

        let portrait = CGSize(width: 669, height: 951)
        let flatHinge = CGRect(x: 0, y: 475.5, width: 669, height: 0)
        let sorted = creases(flatHinge, in: portrait)
        assert(sorted.beside == nil && sorted.across == flatHinge)
        assert(creases(CGRect(x: 0, y: 900, width: 669, height: 0), in: portrait).across == nil)
        // flat or no picture: one column, as before
        assert(layout(in: portrait, beside: nil, across: nil, isCompact: false, halves: true) == .stacked)
        assert(layout(in: portrait, beside: nil, across: sorted.across, isCompact: false, halves: true) == .laptop)
        let landscape = CGSize(width: 951, height: 669)
        let beside = creases(CGRect(x: 475.5, y: 0, width: 0, height: 669), in: landscape).beside
        assert(beside != nil && layout(in: landscape, beside: beside, across: nil, isCompact: false, halves: false) == .equal)
        assert(layout(in: CGSize(width: 1366, height: 1024), beside: nil, across: nil, isCompact: false, halves: false) == .sidebar)
        assert(layout(in: CGSize(width: 1366, height: 1024), beside: nil, across: nil, isCompact: false, halves: true) == .equal)
        assert(layout(in: CGSize(width: 402, height: 874), beside: nil, across: nil, isCompact: true, halves: true) == .stacked)

        let screen = CGRect(origin: .zero, size: portrait)
        let line = laptopFrames(in: screen, seam: (y: 475, height: 1))
        assert(line.picture.maxY == 475 && line.rule.minY == 475 && line.page.minY == 476 && line.page.maxY == 951)
    }
}
#endif

extension UIView {
    /// The fold as a line through the middle of the division region; layouts split there but keep nothing clear of it.
    // simulator reports no division
    @available(iOS 27.1, *)
    public func crease(hasHinge: Bool) -> CGRect? {
        if let region = reservedRegions(kind: .division).first?.frame {
            return region.height >= region.width
                ? CGRect(x: region.midX, y: region.minY, width: 0, height: region.height)
                : CGRect(x: region.minX, y: region.midY, width: region.width, height: 0)
        }
        guard hasHinge, let screen = window?.windowScene?.screen else { return nil }
        let centre = convert(CGPoint(x: screen.bounds.midX, y: screen.bounds.midY), from: screen.coordinateSpace)
        return screen.bounds.width > screen.bounds.height
            ? CGRect(x: centre.x, y: bounds.minY, width: 0, height: bounds.height)
            : CGRect(x: bounds.minX, y: centre.y, width: bounds.width, height: 0)
    }
}
