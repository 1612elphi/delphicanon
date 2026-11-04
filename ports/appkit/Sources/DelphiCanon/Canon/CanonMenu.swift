import AppKit

/// A flush cell showing the chosen title; a click opens a menu of all titles under it.
public final class CanonMenuCell: CanonPressable {
    public let titles: [String]
    private let label = NSTextField.canon(weight: .medium)
    private let chevron = NSImageView(image: .canonSymbol("chevron.up.chevron.down", size: 10) ?? NSImage())
    private var handlers: [(CanonMenuCell) -> Void] = []

    public var selectedIndex: Int {
        didSet { refresh() }
    }

    public init(_ titles: [String], selected: Int = 0) {
        self.titles = titles
        selectedIndex = selected
        super.init(fill: .delphiCard)
        chevron.contentTintColor = .delphiMutedForeground
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        let row = NSStackView(views: [label, chevron])
        row.spacing = 8
        row.distribution = .fill
        pin(row, insets: canonInsets(vertical: 0, horizontal: 12))
        heightAnchor.constraint(greaterThanOrEqualToConstant: DelphiMetrics.controlHeight).isActive = true
        refresh()
    }

    @discardableResult
    public func onChange(_ handler: @escaping (CanonMenuCell) -> Void) -> Self {
        handlers.append(handler)
        return self
    }

    private func refresh() {
        label.stringValue = titles.indices.contains(selectedIndex) ? titles[selectedIndex] : ""
        setAccessibilityValue(label.stringValue)
    }

    public override func stateChanged() {
        fill = isHovering && isEnabled ? .delphiAccentBG : .delphiCard
        alphaValue = isEnabled ? 1 : 0.4
    }

    public override func press() {
        let menu = NSMenu()
        for (index, title) in titles.enumerated() {
            let item = NSMenuItem(title: title, action: #selector(picked(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            item.state = index == selectedIndex ? .on : .off
            menu.addItem(item)
        }
        menu.popUp(positioning: menu.item(at: selectedIndex), at: NSPoint(x: 0, y: bounds.maxY), in: self)
    }

    @objc private func picked(_ item: NSMenuItem) {
        guard item.tag != selectedIndex else { return }
        selectedIndex = item.tag
        handlers.forEach { $0(self) }
    }
}

/// Two menu cells with an arrow between them: a pair picked from the same list, or from `targets`.
public final class CanonFromTo: CanonView {
    public let from: CanonMenuCell
    public let to: CanonMenuCell

    public init(_ titles: [String], targets: [String]? = nil, from: Int = 0, to: Int = 0) {
        self.from = CanonMenuCell(titles, selected: from)
        self.to = CanonMenuCell(targets ?? titles, selected: to)
        super.init(fill: .delphiBorder)
        let symbol = NSImageView(image: .canonSymbol("arrow.forward", size: 11) ?? NSImage())
        symbol.contentTintColor = .delphiMutedForeground
        symbol.setAccessibilityElement(false)
        let arrow = CanonView(fill: .delphiCard)
        arrow.addSubview(symbol)
        symbol.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            symbol.centerXAnchor.constraint(equalTo: arrow.centerXAnchor),
            symbol.centerYAnchor.constraint(equalTo: arrow.centerYAnchor),
            arrow.widthAnchor.constraint(equalToConstant: DelphiMetrics.controlHeight),
        ])
        pin(CanonStack([self.from, arrow, self.to], vertical: false))
        self.from.widthAnchor.constraint(equalTo: self.to.widthAnchor).isActive = true
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @discardableResult
    public func onChange(_ handler: @escaping (CanonFromTo) -> Void) -> Self {
        for cell in [from, to] { cell.onChange { [unowned self] _ in handler(self) } }
        return self
    }
}
