import UIKit

/// A heading that opens a jump grid of its list's groups; the caller adds the action.
public final class CanonJumpHeading: UIControl {
    /// A `CanonHeading` with a chevron.
    public convenience init(_ text: String) {
        self.init(content: CanonHeading("\(text) ›"), label: text)
    }

    /// `content` drawn as the heading, read as `label`.
    public init(content: UIView, label: String) {
        super.init(frame: .zero)
        content.isUserInteractionEnabled = false
        pin(content)
        isAccessibilityElement = true
        accessibilityLabel = label
        accessibilityHint = String(localized: "Jumps to section")
        accessibilityTraits = [.header, .button]
        animatesPress()
        let resting = content.backgroundColor
        tracksHover { [unowned content] in content.backgroundColor = $0 ? .delphiAccentBG : resting }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// windows phone jump list
public final class CanonJumpGridViewController: UIViewController {
    private let sections: [(title: String, detail: String)]
    private let current: Int?
    private let onPick: (Int) -> Void
    private var tiles: [Tile] = []
    private let holder = UIView()
    private let scroll = UIScrollView()
    private var shownColumns = 0
    private var revealedCurrent = false

    public init(sections: [(title: String, detail: String)], current: Int?, onPick: @escaping (Int) -> Void) {
        self.sections = sections
        self.current = current
        self.onPick = onPick
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .delphiBackground.withAlphaComponent(0.94)
        let outside = UITapGestureRecognizer(target: self, action: #selector(tappedOutside))
        // tiles keep their taps
        outside.cancelsTouchesInView = false
        view.addGestureRecognizer(outside)
        tiles = sections.enumerated().map { index, section in
            let tile = Tile(section.title, detail: section.detail, lit: index == current)
            tile.addAction(UIAction { [unowned self] _ in
                onPick(index)
                dismiss(animated: true)
            }, for: .touchUpInside)
            return tile
        }
        scroll.alwaysBounceVertical = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        holder.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(holder)
        let padding = DelphiMetrics.panelPadding
        // side strip: safe area
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            holder.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: padding * 2),
            holder.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -padding),
            holder.centerXAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerXAnchor),
            holder.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -padding * 2).withPriority(.defaultHigh),
            holder.widthAnchor.constraint(lessThanOrEqualToConstant: 640),
        ])
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let columns = view.bounds.width >= 560 ? 3 : 2
        guard columns != shownColumns else { return }
        shownColumns = columns
        holder.subviews.forEach { $0.removeFromSuperview() }
        holder.pin(CanonGrid(columns: columns, boxed: true, tiles))
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !revealedCurrent, let current, tiles.indices.contains(current), scroll.bounds.height > 0 else { return }
        revealedCurrent = true
        scroll.layoutIfNeeded()
        let tile = tiles[current].convert(tiles[current].bounds, to: scroll)
        guard tile.maxY > scroll.bounds.height else { return }
        scroll.contentOffset.y = max(0, min(tile.midY - scroll.bounds.height / 2, scroll.contentSize.height - scroll.bounds.height))
    }

    /// long lists open there
    private var staggerOrigin: Int { tiles.count > 30 ? current ?? 0 : 0 }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        for (index, tile) in tiles.enumerated() {
            tile.alpha = 0
            tile.transform = CGAffineTransform(scaleX: 0.8, y: 0.8).rotated(by: -0.05)
            UIView.animate(withDuration: 0.45, delay: 0.03 * Double(min(abs(index - staggerOrigin), 24)), usingSpringWithDamping: 0.7, initialSpringVelocity: 0) {
                tile.alpha = 1
                tile.transform = .identity
            }
        }
    }

    @objc private func tappedOutside(_ tap: UITapGestureRecognizer) {
        let hit = view.hitTest(tap.location(in: view), with: nil)
        guard !tiles.contains(where: { hit?.isDescendant(of: $0) == true }) else { return }
        dismiss(animated: true)
    }

    private final class Tile: UIControl {
        public init(_ title: String, detail: String, lit: Bool) {
            super.init(frame: .zero)
            backgroundColor = lit ? .delphiPrimary : .delphiCard
            let name = UILabel.canon(title, .title3, weight: .bold, colour: lit ? .delphiPrimaryForeground : .delphiForeground)
            name.numberOfLines = 2
            let count = UILabel.canon(detail, .caption1, colour: lit ? .delphiPrimaryForeground : .delphiMutedForeground)
            let text = UIStackView(arrangedSubviews: [name, count])
            text.axis = .vertical
            text.spacing = 2
            text.isUserInteractionEnabled = false
            pin(text, insets: NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14))
            heightAnchor.constraint(greaterThanOrEqualToConstant: 84).isActive = true
            setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
            isAccessibilityElement = true
            accessibilityLabel = title
            accessibilityValue = detail
            accessibilityTraits = lit ? [.button, .selected] : .button
            animatesPress()
            if !lit { tracksHover { [unowned self] in backgroundColor = $0 ? .delphiAccentBG : .delphiCard } }
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}

extension CanonJumpGridViewController {
    /// Presents the grid from `host`, lit at the last of `headings` at or above the top of their scroll view;
    /// a pick scrolls its heading to the top.
    public static func present(_ sections: [(title: String, detail: String)], headings: [UIView], from host: UIViewController?) {
        guard let scrollView = headings.first?.enclosingScrollView else { return }
        let top = scrollView.contentOffset.y + scrollView.adjustedContentInset.top + 1
        let current = headings.lastIndex { $0.convert($0.bounds, to: scrollView).minY <= top } ?? 0
        host?.present(CanonJumpGridViewController(sections: sections, current: current) { index in
            if headings.indices.contains(index) { scroll(to: headings[index]) }
        }, animated: true)
    }

    /// Scrolls `heading` to the top of its scroll view, or as far as the content allows.
    public static func scroll(to heading: UIView) {
        guard let scrollView = heading.enclosingScrollView else { return }
        scroll(scrollView, toTop: heading.convert(heading.bounds, to: scrollView).minY)
    }

    /// Scrolls content `y` to the top of `scrollView`, or as far as the content allows.
    public static func scroll(_ scrollView: UIScrollView, toTop y: CGFloat) {
        let inset = scrollView.adjustedContentInset
        let lowest = scrollView.contentSize.height - scrollView.bounds.height + inset.bottom
        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: max(-inset.top, min(y - inset.top, lowest))), animated: true)
    }
}

extension UIView {
    public var enclosingScrollView: UIScrollView? {
        sequence(first: superview) { $0?.superview }.lazy.compactMap { $0 as? UIScrollView }.first
    }
}

private extension NSLayoutConstraint {
    public func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}
