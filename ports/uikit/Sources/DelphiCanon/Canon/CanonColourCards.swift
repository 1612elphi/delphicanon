import Combine
import DelphiCore
import UIKit

/// A paint chip: the colour over its name and values. The swatch carries white and black type with their contrast
/// ratios; each value line copies itself on a tap.
public final class CanonColourCard: UIView {

    public enum Layout {
        /// Swatch above, name and three values below.
        case chip
        /// Swatch at the leading edge, name and one value beside it, for lists.
        case row
    }

    public var colour: DelphiColour {
        didSet { if colour != oldValue { refresh() } }
    }

    /// Shown instead of the nearest named colour.
    public var name: String? {
        didSet { refresh() }
    }

    private let swatch = UIView()
    private let nameLabel = UILabel.canon(nil, .headline, weight: .semibold)
    private let inks: [InkSample]
    private let values: [CanonValueLine]
    private var formats: AnyCancellable?

    public init(_ colour: DelphiColour, name: String? = nil, layout: Layout = .chip) {
        self.colour = colour
        self.name = name
        values = (0..<(layout == .chip ? 3 : 1)).map { _ in CanonValueLine() }
        inks = layout == .chip ? [InkSample(white: true), InkSample(white: false)] : []
        super.init(frame: .zero)
        backgroundColor = .delphiBorder
        nameLabel.numberOfLines = 1

        let lines = UIStackView(arrangedSubviews: values)
        lines.axis = .vertical
        lines.spacing = DelphiMetrics.hairline
        let title = UIView()
        title.backgroundColor = .delphiCard
        let info = UIStackView(arrangedSubviews: [title, lines])
        info.axis = .vertical
        info.spacing = DelphiMetrics.hairline

        let padding = DelphiMetrics.panelPadding
        switch layout {
        case .chip:
            title.pin(nameLabel, insets: NSDirectionalEdgeInsets(top: 12, leading: padding, bottom: 12, trailing: padding))
            let samples = UIStackView(arrangedSubviews: inks)
            samples.distribution = .equalSpacing
            samples.translatesAutoresizingMaskIntoConstraints = false
            swatch.addSubview(samples)
            NSLayoutConstraint.activate([
                samples.leadingAnchor.constraint(equalTo: swatch.leadingAnchor, constant: padding),
                swatch.trailingAnchor.constraint(equalTo: samples.trailingAnchor, constant: padding),
                swatch.bottomAnchor.constraint(equalTo: samples.bottomAnchor, constant: 12),
                swatch.heightAnchor.constraint(equalToConstant: 148),
            ])
            let stack = UIStackView(arrangedSubviews: [swatch, info])
            stack.axis = .vertical
            stack.spacing = DelphiMetrics.hairline
            let frame = DelphiMetrics.frame
            pin(stack, insets: NSDirectionalEdgeInsets(top: frame, leading: frame, bottom: frame, trailing: frame))
        case .row:
            title.pin(nameLabel, insets: NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 4, trailing: 12))
            swatch.widthAnchor.constraint(equalToConstant: 56).isActive = true
            let stack = UIStackView(arrangedSubviews: [swatch, info])
            stack.spacing = DelphiMetrics.hairline
            pin(stack)
            heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
        }

        let store = ColourFormatSettings.shared
        formats = store.$primaryFormat.combineLatest(store.$secondaryFormat)
            // init refresh covers it
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
        refresh()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func refresh() {
        swatch.backgroundColor = colour.uiColor
        nameLabel.text = name ?? ColourNames.closest(colour)
        let store = ColourFormatSettings.shared
        var shown: [ColourFormat] = [.hex]
        for format in [store.primaryFormat, store.secondaryFormat, .oklch, .rgb] where !shown.contains(format) {
            shown.append(format)
        }
        for (line, format) in zip(values, shown) {
            line.show(format.label, format.formatted(colour))
        }
        for sample in inks {
            let level: Double = sample.isWhite ? 1 : 0
            sample.show(ratio: DelphiColour.contrastRatio(colour, DelphiColour(r: level, g: level, b: level)))
        }
    }
}

