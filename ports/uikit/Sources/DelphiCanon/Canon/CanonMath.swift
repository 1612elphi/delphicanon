import CoreText
import DelphiCore
import UIKit

/// The tree set as mathematics.
extension CanonMath {
    // MARK: Type

    public struct Atom {
        public enum Mark: Hashable {
            case glyphs(String, italic: Bool)
            case rule
            case paren(open: Bool)
            /// Half of a floor or ceiling bracket.
            case corner(open: Bool, floor: Bool)
            case radical
            case hole
        }

        public enum Ink { case input, result, accent }

        public var mark: Mark
        /// Glyphs: x is the pen position, y the baseline and height the font size. Shapes: their bounds.
        public var frame: CGRect
        /// Stroke width of a shape.
        public var weight: CGFloat = 0
        public var ink: Ink

        public init(mark: Mark, frame: CGRect, weight: CGFloat = 0, ink: Ink) {
            self.mark = mark
            self.frame = frame
            self.weight = weight
            self.ink = ink
        }
    }

    /// A place the editing caret can stand: an index in an edited row, and the caret's line.
    public struct Caret {
        public let row: CanonMathRow
        public let index: Int
        public var rect: CGRect

        public init(row: CanonMathRow, index: Int, rect: CGRect) {
            self.row = row
            self.index = index
            self.rect = rect
        }
    }

    /// Atoms placed around a baseline at y = 0, y growing downwards, and the caret stops among them when edited.
    public struct Box {
        public var width: CGFloat = 0
        public var ascent: CGFloat = 0
        public var descent: CGFloat = 0
        public var atoms: [Atom] = []
        public var carets: [Caret] = []

        public var height: CGFloat { ascent + descent }

        public mutating func append(_ other: Box, gap: CGFloat = 0) {
            embed(other, x: width + gap)
            width += gap + other.width
            ascent = max(ascent, other.ascent)
            descent = max(descent, other.descent)
        }

        /// Adds `other`'s atoms and carets moved by `x` and `y`; the size stays for the caller to set.
        public mutating func embed(_ other: Box, x: CGFloat, y: CGFloat = 0) {
            atoms += other.atoms.map { atom in
                var atom = atom
                atom.frame.origin.x += x
                atom.frame.origin.y += y
                return atom
            }
            carets += other.carets.map { caret in
                var caret = caret
                caret.rect.origin.x += x
                caret.rect.origin.y += y
                return caret
            }
        }

        /// Moved down by `y`; a negative `y` raises it.
        public func lowered(by y: CGFloat) -> Box {
            var box = Box(width: width, ascent: ascent - y, descent: descent + y)
            box.embed(self, x: 0, y: y)
            return box
        }

        public init(width: CGFloat = 0, ascent: CGFloat = 0, descent: CGFloat = 0, atoms: [Atom] = [], carets: [Caret] = []) {
            self.width = width
            self.ascent = ascent
            self.descent = descent
            self.atoms = atoms
            self.carets = carets
        }
    }

    private static var fonts: [String: UIFont] = [:]
    private static var lines: [String: CTLine] = [:]

    /// New York, the system serif: italic letters, upright figures and signs.
    public static func font(_ size: CGFloat, italic: Bool) -> UIFont {
        let key = "\(size)|\(italic)"
        if let font = fonts[key] { return font }
        var descriptor = UIFont.systemFont(ofSize: size).fontDescriptor
        descriptor = descriptor.withDesign(.serif) ?? descriptor
        if italic { descriptor = descriptor.withSymbolicTraits(.traitItalic) ?? descriptor }
        let font = UIFont(descriptor: descriptor, size: size)
        fonts[key] = font
        return font
    }

