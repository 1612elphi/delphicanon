import AppKit
import Observation

/// A flipped, layer-backed view whose fill and border follow the appearance.
open class CanonView: NSView {
    public var fill: NSColor? {
        didSet { needsDisplay = true }
    }

    public var border: (colour: NSColor, width: CGFloat)? {
        didSet { needsDisplay = true }
    }

    public init(fill: NSColor? = nil) {
        self.fill = fill
        super.init(frame: .zero)
        wantsLayer = true
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    open override var isFlipped: Bool { true }
    open override var wantsUpdateLayer: Bool { true }

    open override func updateLayer() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = fill?.cgColor
            layer?.borderColor = border?.colour.cgColor
            layer?.borderWidth = border?.width ?? 0
        }
    }

    open override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
}

extension NSTextField {
    public static func canon(
        _ text: String = "",
        size: CGFloat = 13,
        weight: NSFont.Weight = .regular,
        colour: NSColor = .delphiForeground,
        wraps: Bool = false
    ) -> NSTextField {
        let label = wraps ? NSTextField(wrappingLabelWithString: text) : NSTextField(labelWithString: text)
        label.font = .delphi(size, weight: weight)
        label.textColor = colour
        label.isSelectable = false
        label.lineBreakMode = wraps ? .byWordWrapping : .byTruncatingTail
        return label
    }

    /// Title of a heading bar: `CanonHeading`, the code block label.
    public static func canonHeading(_ text: String) -> NSTextField {
        .canon(text, size: 11, colour: .delphiMutedForeground)
    }
}

/// Runs `apply` now and again after any `@Observable` value it read changes, for as long as `owner` lives.
public func canonObserve(_ owner: AnyObject, _ apply: @escaping @MainActor () -> Void) {
    let weakOwner = WeakOwner(owner)
    withObservationTracking(apply) {
        Task { @MainActor in
            if let owner = weakOwner.value { canonObserve(owner, apply) }
        }
    }
}

// read on the main actor only
private final class WeakOwner: @unchecked Sendable {
    weak var value: AnyObject?

    init(_ value: AnyObject) {
        self.value = value
    }
}

/// Runs the latest body once typing has paused.
public final class CanonDebounce {
    private var pending: DispatchWorkItem?

    public init() {}

    public func after(_ seconds: TimeInterval, _ body: @escaping @MainActor () -> Void) {
        pending?.cancel()
        let item = DispatchWorkItem { MainActor.assumeIsolated(body) }
        pending = item
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: item)
    }

    public func cancel() {
        pending?.cancel()
    }
}

extension NSView {
    public func pin(_ child: NSView, insets: NSEdgeInsets = NSEdgeInsetsZero) {
        child.translatesAutoresizingMaskIntoConstraints = false
        addSubview(child)
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            child.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: child.trailingAnchor, constant: insets.right),
            bottomAnchor.constraint(equalTo: child.bottomAnchor, constant: insets.bottom),
        ])
    }

    /// Nearest view controller up the responder chain.
    public var owningViewController: NSViewController? {
        sequence(first: self as NSResponder, next: \.nextResponder).lazy.compactMap { $0 as? NSViewController }.first
    }
}

public func canonInsets(_ all: CGFloat) -> NSEdgeInsets {
    NSEdgeInsets(top: all, left: all, bottom: all, right: all)
}

public func canonInsets(vertical: CGFloat, horizontal: CGFloat) -> NSEdgeInsets {
    NSEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
}

/// A stack whose views fill its cross axis.
public final class CanonStack: NSStackView {
    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public init(_ views: [NSView] = [], vertical: Bool = true, spacing: CGFloat = DelphiMetrics.hairline) {
        super.init(frame: .zero)
        orientation = vertical ? .vertical : .horizontal
        self.spacing = spacing
        distribution = .fill
        alignment = vertical ? .leading : .top
        setViews(views)
    }

    public func setViews(_ views: [NSView]) {
        arrangedSubviews.forEach { $0.removeFromSuperview() }
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            addArrangedSubview(view)
            if orientation == .vertical {
                view.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
            } else {
                view.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
            }
        }
    }

    public override var isFlipped: Bool { true }
}

public final class CanonRule: CanonView {
    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public init(vertical: Bool = false, weight: CGFloat = DelphiMetrics.hairline) {
        super.init(fill: .delphiBorder)
        translatesAutoresizingMaskIntoConstraints = false
        (vertical ? widthAnchor : heightAnchor).constraint(equalToConstant: weight).isActive = true
    }
}

/// Rows separated by hairlines: the gaps show this view's border colour.
public final class CanonRows: CanonView {
    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let stack = CanonStack()

