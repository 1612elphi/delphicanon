import CoreText
import SwiftUI

/// App-wide condensed font helper. Use `Font.delphi(...)` everywhere.
extension Font {
    public static func delphi(_ style: TextStyle, weight: Weight = .regular) -> Font {
        .system(style, design: .default, weight: weight).width(.condensed)
    }
}

extension UIFont {
    private static var delphiCache: [String: UIFont] = [:]

    public static func delphi(_ style: TextStyle, weight: Weight = .regular) -> UIFont {
        // buttons resolve fonts often
        let key = "\(style.rawValue)|\(weight.rawValue)|\(UIApplication.shared.preferredContentSizeCategory.rawValue)"
        if let cached = delphiCache[key] { return cached }
        let font = makeDelphi(style, weight: weight)
        delphiCache[key] = font
        return font
    }

    private static func makeDelphi(_ style: TextStyle, weight: Weight) -> UIFont {
        // scaled for dynamic type
        let base = UIFontDescriptor.preferredFontDescriptor(
            withTextStyle: style, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
        ).pointSize
        return UIFontMetrics(forTextStyle: style).scaledFont(for: .systemFont(ofSize: base, weight: weight, width: .condensed))
    }
}

extension UIFont {
    /// Monospaced system face at a fixed base size, scaled with Dynamic Type against `style`.
    public static func delphiMono(_ size: CGFloat, weight: Weight = .regular, relativeTo style: TextStyle = .body, digitsOnly: Bool = false) -> UIFont {
        let face: UIFont = digitsOnly ? .monospacedDigitSystemFont(ofSize: size, weight: weight) : .monospacedSystemFont(ofSize: size, weight: weight)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: face)
    }
}

extension NSAttributedString {
    public static func delphiKicker(_ text: String) -> NSAttributedString {
        NSAttributedString(
            string: text.uppercased(),
            attributes: [.font: UIFont.delphi(.caption1, weight: .semibold), .kern: 1.4]
        )
    }
}
