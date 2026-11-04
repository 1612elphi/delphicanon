import AppKit

/// A colour as a swatch beside its hex; the swatch opens the system colour panel, the hex takes typing.
public final class CanonColourWell: CanonView {
    private let swatch = NSColorWell(style: .minimal)
    private let hex = CanonTextCell(placeholder: "000000", width: 0)
    private var handlers: [(CanonColourWell) -> Void] = []

    public var colour: NSColor {
        didSet { refresh() }
    }

    public var isEnabled = true {
        didSet {
            swatch.isEnabled = isEnabled
            hex.isEnabled = isEnabled
            alphaValue = isEnabled ? 1 : 0.4
        }
    }

    public init(_ label: String? = nil, colour: NSColor) {
        self.colour = colour
        super.init(fill: .delphiBorder)
        swatch.setAccessibilityLabel(label ?? String(localized: "Colour"))
        swatch.target = self
        swatch.action = #selector(picked)
        swatch.widthAnchor.constraint(equalToConstant: 56).isActive = true
        hex.font = .delphiMono(14)
        hex.setAccessibilityLabel(label ?? String(localized: "Colour"))
        hex.onEndEditing = { [unowned self] cell in
            guard let typed = Self.colour(hex: cell.stringValue) else { return refresh() }
            self.colour = typed
            handlers.forEach { $0(self) }
        }
        var cells: [NSView] = [swatch, hex]
        if let label {
            let title = CanonView(fill: .delphiCard)
            let text = NSTextField.canon(label)
            text.translatesAutoresizingMaskIntoConstraints = false
            title.addSubview(text)
            NSLayoutConstraint.activate([
                text.leadingAnchor.constraint(equalTo: title.leadingAnchor, constant: DelphiMetrics.panelPadding),
                title.trailingAnchor.constraint(greaterThanOrEqualTo: text.trailingAnchor, constant: 8),
                text.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            ])
            cells.insert(title, at: 0)
        }
        let row = CanonStack(cells, vertical: false)
        if cells.count == 3 { cells[0].widthAnchor.constraint(equalTo: cells[2].widthAnchor).isActive = true }
        pin(row)
        heightAnchor.constraint(equalToConstant: DelphiMetrics.rowHeight).isActive = true
        refresh()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @discardableResult
    public func onChange(_ handler: @escaping (CanonColourWell) -> Void) -> Self {
        handlers.append(handler)
        return self
    }

    private var notifyPending = false

    // throttle panel drag events
    @objc private func picked() {
        colour = swatch.color
        guard !notifyPending else { return }
        notifyPending = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else { return }
            notifyPending = false
            handlers.forEach { $0(self) }
        }
    }

    private func refresh() {
        swatch.color = colour
        if !hex.isEditing { hex.stringValue = Self.hex(colour) }
    }

    /// Six hex digits, upper case, no hash.
    public static func hex(_ colour: NSColor) -> String {
        let rgb = colour.usingColorSpace(.sRGB) ?? .black
        let byte = { (value: CGFloat) in Int((min(max(value, 0), 1) * 255).rounded()) }
        return String(format: "%02X%02X%02X", byte(rgb.redComponent), byte(rgb.greenComponent), byte(rgb.blueComponent))
    }

    static func colour(hex text: String) -> NSColor? {
        let digits = text.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard digits.count == 6, let value = Int(digits, radix: 16) else { return nil }
        return NSColor(srgbRed: CGFloat(value >> 16 & 255) / 255, green: CGFloat(value >> 8 & 255) / 255, blue: CGFloat(value & 255) / 255, alpha: 1)
    }
}
