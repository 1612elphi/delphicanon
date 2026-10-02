import DelphiCore
import UIKit

/// The checks drawn behind transparent pixels in the app's tones: card and muted squares of `side` points, a card square first.
public nonisolated enum CanonChecks {
    public static let side: CGFloat = 8

    /// The tones in the light appearance, for pictures that keep dark art visible in both appearances and for drawing
    /// off the main actor.
    public static let paper: (light: CGColor, dark: CGColor) = {
        let traits = UITraitCollection(userInterfaceStyle: .light)
        let tone = { (name: String) in UIColor(named: name, in: .module, compatibleWith: nil)?.resolvedColor(with: traits).cgColor ?? CGColor(gray: 1, alpha: 1) }
        return (tone("defaultCard"), tone("defaultMuted"))
    }()

    @MainActor private static var cache: [String: UIColor] = [:]

    /// The pattern resolved for `traits`, for a layer; set it again on a style change.
    @MainActor public static func colour(for traits: UITraitCollection) -> UIColor {
        let tones = (light: UIColor.delphiCard.resolvedColor(with: traits).cgColor, dark: UIColor.delphiMuted.resolvedColor(with: traits).cgColor)
        let key = "\(tones.light)|\(tones.dark)"
        if let colour = cache[key] { return colour }
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        let tile = UIGraphicsImageRenderer(size: CGSize(width: side * 2, height: side * 2), format: format).image { context in
            Checkerboard.fill(context.cgContext, CGRect(x: 0, y: 0, width: side * 2, height: side * 2), square: side, tones: tones)
        }
        let colour = UIColor(patternImage: tile)
        cache[key] = colour
        return colour
    }

    /// The pattern following the appearance, for a view's background.
    @MainActor public static let pattern = UIColor { colour(for: $0) }
}
