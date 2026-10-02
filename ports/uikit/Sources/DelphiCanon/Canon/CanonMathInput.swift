import DelphiCore
import UIKit

// MARK: - Model

/// A run of items in an edited expression; some items hold rows of their own, their slots.
public final class CanonMathRow {
    public var items: [CanonMathItem]

    public init(_ items: [CanonMathItem] = []) {
        self.items = items
    }
}

public enum CanonMathItem {
    /// A digit, a letter, an operator sign, π, e, i or ∞.
    case symbol(String)
    case fraction(CanonMathRow, CanonMathRow)
    /// An exponent on the item before it.
    case power(CanonMathRow)
    case root(CanonMathRow)
    case nthRoot(index: CanonMathRow, radicand: CanonMathRow)
    case group(CanonMathRow)
    case fence(CanonMath.Fence, CanonMathRow)
    /// A function under nerdamer's name (`log` is ln, `log10` is log), one slot per argument.
    case function(String, [CanonMathRow])
    case logBase(base: CanonMathRow, argument: CanonMathRow)
    case series(product: Bool, index: CanonMathRow, from: CanonMathRow, to: CanonMathRow, body: CanonMathRow)
    /// Bounds are nil for an indefinite integral.
    case integral(lower: CanonMathRow?, upper: CanonMathRow?, body: CanonMathRow)
    case derivative(CanonMathRow)
    case limit(to: CanonMathRow, body: CanonMathRow)
    case binomial(CanonMathRow, CanonMathRow)
    case permutation(CanonMathRow, CanonMathRow)

    /// In the order the caret walks them.
    public var slots: [CanonMathRow] {
        switch self {
        case .symbol: []
        case .fraction(let top, let bottom), .binomial(let top, let bottom), .permutation(let top, let bottom): [top, bottom]
        case .power(let row), .root(let row), .group(let row), .fence(_, let row), .derivative(let row): [row]
        case .nthRoot(let index, let radicand): [index, radicand]
        case .function(_, let rows): rows
        case .logBase(let base, let argument): [base, argument]
        case .series(_, let index, let from, let to, let body): [index, from, to, body]
        case .integral(let lower, let upper, let body): [lower, upper].compactMap { $0 } + [body]
        case .limit(let to, let body): [to, body]
        }
    }

    /// The slot above or below `slot`, where the layout has one.
    public func slot(from slot: Int, up: Bool) -> Int? {
        switch self {
        case .fraction, .binomial, .nthRoot: up ? (slot == 1 ? 0 : nil) : (slot == 0 ? 1 : nil)
        case .logBase, .limit: up ? (slot == 0 ? 1 : nil) : (slot == 1 ? 0 : nil)
        case .series: up ? (slot == 2 ? nil : 2) : (slot == 2 || slot == 3 ? 1 : nil)
        case .integral(let lower, _, _) where lower != nil: up ? (slot == 1 ? nil : 1) : (slot == 0 ? nil : 0)
        default: nil
        }
    }
}

/// An expression edited in two dimensions, as on a MathPrint calculator: a fraction has numerator and denominator slots,
/// an exponent is raised, a root has a slot under it, brackets grow. It reads and writes the text syntax nerdamer takes.
public final class CanonMathExpression {
    public enum Key: Equatable {
        case symbol(String)
        /// An empty fraction.
        case fraction
        /// A fraction over the operand before the caret.
        case divide
        case power, square, cube, inverse
        case root, cubeRoot, nthRoot, logBase
        /// The base, then an exponent slot: 10^□, e^□.
        case exponential(String)
        /// ×10^□
        case scientific
        case open
        /// Steps out of the bracket, function or fence the caret is in.
        case close
        case fence(CanonMath.Fence)
        case function(String, arity: Int)
        case series(product: Bool)
        case integral(bounded: Bool)
        case derivative, limit, binomial, permutation
        case left, right, up, down
        case delete, clear
    }

    public private(set) var root: CanonMathRow
    public var caret: (row: CanonMathRow, index: Int)
    /// The variable of derivatives, integrals and limits.
    public var variable: String

    public init(text: String, variable: String = "x") {
        self.variable = variable
        root = CanonMathRow(Self.items(text))
        caret = (root, root.items.count)
    }

    public var text: String { Self.text(root, variable: variable) }

    // MARK: Editing

    public func apply(_ key: Key) {
        let row = caret.row
        let index = caret.index
        func empty() -> CanonMathRow { CanonMathRow() }
        func symbols(_ text: String) -> CanonMathRow { CanonMathRow(text.map { .symbol(String($0)) }) }
        switch key {
        case .symbol(let symbol):
            row.items.insert(.symbol(symbol), at: index)
            caret.index += 1
        case .fraction:
            insert(.fraction(empty(), empty()), entering: 0)
        case .divide:
            var start = index
            while start > 0, !Self.isOperator(row.items[start - 1]) { start -= 1 }
            let top = CanonMathRow(Array(row.items[start..<index]))
            row.items.removeSubrange(start..<index)
            caret.index = start
            insert(.fraction(top, empty()), entering: top.items.isEmpty ? 0 : 1)
        case .power:
            insert(.power(empty()), entering: 0)
        case .square, .cube, .inverse:
            let exponent = key == .square ? "2" : key == .cube ? "3" : "\u{2212}1"
            row.items.insert(.power(symbols(exponent)), at: index)
            caret.index += 1
        case .root:
            insert(.root(empty()), entering: 0)
        case .cubeRoot:
            insert(.nthRoot(index: symbols("3"), radicand: empty()), entering: 1)
        case .nthRoot:
            insert(.nthRoot(index: empty(), radicand: empty()), entering: 0)
        case .logBase:
            insert(.logBase(base: empty(), argument: empty()), entering: 0)
        case .exponential(let base):
            for character in base { apply(.symbol(String(character))) }
            apply(.power)
        case .scientific:
            for symbol in ["\u{00D7}", "1", "0"] { apply(.symbol(symbol)) }
            apply(.power)
        case .open:
            insert(.group(empty()), entering: 0)
        case .fence(let kind):
            insert(.fence(kind, empty()), entering: 0)
        case .function(let name, let arity):
            insert(.function(name, (0..<max(1, arity)).map { _ in empty() }), entering: 0)
        case .series(let product):
            insert(.series(product: product, index: symbols("k"), from: empty(), to: empty(), body: empty()), entering: 1)
        case .integral(let bounded):
            insert(bounded ? .integral(lower: empty(), upper: empty(), body: empty()) : .integral(lower: nil, upper: nil, body: empty()), entering: 0)
        case .derivative:
            insert(.derivative(empty()), entering: 0)
        case .limit:
            insert(.limit(to: empty(), body: empty()), entering: 0)
        case .binomial:
            insert(.binomial(empty(), empty()), entering: 0)
        case .permutation:
            insert(.permutation(empty(), empty()), entering: 0)
        case .close:
            var current = row
            while let found = parent(of: current) {
                switch found.row.items[found.index] {
                case .group, .function, .fence, .logBase, .derivative:
                    caret = (found.row, found.index + 1)
                    return
                default:
                    current = found.row
                }
            }
        case .left: moveLeft()
        case .right: moveRight()
        case .up: moveVertically(up: true)
        case .down: moveVertically(up: false)
        case .delete: delete()
        case .clear:
            root.items = []
            caret = (root, 0)
        }
    }

