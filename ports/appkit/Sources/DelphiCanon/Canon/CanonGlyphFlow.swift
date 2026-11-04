import AppKit

/// Glyph widths wrapped into rows, words kept whole unless one is wider than a row.
public enum CanonGlyphRows {
    public enum Kind { case glyph, space, newline }

    /// Frames in a block whose first row starts at y 0, and the number of rows.
    public static func layout(widths: [CGFloat], kinds: [Kind], width: CGFloat, gap: CGFloat, height: CGFloat, pitch: CGFloat) -> (frames: [CGRect], rows: Int) {
        var frames = Array(repeating: CGRect.zero, count: widths.count)
        var row = 0
        var x: CGFloat = 0
        var filled = false
        var i = 0
        func place(_ k: Int, at left: CGFloat) {
            frames[k] = CGRect(x: left, y: CGFloat(row) * pitch, width: widths[k], height: height)
            x = left + widths[k]
            filled = true
        }
        while i < widths.count {
            switch kinds[i] {
            case .newline:
                frames[i] = CGRect(x: x, y: CGFloat(row) * pitch, width: 0, height: height)
                (row, x, filled) = (row + 1, 0, false)
                i += 1
            case .space:
                // no leading row space
                if filled { place(i, at: x + gap) } else { frames[i] = CGRect(x: 0, y: CGFloat(row) * pitch, width: 0, height: height) }
                i += 1
            case .glyph:
                var end = i
                var word: CGFloat = 0
                while end < widths.count, kinds[end] == .glyph {
                    word += widths[end] + (end > i ? gap : 0)
                    end += 1
                }
                if filled, x + gap + word > width { (row, x, filled) = (row + 1, 0, false) }
                for k in i..<end {
                    if filled, x + gap + widths[k] > width { (row, x, filled) = (row + 1, 0, false) }
                    place(k, at: filled ? x + gap : 0)
                }
                i = end
            }
        }
        return (frames, widths.isEmpty ? 0 : row + 1)
    }

    #if DEBUG
    public static func selfCheck() {
        let g = Kind.glyph, s = Kind.space
        // second word wraps whole
        let wrapped = layout(widths: [20, 20, 10, 20, 20], kinds: [g, g, s, g, g], width: 60, gap: 0, height: 10, pitch: 12)
        assert(wrapped.rows == 2 && wrapped.frames[3] == CGRect(x: 0, y: 12, width: 20, height: 10))
        let spaced = layout(widths: [50, 10, 50], kinds: [g, s, g], width: 60, gap: 0, height: 10, pitch: 12)
        assert(spaced.rows == 2 && spaced.frames[2].minX == 0)
        assert(layout(widths: [40, 40, 40], kinds: [g, g, g], width: 90, gap: 5, height: 10, pitch: 12).rows == 2)
        assert(layout(widths: [10, 0, 10], kinds: [g, .newline, g], width: 90, gap: 0, height: 10, pitch: 12).rows == 2)
        assert(layout(widths: [], kinds: [], width: 90, gap: 0, height: 10, pitch: 12).rows == 0)
    }
    #endif
}

/// Glyphs in wrapped rows, the last row in view: the banner of the text tools. New glyphs grow in, glyphs that stay
/// slide to their new places, and removed ones fade.
public final class CanonGlyphFlow<Glyph: Equatable>: NSView {
    public struct Metrics: Equatable {
        /// Height of a row of glyphs.
        public var height: CGFloat
        public var rowGap: CGFloat
        /// Room between glyphs in a row; a space glyph adds its own width.
        public var gap: CGFloat

        public init(height: CGFloat, rowGap: CGFloat, gap: CGFloat) {
            self.height = height
            self.rowGap = rowGap
            self.gap = gap
        }
    }

    public var metrics: Metrics {
        didSet { if metrics != oldValue { relayout() } }
    }

    /// Draws a glyph into its frame; the index is nil for a glyph fading out.
    public var paint: (Glyph, Int?, CGRect, CGContext) -> Void = { _, _, _, _ in }
    /// Draws the picture with no glyphs, into the content area.
    public var paintEmpty: ((CGRect, CGContext) -> Void)?

    private let measure: (Glyph) -> CGFloat
    private let kind: (Glyph) -> CanonGlyphRows.Kind
    public private(set) var glyphs: [Glyph] = []
    private var target: [CGRect] = []
    private var start: [CGRect] = []
    private var appearing: [Bool] = []
    private var ghosts: [(glyph: Glyph, frame: CGRect)] = []
    private var began: CFTimeInterval = 0
    private var progress: Double = 1
    private var link: CADisplayLink?
    private var laidOutSize = CGSize.zero
    /// The rows in view; glyphs outside it are not drawn.
    private var rowWindow = CGRect.zero

    private static var settleDuration: Double { 0.45 }

    public override var isFlipped: Bool { true }

