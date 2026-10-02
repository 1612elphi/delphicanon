import DelphiCore
import SwiftUI
import UIKit

/// A colour typed in any notation beside the system picker. Typed text is read 0.4 s after typing stops, and turns red
/// when it does not read. A picked colour goes to `onColour` at once.
public final class CanonColourNotationInput: UIStackView {
    /// A picked colour, and a typed one read by the default `parse`.
    public var onColour: ((DelphiColour) -> Void)?

    /// Reads typed text and uses it; false turns the text red. The default reads any notation with `ColourNotation` and
    /// passes a finite colour to `onColour`.
    public lazy var parse: (String) -> Bool = { [unowned self] typed in
        // nan traps rgb conversion
        guard let parsed = ColourNotation.parse(typed), parsed.r.isFinite, parsed.g.isFinite, parsed.b.isFinite else { return false }
        onColour?(parsed)
        return true
    }

    /// The colour the system picker opens on; the last shown colour by default.
    public lazy var pickerColour: () -> Color = { [unowned self] in Color(uiColor: shown.uiColor) }

    public let field = CanonTextCell(placeholder: "oklch(0.64 0.15 264)")
    public let pick = CanonButton("", systemImage: "eyedropper", kind: .cell)
    private let typing = CanonDebounce()
    private var shown = DelphiColour(r: 0, g: 0, b: 0)

    public init() {
        super.init(frame: .zero)
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.font = .delphiMono(15, relativeTo: .callout)
        field.accessibilityLabel = String(localized: "Any notation")
        pick.accessibilityLabel = String(localized: "Colour")
        [field, CanonRule(vertical: true), pick].forEach(addArrangedSubview)
        field.onChange { [unowned self] _ in
            typing.after(0.4) { [weak self] in self?.read() }
        }
        pick.addAction(UIAction { [unowned self] _ in
            ColourPickerPresenter.present(initialColour: pickerColour()) { [weak self] picked in
                self?.onColour?(DelphiColour.fromColor(picked))
            }
        }, for: .primaryActionTriggered)
    }

    @available(*, unavailable)
    public required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Shows `colour` as hex, unless it is being typed.
    public func show(_ colour: DelphiColour) {
        shown = colour
        show(text: colour.hex)
    }

    /// Shows `text`, unless the field is being typed in.
    public func show(text: String) {
        guard !field.isFirstResponder else { return }
        field.text = text
        field.textColor = .delphiForeground
    }

    /// Reads the typed text now instead of after the pause.
    public func commit() {
        typing.cancel()
        read()
    }

    private func read() {
        let typed = field.text ?? ""
        field.textColor = parse(typed) || typed.isEmpty ? .delphiForeground : .delphiDestructive
    }
}
