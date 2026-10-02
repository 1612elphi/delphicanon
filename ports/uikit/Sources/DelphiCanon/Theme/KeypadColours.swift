import UIKit

// packages get no generated asset symbols
extension UIColor {
    static let mathBlue = keypad("mathBlue")
    static let mathClay = keypad("mathClay")
    static let mathCream = keypad("mathCream")
    static let mathGreen = keypad("mathGreen")
    static let mathUmber = keypad("mathUmber")
    static let mathYellow = keypad("mathYellow")

    private static func keypad(_ name: String) -> UIColor {
        UIColor(named: name, in: .module, compatibleWith: nil) ?? .magenta
    }
}
