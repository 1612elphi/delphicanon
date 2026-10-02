import Foundation

// ponytail: copy of delphitools Core/Models/ContrastRatio.swift, which its widget extension compiles; one copy in DelphiCore would serve both
/// WCAG 2.2 contrast levels (1.4.3, 1.4.6, 1.4.11) and the ratio as text.
nonisolated enum ContrastRatio {
    /// AA for large text and for controls.
    static let aaLarge = 3.0
    /// AA for normal text, AAA for large text.
    static let aa = 4.5
    /// AAA for normal text.
    static let aaa = 7.0

    /// Not rounded up: 4.499 shows 4.49, which fails 4.5 as the lamps do. No trailing zeros.
    static func figure(_ ratio: Double) -> String {
        var text = String(format: "%.2f", (ratio * 100 + 1e-9).rounded(.down) / 100)
        while text.contains("."), text.hasSuffix("0") || text.hasSuffix(".") { text.removeLast() }
        return text
    }
}