    public init(metrics: Metrics, measure: @escaping (Glyph) -> CGFloat, kind: @escaping (Glyph) -> CanonGlyphRows.Kind) {
        self.metrics = metrics
        self.measure = measure
        self.kind = kind
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Room the glyphs get: inside the panel padding.
    public var contentArea: CGRect {
        let padding = DelphiMetrics.panelPadding
        return CGRect(x: padding, y: padding * 0.75, width: max(0, bounds.width - padding * 2), height: max(0, bounds.height - padding * 1.5))
    }

    /// Replaces the glyphs. Glyphs that match at the start and the end stay and slide; the rest are new.
    /// - Parameter dropping: glyphs cut from the front since the last call, or added there if negative; the rest line up
    ///   with the old glyphs, so a caller that shows only the tail of a long text slides them as if it showed all of it.
    public func show(_ glyphs: [Glyph], dropping: Int = 0, animated: Bool) {
        let old = Array(self.glyphs.dropFirst(max(0, dropping)))
        let shown = Array(presentedFrames().dropFirst(max(0, dropping)))
        let added = min(glyphs.count, max(0, -dropping))
        let new = glyphs.dropFirst(added)
        let prefix = zip(old, new).prefix { $0 == $1 }.count
        let limit = min(old.count, new.count) - prefix
        var suffix = 0
        while suffix < limit, old[old.count - 1 - suffix] == glyphs[glyphs.count - 1 - suffix] { suffix += 1 }
        self.glyphs = glyphs
        target = layoutFrames()
        guard animated, canonAnimates, shown.count == old.count else {
            stopAnimating()
            return
        }
        start = glyphs.indices.map { i in
            if i < added { return target[i] }
            if i < added + prefix { return shown[i - added] }
            if i >= glyphs.count - suffix { return shown[i - glyphs.count + old.count] }
            return target[i]
        }
        appearing = glyphs.indices.map { $0 >= added + prefix && $0 < glyphs.count - suffix }
        let area = bounds
        ghosts = (prefix..<max(prefix, old.count - suffix)).compactMap { i in shown[i].intersects(area) ? (old[i], shown[i]) : nil }
        animate()
    }

    private func presentedFrames() -> [CGRect] {
        target.indices.map(presented)
    }

    private var eased: Double {
        // damped spring, one overshoot
        progress >= 1 ? 1 : 1 - exp(-7 * progress) * cos(8 * progress)
    }

    private func presented(_ i: Int) -> CGRect {
        guard progress < 1, start.indices.contains(i), !appearing[i] else { return target[i] }
        let e = CGFloat(eased)
        let from = start[i], to = target[i]
        return CGRect(x: from.minX + (to.minX - from.minX) * e, y: from.minY + (to.minY - from.minY) * e,
                      width: from.width + (to.width - from.width) * e, height: from.height + (to.height - from.height) * e)
    }

    private func relayout() {
        target = layoutFrames()
        stopAnimating()
    }

    private func layoutFrames() -> [CGRect] {
        let area = contentArea
        rowWindow = area
        guard area.width > 0, !glyphs.isEmpty else { return glyphs.map { _ in .zero } }
        let pitch = metrics.height + metrics.rowGap
        let (frames, rows) = CanonGlyphRows.layout(
            widths: glyphs.map(measure), kinds: glyphs.map(kind), width: area.width, gap: metrics.gap, height: metrics.height, pitch: pitch
        )
        let fit = max(1, Int((area.height + metrics.rowGap) / pitch))
        let first = rows <= fit ? 0 : rows - fit
        let block = CGFloat(min(rows, fit)) * pitch - metrics.rowGap
        let y = area.minY + max(0, (area.height - block) / 2) - CGFloat(first) * pitch
        rowWindow = CGRect(x: bounds.minX, y: y + CGFloat(first) * pitch - metrics.rowGap / 2, width: bounds.width, height: block + metrics.rowGap)
        let x = rows == 1 ? area.minX + (area.width - (frames.map(\.maxX).max() ?? 0)) / 2 : area.minX
        return frames.map { $0.offsetBy(dx: x, dy: y) }
    }

    public override func layout() {
        super.layout()
        guard bounds.size != laidOutSize else { return }
        laidOutSize = bounds.size
        relayout()
    }

    private func animate() {
        began = CACurrentMediaTime()
        progress = 0
        if link == nil {
            let link = displayLink(target: self, selector: #selector(step))
            link.add(to: .main, forMode: .common)
            self.link = link
        }
        needsDisplay = true
    }

    @objc private func step() {
        progress = min(1, (CACurrentMediaTime() - began) / Self.settleDuration)
        if progress >= 1 { stopAnimating() } else { needsDisplay = true }
    }

    private func stopAnimating() {
        link?.invalidate()
        link = nil
        progress = 1
        ghosts = []
        start = target
        appearing = Array(repeating: false, count: target.count)
        needsDisplay = true
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil { stopAnimating() }
    }

    public override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.clip(to: rowWindow)
        if glyphs.isEmpty, ghosts.isEmpty {
            paintEmpty?(contentArea, context)
            return
        }
        let fade = CGFloat(max(0, 1 - progress * 3))
        for ghost in ghosts where fade > 0 {
            context.saveGState()
            context.setAlpha(fade)
            paint(ghost.glyph, nil, ghost.frame, context)
            context.restoreGState()
        }
        let grow = CGFloat(eased)
        let rise = CGFloat(min(1, progress * 2.5))
        for i in glyphs.indices {
            let frame = presented(i)
            guard frame.width > 0, frame.intersects(rowWindow) else { continue }
            context.saveGState()
            if progress < 1, appearing.indices.contains(i), appearing[i] {
                context.setAlpha(rise)
                let scale = 0.55 + 0.45 * grow
                context.translateBy(x: frame.midX, y: frame.midY)
                context.scaleBy(x: scale, y: scale)
                context.translateBy(x: -frame.midX, y: -frame.midY)
            }
            paint(glyphs[i], i, frame, context)
            context.restoreGState()
        }
    }
}
