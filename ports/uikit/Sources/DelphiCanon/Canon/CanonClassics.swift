import Combine
import DelphiCore
import SwiftUI
import UIKit

/// Flush row of buttons divided by hairlines: a `CanonGrid` whose cells are `CanonButton`s.
public typealias CanonActionBar = CanonGrid

extension CanonRow {
    /// File name over a detail line, with a flush Clear cell. Fill it with `setText(title:detail:)`.
    public static func file(onClear: @escaping () -> Void) -> CanonRow {
        CanonRow("", detail: " ", form: .flush, control: CanonButton(String(localized: "Clear"), systemImage: "trash", kind: .cell, action: onClear))
    }
}

/// Framed preview: caption row, hairline, then the content flush beneath.
public final class CanonPreviewPanel: UIView {
    private let captionLabel = UILabel.canonHeading(nil)
    private let detailLabel = UILabel.canon(nil, .footnote, colour: .delphiMutedForeground)

    public var detail: String? {
        get { detailLabel.text }
        set { detailLabel.text = newValue }
    }

    public init(_ caption: String, detail: String? = nil, content: UIView) {
        super.init(frame: .zero)
        backgroundColor = .delphiBorder
        captionLabel.text = caption
        detailLabel.text = detail
        detailLabel.textAlignment = .right
        detailLabel.setContentHuggingPriority(.required, for: .horizontal)

        let labels = UIStackView(arrangedSubviews: [captionLabel, detailLabel])
        labels.spacing = 8
        let header = UIView()
        header.backgroundColor = .canonHeadingBackground
        let padding = DelphiMetrics.panelPadding
        header.pin(labels, insets: NSDirectionalEdgeInsets(top: 8, leading: padding, bottom: 8, trailing: padding))

        let stack = UIStackView(arrangedSubviews: [header, content])
        stack.axis = .vertical
        stack.spacing = DelphiMetrics.hairline
        let frame = DelphiMetrics.frame
        pin(stack, insets: NSDirectionalEdgeInsets(top: frame, leading: frame, bottom: frame, trailing: frame))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Swatch cell that opens the system picker, beside a hex field. Sends `.valueChanged`.
public final class CanonColourWell: UIControl, UITextFieldDelegate {
    private let swatch = UIControl()
    private let hex = UITextField()
    private let echo = UILabel.canon(nil, .caption2, colour: .delphiMutedForeground)
    private var formats: AnyCancellable?

    public var colour: UIColor {
        didSet { refresh() }
    }

    public init(_ label: String? = nil, colour: UIColor) {
        self.colour = colour
        super.init(frame: .zero)
        backgroundColor = .delphiBorder

        swatch.widthAnchor.constraint(equalToConstant: 56).isActive = true
        swatch.isAccessibilityElement = true
        swatch.accessibilityTraits = .button
        swatch.accessibilityLabel = label ?? String(localized: "Colour")
        swatch.animatesPress()
        swatch.addAction(UIAction { [unowned self] _ in
            ColourPickerPresenter.present(initialColour: Color(uiColor: self.colour)) { [weak self] picked in
                self?.colour = UIColor(picked)
                self?.sendActions(for: .valueChanged)
            }
        }, for: .touchUpInside)

        let mono = UIFont.delphiMono(16, relativeTo: .callout)
        let hash = UILabel.canon("#", colour: .delphiMutedForeground)
        hash.font = mono
        hash.setContentHuggingPriority(.required, for: .horizontal)
        hex.font = mono
        hex.adjustsFontForContentSizeCategory = true
        hex.textColor = .delphiForeground
        hex.tintColor = .delphiPrimary
        hex.placeholder = "000000"
        hex.autocapitalizationType = .none
        hex.autocorrectionType = .no
        hex.returnKeyType = .done
        hex.delegate = self
        let field = UIStackView(arrangedSubviews: [hash, hex])
        field.spacing = 3

        echo.font = .delphiMono(11, relativeTo: .caption2)
        echo.numberOfLines = 1

        let text = UIStackView(arrangedSubviews: [field, echo])
        text.axis = .vertical
        text.spacing = 1
        if let label {
            let title = UILabel.canon(label.uppercased(), .caption2, weight: .semibold, colour: .delphiMutedForeground)
            text.insertArrangedSubview(title, at: 0)
        }
        let cell = UIView()
        cell.backgroundColor = .delphiCard
        text.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(text)
        NSLayoutConstraint.activate([
            text.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 12),
            cell.trailingAnchor.constraint(equalTo: text.trailingAnchor, constant: 12),
            text.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            text.topAnchor.constraint(greaterThanOrEqualTo: cell.topAnchor, constant: 8),
        ])

        let stack = UIStackView(arrangedSubviews: [swatch, cell])
        stack.spacing = DelphiMetrics.hairline
        pin(stack)
        heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true

        // echo follows the settings
        formats = ColourFormatSettings.shared.$primaryFormat.sink { [weak self] format in self?.refresh(format) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: 220, height: UIView.noIntrinsicMetric)
    }

    private func refresh(_ format: ColourFormat? = nil) {
        let format = format ?? ColourFormatSettings.shared.primaryFormat
        swatch.backgroundColor = colour
        if !hex.isEditing { hex.text = Color(uiColor: colour).toHex() }
        echo.isHidden = format == .hex
        echo.text = format.formatted(DelphiColour.fromColor(Color(uiColor: colour)))
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        let cleaned = (hex.text ?? "").filter(\.isHexDigit)
        if cleaned.count == 6, let value = UInt32(cleaned, radix: 16) {
            colour = UIColor(
                red: CGFloat(value >> 16 & 0xFF) / 255,
                green: CGFloat(value >> 8 & 0xFF) / 255,
                blue: CGFloat(value & 0xFF) / 255,
                alpha: 1
            )
            sendActions(for: .valueChanged)
        }
        refresh()
    }
}

/// Monospaced, selectable code with a copy button. Lines do not wrap; the block scrolls sideways.
public final class CanonCodeBlock: UIView {
    private let textView = UITextView()
    // uitextview resets container width
    private let sideways = UIScrollView()
    private var width: NSLayoutConstraint!
    private let copy = UIButton(configuration: .plain())
    private let maxHeight: CGFloat?
    private var height: NSLayoutConstraint!
    private var isCopied = false
    private var isHovering = false {
        didSet { showCopied(isCopied) }
    }

