import UIKit
import UniformTypeIdentifiers

/// Pages to scale in a sideways row, numbered, with an optional name under each: drag to reorder, drop files in,
/// a long-press menu, a tap that lights a page, and sheets stacked behind a page that stands for several.
public final class CanonPageStrip: UIView, CanonCanvasContent, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,
    UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    /// pdf points
    public struct Page: Equatable {
        /// nil: opened pdf page
        public let id: UUID?
        public let size: CGSize
        public let area: CGRect
        public let placement: CGRect
        public let picture: UIImage?
        public let name: String?
        /// sheets behind
        public let depth: Int
        /// clockwise degrees, picture only
        public let turn: Int

        /// `area` and `placement` default to the whole page.
        public init(id: UUID? = nil, size: CGSize, area: CGRect? = nil, placement: CGRect? = nil, picture: UIImage?,
             name: String? = nil, depth: Int = 0, turn: Int = 0) {
            let whole = CGRect(origin: .zero, size: size)
            (self.id, self.size, self.area, self.placement) = (id, size, area ?? whole, placement ?? whole)
            (self.picture, self.name, self.depth, self.turn) = (picture, name, depth, turn)
        }
    }

    public static let height: CGFloat = 196
    private static let caption: CGFloat = 34
    private static let sheetOffset: CGFloat = 4

    public var canvasTopInset: CGFloat = 0 {
        didSet { if canvasTopInset != oldValue { layout.invalidateLayout(); setNeedsLayout() } }
    }
    public var reorders = false {
        didSet { collection.dragInteractionEnabled = reorders }
    }
    public var onMove: ((Int, Int) -> Void)?
    public var onDrop: ((Int, [NSItemProvider]) -> Void)?
    public var menu: ((Int) -> UIMenu?)?
    public var onSelect: ((Int) -> Void)?
    /// accepted from other apps
    public var dropTypes: [UTType] = [.image]
    /// lit page
    public var selected: Int? {
        didSet { if selected != oldValue { relight() } }
    }

    private var pages: [Page] = []
    private let layout = UICollectionViewFlowLayout()
    private lazy var collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
    private let empty: UILabel

    public init(empty text: String = String(localized: "Pages")) {
        empty = .canon(text, .subheadline, weight: .semibold, colour: .delphiMutedForeground)
        super.init(frame: .zero)
        backgroundColor = .delphiMuted
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 14
        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.alwaysBounceHorizontal = true
        collection.contentInsetAdjustmentBehavior = .never
        collection.register(Cell.self, forCellWithReuseIdentifier: "page")
        collection.dataSource = self
        collection.delegate = self
        collection.dragDelegate = self
        collection.dropDelegate = self
        collection.reorderingCadence = .fast
        addSubview(collection)
        empty.textAlignment = .center
        addSubview(empty)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let area = bounds.inset(by: UIEdgeInsets(top: max(canvasTopInset, safeAreaInsets.top), left: safeAreaInsets.left, bottom: 0, right: safeAreaInsets.right))
        if collection.frame != area {
            collection.frame = area
            layout.invalidateLayout()
        }
        empty.frame = area
    }

    public func show(_ pages: [Page]) {
        empty.isHidden = !pages.isEmpty
        guard pages != self.pages else { return renumber() }
        // reconfigure keeps drags alive
        let changed = pages.count == self.pages.count ? pages.indices.filter { pages[$0] != self.pages[$0] } : nil
        let resized = changed?.contains { pages[$0].size != self.pages[$0].size || pages[$0].depth != self.pages[$0].depth } ?? true
        self.pages = pages
        guard let changed else { return collection.reloadData() }
        collection.reconfigureItems(at: changed.map { IndexPath(item: $0, section: 0) })
        if resized { layout.invalidateLayout() }
    }

    /// after a drag: numbers only
    private func renumber() {
        for case let cell as Cell in collection.visibleCells {
            if let path = collection.indexPath(for: cell) { cell.number = path.item + 1 }
        }
    }

    private func relight() {
        for case let cell as Cell in collection.visibleCells {
            cell.isLit = collection.indexPath(for: cell)?.item == selected
        }
    }

    // MARK: Data

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { pages.count }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "page", for: indexPath)
        if let cell = cell as? Cell {
            cell.page = pages[indexPath.item]
            cell.number = indexPath.item + 1
            cell.isLit = indexPath.item == selected
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        onSelect?(indexPath.item)
    }

    public func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 14, left: DelphiMetrics.panelPadding, bottom: 8, right: DelphiMetrics.panelPadding)
    }

    public func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = max(20, collectionView.bounds.height - 22 - Self.caption)
        let page = pages[indexPath.item].size
        let width = min(collectionView.bounds.width * 0.7, height * page.width / max(1, page.height))
        return CGSize(width: max(56, width), height: height + Self.caption)
    }

    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        guard let index = indexPaths.first?.item, let menu = menu?(index) else { return nil }
        return UIContextMenuConfiguration(actionProvider: { _ in menu })
    }

    // MARK: Drag and drop

    public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard reorders else { return [] }
        let item = UIDragItem(itemProvider: NSItemProvider())
        item.localObject = indexPath.item
        return [item]
    }

    public func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) as? Cell else { return nil }
        let parameters = UIDragPreviewParameters()
        parameters.visiblePath = UIBezierPath(rect: cell.paperFrame)
        return parameters
    }

    public func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        reorders && (session.localDragSession != nil || session.hasItemsConforming(toTypeIdentifiers: dropTypes.map(\.identifier)))
    }

    public func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard reorders else { return UICollectionViewDropProposal(operation: .forbidden) }
        return UICollectionViewDropProposal(operation: session.localDragSession != nil ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destination = coordinator.destinationIndexPath?.item ?? pages.count
        if let item = coordinator.items.first, let from = item.sourceIndexPath?.item {
            let to = min(destination, pages.count - 1)
            guard to != from else {
                coordinator.drop(item.dragItem, toItemAt: IndexPath(item: from, section: 0))
                return
            }
            let target = IndexPath(item: to, section: 0)
            collectionView.performBatchUpdates {
                pages.insert(pages.remove(at: from), at: to)
                collectionView.moveItem(at: IndexPath(item: from, section: 0), to: target)
            }
            coordinator.drop(item.dragItem, toItemAt: target)
            onMove?(from, to)
        } else {
            onDrop?(destination, coordinator.items.map(\.dragItem.itemProvider))
        }
    }

    // MARK: Cell

    private final class Cell: UICollectionViewCell {
        private let paper = Paper()
        private let sheets = (0..<3).map { _ in Sheet() }
        private let numberLabel = UILabel.canon(nil, .caption1, weight: .semibold)
        private let nameLabel = UILabel.canon(nil, .caption2, colour: .delphiMutedForeground)

        public var page: Page? {
            didSet {
                paper.page = page
                nameLabel.text = page?.name
                setNeedsLayout()
            }
        }

        public var number = 0 {
            didSet { numberLabel.text = "\(number)" }
        }

        public var isLit = false {
            didSet {
                paper.isLit = isLit
                numberLabel.textColor = isLit ? .delphiPrimary : .delphiForeground
            }
        }

        public var paperFrame: CGRect { paper.frame }

        public override init(frame: CGRect) {
            super.init(frame: frame)
            numberLabel.font = .delphiMono(12, weight: .semibold, relativeTo: .caption1)
            nameLabel.lineBreakMode = .byTruncatingMiddle
            (sheets.reversed() + [paper, numberLabel, nameLabel]).forEach(contentView.addSubview)
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        public override func layoutSubviews() {
            super.layoutSubviews()
            let height = bounds.height - CanonPageStrip.caption
            let depth = min(page?.depth ?? 0, sheets.count)
            let offset = CanonPageStrip.sheetOffset
            let room = CGFloat(depth) * offset
            let size = page?.size ?? CGSize(width: 1, height: 1.4)
            let scale = min((bounds.width - room) / max(1, size.width), (height - room) / max(1, size.height))
            let fitted = CGSize(width: size.width * scale, height: size.height * scale)
            paper.frame = CGRect(x: (bounds.width - fitted.width - room) / 2, y: height - fitted.height, width: fitted.width, height: fitted.height)
            for (index, sheet) in sheets.enumerated() {
                sheet.isHidden = index >= depth
                sheet.frame = paper.frame.offsetBy(dx: CGFloat(index + 1) * offset, dy: -CGFloat(index + 1) * offset)
            }
            numberLabel.frame = CGRect(x: 0, y: height + 4, width: bounds.width, height: 15)
            nameLabel.frame = CGRect(x: 0, y: height + 18, width: bounds.width, height: 14)
            numberLabel.textAlignment = nameLabel.text == nil ? .center : .natural
        }
    }

    private final class Sheet: UIView {
        public init() {
            super.init(frame: .zero)
            backgroundColor = .white
            layer.borderWidth = DelphiMetrics.hairline
            redrawsOnStyleChange(layout: true)
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        public override func layoutSubviews() {
            super.layoutSubviews()
            layer.borderColor = UIColor.delphiBorder.resolvedColor(with: traitCollection).cgColor
        }
    }

    private final class Paper: UIView {
        public var page: Page? {
            didSet { setNeedsDisplay() }
        }

        public var isLit = false {
            didSet { if isLit != oldValue { setNeedsDisplay() } }
        }

        public init() {
            super.init(frame: .zero)
            backgroundColor = .white
            contentMode = .redraw
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.12
            layer.shadowRadius = 3
            layer.shadowOffset = CGSize(width: 0, height: 1)
            redrawsOnStyleChange()
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        public override func layoutSubviews() {
            super.layoutSubviews()
            layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        }

        public override func draw(_ rect: CGRect) {
            guard let page, page.size.width > 0, let context = UIGraphicsGetCurrentContext() else { return }
            let scale = bounds.width / page.size.width
            // pdf origin: bottom left
            let flip: (CGRect) -> CGRect = {
                CGRect(x: $0.minX * scale, y: (page.size.height - $0.maxY) * scale, width: $0.width * scale, height: $0.height * scale)
            }
            let area = flip(page.area)
            if let picture = page.picture {
                let quarter = ((page.turn / 90) % 4 + 4) % 4
                let turned = quarter == 0 ? picture : picture.cgImage.map {
                    UIImage(cgImage: $0, scale: picture.scale, orientation: [.up, .right, .down, .left][quarter])
                } ?? picture
                context.saveGState()
                context.clip(to: area)
                turned.draw(in: flip(page.placement))
                context.restoreGState()
            }
            if area != bounds {
                context.setStrokeColor(UIColor.delphiPrimary.withAlphaComponent(0.4).cgColor)
                context.setLineWidth(DelphiMetrics.hairline)
                context.setLineDash(phase: 0, lengths: [3, 3])
                context.stroke(area)
            }
            let edge = isLit ? DelphiMetrics.frame : DelphiMetrics.hairline
            context.setStrokeColor((isLit ? UIColor.delphiPrimary : .delphiBorder).cgColor)
            context.setLineWidth(edge)
            context.setLineDash(phase: 0, lengths: [])
            context.stroke(bounds.insetBy(dx: edge / 2, dy: edge / 2))
        }
    }
}
