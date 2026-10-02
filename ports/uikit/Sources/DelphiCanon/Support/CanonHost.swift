import UIKit

/// What the host app supplies to Canon. Set these once at launch; the defaults suit an app without workflows or a bottom band.
public enum CanonHost {
    /// Whether exports go to the host instead of the share sheet. Read inside observation tracking, so an observable source updates share buttons.
    public static var capturesFiles: () -> Bool = { false }
    /// Takes an export instead of the share sheet; returns true when taken.
    public static var captureExport: (_ data: Data, _ filename: String, _ source: UIView?) -> Bool = { _, _, _ in false }
    /// Height a bar floating over the bottom of `controller`'s page covers above the safe area, or nil when none does.
    public static var bandHeight: (_ controller: UIViewController?, _ traits: UITraitCollection) -> CGFloat? = { _, _ in nil }
}
