import AppKit
import UniformTypeIdentifiers

/// Pages to scale in a sideways row, numbered, with an optional name under each: drag to reorder, drop files in,
/// a right-click `pageMenu`, a click that lights a page, and sheets stacked behind a page that stands for several.
public final class CanonPageStrip: NSView {
    /// PDF points, bottom-left origin.
    public struct Page: Equatable {
        /// nil: an opened PDF page
        public let id: UUID?
        public let size: CGSize
        public let area: CGRect
        public let placement: CGRect
        public let picture: CGImage?
        public let name: String?
        /// sheets behind
        public let depth: Int
        /// clockwise degrees, picture only
        public let turn: Int

        /// `area` and `placement` default to the whole page.
        public init(id: UUID? = nil, size: CGSize, area: CGRect? = nil, placement: CGRect? = nil, picture: CGImage?,
                    name: String? = nil, depth: Int = 0, turn: Int = 0) {
            let whole = CGRect(origin: .zero, size: size)
            (self.id, self.size, self.area, self.placement) = (id, size, area ?? whole, placement ?? whole)
            (self.picture, self.name, self.depth, self.turn) = (picture, name, depth, turn)
        }
    }

    public static let height: CGFloat = 196
    private static let caption: CGFloat = 34
    private static let sheetOffset: CGFloat = 4
    private static let gap: CGFloat = 14

    public var reorders = false
    public var onMove: ((Int, Int) -> Void)?
    /// Files dropped from other apps, with the index they land at.
    public var onDrop: ((Int, [URL]) -> Void)?
    public var pageMenu: ((Int) -> NSMenu?)?
    public var onSelect: ((Int) -> Void)?
    public var dropTypes: [UTType] = [.image]
    public var selected: Int? {
        didSet { if selected != oldValue { strip.needsDisplay = true } }
    }

    private let scroll = NSScrollView()
    private let strip = Strip()
    private let empty: NSTextField

