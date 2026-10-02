import Combine
import DelphiCore
import Foundation

@MainActor
public final class ColourFormatSettings: ObservableObject {
    public static let shared = ColourFormatSettings()

    @Published public var primaryFormat: ColourFormat {
        didSet { UserDefaults.standard.set(primaryFormat.rawValue, forKey: "colourPrimaryFormat") }
    }
    @Published public var secondaryFormat: ColourFormat {
        didSet { UserDefaults.standard.set(secondaryFormat.rawValue, forKey: "colourSecondaryFormat") }
    }

    public init() {
        let p = UserDefaults.standard.string(forKey: "colourPrimaryFormat") ?? "hex"
        let s = UserDefaults.standard.string(forKey: "colourSecondaryFormat") ?? "rgb"
        primaryFormat = ColourFormat(rawValue: p) ?? .hex
        secondaryFormat = ColourFormat(rawValue: s) ?? .rgb
    }
}