    private func insert(_ item: CanonMathItem, entering slot: Int) {
        caret.row.items.insert(item, at: caret.index)
        caret = (item.slots[slot], item.slots[slot].items.count)
    }

    /// The item holding `row`: the row it is in, its index there, and which of its slots `row` is.
    private func parent(of row: CanonMathRow) -> (row: CanonMathRow, index: Int, slot: Int)? {
        func search(_ current: CanonMathRow) -> (row: CanonMathRow, index: Int, slot: Int)? {
            for (index, item) in current.items.enumerated() {
                for (slot, child) in item.slots.enumerated() {
                    if child === row { return (current, index, slot) }
                    if let found = search(child) { return found }
                }
            }
            return nil
        }
        return search(root)
    }

    private func moveLeft() {
        let (row, index) = caret
        if index > 0 {
            if let last = row.items[index - 1].slots.last { caret = (last, last.items.count) } else { caret.index -= 1 }
        } else if let found = parent(of: row) {
            let slots = found.row.items[found.index].slots
            caret = found.slot > 0 ? (slots[found.slot - 1], slots[found.slot - 1].items.count) : (found.row, found.index)
        }
    }

    private func moveRight() {
        let (row, index) = caret
        if index < row.items.count {
            if let first = row.items[index].slots.first { caret = (first, 0) } else { caret.index += 1 }
        } else if let found = parent(of: row) {
            let slots = found.row.items[found.index].slots
            caret = found.slot < slots.count - 1 ? (slots[found.slot + 1], 0) : (found.row, found.index + 1)
        }
    }

    /// To the slot above or below in the nearest structure that has one; up into a neighbouring exponent, down out of one.
    private func moveVertically(up: Bool) {
        var current = caret.row
        while let found = parent(of: current) {
            let item = found.row.items[found.index]
            if let target = item.slot(from: found.slot, up: up) {
                let row = item.slots[target]
                caret = (row, row.items.count)
                return
            }
            if case .power = item, !up {
                caret = (found.row, found.index + 1)
                return
            }
            current = found.row
        }
        guard up else { return }
        let (row, index) = caret
        if index > 0, case .power(let exponent) = row.items[index - 1] {
            caret = (exponent, exponent.items.count)
        } else if index < row.items.count, case .power(let exponent) = row.items[index] {
            caret = (exponent, 0)
        }
    }

    /// A symbol or an empty structure goes; a filled structure is entered from its end. At the start of a first slot,
    /// the structure is taken apart and its contents stay in its place.
    private func delete() {
        let (row, index) = caret
        if index > 0 {
            let item = row.items[index - 1]
            if item.slots.allSatisfy(\.items.isEmpty) {
                row.items.remove(at: index - 1)
                caret.index -= 1
            } else if let last = item.slots.last {
                caret = (last, last.items.count)
            }
        } else if let found = parent(of: row) {
            let item = found.row.items[found.index]
            if found.slot > 0 {
                let previous = item.slots[found.slot - 1]
                caret = (previous, previous.items.count)
            } else {
                found.row.items.replaceSubrange(found.index...found.index, with: item.slots.flatMap(\.items))
                caret = (found.row, found.index)
            }
        }
    }

    // MARK: Text

    private static let operators: Set<String> = ["+", "\u{2212}", "\u{00D7}", "=", ","]

    private static func isOperator(_ item: CanonMathItem) -> Bool {
        if case .symbol(let symbol) = item { return operators.contains(symbol) }
        return false
    }

    private static func isNumeral(_ item: CanonMathItem) -> Bool {
        if case .symbol(let symbol) = item { return symbol.allSatisfy { $0.isNumber || $0 == "." } }
        return false
    }

    private static func isName(_ symbol: String) -> Bool {
        ["\u{03C0}", "\u{221E}"].contains(symbol) || symbol.first?.isLetter == true
    }

    private static func endsOperand(_ item: CanonMathItem) -> Bool {
        if case .symbol(let symbol) = item { return isNumeral(item) || isName(symbol) || symbol == "!" }
        return true
    }

    private static func startsOperand(_ item: CanonMathItem) -> Bool {
        switch item {
        case .symbol(let symbol): isNumeral(item) || isName(symbol)
        case .power: false
        default: true
        }
    }

    /// nerdamer's syntax, with `*` wherever two operands meet.
    public static func text(_ row: CanonMathRow, variable: String) -> String {
        var text = ""
        for (index, item) in row.items.enumerated() {
            if index > 0, endsOperand(row.items[index - 1]), startsOperand(item), !(isNumeral(row.items[index - 1]) && isNumeral(item)) {
                text += "*"
            }
            var piece = self.text(item, variable: variable)
            // exponent covers whole fraction
            if case .fraction = item, index + 1 < row.items.count, case .power = row.items[index + 1] { piece = "(" + piece + ")" }
            text += piece
        }
        return text
    }