    /// - Parameter framed: draws the 2 pt tool frame around the rows.
    public init(framed: Bool = false, _ rows: [NSView] = []) {
        super.init(fill: .delphiBorder)
        pin(stack, insets: canonInsets(framed ? DelphiMetrics.frame : 0))
        setRows(rows)
    }

    public func setRows(_ rows: [NSView]) {
        stack.setViews(rows)
    }
}

public final class CanonHeading: CanonView {
    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let label: NSTextField

    public var text: String {
        get { label.stringValue }
        set { label.stringValue = newValue }
    }

    public init(_ text: String, background: NSColor = .delphiMuted) {
        label = .canonHeading(text)
        super.init(fill: background)
        label.setAccessibilityRole(.staticText)
        pin(label, insets: canonInsets(vertical: 6, horizontal: DelphiMetrics.panelPadding))
    }
}

public final class CanonEmptyRow: CanonView {
    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public init(_ text: String) {
        super.init(fill: .delphiCard)
        let label = CanonStatus(text, .muted)
        label.alignment = .center
        pin(label, insets: canonInsets(vertical: 12, horizontal: DelphiMetrics.panelPadding))
        heightAnchor.constraint(greaterThanOrEqualToConstant: 96).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
}

/// Label beside a control.
// ponytail: no auto stacking, the window has a minimum width; pass .stacked where a control is wide
public final class CanonRow: CanonView {
    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }


    public enum Form {
        /// Control keeps air around it.
        case plain
        /// Control meets the row's top, bottom and trailing edge behind a hairline.
        case flush
        /// Control spans the row below the label.
        case stacked
    }

    public let titleLabel: NSTextField
    public private(set) var detailLabel: NSTextField?

    public init(_ title: String, detail: String? = nil, icon systemImage: String? = nil, form: Form = .plain, control: NSView? = nil) {
        titleLabel = .canon(title)
        super.init(fill: .delphiCard)
        titleLabel.setContentCompressionResistancePriority(.init(800), for: .horizontal)

        let text = NSStackView(views: [titleLabel])
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 2
        if let detail {
            let label = NSTextField.canon(detail, size: 11, colour: .delphiMutedForeground, wraps: true)
            detailLabel = label
            text.addArrangedSubview(label)
        }
        text.translatesAutoresizingMaskIntoConstraints = false
        addSubview(text)

        let padding = DelphiMetrics.panelPadding
        heightAnchor.constraint(greaterThanOrEqualToConstant: DelphiMetrics.rowHeight).isActive = true

        var leading = leadingAnchor
        var leadingGap = padding
        if let systemImage, form == .plain, let image = NSImage(systemSymbolName: systemImage, accessibilityDescription: nil) {
            let icon = NSImageView(image: image)
            icon.contentTintColor = .delphiMutedForeground
            icon.translatesAutoresizingMaskIntoConstraints = false
            addSubview(icon)
            NSLayoutConstraint.activate([
                icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
                icon.widthAnchor.constraint(equalToConstant: 16),
                icon.centerYAnchor.constraint(equalTo: text.centerYAnchor),
            ])
            leading = icon.trailingAnchor
            leadingGap = 12
        }
        text.leadingAnchor.constraint(equalTo: leading, constant: leadingGap).isActive = true

        guard let control else {
            NSLayoutConstraint.activate([
                text.centerYAnchor.constraint(equalTo: centerYAnchor),
                text.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 6),
                trailingAnchor.constraint(greaterThanOrEqualTo: text.trailingAnchor, constant: padding),
            ])
            return
        }
        control.translatesAutoresizingMaskIntoConstraints = false
        addSubview(control)
        if control.accessibilityLabel()?.isEmpty ?? true { control.setAccessibilityLabel(title) }

