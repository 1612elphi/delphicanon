import DelphiCore
import Foundation

/// Hex or functional colour notation: `#1e6626`, `rgb()`, `hsl()`, `lab()`, `lch()`, `oklab()`, `oklch()`.
public nonisolated enum ColourNotation {
    public static func parse(_ input: String) -> DelphiColour? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        if let colour = parseHex(trimmed) { return colour }

        if let vals = parseFunctional(trimmed, prefix: "rgb") {
            return DelphiColour(r: vals[0] / 255, g: vals[1] / 255, b: vals[2] / 255)
        }
        if let vals = parseFunctional(trimmed, prefix: "hsl") {
            return DelphiColour.fromHSL(h: vals[0], s: vals[1], l: vals[2])
        }
        if let vals = parseFunctional(trimmed, prefix: "lab") {
            return DelphiColour.fromLAB(l: vals[0], a: vals[1], b: vals[2])
        }
        if let vals = parseFunctional(trimmed, prefix: "lch") {
            return DelphiColour.fromLCH(l: vals[0], c: vals[1], h: vals[2])
        }
        if let vals = parseFunctional(trimmed, prefix: "oklab") {
            return DelphiColour.fromOKLAB(l: vals[0], a: vals[1], b: vals[2])
        }
        if let vals = parseFunctional(trimmed, prefix: "oklch") {
            return DelphiColour.fromOKLCH(l: vals[0], c: vals[1], h: vals[2])
        }

        return nil
    }

    // MARK: - Private

    private static func parseHex(_ input: String) -> DelphiColour? {
        var cleaned = input
        if cleaned.hasPrefix("#") { cleaned = String(cleaned.dropFirst()) }

        if cleaned.count == 3 {
            cleaned = cleaned.map { "\($0)\($0)" }.joined()
        }

        return DelphiColour.fromHex(cleaned)
    }

    private static func parseFunctional(_ input: String, prefix: String) -> [Double]? {
        let lowered = input.lowercased()
        guard lowered.hasPrefix(prefix + "(") && lowered.hasSuffix(")") else { return nil }
        let inner = lowered
            .dropFirst(prefix.count + 1)
            .dropLast()
        let parts = inner
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: "%", with: "")
            .split(separator: " ", omittingEmptySubsequences: true)
            .compactMap { Double($0) }
        // nan, inf trap delphicolour
        guard parts.count == 3, parts.allSatisfy(\.isFinite) else { return nil }
        return parts
    }
}
