import UIKit

/// Multi-line text input in the canon style: monospaced, wrapping, a fixed height with its own scrolling,
/// and a placeholder. Sends `.valueChanged` for typed edits, not for a `text` set from code.
public final class CanonTextArea: UIControl, UITextViewDelegate {
    private let textView = UITextView()
    private let prompt = UILabel.canon(nil, .footnote, colour: .delphiMutedForeground)
    private var keyboardShown: NSObjectProtocol?

    public var text: String {
        get { textView.text }
        set {
            guard newValue != textView.text else { return }
            textView.text = newValue
            prompt.isHidden = !newValue.isEmpty
        }
    }

    /// True while the keyboard is up for this area: a model echo must not replace the text being typed.
    public var isEditing: Bool { textView.isFirstResponder }

    public init(placeholder: String, height: CGFloat = 200) {
        super.init(frame: .zero)
        backgroundColor = .delphiMuted
        textView.font = .delphiMono(13, relativeTo: .footnote)
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = .delphiForeground
        textView.tintColor = .delphiPrimary
        textView.backgroundColor = .clear
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        pin(textView)

        prompt.text = placeholder
        prompt.font = textView.font
        prompt.isUserInteractionEnabled = false
        prompt.translatesAutoresizingMaskIntoConstraints = false
        addSubview(prompt)
        NSLayoutConstraint.activate([
            prompt.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            prompt.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            prompt.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
            heightAnchor.constraint(equalToConstant: height),
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var accessibilityLabel: String? {
        get { textView.accessibilityLabel }
        set { textView.accessibilityLabel = newValue }
    }

    // keyboard avoidance skips UITextView
    public func textViewDidBeginEditing(_ textView: UITextView) {
        keyboardShown = NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.revealInPage() }
        }
        DispatchQueue.main.async { self.revealInPage() }
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        keyboardShown.map(NotificationCenter.default.removeObserver)
        keyboardShown = nil
    }

    private func revealInPage() {
        guard let page = sequence(first: superview, next: { $0?.superview }).lazy.compactMap({ $0 as? UIScrollView }).first else { return }
        page.scrollRectToVisible(convert(bounds, to: page).insetBy(dx: 0, dy: -12), animated: true)
    }

    public func textViewDidChange(_ textView: UITextView) {
        prompt.isHidden = !textView.text.isEmpty
        sendActions(for: .valueChanged)
    }
}