    private static func text(_ item: CanonMathItem, variable v: String) -> String {
        func t(_ row: CanonMathRow) -> String { text(row, variable: v) }
        switch item {
        case .symbol(let symbol):
            return ["\u{00D7}": "*", "\u{2212}": "-", "\u{03C0}": "pi", "\u{221E}": "Infinity"][symbol] ?? symbol
        case .fraction(let top, let bottom):
            return "(" + t(top) + ")/(" + t(bottom) + ")"
        case .power(let exponent):
            let single = exponent.items.count == 1 && exponent.items[0].slots.isEmpty && startsOperand(exponent.items[0])
            return single ? "^" + t(exponent) : "^(" + t(exponent) + ")"
        case .root(let row): return "sqrt(" + t(row) + ")"
        case .nthRoot(let index, let radicand): return "nthroot(" + t(radicand) + "," + t(index) + ")"
        case .group(let row): return "(" + t(row) + ")"
        case .fence(let kind, let row):
            let name = switch kind {
            case .abs: "abs"
            case .floor: "floor"
            case .ceil: "ceil"
            }
            return name + "(" + t(row) + ")"
        case .function(let name, let rows): return name + "(" + rows.map(t).joined(separator: ",") + ")"
        case .logBase(let base, let argument): return "log(" + t(argument) + "," + t(base) + ")"
        case .series(let product, let index, let from, let to, let body):
            return (product ? "product(" : "sum(") + [body, index, from, to].map(t).joined(separator: ",") + ")"
        case .integral(let lower, let upper, let body):
            guard let lower, let upper else { return "integrate(" + t(body) + "," + v + ")" }
            return "defint(" + t(body) + "," + t(lower) + "," + t(upper) + "," + v + ")"
        case .derivative(let body): return "diff(" + t(body) + "," + v + ")"
        case .limit(let to, let body): return "limit(" + t(body) + "," + v + "," + t(to) + ")"
        // ponytail: nerdamer has no nCr or nPr, so they go out as factorials and come back as them
        case .binomial(let n, let r): return "(factorial(\(t(n)))/(factorial(\(t(r)))*factorial((\(t(n)))-(\(t(r))))))"
        case .permutation(let n, let r): return "(factorial(\(t(n)))/factorial((\(t(n)))-(\(t(r)))))"
        }
    }

    /// Items for text in nerdamer's syntax; text that does not parse comes in as one symbol per character.
    public static func items(_ text: String) -> [CanonMathItem] {
        guard let node = CanonMath.parse(text) else {
            return text.filter { !$0.isWhitespace }.map { .symbol(String($0)) }
        }
        return items(node)
    }

    private static func row(_ node: CanonMath.Node) -> CanonMathRow { CanonMathRow(items(node)) }

    private static func precedence(_ node: CanonMath.Node) -> Int {
        switch node {
        case .relation, .list: 0
        case .sum, .negate: 1
        case .product: 2
        case .power: 3
        case .quotient, .factorial: 4
        default: 5
        }
    }

    private static func operand(_ node: CanonMath.Node, below: Int) -> [CanonMathItem] {
        precedence(node) < below ? [.group(row(node))] : items(node)
    }

    private static func items(_ node: CanonMath.Node) -> [CanonMathItem] {
        switch node {
        case .number(let digits):
            return digits.map { .symbol(String($0)) }
        case .symbol(let name):
            return [.symbol(["pi": "\u{03C0}", "Infinity": "\u{221E}"][name] ?? name)]
        case .word(let word):
            return [.symbol(word)]
        case .hole:
            return []
        case .negate(let inner):
            return [.symbol("\u{2212}")] + operand(inner, below: 2)
        case .sum(let terms):
            var items: [CanonMathItem] = []
            for (index, term) in terms.enumerated() {
                if case .negate(let inner) = term {
                    items += [.symbol("\u{2212}")] + operand(inner, below: 2)
                } else {
                    if index > 0 { items.append(.symbol("+")) }
                    items += operand(term, below: 1)
                }
            }
            return items
        case .product(let factors):
            var items: [CanonMathItem] = []
            for (index, factor) in factors.enumerated() {
                let set = operand(factor, below: 2)
                if index > 0, let first = set.first, isNumeral(first) { items.append(.symbol("\u{00D7}")) }
                items += set
            }
            return items
        case .quotient(let top, let bottom):
            return [.fraction(row(top), row(bottom))]
        case .power(let base, let exponent):
            return operand(base, below: 5) + [.power(row(exponent))]
        case .call(let name, let arguments):
            return call(name, arguments)
        case .factorial(let inner):
            return operand(inner, below: 5) + [.symbol("!")]
        case .relation(let op, let left, let right):
            return items(left) + [.symbol(op)] + items(right)
        case .sub(let base, _):
            return items(base)
        case .derivative(let body, _):
            return [.derivative(row(body))]
        case .integral(let body, _):
            return [.integral(lower: nil, upper: nil, body: row(body))]
        case .list(let entries):
            return entries.enumerated().flatMap { index, node in (index > 0 ? [CanonMathItem.symbol(",")] : []) + items(node) }
        case .group(let inner):
            return [.group(row(inner))]
        }
    }