extension DelphiColour {
    /// sRGB, clamped to 0...1 as `color` is.
    public var uiColor: UIColor {
        let rgb = SIMD3(r, g, b).clamped(lowerBound: .zero, upperBound: .one)
        return UIColor(red: rgb.x, green: rgb.y, blue: rgb.z, alpha: a)
    }

    /// Black type has more contrast on this colour than white.
    public var takesBlackInk: Bool {
        Self.contrastRatio(self, DelphiColour(r: 0, g: 0, b: 0)) >= Self.contrastRatio(self, DelphiColour(r: 1, g: 1, b: 1))
    }
}

/// "Aa" in white or black with its contrast ratio against the swatch under it.
private final class InkSample: UIStackView {
    public let isWhite: Bool
    private let specimen = UILabel.canon("Aa", .title2, weight: .semibold)
    private let ratio = UILabel.canon(nil, .caption2)

    public init(white: Bool) {
        isWhite = white
        super.init(frame: .zero)
        let ink: UIColor = white ? .white : .black
        specimen.textColor = ink
        ratio.textColor = ink
        ratio.font = .delphiMono(11, relativeTo: .caption2)
        addArrangedSubview(specimen)
        addArrangedSubview(ratio)
        axis = .vertical
        spacing = 0
        alignment = white ? .leading : .trailing
        accessibilityElementsHidden = true
    }

    @available(*, unavailable)
    public required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func show(ratio value: Double) {
        ratio.text = ContrastRatio.figure(value)
        alpha = value >= ContrastRatio.aa ? 1 : 0.45
    }
}

/// A name and a value in a flush cell; a tap copies the value. `show` with a nil value shows a dash and turns copying
/// off. `isLit` marks the chosen line of a list; `tint` colours the value character by character.
public final class CanonValueLine: UIControl {
    public enum Layout {
        /// The name in a column `labelWidth` wide, the value on one line beside it, shrinking to fit.
        case beside(labelWidth: CGFloat)
        /// The name above the value.
        case above
        /// The name as wide as it is, the value beside it wrapping by character.
        case wrapping
        /// A list index as the name; `wraps` breaks a long value by character instead of shrinking it.
        case numbered(wraps: Bool)
    }

    public var isLit = false {
        didSet {
            guard isLit != oldValue else { return }
            paintValue()
            paint()
        }
    }

    /// Colours characters by kind; nil sets the whole value in one colour.
    public var tint: ((Character) -> UIColor)?

    private let layout: Layout
    private let format = UILabel.canon(nil, .caption2, weight: .semibold, colour: .delphiMutedForeground)
    private let value = UILabel.canon(nil, .callout)
    private let glyph = UIImageView(image: UIImage(systemName: "doc.on.doc"))
    private var text = ""
    private var isHovering = false {
        didSet { paint() }
    }

    /// - Parameter labelWidth: fits the longest format name in the column.
    public convenience init(labelWidth: CGFloat = 48) {
        self.init(layout: .beside(labelWidth: labelWidth))
    }

