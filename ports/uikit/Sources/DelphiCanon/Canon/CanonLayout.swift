import Observation
import UIKit

extension UILabel {
    public static func canon(
        _ text: String? = nil,
        _ style: UIFont.TextStyle = .body,
        weight: UIFont.Weight = .regular,
        colour: UIColor = .delphiForeground
    ) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .delphi(style, weight: weight)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = colour
        label.numberOfLines = 0
        return label
    }
}

extension UILabel {
    /// Title of a heading bar: `CanonHeading`, the preview panel caption, the code block language.
    public static func canonHeading(_ text: String?) -> UILabel {
        .canon(text, .footnote, weight: .semibold, colour: .delphiMutedForeground)
    }
}

extension UIColor {
    /// Background of every heading bar.
    public static let canonHeadingBackground = UIColor.delphiMuted
}

/// Runs `apply` now and again after any `@Observable` value it read changes, for as long as `owner` lives.
@MainActor
public func canonObserve(_ owner: AnyObject, _ apply: @escaping @MainActor () -> Void) {
    withObservationTracking(apply) { [weak owner] in
        Task { @MainActor [weak owner] in
            if let owner { canonObserve(owner, apply) }
        }
    }
}

/// Runs the latest body once typing has paused.
@MainActor
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

/// A bar filled from the leading edge to `share` of its width.
public class CanonBar: UIView {
    private let fill = UIView()

    public var share: CGFloat = 0 {
        didSet { setNeedsLayout() }
    }

    public var fillColour: UIColor? {
        get { fill.backgroundColor }
        set { fill.backgroundColor = newValue }
    }

    public init(fill colour: UIColor = .delphiPrimary, track: UIColor? = .delphiMuted) {
        super.init(frame: .zero)
        backgroundColor = track
        fill.backgroundColor = colour
        addSubview(fill)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Width of the filled part.
    public var filledWidth: CGFloat { bounds.width * min(max(share, 0), 1) }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let flipped = effectiveUserInterfaceLayoutDirection == .rightToLeft
        fill.frame = CGRect(x: flipped ? bounds.width - filledWidth : 0, y: 0, width: filledWidth, height: bounds.height)
    }
}

public protocol CanonChangeable: UIControl {}
extension UIControl: CanonChangeable {}

extension CanonChangeable {
    @discardableResult
    public func onChange(_ handler: @escaping (Self) -> Void) -> Self {
        addAction(UIAction { [unowned self] _ in handler(self) }, for: .valueChanged)
        return self
    }
}

extension UIResponder {
    /// Nearest view controller up the responder chain.
    public var owningViewController: UIViewController? {
        sequence(first: self, next: \.next).lazy.compactMap { $0 as? UIViewController }.first
    }
}

extension UIView {
    /// True for a page section that spans its column edge to edge, with no panel padding.
    @objc open var canonSpansColumn: Bool { false }
    /// True while the view must keep a touch the page would otherwise take for scrolling.
    // editing text keeps drags
    @objc open var canonKeepsTouch: Bool { self is UISwitch || self is UITextInput && isFirstResponder }

    /// Layer colours and drawn colours do not follow the appearance by themselves.
    public func redrawsOnStyleChange(layout: Bool = false) {
        registerForTraitChanges(UITraitCollection.delphiColourTraits) { (view: Self, _) in
            if layout { view.setNeedsLayout() } else { view.setNeedsDisplay() }
        }
    }

    public func pin(_ child: UIView, insets: NSDirectionalEdgeInsets = .zero) {
        child.translatesAutoresizingMaskIntoConstraints = false
        addSubview(child)
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            child.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.leading),
            trailingAnchor.constraint(equalTo: child.trailingAnchor, constant: insets.trailing),
            bottomAnchor.constraint(equalTo: child.bottomAnchor, constant: insets.bottom),
        ])
    }
}

extension UIViewController {
    /// Fills the controller's view with a canon body, from the screen's top edge to its bottom edge or the keyboard.
    public func fill(with body: UIView) {
        body.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(body)
        // default guide stops early
        view.keyboardLayoutGuide.usesBottomSafeArea = false
        NSLayoutConstraint.activate([
            body.topAnchor.constraint(equalTo: view.topAnchor),
            body.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            body.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
        ])
    }
}