    private static func call(_ name: String, _ arguments: [CanonMath.Node]) -> [CanonMathItem] {
        let rows = arguments.map(row)
        let first = rows.first ?? CanonMathRow()
        switch (name, rows.count) {
        case ("sqrt", _): return [.root(first)]
        case ("abs", _): return [.fence(.abs, first)]
        case ("floor", _): return [.fence(.floor, first)]
        case ("ceil", _): return [.fence(.ceil, first)]
        case ("nthroot", 2): return [.nthRoot(index: rows[1], radicand: rows[0])]
        case ("cbrt", _): return [.nthRoot(index: CanonMathRow([.symbol("3")]), radicand: first)]
        case ("log", 2): return [.logBase(base: rows[1], argument: rows[0])]
        case ("factorial", _): return operand(arguments.first ?? .hole, below: 5) + [.symbol("!")]
        case ("sum", 4), ("product", 4): return [.series(product: name == "product", index: rows[1], from: rows[2], to: rows[3], body: rows[0])]
        case ("defint", 4): return [.integral(lower: rows[1], upper: rows[2], body: rows[0])]
        case ("integrate", 2): return [.integral(lower: nil, upper: nil, body: rows[0])]
        case ("diff", 2): return [.derivative(rows[0])]
        case ("limit", 3): return [.limit(to: rows[2], body: rows[0])]
        default: return [.function(name, rows.isEmpty ? [CanonMathRow()] : rows)]
        }
    }

    #if DEBUG
    public static func selfCheck() {
        // round trip keeps tree
        for text in [
            "(x+1)^2 - x^2", "sin(x)^2 + cos(x)^2", "(a*b)/(a*c)", "x^2 + 5*x + 6", "2*x + 3 = 7", "e^x * x^2", "1/x", "sqrt(x)+abs(x-1)",
            "x^(-1/2)", "-x^2", "2*3", "nthroot(x,3)+log(8,2)+floor(x)", "sum(k^2,k,1,n)", "defint(x^2,0,3,x)", "diff(sin(x),x)",
            "limit(1/x,x,Infinity)", "asin(x)+log10(x)+log(x)", "gcd(12,18)",
        ] {
            let round = CanonMathExpression(text: text).text
            assert(CanonMath.parse(round) == CanonMath.parse(text), "\(text) came back as \(round)")
        }
        let typed = CanonMathExpression(text: "")
        for key: Key in [.symbol("x"), .power, .symbol("2"), .right, .symbol("+"), .symbol("1"), .divide, .symbol("2")] { typed.apply(key) }
        assert(typed.text == "x^2+(1)/(2)")
        typed.apply(.delete)
        assert(typed.text == "x^2+(1)/()")
        for _ in 0..<3 { typed.apply(.delete) }
        assert(typed.text == "x^2+")
        typed.apply(.left)
        typed.apply(.left)
        typed.apply(.symbol("3"))
        assert(typed.text == "x^(23)+")
        let grouped = CanonMathExpression(text: "")
        for key: Key in [.symbol("2"), .open, .symbol("x"), .close, .square] { grouped.apply(key) }
        assert(grouped.text == "2*(x)^2")
        let calculus = CanonMathExpression(text: "", variable: "t")
        for key: Key in [
            .series(product: false), .symbol("1"), .up, .symbol("5"), .right, .symbol("k"), .right, .symbol("+"),
            .integral(bounded: true), .symbol("0"), .up, .symbol("1"), .right, .symbol("t"),
        ] {
            calculus.apply(key)
        }
        assert(calculus.text == "sum(k,k,1,5)+defint(t,0,1,t)", calculus.text)
        assert(Key.fraction.opensSlot && !Key.square.opensSlot && !Key.symbol("x").opensSlot)
    }
    #endif
}

// MARK: - Layout

extension CanonMath.Typesetter {
    /// An edited row set with its caret stops. An empty slot shows a dashed box, lit while the caret is in it.
    public func layout(_ row: CanonMathRow, level: Int = 0, caret: CanonMathRow?, variable: String = "x", isSlot: Bool = false) -> CanonMath.Box {
        let s = points(level)
        func slot(_ row: CanonMathRow, _ level: Int) -> CanonMath.Box {
            layout(row, level: level, caret: caret, variable: variable, isSlot: true)
        }
        // multi-term bodies show end
        func bodied(_ body: CanonMathRow) -> CanonMath.Box {
            let terms = body.items.dropFirst().contains { if case .symbol(let sign) = $0 { ["+", "\u{2212}", "="].contains(sign) } else { false } }
            return terms ? parens(slot(body, level), level) : slot(body, level)
        }
        func variableBox(_ level: Int) -> CanonMath.Box {
            text(variable, italic: CanonMath.isItalic(variable), level: level)
        }
        var box = CanonMath.Box()
        var stops: [CGFloat] = []
        if row.items.isEmpty {
            if isSlot {
                box = hole(level, ink: caret === row ? .accent : nil)
            } else {
                box.ascent = s * 0.72
                box.descent = s * 0.2
                stops = [0]
            }
        }
        var previousAscent: CGFloat?
        var previousItalic = false
        for (index, item) in row.items.enumerated() {
            let previous = index > 0 ? row.items[index - 1] : nil
            let gap = Self.gap(previous, item, in: row, at: index, points: s, level: level)
            stops.append(box.width + gap / 2)
            var set: CanonMath.Box
            switch item {
            case .symbol(let symbol):
                let shown = CanonMath.shown(symbol: symbol)
                set = text(shown, italic: CanonMath.isItalic(shown), level: level)
            case .fraction(let top, let bottom):
                set = fraction(slot(top, level + 1), slot(bottom, level + 1), level)
            case .power(let exponent):
                set = raised(slot(exponent, script(level)), over: previousAscent ?? s * 0.5, level)
            case .root(let inner):
                set = radical(slot(inner, level), level)
            case .nthRoot(let index, let radicand):
                set = indexedRadical(index: slot(index, script(level)), content: slot(radicand, level), level)
            case .group(let inner):
                set = parens(slot(inner, level), level)
            case .fence(let kind, let inner):
                set = fence(kind, slot(inner, level), level)
            case .function(let name, let rows):
                var arguments = CanonMath.Box()
                for (index, argument) in rows.enumerated() {
                    if index > 0 { arguments.append(text(",", level: level), gap: s * 0.02) }
                    arguments.append(slot(argument, level), gap: index > 0 ? s * 0.2 : 0)
                }
                set = functionName(name, level)
                set.append(parens(arguments, level), gap: s * 0.03)
            case .logBase(let base, let argument):
                set = logBase(slot(base, script(level)), level)
                set.append(parens(slot(argument, level), level), gap: s * 0.03)
            case .series(let product, let index, let from, let to, let body):
                var below = slot(index, script(level))
                below.append(text("=", level: script(level)), gap: s * 0.04)
                below.append(slot(from, script(level)), gap: s * 0.04)
                set = series(product ? "\u{03A0}" : "\u{03A3}", below: below, above: slot(to, script(level)), level)
                set.append(bodied(body), gap: s * 0.1)
            case .integral(let lower, let upper, let body):
                set = integralSign(lower: lower.map { slot($0, script(level)) }, upper: upper.map { slot($0, script(level)) }, level)
                set.append(bodied(body), gap: s * 0.1)
                set.append(differential(variableBox(level), level), gap: s * 0.17)
            case .derivative(let body):
                set = derivativeOperator(variableBox(level + 1), level)
                set.append(parens(slot(body, level), level), gap: s * 0.1)
            case .limit(let to, let body):
                set = limitOperator(variableBox(script(level)), approach: slot(to, script(level)), level)
                set.append(bodied(body), gap: s * 0.17)
            case .binomial(let n, let r):
                set = parens(stacked(slot(n, level + 1), slot(r, level + 1), level), level)
            case .permutation(let n, let r):
                set = permutation(slot(n, script(level)), slot(r, script(level)), level)
            }
            let italicGap: CGFloat = if case .power = item, previousItalic { s * 0.04 } else { 0 }
            box.append(set, gap: gap + italicGap)
            if case .power = item {} else {
                previousAscent = set.ascent
                previousItalic = if case .symbol(let symbol) = item { CanonMath.isItalic(CanonMath.shown(symbol: symbol)) } else { false }
            }
        }
        // extra gap after italics
        let endsItalic = if case .symbol(let symbol) = row.items.last { CanonMath.isItalic(CanonMath.shown(symbol: symbol)) } else { false }
        if !row.items.isEmpty { stops.append(box.width + (endsItalic ? s * 0.1 : s * 0.04)) }
        if row.items.isEmpty, isSlot, let hole = box.atoms.first {
            // empty slot is caret
            box.carets.append(CanonMath.Caret(row: row, index: 0, rect: hole.frame))
        } else {
            box.carets += stops.enumerated().map { index, x in
                CanonMath.Caret(row: row, index: index, rect: CGRect(x: x, y: -s * 0.78, width: 0, height: s))
            }
        }
        return box
    }