    /// What the copy button copies in place of `code`, for a block that shows the code shortened.
    public var copyText: String?

    public var code: String {
        didSet {
            guard code != oldValue else { return }
            textView.text = code
            resize()
        }
    }

    /// - Parameter maxHeight: taller code scrolls inside the block, so only the visible lines are laid out.
    public init(_ code: String, language: String? = nil, maxHeight: CGFloat? = nil) {
        self.code = code
        self.maxHeight = maxHeight
        super.init(frame: .zero)
        backgroundColor = .delphiCard

        textView.text = code
        textView.font = .delphiMono(12, relativeTo: .caption1)
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = .delphiForeground
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.textContainer.lineFragmentPadding = 0
        textView.translatesAutoresizingMaskIntoConstraints = false
        sideways.showsHorizontalScrollIndicator = false
        sideways.addSubview(textView)
        width = textView.widthAnchor.constraint(equalToConstant: 0)
        width.priority = .defaultHigh
        height = sideways.heightAnchor.constraint(equalToConstant: 44)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: sideways.contentLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: sideways.contentLayoutGuide.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: sideways.contentLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: sideways.contentLayoutGuide.trailingAnchor),
            textView.heightAnchor.constraint(equalTo: sideways.frameLayoutGuide.heightAnchor),
            textView.widthAnchor.constraint(greaterThanOrEqualTo: sideways.frameLayoutGuide.widthAnchor),
            width, height,
        ])

        copy.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        copy.configuration?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(textStyle: .caption2)
        copy.accessibilityLabel = String(localized: "Copy code")
        copy.addAction(UIAction { [unowned self] _ in copyCode() }, for: .primaryActionTriggered)
        copy.setContentHuggingPriority(.required, for: .horizontal)
        copy.animatesPress()
        copy.tracksHover { [unowned self] in isHovering = $0 }
        showCopied(false)

        let title = UILabel.canonHeading(language?.uppercased())
        let bar = UIStackView(arrangedSubviews: [title, copy])
        bar.alignment = .center
        bar.isLayoutMarginsRelativeArrangement = true
        bar.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 0)
        let header = UIView()
        header.backgroundColor = language == nil ? .clear : .canonHeadingBackground
        header.pin(bar)

        let stack = UIStackView(arrangedSubviews: language == nil ? [sideways, header] : [header, sideways])
        stack.axis = .vertical
        pin(stack)
        resize()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: Self, _) in view.resize() }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // unwrapped monospace: arithmetic size
    private func resize() {
        guard let font = textView.font else { return }
        let lines = code.split(separator: "\n", omittingEmptySubsequences: false)
        let longest = lines.max { $0.utf16.count < $1.utf16.count } ?? ""
        let inset = textView.textContainerInset
        width.constant = (String(longest) as NSString).size(withAttributes: [.font: font]).width.rounded(.up) + inset.left + inset.right + 1
        let full = (CGFloat(max(lines.count, 1)) * font.lineHeight).rounded(.up) + inset.top + inset.bottom
        height.constant = min(full, maxHeight ?? full)
    }

    private func copyCode() {
        ClipboardService.copy(copyText ?? code)
        showCopied(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.showCopied(false) }
    }

    private func showCopied(_ copied: Bool) {
        isCopied = copied
        copy.configuration?.image = UIImage(systemName: copied ? "checkmark" : "doc.on.doc")
        copy.configuration?.baseForegroundColor = copied ? .systemGreen : isHovering ? .delphiForeground : .delphiMutedForeground
    }
}
