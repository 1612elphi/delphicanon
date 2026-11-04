import AppKit

public enum DelphiMetrics {
    public static let hairline: CGFloat = 1
    public static let frame: CGFloat = 2
    public static let controlHeight: CGFloat = 32
    public static let rowHeight: CGFloat = 44
    public static let barHeight: CGFloat = 52
    public static let panelPadding: CGFloat = 16
    public static let panelSpacing: CGFloat = 12
}

// values match web app.scss
extension NSColor {
    public static let delphiBackground = oklch((0.97, 0.02, 90), dark: (0.18, 0.03, 145))
    public static let delphiForeground = oklch((0.25, 0.05, 140), dark: (0.92, 0.025, 90))
    public static let delphiCard = oklch((0.98, 0.015, 90), dark: (0.22, 0.035, 145))
    public static let delphiMuted = oklch((0.93, 0.02, 90), dark: (0.25, 0.03, 145))
    public static let delphiMutedForeground = oklch((0.5, 0.04, 140), dark: (0.65, 0.04, 100))
    public static let delphiPrimary = oklch((0.45, 0.12, 145), dark: (0.75, 0.1, 95))
    public static let delphiPrimaryForeground = oklch((0.97, 0.02, 90), dark: (0.2, 0.04, 145))
    public static let delphiAccentBG = oklch((0.91, 0.04, 95), dark: (0.28, 0.04, 145))
    public static let delphiDestructive = oklch((0.55, 0.2, 25), dark: (0.6, 0.18, 25))
    public static let delphiBorder = oklch((0.88, 0.03, 95), dark: (0.3, 0.04, 145))

    private static func oklch(_ light: (Double, Double, Double), dark: (Double, Double, Double)) -> NSColor {
        NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(oklch: isDark ? dark : light)
        }
    }

    // matrices: bottosson.github.io/posts/oklab
    public convenience init(oklch: (Double, Double, Double)) {
        let (lightness, chroma, hueDegrees) = oklch
        let hue = hueDegrees * .pi / 180
        let a = chroma * cos(hue)
        let b = chroma * sin(hue)
        let l_ = lightness + 0.3963377774 * a + 0.2158037573 * b
        let m_ = lightness - 0.1055613458 * a - 0.0638541728 * b
        let s_ = lightness - 0.0894841775 * a - 1.2914855480 * b
        let l = l_ * l_ * l_
        let m = m_ * m_ * m_
        let s = s_ * s_ * s_
        let red = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
        let green = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
        let blue = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
        func gamma(_ x: Double) -> CGFloat {
            let c = min(max(x, 0), 1)
            return CGFloat(c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1 / 2.4) - 0.055)
        }
        self.init(srgbRed: gamma(red), green: gamma(green), blue: gamma(blue), alpha: 1)
    }
}

extension NSFont {
    public static let delphiFamily = "iA Writer Quattro V"

    private static var delphiCache: [String: NSFont] = [:]

    // host registers the face
    public static func delphi(_ size: CGFloat = 13, weight: Weight = .regular) -> NSFont {
        let key = "\(size)|\(weight.rawValue)"
        if let cached = delphiCache[key] { return cached }
        let descriptor = NSFontDescriptor(fontAttributes: [
            .family: delphiFamily,
            .traits: [NSFontDescriptor.TraitKey.weight: weight.rawValue],
        ])
        let font = NSFont(descriptor: descriptor, size: size) ?? .systemFont(ofSize: size, weight: weight)
        delphiCache[key] = font
        return font
    }

    public static let delphiBody = delphi()
    public static let delphiCaption = delphi(11)
    public static let delphiHeading = delphi(15, weight: .semibold)

    public static func delphiMono(_ size: CGFloat = 12, weight: Weight = .regular) -> NSFont {
        .monospacedSystemFont(ofSize: size, weight: weight)
    }
}