        switch form {
        case .plain:
            control.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            NSLayoutConstraint.activate([
                text.centerYAnchor.constraint(equalTo: centerYAnchor),
                text.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 6),
                control.leadingAnchor.constraint(greaterThanOrEqualTo: text.trailingAnchor, constant: 12),
                trailingAnchor.constraint(equalTo: control.trailingAnchor, constant: padding),
                control.centerYAnchor.constraint(equalTo: centerYAnchor),
                control.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 6),
            ])
        case .flush:
            let rule = CanonRule(vertical: true)
            addSubview(rule)
            control.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            NSLayoutConstraint.activate([
                text.centerYAnchor.constraint(equalTo: centerYAnchor),
                text.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 6),
                rule.leadingAnchor.constraint(greaterThanOrEqualTo: text.trailingAnchor, constant: 12),
                rule.topAnchor.constraint(equalTo: topAnchor),
                rule.bottomAnchor.constraint(equalTo: bottomAnchor),
                control.leadingAnchor.constraint(equalTo: rule.trailingAnchor),
                control.trailingAnchor.constraint(equalTo: trailingAnchor),
                control.topAnchor.constraint(equalTo: topAnchor),
                control.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        case .stacked:
            let rule = CanonRule()
            addSubview(rule)
            NSLayoutConstraint.activate([
                text.topAnchor.constraint(equalTo: topAnchor, constant: 10),
                trailingAnchor.constraint(greaterThanOrEqualTo: text.trailingAnchor, constant: padding),
                rule.topAnchor.constraint(equalTo: text.bottomAnchor, constant: 10),
                rule.leadingAnchor.constraint(equalTo: leadingAnchor),
                rule.trailingAnchor.constraint(equalTo: trailingAnchor),
                control.topAnchor.constraint(equalTo: rule.bottomAnchor),
                control.leadingAnchor.constraint(equalTo: leadingAnchor),
                control.trailingAnchor.constraint(equalTo: trailingAnchor),
                control.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }
    }

    public func setText(title: String, detail: String? = nil) {
        titleLabel.stringValue = title
        if let detail { detailLabel?.stringValue = detail }
    }
}

/// Equal cells divided by hairlines. Rows are balanced; the last cell of a short row spans the rest.
public final class CanonGrid: CanonView {
    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let stack = CanonStack()
    private let columns: Int?

    /// - Parameter boxed: draws the outer hairline; leave false inside `CanonRows` or a `CanonRow`.
    public init(columns: Int? = nil, boxed: Bool = false, _ cells: [NSView] = []) {
        self.columns = columns
        super.init(fill: .delphiBorder)
        pin(stack, insets: canonInsets(boxed ? DelphiMetrics.hairline : 0))
        setCells(cells)
    }

    public func setCells(_ cells: [NSView]) {
        let sizes = Self.balanced(cells.count, perRow: columns ?? cells.count)
        let widest = sizes.max() ?? 0
        var index = 0
        var rows: [NSView] = []
        var widths: [NSLayoutConstraint] = []
        for size in sizes {
            let slice = Array(cells[index..<index + size])
            let row = CanonStack(slice, vertical: false)
            let units = size == widest ? size : size - 1
            widths += slice[0..<units].map { $0.widthAnchor.constraint(equalTo: cells[0].widthAnchor) }
            rows.append(row)
            index += size
        }
        stack.setViews(rows)
        // rows share the height
        widths += rows.dropFirst().map { $0.heightAnchor.constraint(equalTo: rows[0].heightAnchor) }
        NSLayoutConstraint.activate(widths)
    }

    /// Row sizes that differ by at most one, larger rows first.
    public static func balanced(_ count: Int, perRow: Int) -> [Int] {
        guard count > 0 else { return [] }
        let perRow = min(max(1, perRow), count)
        let rowCount = (count + perRow - 1) / perRow
        return (0..<rowCount).map { count / rowCount + ($0 < count % rowCount ? 1 : 0) }
    }
}

/// Scrolling body. Sections are centred, capped at `maxWidth` when set, and inset by the panel padding.
public final class CanonPage: NSScrollView {
    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let stack: CanonStack

    public convenience init(_ content: NSView, maxWidth: CGFloat? = nil) {
        self.init(sections: [content], maxWidth: maxWidth)
    }

    public init(sections: [NSView], maxWidth: CGFloat? = nil) {
        stack = CanonStack(sections, spacing: DelphiMetrics.panelPadding)
        super.init(frame: .zero)
        drawsBackground = true
        backgroundColor = .delphiBackground
        hasVerticalScroller = true
        autohidesScrollers = true
        let document = CanonView()
        document.translatesAutoresizingMaskIntoConstraints = false
        documentView = document
        let padding = DelphiMetrics.panelPadding
        stack.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(stack)
        let fill = stack.widthAnchor.constraint(equalTo: document.widthAnchor, constant: -padding * 2)
        fill.priority = .init(999)
        NSLayoutConstraint.activate([
            document.topAnchor.constraint(equalTo: contentView.topAnchor),
            document.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            stack.topAnchor.constraint(equalTo: document.topAnchor, constant: padding),
            document.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: padding),
            stack.centerXAnchor.constraint(equalTo: document.centerXAnchor),
            fill,
        ])
        if let maxWidth { stack.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth).isActive = true }
    }

    public func setSections(_ sections: [NSView]) {
        stack.setViews(sections)
    }
}
