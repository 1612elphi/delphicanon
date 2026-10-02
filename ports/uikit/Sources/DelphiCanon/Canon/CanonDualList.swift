import UIKit

public struct CanonDualItem: Hashable {
    public let id: String
    public let name: String
    public var caption: String?

    public init(id: String, name: String, caption: String? = nil) {
        self.id = id
        self.name = name
        self.caption = caption
    }
}

/// Two columns with one selection between them; the right column can be reordered.
public final class CanonDualList: UIView {

    public enum Side { case left, right }

    public var onMoveRight: (String) -> Void = { _ in }
    public var onMoveLeft: (String) -> Void = { _ in }
    /// Item id and a delta of -1 or 1.
    public var onReorder: (String, Int) -> Void = { _, _ in }

    public private(set) var selection: (side: Side, id: String)?
    private var left: [CanonDualItem] = []
    private var right: [CanonDualItem] = []
    private let leftRows = CanonRows()
    private let rightRows = CanonRows()
    private let show = CanonButton(String(localized: "Show"), kind: .cell)
    private let hide = CanonButton(String(localized: "Hide"), kind: .cell)
    private let up = CanonButton(String(localized: "Up"), kind: .cell)
    private let down = CanonButton(String(localized: "Down"), kind: .cell)

    public init(leftTitle: String, rightTitle: String, listHeight: CGFloat = 240) {
        super.init(frame: .zero)
        backgroundColor = .delphiBorder

        let columns = UIStackView(arrangedSubviews: [
            column(leftTitle, leftRows, height: listHeight),
            column(rightTitle, rightRows, height: listHeight),
        ])
        columns.spacing = DelphiMetrics.hairline
        columns.distribution = .fillEqually

        show.addAction(UIAction { [unowned self] _ in move(from: .left) }, for: .primaryActionTriggered)
        hide.addAction(UIAction { [unowned self] _ in move(from: .right) }, for: .primaryActionTriggered)
        up.addAction(UIAction { [unowned self] _ in reorder(-1) }, for: .primaryActionTriggered)
        down.addAction(UIAction { [unowned self] _ in reorder(1) }, for: .primaryActionTriggered)

        let stack = UIStackView(arrangedSubviews: [columns, CanonGrid([show, hide, up, down])])
        stack.axis = .vertical
        stack.spacing = DelphiMetrics.hairline
        pin(stack)
        reload()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func setItems(left: [CanonDualItem], right: [CanonDualItem]) {
        self.left = left
        self.right = right
        if let selection, !(selection.side == .left ? left : right).contains(where: { $0.id == selection.id }) {
            self.selection = nil
        }
        reload()
    }

    private func column(_ title: String, _ rows: CanonRows, height: CGFloat) -> UIView {
        let scroll = UIScrollView()
        scroll.backgroundColor = .delphiCard
        scroll.heightAnchor.constraint(equalToConstant: height).isActive = true
        rows.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(rows)
        NSLayoutConstraint.activate([
            rows.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            rows.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            rows.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor),
        ])
        let stack = UIStackView(arrangedSubviews: [CanonHeading(title), scroll])
        stack.axis = .vertical
        return stack
    }

    private func reload() {
        leftRows.setRows(left.map { cell($0, side: .left) })
        rightRows.setRows(right.map { cell($0, side: .right) })
        show.isEnabled = selection?.side == .left
        let index = selection?.side == .right ? right.firstIndex { $0.id == selection?.id } : nil
        hide.isEnabled = index != nil
        up.isEnabled = index.map { $0 > 0 } ?? false
        down.isEnabled = index.map { $0 < right.count - 1 } ?? false
    }

    private func cell(_ item: CanonDualItem, side: Side) -> UIView {
        let isSelected = selection?.side == side && selection?.id == item.id
        let ink: UIColor = isSelected ? .delphiPrimaryForeground : .delphiForeground
        let name = UILabel.canon(item.name, colour: ink)
        name.numberOfLines = 1
        let caption = UILabel.canon(item.caption, .footnote, colour: ink.withAlphaComponent(0.7))
        caption.setContentHuggingPriority(.required, for: .horizontal)
        caption.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [name, caption])
        stack.spacing = 8
        stack.isUserInteractionEnabled = false
        let control = UIControl()
        control.backgroundColor = isSelected ? .delphiPrimary : .delphiCard
        let padding = DelphiMetrics.panelPadding
        control.pin(stack, insets: NSDirectionalEdgeInsets(top: 0, leading: padding, bottom: 0, trailing: padding))
        control.heightAnchor.constraint(greaterThanOrEqualToConstant: DelphiMetrics.controlHeight).isActive = true
        control.isAccessibilityElement = true
        control.accessibilityLabel = [item.name, item.caption].compactMap { $0 }.joined(separator: ", ")
        control.accessibilityTraits = isSelected ? [.button, .selected] : .button
        control.animatesPress()
        if !isSelected {
            control.tracksHover { [unowned control] in control.backgroundColor = $0 ? .delphiAccentBG : .delphiCard }
        }
        control.addAction(UIAction { [unowned self] _ in
            selection = (side, item.id)
            reload()
        }, for: .touchUpInside)
        return control
    }

    private func move(from side: Side) {
        guard let selection, selection.side == side else { return }
        self.selection = (side == .left ? .right : .left, selection.id)
        (side == .left ? onMoveRight : onMoveLeft)(selection.id)
        reload()
    }

    private func reorder(_ delta: Int) {
        guard let selection, selection.side == .right else { return }
        onReorder(selection.id, delta)
    }
}
