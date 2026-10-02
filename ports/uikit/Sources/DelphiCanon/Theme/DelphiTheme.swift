import Combine
import SwiftUI
import UIKit

/// A colour theme: any of the delphi colours, each with a light and a dark value. A colour a theme leaves out is the default one.
public nonisolated struct DelphiTheme: Sendable {
    public enum Role: String, CaseIterable, Sendable {
        case background = "Background"
        case card = "Card"
        case foreground = "Foreground"
        case mutedForeground = "MutedForeground"
        case muted = "Muted"
        case border = "Border"
        case primary = "Primary"
        case primaryForeground = "PrimaryForeground"
        case accentBG = "AccentBG"
        case secondaryForeground = "SecondaryForeground"
        case destructive = "Destructive"

        /// The role's name in `themes.json`: `mutedForeground`, `accentBG`.
        public var key: String { rawValue.prefix(1).lowercased() + rawValue.dropFirst() }
    }

    public let id: String
    public let name: String
    public let colours: [Role: UIColor]

    public func colour(_ role: Role) -> UIColor {
        colours[role] ?? Self.standard.colours[role] ?? .magenta
    }

    /// The asset catalog's `default…` colour sets.
    public static let standard = DelphiTheme(
        id: "default",
        name: "Delphi",
        colours: Dictionary(uniqueKeysWithValues: Role.allCases.compactMap { role in
            UIColor(named: "default" + role.rawValue, in: .module, compatibleWith: nil).map { (role, $0) }
        })
    )

    public static let all: [DelphiTheme] = {
        var themes = [standard] + library
        #if DEBUG
        themes.append(debugSlate)
        #endif
        return themes
    }()

    /// `Resources/themes.json`, exported from the Theme Lab artifact: every role, light and dark, as `#RRGGBB`.
    public static let library: [DelphiTheme] = {
        struct Entry: Decodable {
            public let id: String
            public let name: String
            public let colours: [String: [String: String]]
        }
        guard let url = Bundle.module.url(forResource: "themes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([Entry].self, from: data) else { return [] }
        return entries.map { entry in
            let colours = Role.allCases.compactMap { role -> (Role, UIColor)? in
                guard let values = entry.colours[role.key],
                      let light = values["light"].flatMap(hex), let dark = values["dark"].flatMap(hex) else { return nil }
                return (role, pair(light: light, dark: dark))
            }
            return DelphiTheme(id: entry.id, name: entry.name, colours: Dictionary(uniqueKeysWithValues: colours))
        }
    }()

    /// `#RRGGBB` as `0xRRGGBB`.
    public static func hex(_ string: String) -> UInt32? {
        guard string.count == 7, string.first == "#" else { return nil }
        return UInt32(string.dropFirst(), radix: 16)
    }

    public static func named(_ id: String) -> DelphiTheme {
        all.first { $0.id == id } ?? standard
    }

    /// sRGB hex values, as `0xRRGGBB`.
    public static func pair(light: UInt32, dark: UInt32) -> UIColor {
        func colour(_ hex: UInt32) -> UIColor {
            UIColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        }
        let light = colour(light), dark = colour(dark)
        return UIColor { $0.userInterfaceStyle == .dark ? dark : light }
    }

    #if DEBUG
    /// Every role changed, to find colours that do not follow the theme.
    public static let debugSlate = DelphiTheme(id: "debug-slate", name: "Debug Slate", colours: [
        .background: pair(light: 0xEEF1F7, dark: 0x111827),
        .card: pair(light: 0xF8FAFD, dark: 0x1A2233),
        .foreground: pair(light: 0x1B2433, dark: 0xE8ECF3),
        .mutedForeground: pair(light: 0x5A6475, dark: 0x9AA6B8),
        .muted: pair(light: 0xE1E6EF, dark: 0x243047),
        .border: pair(light: 0xC9D1DE, dark: 0x334158),
        .primary: pair(light: 0x3B5BDB, dark: 0x8FA8FF),
        .primaryForeground: pair(light: 0xF8FAFD, dark: 0x111827),
        .accentBG: pair(light: 0xDCE4FA, dark: 0x22305A),
        .secondaryForeground: pair(light: 0x24324A, dark: 0xD5DCE8),
        .destructive: pair(light: 0xC2255C, dark: 0xF06595),
    ])
    #endif
}

#if DEBUG
extension DelphiTheme {
    /// The bundled library decodes whole: every theme sets all eleven roles, and ids are unique.
    public static func selfCheck() {
        assert(!library.isEmpty)
        assert(library.allSatisfy { $0.colours.count == Role.allCases.count })
        assert(Set(all.map(\.id)).count == all.count)
        assert(hex("#1E6626") == 0x1E6626 && hex("1E6626") == nil)
        assert(Role.accentBG.key == "accentBG" && Role.mutedForeground.key == "mutedForeground")
    }
}
#endif

extension DelphiTheme {
    public static let defaultsKey = "delphitools.theme"

    /// The stored theme's id; `-theme <id>` overrides it in debug builds.
    @MainActor public static var selectedID: String {
        #if DEBUG
        if let id = UserDefaults.standard.string(forKey: "theme") { return id }
        #endif
        return UserDefaults.standard.string(forKey: defaultsKey) ?? standard.id
    }
}

/// The chosen theme's id, kept across launches.
public final class ThemeStore: ObservableObject {
    @Published public var id: String {
        didSet { UserDefaults.standard.set(id, forKey: DelphiTheme.defaultsKey) }
    }

    public init() {
        id = DelphiTheme.selectedID
    }
}

/// The theme's id. Colours read it, so a window's override recolours everything below it.
public nonisolated struct DelphiThemeTrait: UITraitDefinition {
    public static let defaultValue = DelphiTheme.standard.id
    public static let affectsColorAppearance = true
}

extension UITraitCollection {
    public nonisolated var delphiTheme: DelphiTheme { DelphiTheme.named(self[DelphiThemeTrait.self]) }

    /// Where a delphi colour is resolved once (a `CGColor`, a drawn image), register for these and resolve again.
    public static let delphiColourTraits: [UITrait] = [UITraitUserInterfaceStyle.self, DelphiThemeTrait.self]
}

extension UIColor {
    public nonisolated static let delphiBackground = themed(.background)
    public nonisolated static let delphiCard = themed(.card)
    public nonisolated static let delphiForeground = themed(.foreground)
    public nonisolated static let delphiMutedForeground = themed(.mutedForeground)
    public nonisolated static let delphiMuted = themed(.muted)
    public nonisolated static let delphiBorder = themed(.border)
    public nonisolated static let delphiPrimary = themed(.primary)
    public nonisolated static let delphiPrimaryForeground = themed(.primaryForeground)
    public nonisolated static let delphiAccentBG = themed(.accentBG)
    public nonisolated static let delphiSecondaryForeground = themed(.secondaryForeground)
    public nonisolated static let delphiDestructive = themed(.destructive)

    private nonisolated static func themed(_ role: DelphiTheme.Role) -> UIColor {
        UIColor { traits in traits.delphiTheme.colour(role).resolvedColor(with: traits) }
    }
}

extension Color {
    public nonisolated static let delphiBackground = Color(uiColor: .delphiBackground)
    public nonisolated static let delphiCard = Color(uiColor: .delphiCard)
    public nonisolated static let delphiForeground = Color(uiColor: .delphiForeground)
    public nonisolated static let delphiMutedForeground = Color(uiColor: .delphiMutedForeground)
    public nonisolated static let delphiMuted = Color(uiColor: .delphiMuted)
    public nonisolated static let delphiBorder = Color(uiColor: .delphiBorder)
    public nonisolated static let delphiPrimary = Color(uiColor: .delphiPrimary)
    public nonisolated static let delphiPrimaryForeground = Color(uiColor: .delphiPrimaryForeground)
    public nonisolated static let delphiAccentBG = Color(uiColor: .delphiAccentBG)
    public nonisolated static let delphiSecondaryForeground = Color(uiColor: .delphiSecondaryForeground)
    public nonisolated static let delphiDestructive = Color(uiColor: .delphiDestructive)
}

extension ShapeStyle where Self == Color {
    public static var delphiBackground: Color { Color(uiColor: .delphiBackground) }
    public static var delphiCard: Color { Color(uiColor: .delphiCard) }
    public static var delphiForeground: Color { Color(uiColor: .delphiForeground) }
    public static var delphiMutedForeground: Color { Color(uiColor: .delphiMutedForeground) }
    public static var delphiMuted: Color { Color(uiColor: .delphiMuted) }
    public static var delphiBorder: Color { Color(uiColor: .delphiBorder) }
    public static var delphiPrimary: Color { Color(uiColor: .delphiPrimary) }
    public static var delphiPrimaryForeground: Color { Color(uiColor: .delphiPrimaryForeground) }
    public static var delphiAccentBG: Color { Color(uiColor: .delphiAccentBG) }
    public static var delphiSecondaryForeground: Color { Color(uiColor: .delphiSecondaryForeground) }
    public static var delphiDestructive: Color { Color(uiColor: .delphiDestructive) }
}