    private static let spaced: Set<String> = ["+", "\u{2212}", "\u{00D7}"]

    /// Space before `item`: around binary operators and relations, none inside a number, a hair between letters.
    private static func gap(_ previous: CanonMathItem?, _ item: CanonMathItem, in row: CanonMathRow, at index: Int, points s: CGFloat, level: Int) -> CGFloat {
        guard let previous else { return 0 }
        let operatorGap = level >= 2 ? s * 0.12 : s * 0.22
        func symbol(_ item: CanonMathItem) -> String? {
            if case .symbol(let symbol) = item { return symbol }
            return nil
        }
        if symbol(previous) == "=" || symbol(item) == "=" { return level >= 2 ? s * 0.14 : s * 0.28 }
        if let sign = symbol(item), spaced.contains(sign) { return operatorGap }
        if let sign = symbol(previous), spaced.contains(sign) {
            // sign after sign: unary
            let before = index >= 2 ? symbol(row.items[index - 2]) : "="
            return before.map { spaced.contains($0) || $0 == "=" || $0 == "," } == true ? s * 0.04 : operatorGap
        }
        if case .power = item { return s * 0.03 }
        if symbol(previous) == "," { return s * 0.2 }
        // sin(x) x, (a+b)(a−b)
        if symbol(previous) == nil { return s * 0.1 }
        let digits = { (item: CanonMathItem) in symbol(item)?.allSatisfy { $0.isNumber || $0 == "." } == true }
        return digits(previous) && digits(item) ? 0 : s * 0.05
    }
}

// MARK: - Editor

/// The expression being edited, typeset, with a blinking caret. A tap moves the caret to the nearest place.
public final class CanonMathEditor: UIView {
    public let expression: CanonMathExpression
    /// Called after every key that changes the text.
    public var onChange: (() -> Void)?
    /// Called when the caret moves, with its rectangle in this view.
    public var onCaret: ((CGRect) -> Void)?
    private let size: CGFloat
    private var box = CanonMath.Box()
    public private(set) var caretRect = CGRect.zero
    private var caretShown = true
    private var blink: Timer?
    private lazy var morph = CanonMathMorph(view: self)
    private var animatesNext = false
    private var generation = 0
    private var shown = (generation: -1, size: CGSize.zero)
    public static let padding: CGFloat = 16
    public static let blinkInterval = 0.53
    /// Seconds of holding before the caret follows the finger.
    public static let dragDelay = 0.22