    public init(empty text: String = String(localized: "Pages")) {
        empty = .canon(text, size: 13, weight: .semibold, colour: .delphiMutedForeground)
        super.init(frame: .zero)
        strip.owner = self
        scroll.documentView = strip
        scroll.drawsBackground = false
        scroll.hasHorizontalScroller = true
        scroll.autohidesScrollers = true
        scroll.scrollerStyle = .overlay
        scroll.horizontalScrollElasticity = .allowed
        scroll.verticalScrollElasticity = .none
        empty.alignment = .center
        empty.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scroll)
        addSubview(empty)
        NSLayoutConstraint.activate([
            empty.centerXAnchor.constraint(equalTo: centerXAnchor), empty.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        registerForDraggedTypes([.fileURL])
        setAccessibilityElement(true)
        setAccessibilityRole(.list)
        setAccessibilityLabel(text)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var isFlipped: Bool { true }

    public override func layout() {
        super.layout()
        scroll.frame = bounds
        strip.relayout(height: bounds.height)
    }

    public func show(_ pages: [Page]) {
        empty.isHidden = !pages.isEmpty
        guard pages != strip.pages else { return }
        let resized = pages.count != strip.pages.count || zip(pages, strip.pages).contains { $0.size != $1.size || $0.depth != $1.depth }
        strip.pages = pages
        if resized { strip.relayout(height: bounds.height, force: true) }
        strip.needsDisplay = true
        setAccessibilityValue("\(pages.count)")
    }

    /// Scrolls the page into view.
    public func reveal(_ index: Int) {
        guard strip.frames.indices.contains(index) else { return }
        strip.scrollToVisible(strip.frames[index].insetBy(dx: -40, dy: 0))
    }


    private func droppedURLs(_ info: NSDraggingInfo) -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true, .urlReadingContentsConformToTypes: dropTypes.map(\.identifier),
        ]
        return info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL] ?? []
    }

    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        reorders && onDrop != nil && !droppedURLs(sender).isEmpty ? .copy : []
    }

    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = droppedURLs(sender)
        guard reorders, let onDrop, !urls.isEmpty else { return false }
        onDrop(strip.insertion(at: strip.convert(sender.draggingLocation, from: nil).x), urls)
        return true
    }


    private final class Strip: NSView {
        weak var owner: CanonPageStrip?
        var pages: [Page] = []
        private(set) var frames: [CGRect] = []
        private var laidOut: (height: CGFloat, width: CGFloat)?
        private var pressed: Int?
        private var dragX: CGFloat?

        override var isFlipped: Bool { true }

        func relayout(height: CGFloat, force: Bool = false) {
            guard let owner else { return }
            let visible = owner.scroll.contentSize.width
            if !force, laidOut?.height == height, laidOut?.width == visible { return }
            laidOut = (height, visible)
            let paper = max(20, height - 22 - CanonPageStrip.caption)
            var x = DelphiMetrics.panelPadding
            frames = pages.map { page in
                let width = max(56, min(visible * 0.7, paper * page.size.width / max(1, page.size.height)))
                defer { x += width + CanonPageStrip.gap }
                return CGRect(x: x, y: 14, width: width, height: paper + CanonPageStrip.caption)
            }
            let total = pages.isEmpty ? 0 : x - CanonPageStrip.gap + DelphiMetrics.panelPadding
            setFrameSize(CGSize(width: max(total, visible), height: height))
            needsDisplay = true
        }

        func insertion(at x: CGFloat) -> Int {
            frames.firstIndex { x < $0.midX } ?? frames.count
        }

        private func index(at point: CGPoint) -> Int? {
            frames.firstIndex { $0.contains(point) }
        }

        /// The paper inside a cell, room left for stacked sheets.
        private func paperRect(_ index: Int) -> CGRect {
            let cell = frames[index]
            let page = pages[index]
            let height = cell.height - CanonPageStrip.caption
            let room = CGFloat(min(page.depth, 3)) * CanonPageStrip.sheetOffset
            let scale = min((cell.width - room) / max(1, page.size.width), (height - room) / max(1, page.size.height))
            let size = CGSize(width: page.size.width * scale, height: page.size.height * scale)
            return CGRect(x: cell.minX + (cell.width - size.width - room) / 2, y: cell.minY + height - size.height, width: size.width, height: size.height)
        }

        override func draw(_ dirtyRect: NSRect) {
            guard let context = NSGraphicsContext.current?.cgContext else { return }
            let lit = owner?.selected
            for (index, cell) in frames.enumerated() where cell.insetBy(dx: -20, dy: 0).intersects(dirtyRect) {
                let page = pages[index]
                let paper = paperRect(index)
                for sheet in (0..<min(page.depth, 3)).reversed() {
                    let offset = CGFloat(sheet + 1) * CanonPageStrip.sheetOffset
                    let rect = paper.offsetBy(dx: offset, dy: -offset)
                    NSColor.white.setFill()
                    rect.fill()
                    NSColor.delphiBorder.setStroke()
                    NSBezierPath(rect: rect.insetBy(dx: 0.5, dy: 0.5)).stroke()
                }
                drawPaper(page, in: paper, lit: index == lit, context: context)
                let numberAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.delphiMono(12, weight: .semibold), .foregroundColor: index == lit ? NSColor.delphiPrimary : .delphiForeground,
                ]
                let number = "\(index + 1)" as NSString
                let numberWidth = number.size(withAttributes: numberAttributes).width
                let captionY = cell.maxY - CanonPageStrip.caption + 4
                number.draw(at: CGPoint(x: page.name == nil ? cell.midX - numberWidth / 2 : cell.minX, y: captionY), withAttributes: numberAttributes)
                if let name = page.name {
                    let style = NSMutableParagraphStyle()
                    style.lineBreakMode = .byTruncatingMiddle
                    (name as NSString).draw(in: CGRect(x: cell.minX, y: captionY + 14, width: cell.width, height: 14), withAttributes: [
                        .font: NSFont.delphi(11), .foregroundColor: NSColor.delphiMutedForeground, .paragraphStyle: style,
                    ])
                }
            }
            if let dragX, let pressed {
                let at = insertion(at: dragX)
                let x = at < frames.count ? frames[at].minX - CanonPageStrip.gap / 2 : (frames.last?.maxX ?? 0) + CanonPageStrip.gap / 2
                if at != pressed, at != pressed + 1 {
                    NSColor.delphiPrimary.setFill()
                    CGRect(x: x - DelphiMetrics.frame / 2, y: 10, width: DelphiMetrics.frame, height: bounds.height - 20).fill()
                }
            }
        }

        private func drawPaper(_ page: Page, in rect: CGRect, lit: Bool, context: CGContext) {
            NSColor.white.setFill()
            rect.fill()
            let scale = rect.width / max(1, page.size.width)
            // pdf origin: bottom left
            let flip = { (r: CGRect) in
                CGRect(x: rect.minX + r.minX * scale, y: rect.minY + (page.size.height - r.maxY) * scale, width: r.width * scale, height: r.height * scale)
            }
            let area = flip(page.area)
            if let picture = page.picture {
                context.saveGState()
                context.clip(to: area)
                let target = flip(page.placement)
                context.translateBy(x: target.midX, y: target.midY)
                context.rotate(by: CGFloat(page.turn) * .pi / 180)
                // flipped view: images draw upside down
                context.scaleBy(x: 1, y: -1)
                let quarter = ((page.turn / 90) % 4 + 4) % 4
                let size = quarter % 2 == 0 ? target.size : CGSize(width: target.height, height: target.width)
                context.interpolationQuality = .high
                context.draw(picture, in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
                context.restoreGState()
            }
            if page.area != CGRect(origin: .zero, size: page.size) {
                let dash = NSBezierPath(rect: area)
                dash.lineWidth = DelphiMetrics.hairline
                dash.setLineDash([3, 3], count: 2, phase: 0)
                NSColor.delphiPrimary.withAlphaComponent(0.4).setStroke()
                dash.stroke()
            }
            let edge = lit ? DelphiMetrics.frame : DelphiMetrics.hairline
            (lit ? NSColor.delphiPrimary : .delphiBorder).setStroke()
            let outline = NSBezierPath(rect: rect.insetBy(dx: edge / 2, dy: edge / 2))
            outline.lineWidth = edge
            outline.stroke()
        }

        override func mouseDown(with event: NSEvent) {
            pressed = index(at: convert(event.locationInWindow, from: nil))
            dragX = nil
        }

        override func mouseDragged(with event: NSEvent) {
            guard owner?.reorders == true, pressed != nil else { return }
            dragX = convert(event.locationInWindow, from: nil).x
            autoscroll(with: event)
            needsDisplay = true
        }

        override func mouseUp(with event: NSEvent) {
            defer { (pressed, dragX) = (nil, nil); needsDisplay = true }
            guard let pressed, let owner else { return }
            guard let dragX else { return owner.onSelect?(pressed) ?? () }
            var to = insertion(at: dragX)
            if to > pressed { to -= 1 }
            guard to != pressed, pages.indices.contains(to) else { return }
            pages.insert(pages.remove(at: pressed), at: to)
            owner.onMove?(pressed, to)
        }

        override func menu(for event: NSEvent) -> NSMenu? {
            guard let index = index(at: convert(event.locationInWindow, from: nil)) else { return nil }
            return owner?.pageMenu?(index)
        }

        override func viewDidChangeEffectiveAppearance() {
            super.viewDidChangeEffectiveAppearance()
            needsDisplay = true
        }
    }
}
