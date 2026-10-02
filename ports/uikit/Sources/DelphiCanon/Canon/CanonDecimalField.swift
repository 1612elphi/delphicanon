import UIKit

/// A decimal number with step buttons and a unit: seconds to three decimals in tenths by default. Sends `.valueChanged`.
public final class CanonDecimalField: UIControl, UITextFieldDelegate {
    public private(set) var value = 0.0
    private var range = 0.0...0.0
    private let field = UITextField()
    private let typing = CanonDebounce()
    private let step: Double
    private let decimals: Int

    /// - Parameter signed: gives the keyboard a minus key; the decimal pad has none.
    public init(unit: String = "s", step: Double = 0.1, decimals: Int = 3, signed: Bool = false) {
        self.step = step
        self.decimals = decimals
        super.init(frame: .zero)
        field.font = .delphiMono(17, weight: .semibold, digitsOnly: true)
        field.adjustsFontForContentSizeCategory = true
        field.textColor = .delphiForeground
        field.tintColor = .delphiPrimary
        field.textAlignment = .right
        field.keyboardType = signed ? .numbersAndPunctuation : .decimalPad
        field.delegate = self
        field.widthAnchor.constraint(greaterThanOrEqualToConstant: 72).isActive = true
        field.addAction(UIAction { [unowned self] _ in
            typing.after(0.6) { [weak self] in self?.commit() }
        }, for: .editingChanged)

        let unit = UILabel.canon(unit, .caption1, colour: .delphiMutedForeground)
        unit.setContentHuggingPriority(.required, for: .horizontal)
        let middle = UIStackView(arrangedSubviews: [field, unit])
        middle.spacing = 4
        middle.alignment = .firstBaseline
        pin(CanonStepper(centre: middle, field: field) { [unowned self] direction in set(value + Double(direction) * self.step) })
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func show(_ value: Double, range: ClosedRange<Double>) {
        self.value = value
        self.range = range
        if !field.isEditing { field.text = format(value) }
    }

    private func set(_ seconds: Double) {
        let grain = pow(10, Double(decimals))
        let next = min(max((seconds * grain).rounded() / grain, range.lowerBound), range.upperBound)
        guard next != value else { return }
        value = next
        if !field.isEditing { field.text = format(value) }
        sendActions(for: .valueChanged)
    }

    private func commit() {
        typing.cancel()
        if let typed = Double((field.text ?? "").replacingOccurrences(of: ",", with: ".")) { set(typed) }
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        commit()
        field.text = format(value)
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private static let posix = Locale(identifier: "en_US_POSIX")

    private func format(_ seconds: Double) -> String {
        seconds.formatted(.number.precision(.fractionLength(0...decimals)).grouping(.never).locale(Self.posix))
    }
}

/// A tool's main number, large and centred over its unit, between step buttons that repeat while held. The tool reads
/// `field` on `.editingChanged` and sets its text; `onEndEditing` runs when typing ends.
public final class CanonBigNumberField: UIView, UITextFieldDelegate {
    public let field = UITextField()
    public let unit = UILabel.canon(nil, .footnote, weight: .bold, colour: .delphiMutedForeground)
    public var onEndEditing: (() -> Void)?

    /// - Parameter onStep: called with -1 or 1.
    public init(placeholder: String, unit: String? = nil, onStep: @escaping (Int) -> Void) {
        super.init(frame: .zero)
        field.placeholder = placeholder
        field.font = .delphiMono(36, weight: .bold, relativeTo: .largeTitle)
        field.adjustsFontForContentSizeCategory = true
        field.textColor = .delphiForeground
        field.tintColor = .delphiPrimary
        field.textAlignment = .center
        field.keyboardType = .decimalPad
        field.delegate = self
        self.unit.text = unit
        self.unit.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [field, self.unit])
        stack.axis = .vertical
        stack.spacing = 4
        pin(CanonStepper(centre: stack, field: field, insets: NSDirectionalEdgeInsets(top: 20, leading: 16, bottom: 16, trailing: 16), onStep: onStep))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        onEndEditing?()
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