    public init(expression: CanonMathExpression, size: CGFloat = 30) {
        self.expression = expression
        self.size = size
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
        isAccessibilityElement = true
        accessibilityLabel = String(localized: "Expression")
        accessibilityTraits = .updatesFrequently
        redrawsOnStyleChange()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
        let drag = UILongPressGestureRecognizer(target: self, action: #selector(dragged))
        drag.minimumPressDuration = Self.dragDelay
        addGestureRecognizer(drag)
        relayout()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// False when the key changed neither the text nor the caret.
    @discardableResult
    public func apply(_ key: CanonMathExpression.Key) -> Bool {
        let before = (text: expression.text, row: expression.caret.row, index: expression.caret.index)
        expression.apply(key)
        let caretMoved = expression.caret.row !== before.row || expression.caret.index != before.index
        let changed = expression.text != before.text
        guard changed || caretMoved else { return false }
        animatesNext = true
        relayout()
        if changed { onChange?() }
        return true
    }

    private var origin: CGPoint {
        CGPoint(x: Self.padding, y: (bounds.height - box.height) / 2 + box.ascent)
    }

    private func relayout() {
        generation += 1
        box = CanonMath.Typesetter(size: size, ink: .result).layout(expression.root, caret: expression.caret.row, variable: expression.variable)
        invalidateIntrinsicContentSize()
        accessibilityValue = expression.text
        restartBlink()
        setNeedsLayout()
        setNeedsDisplay()
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: box.width + Self.padding * 2 + 2, height: box.height + Self.padding * 2)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let (row, index) = expression.caret
        let stop = box.carets.first { $0.row === row && $0.index == index }?.rect ?? .zero
        let rect = stop.width > 0 ? stop.offsetBy(dx: origin.x, dy: origin.y) : stop.offsetBy(dx: origin.x, dy: origin.y).insetBy(dx: -1, dy: 0)
        if rect != caretRect {
            caretRect = rect
            onCaret?(rect)
        }
        if shown.generation != generation || shown.size != bounds.size {
            shown = (generation, bounds.size)
            let origin = origin
            morph.show(CanonMathMorph.keyed(box.atoms, prefix: "edit") { atom in
                CanonMathMorph.Placed(atom: atom, frame: atom.frame.offsetBy(dx: origin.x, dy: origin.y), alpha: 1)
            }, animated: animatesNext)
            animatesNext = false
        }
        setNeedsDisplay()
    }

    private func restartBlink() {
        blink?.invalidate()
        caretShown = true
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let timer = Timer(timeInterval: Self.blinkInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.caretShown.toggle()
                self.setNeedsDisplay(self.caretRect.insetBy(dx: -2, dy: -2))
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        blink = timer
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            blink?.invalidate()
            morph.land()
        } else {
            restartBlink()
        }
    }

    @objc private func tapped(_ tap: UITapGestureRecognizer) {
        moveCaret(to: tap.location(in: self))
    }

    /// Held, the caret follows the finger from place to place.
    @objc private func dragged(_ drag: UILongPressGestureRecognizer) {
        guard drag.state == .began || drag.state == .changed else { return }
        moveCaret(to: drag.location(in: self))
    }

    private func moveCaret(to point: CGPoint) {
        let target = box.carets.min { distance($0.rect, point) < distance($1.rect, point) }
        guard let target, target.row !== expression.caret.row || target.index != expression.caret.index else { return }
        expression.caret = (target.row, target.index)
        CanonMathHaptics.select()
        relayout()
    }

    /// Distance to a caret line; vertical distance counts double, so a tap picks its own line of a fraction.
    private func distance(_ rect: CGRect, _ point: CGPoint) -> CGFloat {
        let frame = rect.offsetBy(dx: origin.x, dy: origin.y)
        let dy = point.y < frame.minY ? frame.minY - point.y : max(0, point.y - frame.maxY)
        let dx = point.x < frame.minX ? frame.minX - point.x : max(0, point.x - frame.maxX)
        return dx + dy * 2
    }

    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        morph.draw(in: context)
        if caretShown {
            // empty slot fills faintly
            context.setFillColor(UIColor.delphiPrimary.withAlphaComponent(caretRect.width > 2 ? 0.22 : 1).cgColor)
            context.fill(caretRect)
        }
    }
}


// MARK: - Sheet

/// The expression over its caret rail and the keypad, as a sheet. Compact width: the system sheet sized to the keypad,
/// tool above undimmed; the large detent gives the expression room. Regular width: docked to the bottom of the pane
/// holding the opening field, clear of any crease; a drag down or a tap outside closes it.
public final class CanonMathInputViewController: UIViewController, UISheetPresentationControllerDelegate, UIViewControllerTransitioningDelegate {
    private let editor: CanonMathEditor
    private let keypad: CanonMathKeypad
    private let rail: CanonMathRail
    private let scroller = UIScrollView()
    private let onChange: (String) -> Void
    private let completion: (String) -> Void
    private var finished = false
    private weak var source: UIView?
    private var docked = false
    private var contentHeight: CGFloat = 0
    /// Editor height, and the height on a short screen.
    public static let editorHeights = (regular: CGFloat(112), short: CGFloat(84))
    /// Screens shorter than this get the short keys and editor.
    public static let shortScreen: CGFloat = 800
    /// Widest the docked sheet gets.
    public static let maxWidth: CGFloat = 560
    /// Gap between the display and the keypad.
    public static let gap: CGFloat = 12
    private let isShort: Bool
    private static let detent = UISheetPresentationController.Detent.Identifier("canonMathKeypad")

