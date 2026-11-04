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