public final class CanonRule: UIView {
    public init(vertical: Bool = false) {
        super.init(frame: .zero)
        backgroundColor = .delphiBorder
        translatesAutoresizingMaskIntoConstraints = false
        (vertical ? widthAnchor : heightAnchor).constraint(equalToConstant: DelphiMetrics.hairline).isActive = true
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Rows separated by hairlines: the gaps show this view's border colour.
public final class CanonRows: UIView {
    private let stack = UIStackView()

    /// - Parameter framed: draws the 2 pt tool frame around the rows.
    public init(framed: Bool = false, _ rows: [UIView] = []) {
        super.init(frame: .zero)
        backgroundColor = .delphiBorder
        stack.axis = .vertical
        stack.spacing = DelphiMetrics.hairline
        let inset = framed ? DelphiMetrics.frame : 0
        pin(stack, insets: NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset))
        setRows(rows)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func setRows(_ rows: [UIView]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        rows.forEach(stack.addArrangedSubview)
    }
}

public final class CanonHeading: UIView {
    private let label: UILabel

    public var text: String? {
        get { label.text }
        set { if newValue != label.text { label.text = newValue } }
    }

    public init(_ text: String, background: UIColor = .canonHeadingBackground) {
        label = UILabel.canonHeading(text)
        super.init(frame: .zero)
        backgroundColor = background
        label.accessibilityTraits = .header
        let padding = DelphiMetrics.panelPadding
        pin(label, insets: NSDirectionalEdgeInsets(top: 8, leading: padding, bottom: 8, trailing: padding))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

public final class CanonEmptyRow: UIView {
    public init(_ text: String) {
        super.init(frame: .zero)
        backgroundColor = .delphiCard
        let label = CanonStatus(text, .muted)
        label.textAlignment = .center
        label.numberOfLines = 0
        pin(label, insets: NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        heightAnchor.constraint(greaterThanOrEqualToConstant: 96).isActive = true
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Label beside a control. A row that is too narrow for both puts the control below the label.
public final class CanonRow: UIView {

    public enum Form {
        /// Control keeps air around it.
        case plain
        /// Control meets the row's top, bottom and trailing edge behind a hairline.
        case flush
        /// Control spans the row below the label.
        case stacked
    }

    public let titleLabel: UILabel
    public private(set) var detailLabel: UILabel?

    /// New text can change whether the control still fits beside the label.
    public func setText(title: String?, detail: String? = nil) {
        guard titleLabel.text != title || (detail != nil && detailLabel?.text != detail) else { return }
        // keep tool-set labels
        if controlReadsTitle, control?.accessibilityLabel == titleLabel.text { control?.accessibilityLabel = title }
        titleLabel.text = title
        if let detail { detailLabel?.text = detail }
        measuredWidth = -1
        setNeedsLayout()
    }
    /// Longest title among sibling rows, so a grid of rows stacks or not as one.
    public var sizingTitle: String? {
        didSet { measuredWidth = -1; setNeedsLayout() }
    }
    private let form: Form
    private let control: UIView?
    private var controlReadsTitle = false
    private let text = UIStackView()
    private var icon: UIImageView?
    private let sideRule = CanonRule(vertical: true)
    private let stackRule = CanonRule()
    private var side: [NSLayoutConstraint] = []
    private var stacked: [NSLayoutConstraint] = []
    private var isStacked = false
    private var measuredWidth: CGFloat = -1

    public init(_ title: String, detail: String? = nil, icon systemImage: String? = nil, form: Form = .plain, control: UIView? = nil) {
        titleLabel = .canon(title)
        self.form = form
        self.control = control
        super.init(frame: .zero)
        backgroundColor = .delphiCard

        titleLabel.setContentCompressionResistancePriority(.init(800), for: .horizontal)
        text.axis = .vertical
        text.spacing = 2
        text.addArrangedSubview(titleLabel)
        if let detail {
            let label = UILabel.canon(detail, .caption1, colour: .delphiMutedForeground)
            detailLabel = label
            text.addArrangedSubview(label)
        }
        text.translatesAutoresizingMaskIntoConstraints = false
        addSubview(text)

        if let systemImage, form == .plain {
            let view = UIImageView(image: UIImage(systemName: systemImage))
            view.tintColor = .delphiMutedForeground
            view.contentMode = .scaleAspectFit
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            icon = view
        }
        if let control {
            control.translatesAutoresizingMaskIntoConstraints = false
            control.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            addSubview(control)
            addSubview(sideRule)
            addSubview(stackRule)
            if control.accessibilityLabel?.isEmpty ?? true {
                controlReadsTitle = true
                control.accessibilityLabel = title
                titleLabel.isAccessibilityElement = !control.isAccessibilityElement
            }
        }
        build()
        isStacked = form == .stacked
        apply()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        let padding = DelphiMetrics.panelPadding
        let textLeading = icon.map { $0.trailingAnchor } ?? leadingAnchor
        heightAnchor.constraint(greaterThanOrEqualToConstant: DelphiMetrics.rowHeight).isActive = true
        if let icon {
            NSLayoutConstraint.activate([
                icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
                icon.widthAnchor.constraint(equalToConstant: 20),
                icon.centerYAnchor.constraint(equalTo: text.centerYAnchor),
            ])
        }
        let textLead = text.leadingAnchor.constraint(equalTo: textLeading, constant: icon == nil ? padding : 12)
        textLead.isActive = true

        side = [
            text.centerYAnchor.constraint(equalTo: centerYAnchor),
            text.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 6),
            bottomAnchor.constraint(greaterThanOrEqualTo: text.bottomAnchor, constant: 6),
        ]
        stacked = [text.topAnchor.constraint(equalTo: topAnchor, constant: 10)]

        guard let control else {
            side.append(trailingAnchor.constraint(greaterThanOrEqualTo: text.trailingAnchor, constant: padding))
            return
        }
        stacked.append(trailingAnchor.constraint(greaterThanOrEqualTo: text.trailingAnchor, constant: padding))

        // width is otherwise ambiguous
        let narrow = control.widthAnchor.constraint(equalToConstant: 0)
        narrow.priority = .init(240)
        side.append(narrow)

        if form == .plain {
            side += [
                control.leadingAnchor.constraint(greaterThanOrEqualTo: text.trailingAnchor, constant: 12),
                trailingAnchor.constraint(equalTo: control.trailingAnchor, constant: padding),
                control.centerYAnchor.constraint(equalTo: centerYAnchor),
                control.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 6),
                bottomAnchor.constraint(greaterThanOrEqualTo: control.bottomAnchor, constant: 6),
            ]
            stacked += [
                control.topAnchor.constraint(equalTo: text.bottomAnchor, constant: 8),
                control.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
                trailingAnchor.constraint(greaterThanOrEqualTo: control.trailingAnchor, constant: padding),
                bottomAnchor.constraint(equalTo: control.bottomAnchor, constant: 10),
            ]
        } else {
            side += [
                sideRule.leadingAnchor.constraint(greaterThanOrEqualTo: text.trailingAnchor, constant: 12),
                sideRule.topAnchor.constraint(equalTo: topAnchor),
                sideRule.bottomAnchor.constraint(equalTo: bottomAnchor),
                control.leadingAnchor.constraint(equalTo: sideRule.trailingAnchor),
                control.trailingAnchor.constraint(equalTo: trailingAnchor),
                control.topAnchor.constraint(equalTo: topAnchor),
                control.bottomAnchor.constraint(equalTo: bottomAnchor),
            ]
            stacked += [
                stackRule.topAnchor.constraint(equalTo: text.bottomAnchor, constant: 10),
                stackRule.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackRule.trailingAnchor.constraint(equalTo: trailingAnchor),
                control.topAnchor.constraint(equalTo: stackRule.bottomAnchor),
                control.leadingAnchor.constraint(equalTo: leadingAnchor),
                control.trailingAnchor.constraint(equalTo: trailingAnchor),
                control.bottomAnchor.constraint(equalTo: bottomAnchor),
            ]
        }
    }

    private func apply() {
        NSLayoutConstraint.deactivate(isStacked ? side : stacked)
        NSLayoutConstraint.activate(isStacked ? stacked : side)
        sideRule.isHidden = isStacked || form == .plain
        stackRule.isHidden = !isStacked || form == .plain
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard form != .stacked, let control, bounds.width != measuredWidth else { return }
        measuredWidth = bounds.width
        let fitting = UIView.layoutFittingCompressedSize
        let padding = DelphiMetrics.panelPadding * (form == .plain ? 2 : 1) + 12 + (icon == nil ? 0 : 32)
        let sizing = sizingTitle.map { ($0 as NSString).size(withAttributes: [.font: titleLabel.font!]).width.rounded(.up) } ?? 0
        let needed = max(text.systemLayoutSizeFitting(fitting).width, sizing) + control.systemLayoutSizeFitting(fitting).width + padding
        guard (needed > bounds.width) != isStacked else { return }
        isStacked.toggle()
        apply()
        setNeedsLayout()
    }
}

/// Equal cells divided by hairlines. Rows are balanced; the last cell of a short row spans the rest.
public final class CanonGrid: UIView {
    private let stack = UIStackView()
    private let columns: Int?
    private var fitKey = ""

    /// - Parameter boxed: draws the outer hairline; leave false inside `CanonRows` or a `CanonRow`.
    public init(columns: Int? = nil, boxed: Bool = false, _ cells: [UIView] = []) {
        self.columns = columns
        super.init(frame: .zero)
        backgroundColor = .delphiBorder
        stack.axis = .vertical
        stack.spacing = DelphiMetrics.hairline
        stack.distribution = .fillEqually
        let inset = boxed ? DelphiMetrics.hairline : 0
        pin(stack, insets: NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset))
        setCells(cells)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Change the cells with this, not with `isHidden`: a hidden cell's zero width collapses its equal-width siblings.
    public func setCells(_ cells: [UIView]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let rows = Self.balanced(cells.count, perRow: columns ?? cells.count)
        let widest = rows.max() ?? 0
        var index = 0
        var equalWidths: [NSLayoutConstraint] = []
        for size in rows {
            let row = UIStackView(arrangedSubviews: Array(cells[index..<index + size]))
            row.spacing = DelphiMetrics.hairline
            let units = size == widest ? size : size - 1
            equalWidths += cells[index..<index + units].map { $0.widthAnchor.constraint(equalTo: cells[0].widthAnchor) }
            stack.addArrangedSubview(row)
            index += size
        }
        NSLayoutConstraint.activate(equalWidths)
    }

    // titles drop together
    public override func layoutSubviews() {
        super.layoutSubviews()
        let rows = stack.arrangedSubviews.compactMap { ($0 as? UIStackView)?.arrangedSubviews }
        // measure on change only
        let key = "\(stack.bounds.width)" + rows.joined().compactMap { ($0 as? CanonButton)?.text }.joined(separator: "|")
        guard key != fitKey else { return }
        fitKey = key
        // from own width: cells lag
        let tight = rows.contains { row in
            let width = (stack.bounds.width - DelphiMetrics.hairline * CGFloat(row.count - 1)) / CGFloat(max(1, row.count))
            return row.contains { ($0 as? CanonButton)?.titleFits(in: width) == false }
        }
        rows.joined().forEach { ($0 as? CanonButton)?.isSymbolOnly = tight }
    }

    /// Row sizes that differ by at most one, larger rows first.
    public static func balanced(_ count: Int, perRow: Int) -> [Int] {
        guard count > 0 else { return [] }
        let perRow = min(max(1, perRow), count)
        let rowCount = (count + perRow - 1) / perRow
        return (0..<rowCount).map { count / rowCount + ($0 < count % rowCount ? 1 : 0) }
    }
}

/// Scrolling tool body. Sections are centred, capped at `maxWidth` when set, and inset by the panel padding.
/// A `CanonCanvas` section instead spans the full width of the page's safe area.
public final class CanonPage: UIScrollView {
    // leading canvas bleeds up
    private let leadingCanvas: CanonCanvas?
    private var top: NSLayoutConstraint!

    public convenience init(_ content: UIView, maxWidth: CGFloat? = 720) {
        self.init(sections: [content], maxWidth: maxWidth)
    }

    public init(sections: [UIView], maxWidth: CGFloat? = 720) {
        leadingCanvas = (sections.first as? CanonCanvas).flatMap { $0.canonSpansColumn ? $0 : nil }
        super.init(frame: .zero)
        backgroundColor = .delphiBackground
        alwaysBounceVertical = true
        keyboardDismissMode = .interactive
        // press starts on touch
        delaysContentTouches = false

        let padding = DelphiMetrics.panelPadding
        let stack = UIStackView(arrangedSubviews: sections.map { section in
            section.canonSpansColumn ? section : Self.padded(section, maxWidth: maxWidth)
        })
        stack.axis = .vertical
        stack.spacing = padding
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        // landscape and duo insets
        top = stack.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor, constant: leadingCanvas == nil ? padding : 0)
        NSLayoutConstraint.activate([
            top,
            contentLayoutGuide.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: padding),
            stack.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            stack.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor),
            contentLayoutGuide.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor),
        ])
    }

    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        guard let leadingCanvas else { return }
        leadingCanvas.bleedTop = safeAreaInsets.top
        top.constant = -safeAreaInsets.top
    }