    public init(text: String, variable: String, isShort: Bool = false, onChange: @escaping (String) -> Void, completion: @escaping (String) -> Void) {
        editor = CanonMathEditor(expression: CanonMathExpression(text: text, variable: variable), size: isShort ? 26 : 30)
        keypad = CanonMathKeypad(variable: variable, isShort: isShort)
        rail = CanonMathRail(height: isShort ? CanonMathRail.heights.short : CanonMathRail.heights.regular)
        self.isShort = isShort
        self.onChange = onChange
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Height of the content, without the bottom safe area.
    public static func contentHeight(isShort: Bool) -> CGFloat {
        let display = (isShort ? editorHeights.short : editorHeights.regular) + DelphiMetrics.hairline
            + (isShort ? CanonMathRail.heights.short : CanonMathRail.heights.regular)
        return DelphiMetrics.panelPadding * 2 + DelphiMetrics.frame * 4 + display + gap + CanonMathKeypad.height(isShort: isShort)
    }

    /// - Parameter source: the view whose pane the sheet docks to on a regular width.
    public static func present(
        from host: UIViewController, source: UIView, text: String, variable: String, keys: [CanonMathExpression.Key] = [],
        onChange: @escaping (String) -> Void, completion: @escaping (String) -> Void
    ) {
        var isShort = host.view.bounds.height < shortScreen
        #if DEBUG
        // -mathshort yes: the short keys and editor on any screen
        if UserDefaults.standard.bool(forKey: "mathShort") { isShort = true }
        #endif
        let input = CanonMathInputViewController(text: text, variable: variable, isShort: isShort, onChange: onChange, completion: completion)
        for key in keys { input.editor.apply(key) }
        if !keys.isEmpty { onChange(input.editor.expression.text) }
        let height = contentHeight(isShort: isShort)
        if host.traitCollection.horizontalSizeClass == .regular {
            input.source = source
            input.docked = true
            input.contentHeight = height
            input.modalPresentationStyle = .custom
            input.transitioningDelegate = input
        } else {
            input.modalPresentationStyle = .pageSheet
            if let sheet = input.sheetPresentationController {
                sheet.detents = [.custom(identifier: detent) { _ in height }, .large()]
                sheet.largestUndimmedDetentIdentifier = detent
                sheet.prefersGrabberVisible = true
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.delegate = input
                #if DEBUG
                // -mathlarge yes: opens at the large detent
                if UserDefaults.standard.bool(forKey: "mathLarge") { sheet.selectedDetentIdentifier = .large }
                #endif
            }
        }
        host.present(input, animated: true)
    }

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        CanonPaneSheetPresentation(presentedViewController: presented, presenting: presenting, source: self.source, height: contentHeight) { [weak self] in
            self?.finish()
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .delphiBackground
        editor.onChange = { [unowned self] in onChange(editor.expression.text) }
        editor.onCaret = { [unowned self] rect in scroller.scrollRectToVisible(rect.insetBy(dx: -24, dy: -8), animated: true) }
        keypad.onKey = { [unowned self] in editor.apply($0) }
        keypad.onDone = { [unowned self] in finish() }
        rail.onStep = { [unowned self] in editor.apply($0) }

        scroller.backgroundColor = .delphiCard
        scroller.alwaysBounceHorizontal = true
        scroller.showsVerticalScrollIndicator = false
        editor.translatesAutoresizingMaskIntoConstraints = false
        scroller.addSubview(editor)
        let editorHeight = isShort ? Self.editorHeights.short : Self.editorHeights.regular
        // large detent grows expression
        let natural = scroller.heightAnchor.constraint(equalToConstant: editorHeight)
        natural.priority = .defaultLow
        NSLayoutConstraint.activate([
            editor.topAnchor.constraint(equalTo: scroller.contentLayoutGuide.topAnchor),
            editor.bottomAnchor.constraint(equalTo: scroller.contentLayoutGuide.bottomAnchor),
            editor.leadingAnchor.constraint(equalTo: scroller.contentLayoutGuide.leadingAnchor),
            editor.trailingAnchor.constraint(equalTo: scroller.contentLayoutGuide.trailingAnchor),
            editor.widthAnchor.constraint(greaterThanOrEqualTo: scroller.frameLayoutGuide.widthAnchor),
            editor.heightAnchor.constraint(greaterThanOrEqualTo: scroller.frameLayoutGuide.heightAnchor),
            scroller.heightAnchor.constraint(greaterThanOrEqualToConstant: editorHeight),
            natural,
        ])
        let stack = UIStackView(arrangedSubviews: [CanonRows(framed: true, [scroller, rail]), CanonRows(framed: true, [keypad])])
        stack.axis = .vertical
        stack.spacing = Self.gap
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        let padding = DelphiMetrics.panelPadding
        // duo strip is inset
        let guide = view.safeAreaLayoutGuide
        let bottom = guide.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: padding)
        bottom.priority = .init(999)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: guide.topAnchor, constant: padding),
            stack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: padding),
            guide.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: padding),
            bottom,
        ])
        if docked {
            let grabber = UIView()
            grabber.backgroundColor = .delphiBorder
            grabber.layer.cornerRadius = 2.5
            grabber.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(grabber)
            NSLayoutConstraint.activate([
                grabber.topAnchor.constraint(equalTo: view.topAnchor, constant: 5),
                grabber.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                grabber.widthAnchor.constraint(equalToConstant: 36),
                grabber.heightAnchor.constraint(equalToConstant: 5),
            ])
        }

        #if DEBUG
        // -mathkeys "x,pow,2,right,+,frac,1,down,x" (played one by one after 1 s) -mathkeydelay <seconds between keys>
        // Key names are listed in CanonMathKeypad.key(named:); a name the open submenu or the page in view has presses that key,
        // and sinh or sec on the f(x) page open their submenus. Also page1 … page4 and rail:<n> (slide the caret n places, negative left).
        let defaults = UserDefaults.standard
        if let script = defaults.string(forKey: "mathKeys") {
            let delay = defaults.object(forKey: "mathKeyDelay") == nil ? 0.5 : defaults.double(forKey: "mathKeyDelay")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.play(script.split(separator: ",").map(String.init)[...], delay: delay)
            }
        }
        #endif
    }

    #if DEBUG
    private func play(_ tokens: ArraySlice<String>, delay: Double) {
        guard let token = tokens.first else { return }
        var duration = 0.0
        if token.hasPrefix("rail:"), let steps = Int(token.dropFirst(5)) {
            duration = rail.glide(steps: steps)
        } else if let played = keypad.perform(token) {
            duration = played
        } else if let key = CanonMathKeypad.key(named: token) {
            editor.apply(key)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + max(delay, duration)) { [weak self] in
            self?.play(tokens.dropFirst(), delay: delay)
        }
    }
    #endif

    private func finish() {
        guard !finished else { return }
        finished = true
        completion(editor.expression.text)
        dismiss(animated: true)
    }

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard !finished else { return }
        finished = true
        completion(editor.expression.text)
    }
}

/// A sheet docked to the bottom of the pane holding `source`: that pane's width up to `maxWidth`, its content's height. The tool
/// stays in view around it; a tap outside or a drag down calls `onClose`.
public final class CanonPaneSheetPresentation: UIPresentationController, UIGestureRecognizerDelegate {
    private weak var source: UIView?
    private let height: CGFloat
    private let onClose: () -> Void
    private let backdrop = UIView()
    /// Drag, in points, or speed, in points per second, that closes the sheet.
    public static let closing = (distance: CGFloat(100), speed: CGFloat(900))