    public init(layout: Layout) {
        self.layout = layout
        super.init(frame: .zero)
        value.font = .delphiMono(14, relativeTo: .callout)
        glyph.tintColor = .delphiMutedForeground
        glyph.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .caption2)
        glyph.setContentHuggingPriority(.required, for: .horizontal)
        glyph.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stack: UIStackView
        var inset: CGFloat = 0
        var height = DelphiMetrics.controlHeight
        switch layout {
        case .beside(let labelWidth):
            value.numberOfLines = 1
            value.adjustsFontSizeToFitWidth = true
            value.minimumScaleFactor = 0.7
            format.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
            stack = UIStackView(arrangedSubviews: [format, value, glyph])
            stack.spacing = 8
            stack.alignment = .center
        case .above:
            let text = UIStackView(arrangedSubviews: [format, value])
            text.axis = .vertical
            text.spacing = 2
            stack = UIStackView(arrangedSubviews: [text, glyph])
            stack.spacing = 12
            stack.alignment = .center
            inset = 10
            height = DelphiMetrics.rowHeight
        case .wrapping:
            format.setContentHuggingPriority(.required, for: .horizontal)
            format.setContentCompressionResistancePriority(.required, for: .horizontal)
            value.lineBreakMode = .byCharWrapping
            stack = UIStackView(arrangedSubviews: [format, value, glyph])
            stack.spacing = 12
            stack.alignment = .firstBaseline
            inset = 13
        case .numbered(let wraps):
            format.font = .delphiMono(11, weight: .semibold, relativeTo: .caption2)
            format.setContentHuggingPriority(.required, for: .horizontal)
            format.widthAnchor.constraint(greaterThanOrEqualToConstant: 26).isActive = true
            value.numberOfLines = wraps ? 0 : 1
            value.lineBreakMode = wraps ? .byCharWrapping : .byTruncatingTail
            value.adjustsFontSizeToFitWidth = !wraps
            value.minimumScaleFactor = 0.6
            stack = UIStackView(arrangedSubviews: [format, value, glyph])
            stack.spacing = 10
            stack.alignment = .center
            inset = wraps ? 10 : 0
            accessibilityHint = String(localized: "Copy")
        }
        stack.isUserInteractionEnabled = false
        let padding = DelphiMetrics.panelPadding
        pin(stack, insets: NSDirectionalEdgeInsets(top: inset, leading: padding, bottom: inset, trailing: padding))
        heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        isAccessibilityElement = true
        accessibilityTraits = .button
        animatesPress()
        tracksHover { [unowned self] in isHovering = $0 }
        addAction(UIAction { [unowned self] _ in CanonCopyFeedback.copy(text) }, for: .touchUpInside)
        paint()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var isEnabled: Bool {
        didSet {
            glyph.isHidden = !isEnabled
            paint()
        }
    }

    /// - Parameter fadeDelay: fades a changed value in after this many seconds; nil changes it at once.
    public func show(_ label: String, _ text: String?, fadeDelay: Double? = nil) {
        let shown = text ?? "\u{2014}"
        if format.text != label { format.text = label }
        let changed = shown != self.text
        if let fadeDelay, changed {
            let fade = CATransition()
            fade.type = .fade
            fade.duration = 0.25
            fade.beginTime = CACurrentMediaTime() + fadeDelay
            fade.fillMode = .backwards
            value.layer.add(fade, forKey: "fade")
        }
        self.text = shown
        if changed { paintValue() }
        if isEnabled != (text != nil) { isEnabled = text != nil }
        if case .numbered = layout {
            accessibilityLabel = shown
        } else {
            accessibilityLabel = label
            accessibilityValue = shown
        }
    }

    private func paintValue() {
        accessibilityTraits = isLit ? [.button, .selected] : .button
        guard let tint else {
            value.text = text
            value.textColor = isLit ? .delphiPrimary : .delphiForeground
            return
        }
        let font = value.font!
        value.attributedText = text.reduce(into: NSMutableAttributedString()) { out, character in
            out.append(NSAttributedString(string: String(character), attributes: [.font: font, .foregroundColor: tint(character)]))
        }
    }

    private func paint() {
        backgroundColor = isLit || isHovering && isEnabled ? .delphiAccentBG : .delphiCard
    }
}

/// A strip along the bottom of a colour picture: swatch, nearest name, the colour in the primary format; a tap copies
/// the value. With a `palette` it shows those colours as swatches instead, each copying its hex on a tap.
public final class CanonColourStrip: UIControl {
    public var colour: DelphiColour {
        didSet { if colour != oldValue { refresh() } }
    }

    public var palette: [DelphiColour] = [] {
        didSet {
            guard palette != oldValue else { return }
            // reuse swatches, live updates
            while paletteRow.arrangedSubviews.count < palette.count { paletteRow.addArrangedSubview(CanonSwatch()) }
            while paletteRow.arrangedSubviews.count > palette.count { paletteRow.arrangedSubviews.last?.removeFromSuperview() }
            for (swatch, colour) in zip(paletteRow.arrangedSubviews, palette) { (swatch as? CanonSwatch)?.colour = colour }
            single.isHidden = !palette.isEmpty
            paletteRow.isHidden = palette.isEmpty
            isAccessibilityElement = palette.isEmpty
        }
    }