    public static func line(_ text: String, italic: Bool, size: CGFloat) -> CTLine {
        let key = "\(text)|\(italic)|\(size)"
        if let line = lines[key] { return line }
        // ponytail: unbounded caches cleared wholesale; typing makes a few hundred entries at most
        if lines.count > 2000 { lines.removeAll() }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font(size, italic: italic),
            NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): true,
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
        lines[key] = line
        return line
    }

    public static func colour(_ ink: Atom.Ink) -> UIColor {
        switch ink {
        case .input: .delphiMutedForeground
        case .result: .delphiForeground
        case .accent: .delphiPrimary
        }
    }

    /// Draws `atom` at `frame`, a frame the atom is moving through; a glyph run scales with the frame's height.
    public static func draw(_ atom: Atom, in frame: CGRect, colour: UIColor, context: CGContext) {
        context.setFillColor(colour.cgColor)
        context.setStrokeColor(colour.cgColor)
        switch atom.mark {
        case .glyphs(let text, let italic):
            let nominal = atom.frame.height
            guard nominal > 0, frame.height > 0 else { return }
            context.saveGState()
            context.translateBy(x: frame.minX, y: frame.minY)
            context.scaleBy(x: frame.height / nominal, y: frame.height / nominal)
            context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
            context.textPosition = .zero
            CTLineDraw(line(text, italic: italic, size: nominal), context)
            context.restoreGState()
        case .rule:
            context.fill(frame)
        case .paren(let open):
            let path = UIBezierPath()
            let (near, far) = open ? (frame.maxX, frame.minX) : (frame.minX, frame.maxX)
            let inset = frame.width * 0.15 * (open ? -1 : 1)
            path.move(to: CGPoint(x: near + inset, y: frame.minY))
            path.addQuadCurve(to: CGPoint(x: near + inset, y: frame.maxY), controlPoint: CGPoint(x: far - inset * 2, y: frame.midY))
            path.lineWidth = atom.weight
            path.lineCapStyle = .round
            path.stroke()
        case .corner(let open, let floor):
            let path = UIBezierPath()
            let stem = open ? frame.minX + frame.width * 0.3 : frame.maxX - frame.width * 0.3
            let foot = open ? frame.maxX : frame.minX
            let (start, end) = floor ? (frame.minY, frame.maxY) : (frame.maxY, frame.minY)
            path.move(to: CGPoint(x: stem, y: start))
            path.addLine(to: CGPoint(x: stem, y: end))
            path.addLine(to: CGPoint(x: foot, y: end))
            path.lineWidth = atom.weight
            path.lineJoinStyle = .miter
            path.stroke()
        case .radical:
            let path = UIBezierPath()
            let w = frame.width, h = frame.height
            path.move(to: CGPoint(x: frame.minX, y: frame.minY + h * 0.6))
            path.addLine(to: CGPoint(x: frame.minX + w * 0.22, y: frame.minY + h * 0.5))
            path.addLine(to: CGPoint(x: frame.minX + w * 0.5, y: frame.maxY))
            path.addLine(to: CGPoint(x: frame.maxX, y: frame.minY))
            path.lineWidth = atom.weight
            path.lineJoinStyle = .round
            path.lineCapStyle = .round
            path.stroke()
        case .hole:
            let path = UIBezierPath(rect: frame.insetBy(dx: atom.weight / 2, dy: atom.weight / 2))
            path.lineWidth = atom.weight
            path.setLineDash([atom.weight * 2, atom.weight * 1.5], count: 2, phase: 0)
            path.stroke()
        }
    }

    /// Sets a tree in New York at `size`. Levels follow TeX: 0 display, 1 text (a fraction's parts, same size), 2 script, 3 script-script.
    public struct Typesetter {
        public let size: CGFloat
        public let ink: Atom.Ink

        public init(size: CGFloat, ink: Atom.Ink) {
            self.size = size
            self.ink = ink
        }

        public func points(_ level: Int) -> CGFloat {
            size * [1, 1, 0.7, 0.55][min(level, 3)]
        }

        public func script(_ level: Int) -> Int { level < 2 ? 2 : 3 }

        public func text(_ string: String, italic: Bool = false, level: Int = 0, scale: CGFloat = 1, ink: Atom.Ink? = nil) -> Box {
            let points = points(level) * scale
            guard !string.isEmpty else { return Box() }
            let line = CanonMath.line(string, italic: italic, size: points)
            let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
            let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
            let font = CanonMath.font(points, italic: italic)
            return Box(
                width: width, ascent: max(font.xHeight, bounds.maxY), descent: max(0, -bounds.minY),
                atoms: [Atom(mark: .glyphs(string, italic: italic), frame: CGRect(x: 0, y: 0, width: width, height: points), ink: ink ?? self.ink)]
            )
        }

        /// Binding strength: an operand weaker than its place needs brackets.
        private func precedence(_ node: Node, _ level: Int) -> Int {
            switch node {
            case .relation, .list: 0
            case .sum, .negate, .derivative, .integral: 1
            case .product: 2
            case .quotient: level < 2 ? 4 : 2
            case .power: 3
            case .call, .factorial: 4
            default: 5
            }
        }

        private func operand(_ node: Node, _ level: Int, below: Int) -> Box {
            let box = layout(node, level)
            return precedence(node, level) < below ? parens(box, level) : box
        }

        public func layout(_ node: Node, _ level: Int = 0) -> Box {
            let s = points(level)
            let operatorGap = level >= 2 ? s * 0.12 : s * 0.22
            switch node {
            case .number(let digits):
                return text(digits, level: level)
            case .symbol(let name):
                let shown = CanonMath.shown(symbol: name)
                return text(shown, italic: CanonMath.isItalic(shown), level: level)
            case .word(let word):
                return text(word, level: level)
            case .hole:
                return hole(level)
            case .negate(let inner):
                var box = text("\u{2212}", level: level)
                box.append(operand(inner, level, below: 2), gap: s * 0.04)
                return box
            case .sum(let terms):
                var box = Box()
                for (index, term) in terms.enumerated() {
                    var body = term
                    var minus = false
                    if case .negate(let inner) = term {
                        minus = true
                        body = inner
                    }
                    let isNegation = if case .negate = body { true } else { false }
                    let set = operand(body, level, below: minus || index > 0 && isNegation ? 2 : 1)
                    if index == 0 {
                        if minus { box.append(text("\u{2212}", level: level)) }
                        box.append(set, gap: minus ? s * 0.04 : 0)
                    } else {
                        box.append(text(minus ? "\u{2212}" : "+", level: level), gap: operatorGap)
                        box.append(set, gap: operatorGap)
                    }
                }
                return box
            case .product(let factors):
                var box = Box()
                for (index, factor) in factors.enumerated() {
                    let isNegation = if case .negate = factor { true } else { false }
                    // parens: sin(x) x²
                    var factor = factor
                    if index < factors.count - 1, case .call(let name, let arguments) = factor, arguments.count == 1, Self.isBare(arguments[0]), !CanonMath.structural.contains(name) {
                        factor = .call(name, [.group(arguments[0])])
                    }
                    let set = operand(factor, level, below: index == 0 && isNegation ? 1 : 2)
                    guard index > 0 else {
                        box = set
                        continue
                    }
                    if Self.startsWithDigit(factors[index]) {
                        box.append(text("\u{00B7}", level: level), gap: s * 0.14)
                        box.append(set, gap: s * 0.14)
                    } else {
                        let previous = factors[index - 1]
                        let spaced = Self.isFunction(previous) || Self.isFunction(factor)
                            || level < 2 && (Self.isQuotient(previous) || Self.isQuotient(factor))
                        box.append(set, gap: spaced ? s * 0.26 : s * 0.04)
                    }
                }
                return box
            case .quotient(let top, let bottom):
                guard level < 2 else {
                    var box = operand(top, level, below: 2)
                    box.append(text("/", level: level), gap: s * 0.03)
                    box.append(operand(bottom, level, below: 3), gap: s * 0.03)
                    return box
                }
                return fraction(layout(top, level + 1), layout(bottom, level + 1), level)
            case .power(let base, let exponent):
                if case .call(let name, let arguments) = base, arguments.count == 1, !CanonMath.structural.contains(name), !CanonMath.inverses.contains(name) {
                    // sin²x
                    var box = superscript(functionName(name, level), exponent, level, italic: false)
                    box.append(argument(arguments[0], level), gap: Self.isBare(arguments[0]) ? s * 0.17 : s * 0.03)
                    return box
                }
                return superscript(operand(base, level, below: 5), exponent, level, italic: Self.isItalic(base))
            case .call("sqrt", let arguments):
                return radical(layout(arguments.first ?? .hole, level), level)
            case .call("abs", let arguments):
                return bars(layout(arguments.first ?? .hole, level), level)
            case .call("floor", let arguments):
                return fence(.floor, layout(arguments.first ?? .hole, level), level)
            case .call("ceil", let arguments):
                return fence(.ceil, layout(arguments.first ?? .hole, level), level)
            case .call("nthroot", let arguments) where arguments.count == 2:
                return indexedRadical(index: layout(arguments[1], script(level)), content: layout(arguments[0], level), level)
            case .call("cbrt", let arguments):
                return indexedRadical(index: text("3", level: script(level)), content: layout(arguments.first ?? .hole, level), level)
            case .call("log", let arguments) where arguments.count == 2:
                var box = logBase(layout(arguments[1], script(level)), level)
                box.append(parens(layout(arguments[0], level), level), gap: s * 0.03)
                return box
            case .call("factorial", let arguments):
                var box = operand(arguments.first ?? .hole, level, below: 5)
                box.append(text("!", level: level), gap: s * 0.02)
                return box
            case .call(let name, let arguments) where ["sum", "product"].contains(name) && arguments.count == 4:
                var below = layout(arguments[1], script(level))
                below.append(text("=", level: script(level)), gap: s * 0.04)
                below.append(layout(arguments[2], script(level)), gap: s * 0.04)
                var box = series(name == "sum" ? "\u{03A3}" : "\u{03A0}", below: below, above: layout(arguments[3], script(level)), level)
                box.append(operand(arguments[0], level, below: 2), gap: s * 0.1)
                return box
            case .call("defint", let arguments) where arguments.count == 4:
                var box = integralSign(lower: layout(arguments[1], script(level)), upper: layout(arguments[2], script(level)), level)
                box.append(operand(arguments[0], level, below: 2), gap: s * 0.1)
                box.append(differential(layout(arguments[3], level), level), gap: s * 0.17)
                return box
            case .call("integrate", let arguments) where arguments.count == 2:
                var box = integralSign(lower: nil, upper: nil, level)
                box.append(operand(arguments[0], level, below: 2), gap: s * 0.12)
                box.append(differential(layout(arguments[1], level), level), gap: s * 0.17)
                return box
            case .call("diff", let arguments) where arguments.count == 2:
                var box = derivativeOperator(layout(arguments[1], level + 1), level)
                box.append(parens(layout(arguments[0], level), level), gap: s * 0.1)
                return box
            case .call("limit", let arguments) where arguments.count == 3:
                var box = limitOperator(layout(arguments[1], script(level)), approach: layout(arguments[2], script(level)), level)
                box.append(operand(arguments[0], level, below: 2), gap: s * 0.17)
                return box
            case .call(let name, let arguments):
                var box = functionName(name, level)
                if arguments.count == 1 {
                    box.append(argument(arguments[0], level), gap: Self.isBare(arguments[0]) ? s * 0.17 : s * 0.03)
                } else {
                    box.append(parens(listed(arguments, level), level), gap: s * 0.03)
                }
                return box
            case .factorial(let inner):
                var box = operand(inner, level, below: 4)
                box.append(text("!", level: level), gap: s * 0.02)
                return box
            case .relation(let op, let left, let right):
                let isBlank = left == .word("")
                var box = isBlank ? Box() : layout(left, level)
                box.append(text(op, level: level, ink: ink == .result ? .accent : ink), gap: isBlank ? 0 : s * 0.28)
                box.append(layout(right, level), gap: s * 0.28)
                return box
            case .sub(let base, let index):
                var box = layout(base, level)
                box.append(text(index, level: script(level)).lowered(by: s * 0.2), gap: Self.isItalic(base) ? s * 0.05 : s * 0.02)
                return box
            case .list(let items):
                return listed(items, level, gap: s * 0.7)
            case .group(let inner):
                return parens(layout(inner, level), level)
            case .derivative(let inner, let variable):
                var box = derivativeOperator(layout(.symbol(variable), level + 1), level)
                box.append(parens(layout(inner, level), level), gap: s * 0.1)
                return box
            case .integral(let inner, let variable):
                var box = integralSign(lower: nil, upper: nil, level)
                box.append(operand(inner, level, below: 2), gap: s * 0.12)
                box.append(differential(layout(.symbol(variable), level), level), gap: s * 0.17)
                return box
            }
        }

        /// A function's name as a calculator prints it: `ln` for nerdamer's natural `log`, `log` for `log10`, sin⁻¹ for `asin`.
        public func functionName(_ name: String, _ level: Int) -> Box {
            switch name {
            case "log": return text("ln", level: level)
            case "log10": return text("log", level: level)
            case _ where CanonMath.inverses.contains(name):
                var box = text(String(name.dropFirst()), level: level)
                box.append(raised(text("\u{2212}1", level: script(level)), over: box.ascent, level), gap: points(level) * 0.03)
                return box
            default: return text(name, level: level)
            }
        }

        /// Absolute value bars, or floor or ceiling brackets, around `content`.
        public func fence(_ kind: CanonMath.Fence, _ content: Box, _ level: Int) -> Box {
            guard kind != .abs else { return bars(content, level) }
            let s = points(level)
            let top = -max(content.ascent, s * 0.72) - s * 0.08
            let bottom = max(content.descent, s * 0.2) + s * 0.08
            let width = s * 0.26
            func side(open: Bool) -> Box {
                Box(width: width, ascent: -top, descent: bottom, atoms: [
                    Atom(mark: .corner(open: open, floor: kind == .floor), frame: CGRect(x: 0, y: top, width: width, height: bottom - top), weight: max(1, s * 0.05), ink: ink),
                ])
            }
            var box = side(open: true)
            box.append(content, gap: s * 0.05)
            box.append(side(open: false), gap: s * 0.05)
            return box
        }

        /// A radical with its index over the sign's short stroke.
        public func indexedRadical(index: Box, content: Box, _ level: Int) -> Box {
            let root = radical(content, level)
            let hook = points(level) * 0.15
            let shift = max(0, index.width - hook)
            let lift = root.ascent * 0.42
            var box = Box(width: shift + root.width, ascent: max(root.ascent, lift + index.ascent), descent: root.descent)
            box.embed(index, x: shift + hook - index.width, y: -lift)
            box.embed(root, x: shift)
            return box
        }

        /// `log` with its base lowered after it.
        public func logBase(_ base: Box, _ level: Int) -> Box {
            var box = text("log", level: level)
            box.append(base.lowered(by: points(level) * 0.25), gap: points(level) * 0.02)
            return box
        }

        /// Σ or Π on the axis with its limits centred above and below.
        public func series(_ glyph: String, below: Box, above: Box, _ level: Int) -> Box {
            let s = points(level)
            let sign = text(glyph, level: level, scale: 1.4)
            let centred = sign.lowered(by: (sign.ascent - sign.descent) / 2 - s * 0.26)
            let width = max(centred.width, below.width, above.width)
            let gap = s * 0.1
            let aboveBaseline = -centred.ascent - gap - above.descent
            let belowBaseline = centred.descent + gap + below.ascent
            var box = Box(width: width + s * 0.06, ascent: -aboveBaseline + above.ascent, descent: belowBaseline + below.descent)
            box.embed(centred, x: (width - centred.width) / 2)
            box.embed(above, x: (width - above.width) / 2, y: aboveBaseline)
            box.embed(below, x: (width - below.width) / 2, y: belowBaseline)
            return box
        }

        /// ∫ on the axis, with its bounds at the top and bottom of its right side when given.
        public func integralSign(lower: Box?, upper: Box?, _ level: Int) -> Box {
            let s = points(level)
            let sign = text("\u{222B}", level: level, scale: 1.55)
            var box = sign.lowered(by: (sign.ascent - sign.descent) / 2 - s * 0.26)
            guard lower != nil || upper != nil else { return box }
            let signWidth = box.width
            let upper = upper ?? Box()
            let lower = lower ?? Box()
            let upperBaseline = -box.ascent + upper.ascent
            let lowerBaseline = box.descent - lower.descent
            box.embed(upper, x: signWidth + s * 0.02, y: upperBaseline)
            box.embed(lower, x: signWidth - s * 0.14, y: lowerBaseline)
            box.width = max(signWidth + s * 0.02 + upper.width, signWidth - s * 0.14 + lower.width) + s * 0.04
            box.ascent = max(box.ascent, -upperBaseline + upper.ascent)
            box.descent = max(box.descent, lowerBaseline + lower.descent)
            return box
        }

        /// The `dx` closing an integral.
        public func differential(_ variable: Box, _ level: Int) -> Box {
            var box = text("d", level: level)
            box.append(variable, gap: points(level) * 0.03)
            return box
        }

        /// d over d and the variable, as a fraction.
        public func derivativeOperator(_ variable: Box, _ level: Int) -> Box {
            var bottom = text("d", level: level + 1)
            bottom.append(variable, gap: points(level) * 0.03)
            return fraction(text("d", level: level + 1), bottom, level)
        }

        /// `lim` with the variable's approach set small under it.
        public func limitOperator(_ variable: Box, approach: Box, _ level: Int) -> Box {
            let s = points(level)
            let lim = text("lim", level: level)
            var below = variable
            below.append(text("\u{2192}", level: script(level)), gap: s * 0.03)
            below.append(approach, gap: s * 0.03)
            let width = max(lim.width, below.width)
            let belowBaseline = lim.descent + s * 0.14 + below.ascent
            var box = Box(width: width, ascent: lim.ascent, descent: belowBaseline + below.descent)
            box.embed(lim, x: (width - lim.width) / 2)
            box.embed(below, x: (width - below.width) / 2, y: belowBaseline)
            return box
        }

        /// Two lines centred on the axis with no bar: a binomial coefficient's inside.
        public func stacked(_ top: Box, _ bottom: Box, _ level: Int) -> Box {
            let s = points(level)
            let width = max(top.width, bottom.width)
            let above = top.lowered(by: -s * 0.26 - s * 0.1 - top.descent)
            let below = bottom.lowered(by: -s * 0.26 + s * 0.1 + bottom.ascent)
            var box = Box(width: width, ascent: above.ascent, descent: below.descent)
            box.embed(above, x: (width - top.width) / 2)
            box.embed(below, x: (width - bottom.width) / 2)
            return box
        }

        /// ₙPᵣ, as a calculator prints it.
        public func permutation(_ n: Box, _ r: Box, _ level: Int) -> Box {
            let s = points(level)
            var box = n.lowered(by: s * 0.2)
            box.append(text("P", level: level), gap: s * 0.02)
            box.append(r.lowered(by: s * 0.2), gap: s * 0.02)
            return box
        }

        /// A dashed box for an operand still to be typed.
        public func hole(_ level: Int, ink: Atom.Ink? = nil) -> Box {
            let s = points(level)
            let side = s * 0.52
            let height = s * 0.64
            return Box(width: side + s * 0.12, ascent: height, descent: 0, atoms: [
                Atom(mark: .hole, frame: CGRect(x: s * 0.06, y: -height, width: side, height: height), weight: max(1, s * 0.04), ink: ink ?? self.ink),
            ])
        }

        /// Absolute value bars around `content`.
        public func bars(_ content: Box, _ level: Int) -> Box {
            let s = points(level)
            let weight = max(1, s * 0.05)
            let top = -content.ascent - s * 0.08
            let bar = Box(width: weight, ascent: -top, descent: content.descent + s * 0.08, atoms: [
                Atom(mark: .rule, frame: CGRect(x: 0, y: top, width: weight, height: content.height + s * 0.16), ink: ink),
            ])
            var box = Box(width: s * 0.06)
            box.append(bar)
            box.append(content, gap: s * 0.1)
            box.append(bar, gap: s * 0.1)
            box.width += s * 0.06
            return box
        }

        /// A function's argument: bare when it is one letter or number (`sin x`), bracketed otherwise.
        private func argument(_ node: Node, _ level: Int) -> Box {
            if case .group = node { return layout(node, level) }
            return Self.isBare(node) ? layout(node, level) : parens(layout(node, level), level)
        }

        private func listed(_ items: [Node], _ level: Int, gap: CGFloat? = nil) -> Box {
            var box = Box()
            for (index, item) in items.enumerated() {
                if index > 0 { box.append(text(",", level: level), gap: points(level) * 0.02) }
                box.append(layout(item, level), gap: index > 0 ? gap ?? points(level) * 0.2 : 0)
            }
            return box
        }

        private func superscript(_ base: Box, _ exponent: Node, _ level: Int, italic: Bool) -> Box {
            var box = base
            box.append(raised(layout(exponent, script(level)), over: base.ascent, level), gap: italic ? points(level) * 0.07 : points(level) * 0.03)
            return box
        }

        /// An exponent lifted to sit over a base whose ascent is `ascent`.
        public func raised(_ exponent: Box, over ascent: CGFloat, _ level: Int) -> Box {
            let lift = max(points(level) * 0.38, ascent - exponent.height * 0.45)
            return exponent.lowered(by: -lift)
        }

        public func fraction(_ top: Box, _ bottom: Box, _ level: Int) -> Box {
            let s = points(level)
            let weight = max(1, s * 0.05)
            let gap = s * 0.16
            let axis = s * 0.26
            let margin = s * 0.08
            let bar = max(top.width, bottom.width) + s * 0.16
            var box = Box(width: bar + margin * 2)
            let above = top.lowered(by: -axis - weight / 2 - gap - top.descent)
            let below = bottom.lowered(by: -axis + weight / 2 + gap + bottom.ascent)
            box.embed(above, x: margin + (bar - top.width) / 2)
            box.embed(below, x: margin + (bar - bottom.width) / 2)
            box.atoms.append(Atom(mark: .rule, frame: CGRect(x: margin, y: -axis - weight / 2, width: bar, height: weight), ink: ink))
            box.ascent = above.ascent
            box.descent = below.descent
            return box
        }

        public func radical(_ content: Box, _ level: Int) -> Box {
            let s = points(level)
            let weight = max(1, s * 0.05)
            let top = content.ascent + s * 0.1 + weight
            let sign = CGRect(x: s * 0.04, y: -top + weight / 2, width: s * 0.5, height: top + content.descent + s * 0.04 - weight / 2)
            let start = sign.maxX + s * 0.06
            let end = start + content.width + s * 0.06
            var box = Box(width: end + s * 0.04, ascent: top + s * 0.02, descent: max(content.descent, sign.maxY), atoms: [
                Atom(mark: .radical, frame: sign, weight: weight, ink: ink),
                Atom(mark: .rule, frame: CGRect(x: sign.maxX - weight / 2, y: -top, width: end - sign.maxX + weight / 2, height: weight), ink: ink),
            ])
            box.embed(content, x: start)
            return box
        }

        /// Font brackets around content of about one line, drawn brackets around taller content.
        public func parens(_ content: Box, _ level: Int) -> Box {
            let s = points(level)
            guard content.height > s * 1.05 else {
                var box = text("(", level: level)
                box.append(content, gap: s * 0.03)
                box.append(text(")", level: level), gap: s * 0.03)
                return box
            }
            let weight = max(1, s * 0.07)
            let width = s * 0.26 + content.height * 0.03
            let top = -content.ascent - s * 0.08
            let height = content.height + s * 0.16
            func bracket(open: Bool) -> Box {
                Box(width: width, ascent: -top, descent: height + top, atoms: [
                    Atom(mark: .paren(open: open), frame: CGRect(x: 0, y: top, width: width, height: height), weight: weight, ink: ink),
                ])
            }
            var box = bracket(open: true)
            box.append(content, gap: s * 0.04)
            box.append(bracket(open: false), gap: s * 0.04)
            return box
        }

        private static func startsWithDigit(_ node: Node) -> Bool {
            switch node {
            case .number: true
            case .power(let base, _), .factorial(let base): startsWithDigit(base)
            case .product(let factors): factors.first.map(startsWithDigit) ?? false
            default: false
            }
        }

        private static func isFunction(_ node: Node) -> Bool {
            switch node {
            case .call(let name, _): !CanonMath.structural.contains(name)
            case .power(let base, _): isFunction(base)
            default: false
            }
        }

        private static func isQuotient(_ node: Node) -> Bool {
            if case .quotient = node { return true }
            return false
        }

        private static func isBare(_ node: Node) -> Bool {
            switch node {
            case .symbol, .number: true
            default: false
            }
        }

        private static func isItalic(_ node: Node) -> Bool {
            if case .symbol(let name) = node { return CanonMath.isItalic(CanonMath.shown(symbol: name)) }
            return false
        }
    }

    private static let signs = [
        "pi": "\u{03C0}", "Infinity": "\u{221E}", "alpha": "\u{03B1}", "beta": "\u{03B2}", "gamma": "\u{03B3}",
        "delta": "\u{03B4}", "epsilon": "\u{03B5}", "theta": "\u{03B8}", "lambda": "\u{03BB}", "mu": "\u{03BC}",
        "sigma": "\u{03C3}", "tau": "\u{03C4}", "phi": "\u{03C6}", "omega": "\u{03C9}",
    ]

    public static func shown(symbol name: String) -> String { signs[name] ?? name }

    /// Calls set as their own notation, with no function spacing.
    public static let structural: Set<String> = [
        "sqrt", "abs", "floor", "ceil", "nthroot", "cbrt", "factorial", "sum", "product", "defint", "integrate", "diff", "limit",
    ]

    /// Inverse functions, set as the function with a raised −1.
    public static let inverses: Set<String> = ["asin", "acos", "atan", "asec", "acsc", "acot", "asinh", "acosh", "atanh"]

    /// Letters are italic; constants shown as signs (π, ∞, ∅) are upright.
    public static func isItalic(_ shown: String) -> Bool {
        !["\u{03C0}", "\u{221E}", "\u{2205}"].contains(shown) && shown.allSatisfy(\.isLetter)
    }
}