    public init(presentedViewController: UIViewController, presenting: UIViewController?, source: UIView?, height: CGFloat, onClose: @escaping () -> Void) {
        self.source = source
        self.height = height
        self.onClose = onClose
        super.init(presentedViewController: presentedViewController, presenting: presenting)
    }

    /// The scrolling page holding `source`, in `container`'s coordinates; the whole container when there is none.
    public static func pane(of source: UIView?, in container: UIView) -> CGRect {
        guard let source, let page = sequence(first: source, next: \.superview).first(where: { $0 is CanonPage }) else { return container.bounds }
        return page.convert(page.bounds, to: container)
    }

    public override var frameOfPresentedViewInContainerView: CGRect {
        guard let container = containerView else { return .zero }
        let pane = Self.pane(of: source, in: container)
        let width = min(CanonMathInputViewController.maxWidth, pane.width)
        let total = min(height + container.safeAreaInsets.bottom, container.bounds.height - container.safeAreaInsets.top)
        return CGRect(x: pane.midX - width / 2, y: container.bounds.maxY - total, width: width, height: total)
    }

    public override func presentationTransitionWillBegin() {
        guard let container = containerView, let sheet = presentedView else { return }
        backdrop.frame = container.bounds
        backdrop.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backdrop.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
        container.insertSubview(backdrop, at: 0)
        sheet.layer.cornerRadius = 24
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheet.layer.shadowOpacity = 0.14
        sheet.layer.shadowRadius = 16
        sheet.layer.shadowOffset = CGSize(width: 0, height: -2)
        let drag = UIPanGestureRecognizer(target: self, action: #selector(dragged))
        drag.delegate = self
        sheet.addGestureRecognizer(drag)
    }

    public override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    @objc private func close() {
        onClose()
    }

    @objc private func dragged(_ drag: UIPanGestureRecognizer) {
        guard let sheet = presentedView else { return }
        let travel = drag.translation(in: sheet).y
        switch drag.state {
        case .changed:
            // resists upwards
            sheet.transform = CGAffineTransform(translationX: 0, y: travel > 0 ? travel : travel / 6)
        case .ended, .cancelled:
            if drag.state == .ended, travel > Self.closing.distance || drag.velocity(in: sheet).y > Self.closing.speed {
                onClose()
            } else {
                UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) { sheet.transform = .identity }
            }
        default:
            break
        }
    }

    // mostly-vertical drags only
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let drag = gestureRecognizer as? UIPanGestureRecognizer, let sheet = presentedView else { return true }
        let velocity = drag.velocity(in: sheet)
        return abs(velocity.y) > abs(velocity.x)
    }
}

// MARK: - Field

/// An expression typeset in a flush cell; a tap opens the keypad sheet. Sends `.valueChanged` on every edit made there and
/// `.editingDidEnd` when the sheet closes. `text` is nerdamer's syntax.
public final class CanonMathField: UIControl {
    public var text: String {
        didSet { if text != oldValue { refresh() } }
    }

    /// The letter the keypad offers first, and the variable of derivatives, integrals and limits.
    public var variable: String {
        didSet { if variable != oldValue { refresh() } }
    }

    /// Shown faint while `text` is empty, in the same syntax.
    public var placeholder: String {
        didSet { if placeholder != oldValue { refresh() } }
    }

    /// Called with the text when the sheet closes.
    public var onCompletion: ((String) -> Void)?

    private let size: CGFloat
    private let math = CanonMathView()
    private var isHovering = false {
        didSet { paint() }
    }
    public private(set) var isEditing = false {
        didSet { paint() }
    }

    public init(text: String = "", variable: String = "x", placeholder: String = "", size: CGFloat = 22) {
        self.text = text
        self.variable = variable
        self.placeholder = placeholder
        self.size = size
        super.init(frame: .zero)
        let glyph = UIImageView(image: UIImage(systemName: "keyboard"))
        glyph.tintColor = .delphiMutedForeground
        glyph.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .footnote)
        glyph.setContentHuggingPriority(.required, for: .horizontal)
        glyph.setContentCompressionResistancePriority(.required, for: .horizontal)
        math.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [math, UIView(), glyph])
        stack.alignment = .center
        stack.spacing = 12
        stack.isUserInteractionEnabled = false
        let padding = DelphiMetrics.panelPadding
        pin(stack, insets: NSDirectionalEdgeInsets(top: 10, leading: padding, bottom: 10, trailing: padding))
        heightAnchor.constraint(greaterThanOrEqualToConstant: DelphiMetrics.rowHeight + 12).isActive = true
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = String(localized: "Expression")
        addAction(UIAction { [unowned self] _ in edit() }, for: .touchUpInside)
        animatesPress()
        tracksHover { [unowned self] in isHovering = $0 }
        paint()
        refresh()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func refresh() {
        let shown = text.isEmpty ? placeholder : text
        math.box = CanonMath.Typesetter(size: size, ink: .result).layout(CanonMathExpression(text: shown, variable: variable).root, caret: nil, variable: variable)
        math.inkAlpha = text.isEmpty ? 0.35 : 1
        accessibilityValue = text
    }

    private func paint() {
        backgroundColor = isEditing || isHovering ? .delphiAccentBG : .delphiCard
    }

    /// Opens the keypad sheet, then types `keys`.
    public func edit(then keys: [CanonMathExpression.Key] = []) {
        guard !isEditing, let host = owningViewController else { return }
        isEditing = true
        CanonMathInputViewController.present(from: host, source: self, text: text, variable: variable, keys: keys) { [weak self] text in
            guard let self else { return }
            self.text = text
            sendActions(for: .valueChanged)
        } completion: { [weak self] text in
            guard let self else { return }
            self.text = text
            isEditing = false
            sendActions(for: .editingDidEnd)
            onCompletion?(text)
        }
    }
}
