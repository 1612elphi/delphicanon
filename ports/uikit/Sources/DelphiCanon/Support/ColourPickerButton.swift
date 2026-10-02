import SwiftUI
import UIKit

// MARK: - Presenter

public enum ColourPickerPresenter {
    /// Present UIColorPickerViewController from the topmost view controller.
    public static func present(
        initialColour: Color,
        supportsAlpha: Bool = false,
        onChange: @escaping (Color) -> Void
    ) {
        let picker = UIColorPickerViewController()
        picker.selectedColor = UIColor(initialColour)
        picker.supportsAlpha = supportsAlpha

        let delegate = Delegate(onChange: onChange)
        picker.delegate = delegate
        // Retain delegate for the picker's lifetime
        objc_setAssociatedObject(picker, "colourPickerDelegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        var presenter = root
        while let presented = presenter.presentedViewController { presenter = presented }
        presenter.present(picker, animated: true)
    }

    private final class Delegate: NSObject, UIColorPickerViewControllerDelegate {
        public let onChange: (Color) -> Void

        public init(onChange: @escaping (Color) -> Void) {
            self.onChange = onChange
        }

        public func colorPickerViewController(
            _ viewController: UIColorPickerViewController,
            didSelect color: UIColor,
            continuously: Bool
        ) {
            onChange(Color(uiColor: color))
        }
    }
}

extension Color {
    public func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(
            format: "%02X%02X%02X",
            Int(round(r * 255)),
            Int(round(g * 255)),
            Int(round(b * 255))
        )
    }
}