/// A typeset box drawn at its own size, scaled down to fit a narrower frame, centred vertically.
public final class CanonMathView: UIView {
    public var box = CanonMath.Box() {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }

    /// Opacity of every atom, for a placeholder.
    public var inkAlpha: CGFloat = 1 {
        didSet { setNeedsDisplay() }
    }

    public init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
        isUserInteractionEnabled = false
        redrawsOnStyleChange()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: box.width.rounded(.up), height: box.height.rounded(.up))
    }

    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), box.width > 0 else { return }
        let scale = min(1, bounds.width / box.width, box.height > 0 ? bounds.height / box.height : 1)
        context.setAlpha(inkAlpha)
        context.translateBy(x: (bounds.width - box.width * scale) / 2, y: (bounds.height - box.height * scale) / 2 + box.ascent * scale)
        context.scaleBy(x: scale, y: scale)
        for atom in box.atoms {
            CanonMath.draw(atom, in: atom.frame, colour: CanonMath.colour(atom.ink), context: context)
        }
    }
}

/// Typeset atoms moving from one arrangement to the next: an atom whose key stays slides and resizes on a damped spring,
/// a new one grows in, a removed one fades. The owning view calls `draw(in:)` from its `draw(_:)`.
public final class CanonMathMorph: NSObject {
    public struct Placed {
        public var atom: CanonMath.Atom
        /// Where the atom is drawn; `atom.frame` keeps its set size.
        public var frame: CGRect
        public var alpha: CGFloat