    private static func padded(_ section: UIView, maxWidth: CGFloat?) -> UIView {
        let wrapper = CanonPaddedSection()
        wrapper.isHidden = section.isHidden
        let padding = DelphiMetrics.panelPadding
        section.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(section)
        let fill = section.widthAnchor.constraint(equalTo: wrapper.widthAnchor, constant: -padding * 2)
        fill.priority = .init(999)
        NSLayoutConstraint.activate([
            section.topAnchor.constraint(equalTo: wrapper.topAnchor),
            section.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            section.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
            section.widthAnchor.constraint(lessThanOrEqualTo: wrapper.widthAnchor, constant: -padding * 2),
            fill,
        ])
        if let maxWidth { section.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth).isActive = true }
        return wrapper
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Scrolls to `distance` below the top of the content, clamped to the ends.
    public func scroll(fromTop distance: CGFloat) {
        let top = -adjustedContentInset.top
        contentOffset.y = max(top, min(top + distance, max(top, contentSize.height + adjustedContentInset.bottom - bounds.height)))
    }

    // drag on button scrolls
    public override func touchesShouldCancel(in view: UIView) -> Bool {
        !view.canonKeepsTouch
    }
}

public final class CanonPaddedSection: UIView {}

extension UIView {
    /// Hides a page section together with the padding the page wrapped around it.
    public func setCanonSectionHidden(_ hidden: Bool) {
        isHidden = hidden
        (superview as? CanonPaddedSection)?.isHidden = hidden
    }
}
