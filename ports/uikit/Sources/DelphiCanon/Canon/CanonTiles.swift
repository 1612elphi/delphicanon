import UIKit

/// Read-only values as a hairline grid of tiles: label over value. As many columns as fit; a short last row stretches its last tile.
/// An item that carries a `level` gets a bar along the tile's bottom edge.
public final class CanonTiles: UIView {
    public struct Item {
        public var label: String
        public var value: String
        /// Share of a level bar, 0...1. `nil` draws no bar.
        public var level: Double?

        public init(label: String, value: String, level: Double? = nil) {
            self.label = label
            self.value = value
            self.level = level
        }
    }

    /// Least width of a tile; the grid never goes below two columns.
    private static let tileWidth: CGFloat = 168

    private var rows: [Item]
    private var grid: CanonGrid?
    private var columns = 0
    private var labels: [(value: UILabel, bar: CanonBar?)] = []

    public init(_ rows: [Item]) {
        self.rows = rows
        super.init(frame: .zero)
        build(columns: 2)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        build(columns: max(2, Int(bounds.width / Self.tileWidth)))
    }

    /// New values for the same labels: the tiles update in place. A different count rebuilds.
    public func show(_ items: [Item]) {
        let sameShape = items.count == rows.count && items.map(\.label) == rows.map(\.label)
            && items.map { $0.level == nil } == rows.map { $0.level == nil }
        guard sameShape else {
            rows = items
            columns = 0
            build(columns: max(2, Int(bounds.width / Self.tileWidth)))
            return
        }
        rows = items
        for (item, tile) in zip(items, labels) {
            if tile.value.text != item.value { tile.value.text = item.value }
            tile.value.superview?.superview?.accessibilityValue = item.value
            if let level = item.level { tile.bar?.share = CGFloat(level) }
        }
    }

    private func build(columns: Int) {
        guard columns != self.columns else { return }
        self.columns = columns
        grid?.removeFromSuperview()
        labels = []
        let grid = CanonGrid(columns: columns, rows.map { tile($0) })
        pin(grid)
        self.grid = grid
    }

    private func tile(_ row: Item) -> UIView {
        let label = UILabel.canon(row.label, .caption2, weight: .semibold, colour: .delphiMutedForeground)
        let value = UILabel.canon(row.value, .footnote)
        value.font = .delphiMono(13, relativeTo: .footnote)
        value.lineBreakMode = .byTruncatingMiddle
        value.adjustsFontSizeToFitWidth = true
        value.minimumScaleFactor = 0.8
        for label in [label, value] { label.numberOfLines = 1 }

        let text = UIStackView(arrangedSubviews: [label, value])
        text.axis = .vertical
        text.spacing = 2
        let tile = UIView()
        tile.backgroundColor = .delphiCard
        tile.pin(text, insets: NSDirectionalEdgeInsets(top: 10, leading: DelphiMetrics.panelPadding, bottom: 12, trailing: 12))
        tile.isAccessibilityElement = true
        tile.accessibilityLabel = row.label
        tile.accessibilityValue = row.value

        guard let level = row.level else {
            labels.append((value, nil))
            return tile
        }
        let bar = CanonBar()
        labels.append((value, bar))
        bar.share = CGFloat(level)
        bar.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: tile.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: tile.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: tile.bottomAnchor),
            bar.heightAnchor.constraint(equalToConstant: 4),
        ])
        return tile
    }
}