        public init(atom: CanonMath.Atom, frame: CGRect, alpha: CGFloat) {
            self.atom = atom
            self.frame = frame
            self.alpha = alpha
        }
    }

    public static let settleDuration = 0.55

    private weak var view: UIView?
    /// Keys in drawing order: leaving atoms first, then the target's.
    private var order: [String] = []
    private var from: [String: Placed] = [:]
    private var target: [String: Placed] = [:]
    private var shown: [String: Placed] = [:]
    private var started: CFTimeInterval = 0
    private var link: CADisplayLink?

    public init(view: UIView) {
        self.view = view
    }

    /// Keys each atom by its mark and the count of that mark before it, so a glyph that stays keeps its key.
    public static func keyed(_ atoms: [CanonMath.Atom], prefix: String, place: (CanonMath.Atom) -> Placed) -> [(key: String, placed: Placed)] {
        var seen: [String: Int] = [:]
        return atoms.map { atom in
            let base = prefix + "|" + key(atom.mark)
            let count = seen[base, default: 0]
            seen[base] = count + 1
            return (base + "#\(count)", place(atom))
        }
    }

    private static func key(_ mark: CanonMath.Atom.Mark) -> String {
        switch mark {
        case .glyphs(let text, let italic): "g" + (italic ? "i" : "u") + text
        case .rule: "rule"
        case .paren(let open): open ? "(" : ")"
        case .corner(let open, let floor): (floor ? "floor" : "ceil") + (open ? "(" : ")")
        case .radical: "root"
        case .hole: "hole"
        }
    }