    private let swatch = UIView()
    private let name = UILabel.canon(nil, .subheadline, weight: .semibold)
    private let value = UILabel.canon(nil, .footnote, colour: .delphiMutedForeground)
    private let single = UIStackView()
    private let paletteRow = UIStackView()
    private var formats: AnyCancellable?
    private var rowHeight: NSLayoutConstraint!
    private var textCentre: NSLayoutConstraint!

    /// Extra height below the row, for a strip that runs to a screen edge: the swatch and card grow, the text stays in the row.
    public var foot: CGFloat = 0 {
        didSet {
            guard foot != oldValue else { return }
            rowHeight.constant = DelphiMetrics.rowHeight + foot
            textCentre.constant = -foot / 2
        }
    }

    public init(_ colour: DelphiColour) {
        self.colour = colour
        super.init(frame: .zero)
        backgroundColor = .delphiBorder
        value.font = .delphiMono(13, relativeTo: .footnote)
        value.setContentCompressionResistancePriority(.required, for: .horizontal)
        value.setContentHuggingPriority(.required, for: .horizontal)
        for label in [name, value] { label.numberOfLines = 1 }
        swatch.widthAnchor.constraint(equalToConstant: 56).isActive = true
        let text = UIStackView(arrangedSubviews: [name, value])
        text.spacing = 12
        text.alignment = .firstBaseline
        let cell = UIView()
        cell.backgroundColor = .delphiCard
        text.translatesAutoresizingMaskIntoConstraints = false
        textCentre = text.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        cell.addSubview(text)
        NSLayoutConstraint.activate([
            text.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: DelphiMetrics.panelPadding),
            cell.trailingAnchor.constraint(equalTo: text.trailingAnchor, constant: DelphiMetrics.panelPadding),
            textCentre,
        ])
        [swatch, cell].forEach(single.addArrangedSubview)
        single.spacing = DelphiMetrics.hairline
        single.isUserInteractionEnabled = false
        paletteRow.spacing = DelphiMetrics.hairline
        paletteRow.distribution = .fillEqually
        paletteRow.isHidden = true
        let insets = NSDirectionalEdgeInsets(top: DelphiMetrics.hairline, leading: 0, bottom: 0, trailing: 0)
        pin(single, insets: insets)
        pin(paletteRow, insets: insets)
        rowHeight = heightAnchor.constraint(equalToConstant: DelphiMetrics.rowHeight)
        rowHeight.isActive = true
        isAccessibilityElement = true
        accessibilityTraits = .button
        addAction(UIAction { [unowned self] _ in copyValue() }, for: .touchUpInside)
        formats = ColourFormatSettings.shared.$primaryFormat
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
        refresh()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// `picture` over this strip. The strip runs to the bottom edge, its row above the safe area; over the shell's band it sits
    /// above the page fade instead.
    public func placed(under picture: UIView) -> UIView {
        StripViewer(picture: picture, strip: self)
    }

    private func refresh() {
        swatch.backgroundColor = colour.uiColor
        name.text = ColourNames.closest(colour)
        value.text = formattedValue
        accessibilityLabel = name.text
        accessibilityValue = formattedValue
    }

    private var formattedValue: String { ColourFormatSettings.shared.primaryFormat.formatted(colour) }

    private func copyValue() {
        guard palette.isEmpty else { return }
        CanonCopyFeedback.copy(formattedValue)
    }
}

/// One colour, its hex where it fits; a tap copies the hex. The swatch of a `CanonColourStrip` palette.
public final class CanonSwatch: UIControl {
    public var colour = DelphiColour(r: 0, g: 0, b: 0) {
        didSet {
            guard colour != oldValue else { return }
            backgroundColor = colour.uiColor
            hex.textColor = colour.takesBlackInk ? .black : .white
            hex.text = colour.hex
            accessibilityValue = colour.hex
            setNeedsLayout()
        }
    }

    public override var accessibilityLabel: String? {
        get { ColourNames.closest(colour) }
        set {}
    }

    private let hex = UILabel.canon(nil, .caption2)

