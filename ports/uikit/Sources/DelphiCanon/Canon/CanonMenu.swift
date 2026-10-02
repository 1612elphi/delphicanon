import UIKit

/// A flush cell that shows one choice and opens the system menu of all of them. Sends `.valueChanged`.
public final class CanonMenuCell: UIControl {
    private let titles: [String]
    private let placeholder: String
    private let button = CanonButton("", systemImage: "chevron.up.chevron.down", kind: .cell)

    /// `nil` shows the placeholder: a value set elsewhere that matches no choice.
    public var selectedIndex: Int? {
        didSet { if selectedIndex != oldValue { show() } }
    }

    public init(_ titles: [String], selected: Int? = nil, placeholder: String = "\u{2014}") {
        self.titles = titles
        self.placeholder = placeholder
        selectedIndex = selected
        super.init(frame: .zero)
        button.configuration?.imagePlacement = .trailing
        button.showsMenuAsPrimaryAction = true
        pin(button)
        heightAnchor.constraint(greaterThanOrEqualToConstant: DelphiMetrics.controlHeight).isActive = true
        show()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var isEnabled: Bool {
        didSet { button.isEnabled = isEnabled }
    }

    public override var accessibilityLabel: String? {
        get { button.accessibilityLabel }
        set { button.accessibilityLabel = newValue }
    }

    private func show() {
        let title = selectedIndex.flatMap { titles.indices.contains($0) ? titles[$0] : nil }
        button.text = title ?? placeholder
        button.accessibilityValue = title
        button.menu = UIMenu(children: titles.enumerated().map { index, title in
            UIAction(title: title, state: index == selectedIndex ? .on : .off) { [weak self] _ in
                guard let self, selectedIndex != index else { return }
                selectedIndex = index
                sendActions(for: .valueChanged)
            }
        })
    }
}

public final class CanonFromTo: UIControl {
    public let from: CanonMenuCell
    public let to: CanonMenuCell

    public init(_ titles: [String], targets: [String]? = nil, from: Int? = nil, to: Int? = nil) {
        self.from = CanonMenuCell(titles, selected: from)
        self.to = CanonMenuCell(targets ?? titles, selected: to)
        super.init(frame: .zero)
        backgroundColor = .delphiBorder

        let symbol = UIImageView(image: UIImage(systemName: "arrow.forward", withConfiguration: UIImage.SymbolConfiguration(textStyle: .footnote, scale: .medium)))
        symbol.tintColor = .delphiMutedForeground
        symbol.isAccessibilityElement = false
        symbol.translatesAutoresizingMaskIntoConstraints = false
        // bare image view shrinks
        let arrow = UIView()
        arrow.backgroundColor = .delphiCard
        arrow.addSubview(symbol)
        NSLayoutConstraint.activate([
            symbol.centerXAnchor.constraint(equalTo: arrow.centerXAnchor),
            symbol.centerYAnchor.constraint(equalTo: arrow.centerYAnchor),
            arrow.widthAnchor.constraint(equalToConstant: DelphiMetrics.controlHeight),
        ])

        let stack = UIStackView(arrangedSubviews: [self.from, arrow, self.to])
        stack.spacing = DelphiMetrics.hairline
        pin(stack)
        self.from.widthAnchor.constraint(equalTo: self.to.widthAnchor).isActive = true
        for cell in [self.from, self.to] {
            cell.onChange { [unowned self] _ in sendActions(for: .valueChanged) }
        }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var isEnabled: Bool {
        didSet { [from, to].forEach { $0.isEnabled = isEnabled } }
    }
}