    /// Renames the shown atoms, so the next `show` moves them to where their new keys are.
    public func rename(_ transform: (String) -> String) {
        shown = Dictionary(shown.map { (transform($0.key), $0.value) }) { first, _ in first }
    }

    public func show(_ next: [(key: String, placed: Placed)], animated: Bool) {
        link?.invalidate()
        link = nil
        let keys = next.map(\.key)
        target = Dictionary(next.map { ($0.key, $0.placed) }) { first, _ in first }
        guard animated, view?.window != nil, !UIAccessibility.isReduceMotionEnabled else {
            order = keys
            shown = target
            view?.setNeedsDisplay()
            return
        }
        from = shown
        order = from.keys.filter { target[$0] == nil }.sorted() + keys
        started = CACurrentMediaTime()
        link = CADisplayLink(target: self, selector: #selector(step))
        link?.add(to: .main, forMode: .common)
    }

    /// Jumps to the end; call it when the view leaves the window.
    public func land() {
        link?.invalidate()
        link = nil
        order = order.filter { target[$0] != nil }
        shown = target
        view?.setNeedsDisplay()
    }

    @objc private func step() {
        let progress = min(1, (CACurrentMediaTime() - started) / Self.settleDuration)
        guard progress < 1 else { return land() }
        // damped spring, one overshoot
        let eased = 1 - exp(-7 * progress) * cos(9 * progress)
        let appear = min(1, max(0, (progress - 0.12) / 0.5))
        let vanish = max(0, 1 - progress * 2.5)
        var next: [String: Placed] = [:]
        for key in order {
            switch (from[key], target[key]) {
            case (let old?, let new?):
                next[key] = Placed(atom: new.atom, frame: Self.mix(old.frame, new.frame, eased), alpha: old.alpha + (new.alpha - old.alpha) * progress)
            case (nil, let new?):
                next[key] = Placed(atom: new.atom, frame: Self.grown(new, 0.6 + 0.4 * eased), alpha: new.alpha * appear)
            case (let old?, nil):
                next[key] = Placed(atom: old.atom, frame: Self.grown(old, 1 - 0.2 * progress), alpha: old.alpha * vanish)
            case (nil, nil):
                break
            }
        }
        shown = next
        view?.setNeedsDisplay()
    }

    private static func mix(_ a: CGRect, _ b: CGRect, _ t: CGFloat) -> CGRect {
        CGRect(x: a.minX + (b.minX - a.minX) * t, y: a.minY + (b.minY - a.minY) * t,
               width: max(0, a.width + (b.width - a.width) * t), height: max(0, a.height + (b.height - a.height) * t))
    }

    /// A glyph run grows about its centre on the baseline, a shape about its centre.
    private static func grown(_ placed: Placed, _ scale: CGFloat) -> CGRect {
        var frame = placed.frame
        if case .glyphs = placed.atom.mark {
            frame.origin.x += frame.width * (1 - scale) / 2
            frame.size = CGSize(width: frame.width * scale, height: frame.height * scale)
            return frame
        }
        return frame.insetBy(dx: frame.width * (1 - scale) / 2, dy: frame.height * (1 - scale) / 2)
    }

    public func draw(in context: CGContext) {
        for key in order {
            guard let placed = shown[key], placed.alpha > 0.01 else { continue }
            context.saveGState()
            context.setAlpha(placed.alpha)
            CanonMath.draw(placed.atom, in: placed.frame, colour: CanonMath.colour(placed.atom.ink), context: context)
            context.restoreGState()
        }
    }
}