    public init() {
        super.init(frame: .zero)
        hex.font = .delphiMono(11, relativeTo: .caption2)
        hex.numberOfLines = 1
        addSubview(hex)
        isAccessibilityElement = true
        accessibilityTraits = .button
        animatesPress()
        addAction(UIAction { [unowned self] _ in CanonCopyFeedback.copy(colour.hex) }, for: .touchUpInside)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        hex.sizeToFit()
        hex.center = CGPoint(x: bounds.midX, y: bounds.midY)
        hex.isHidden = hex.bounds.width + 8 > bounds.width
    }
}

private final class StripViewer: UIView {
    private let strip: CanonColourStrip
    private var aboveFade: NSLayoutConstraint!
    private var toEdge: NSLayoutConstraint!

    public init(picture: UIView, strip: CanonColourStrip) {
        self.strip = strip
        super.init(frame: .zero)
        for view in [picture, strip] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        let safe = safeAreaLayoutGuide
        aboveFade = safe.bottomAnchor.constraint(equalTo: strip.bottomAnchor)
        toEdge = bottomAnchor.constraint(equalTo: strip.bottomAnchor)
        NSLayoutConstraint.activate([
            picture.topAnchor.constraint(equalTo: topAnchor),
            picture.leadingAnchor.constraint(equalTo: leadingAnchor),
            picture.trailingAnchor.constraint(equalTo: trailingAnchor),
            picture.bottomAnchor.constraint(equalTo: strip.topAnchor),
            strip.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            strip.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            toEdge,
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        let below = safeAreaInsets.bottom
        // band covers the edge
        let band = below > 0 ? CanonHost.bandHeight(owningViewController, traitCollection) : nil
        let overBand = band != nil
        aboveFade.constant = band ?? 0
        NSLayoutConstraint.deactivate([overBand ? toEdge : aboveFade])
        NSLayoutConstraint.activate([overBand ? aboveFade : toEdge])
        strip.foot = overBand ? 0 : below
    }
}

/// A palette as swatches meeting at hairlines, under a heading. A tap widens a swatch to show its name and values;
/// a tap on the widened swatch copies its hex.
public final class CanonPaletteCard: UIView {
    private let heading: CanonHeading
    private let strip = PaletteStrip()

    public var colours: [DelphiColour] {
        get { strip.colours }
        set { strip.colours = newValue }
    }

    public var selected: Int? {
        get { strip.selected }
        set { strip.select(newValue, animated: false) }
    }

    public var onSelect: ((Int?) -> Void)? {
        get { strip.onSelect }
        set { strip.onSelect = newValue }
    }

    /// - Parameter picker: a choice between palettes, under the heading.
    /// - Parameter actions: flush cells in a bar under the swatches.
    public init(_ title: String, colours: [DelphiColour], height: CGFloat = 156, picker: CanonSegmented? = nil, actions: [CanonButton] = []) {
        heading = CanonHeading(title)
        super.init(frame: .zero)
        backgroundColor = .delphiBorder
        strip.colours = colours
        strip.heightAnchor.constraint(equalToConstant: height).isActive = true
        let stack = UIStackView(arrangedSubviews: [heading] + [picker].compactMap { $0 } + [strip])
        if !actions.isEmpty { stack.addArrangedSubview(CanonActionBar(actions)) }
        stack.axis = .vertical
        stack.spacing = DelphiMetrics.hairline
        let frame = DelphiMetrics.frame
        pin(stack, insets: NSDirectionalEdgeInsets(top: frame, leading: frame, bottom: frame, trailing: frame))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

private final class PaletteStrip: UIView {
    /// Width of the widened swatch against the others.
    public static let widened: CGFloat = 3
    /// Narrower swatches turn their hex on its side.
    public static let sidewaysBelow: CGFloat = 72

    public var colours: [DelphiColour] = [] {
        didSet {
            while swatches.count < colours.count {
                let swatch = PaletteSwatch()
                addSubview(swatch)
                swatches.append(swatch)
            }
            while swatches.count > colours.count { swatches.removeLast().removeFromSuperview() }
            for (swatch, colour) in zip(swatches, colours) { swatch.colour = colour }
            if let selected, selected >= colours.count { self.selected = nil }
            setNeedsLayout()
        }
    }

    public private(set) var selected: Int?
    public var onSelect: ((Int?) -> Void)?
    private var swatches: [PaletteSwatch] = []

    public init() {
        super.init(frame: .zero)
        backgroundColor = .delphiBorder
        clipsToBounds = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func select(_ index: Int?, animated: Bool) {
        guard index != selected else { return }
        selected = index
        for (offset, swatch) in swatches.enumerated() { swatch.isWide = offset == index }
        guard animated, !UIAccessibility.isReduceMotionEnabled else { return setNeedsLayout() }
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard !swatches.isEmpty else { return }
        let seams = DelphiMetrics.hairline * CGFloat(swatches.count - 1)
        let weights = swatches.indices.map { $0 == selected ? Self.widened : 1 }
        let unit = (bounds.width - seams) / weights.reduce(0, +)
        let flipped = effectiveUserInterfaceLayoutDirection == .rightToLeft
        var x: CGFloat = 0
        for (swatch, weight) in zip(swatches, weights) {
            let width = unit * weight
            swatch.frame = CGRect(x: flipped ? bounds.width - x - width : x, y: 0, width: width, height: bounds.height)
            x += width + DelphiMetrics.hairline
        }
    }

    @objc private func tapped(_ recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self)
        guard let index = swatches.firstIndex(where: { $0.frame.contains(location) }) else { return }
        if index == selected {
            swatches[index].copyHex()
        } else {
            UISelectionFeedbackGenerator().selectionChanged()
            select(index, animated: true)
            onSelect?(index)
        }
    }
}

private final class PaletteSwatch: UIView {
    public var colour = DelphiColour(r: 0, g: 0, b: 0) {
        didSet { if colour != oldValue { refresh() } }
    }

    public var isWide = false {
        didSet {
            guard isWide != oldValue else { return }
            // name scan when shown
            if isWide { name.text = ColourNames.closest(colour) }
            setNeedsLayout()
        }
    }

    public override var accessibilityLabel: String? {
        get { ColourNames.closest(colour) }
        set {}
    }

    private let hex = UILabel.canon(nil, .caption1)
    private let details = UILabel.canon(nil, .caption2)
    private let name = UILabel.canon(nil, .subheadline, weight: .semibold)

    public init() {
        super.init(frame: .zero)
        hex.font = .delphiMono(12, relativeTo: .caption1)
        details.font = .delphiMono(11, relativeTo: .caption2)
        for label in [hex, details, name] {
            label.numberOfLines = 1
            addSubview(label)
        }
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func refresh() {
        backgroundColor = colour.uiColor
        let ink: UIColor = colour.takesBlackInk ? .black : .white
        [hex, details, name].forEach { $0.textColor = ink }
        hex.text = colour.hex
        if isWide { name.text = ColourNames.closest(colour) }
        let store = ColourFormatSettings.shared
        details.text = ([store.primaryFormat, store.secondaryFormat].first { $0 != .hex } ?? .oklch).formatted(colour)
        accessibilityValue = colour.hex
        setNeedsLayout()
    }

    public func copyHex() {
        CanonCopyFeedback.copy(colour.hex)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let inset: CGFloat = 10
        let sideways = !isWide && bounds.width < PaletteStrip.sidewaysBelow
        name.alpha = isWide ? 1 : 0
        details.alpha = isWide ? 1 : 0
        hex.transform = .identity
        hex.sizeToFit()
        if sideways {
            hex.transform = CGAffineTransform(rotationAngle: -.pi / 2)
            hex.center = CGPoint(x: bounds.midX, y: bounds.maxY - inset - hex.bounds.width / 2)
        } else {
            hex.frame.origin = CGPoint(x: inset, y: bounds.maxY - inset - hex.bounds.height)
        }
        let width = max(bounds.width - inset * 2, 0)
        details.frame = CGRect(x: inset, y: hex.frame.minY - 16, width: width, height: 16)
        name.frame = CGRect(x: inset, y: details.frame.minY - 22, width: width, height: 22)
    }
}

/// Copies a tapped value with the success haptic and a `CanonToast` that shows it; the toast is the one confirmation.
@MainActor
public enum CanonCopyFeedback {
    public static func copy(_ text: String) {
        ClipboardService.copy(text)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        CanonToast.show(text)
    }
}
