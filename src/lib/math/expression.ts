import {
  isItalic,
  isLetter,
  N,
  parse,
  shown,
  type Fence,
  type Node,
} from './node.ts';
import { Box, type Caret, type Typesetter } from './typeset.ts';

/** A run of items in an edited expression; some items hold rows of their own, their slots. */
export class Row {
  items: Item[];

  constructor(items: Item[] = []) {
    this.items = items;
  }
}

export type Item =
  /** A digit, a letter, an operator sign, π, e, i or ∞. */
  | { kind: 'symbol'; symbol: string }
  | { kind: 'fraction'; top: Row; bottom: Row }
  /** An exponent on the item before it. */
  | { kind: 'power'; exponent: Row }
  | { kind: 'root'; radicand: Row }
  | { kind: 'nthRoot'; index: Row; radicand: Row }
  | { kind: 'group'; inner: Row }
  | { kind: 'fence'; fence: Fence; inner: Row }
  /** A function under nerdamer's name (`log` is ln, `log10` is log), one slot per argument. */
  | { kind: 'function'; name: string; args: Row[] }
  | { kind: 'logBase'; base: Row; argument: Row }
  | {
      kind: 'series';
      product: boolean;
      index: Row;
      from: Row;
      to: Row;
      body: Row;
    }
  /** Bounds are absent for an indefinite integral. */
  | { kind: 'integral'; lower?: Row; upper?: Row; body: Row }
  | { kind: 'derivative'; body: Row }
  | { kind: 'limit'; to: Row; body: Row }
  | { kind: 'binomial'; n: Row; r: Row }
  | { kind: 'permutation'; n: Row; r: Row };

/** An item's slots in the order the caret walks them. */
export function slots(item: Item): Row[] {
  switch (item.kind) {
    case 'symbol':
      return [];
    case 'fraction':
      return [item.top, item.bottom];
    case 'binomial':
    case 'permutation':
      return [item.n, item.r];
    case 'power':
      return [item.exponent];
    case 'root':
      return [item.radicand];
    case 'group':
    case 'fence':
      return [item.inner];
    case 'derivative':
      return [item.body];
    case 'nthRoot':
      return [item.index, item.radicand];
    case 'function':
      return item.args;
    case 'logBase':
      return [item.base, item.argument];
    case 'series':
      return [item.index, item.from, item.to, item.body];
    case 'integral':
      return item.lower && item.upper
        ? [item.lower, item.upper, item.body]
        : [item.body];
    case 'limit':
      return [item.to, item.body];
  }
}

/** The slot above or below `slot`, where the layout has one. */
function slotFrom(item: Item, slot: number, up: boolean): number | undefined {
  switch (item.kind) {
    case 'fraction':
    case 'binomial':
    case 'nthRoot':
      return up ? (slot === 1 ? 0 : undefined) : slot === 0 ? 1 : undefined;
    case 'logBase':
    case 'limit':
      return up ? (slot === 0 ? 1 : undefined) : slot === 1 ? 0 : undefined;
    case 'series':
      return up
        ? slot === 2
          ? undefined
          : 2
        : slot === 2 || slot === 3
          ? 1
          : undefined;
    case 'integral':
      if (!item.lower) return undefined;
      return up ? (slot === 1 ? undefined : 1) : slot === 0 ? undefined : 0;
    default:
      return undefined;
  }
}

export type Key =
  | { kind: 'symbol'; symbol: string }
  | {
      kind:
        | 'fraction'
        | 'divide'
        | 'power'
        | 'square'
        | 'cube'
        | 'inverse'
        | 'root'
        | 'cubeRoot'
        | 'nthRoot'
        | 'logBase'
        | 'scientific'
        | 'open'
        | 'close'
        | 'derivative'
        | 'limit'
        | 'binomial'
        | 'permutation'
        | 'left'
        | 'right'
        | 'up'
        | 'down'
        | 'delete'
        | 'clear';
    }
  /** The base, then an exponent slot: 10^□, e^□. */
  | { kind: 'exponential'; base: string }
  | { kind: 'fence'; fence: Fence }
  | { kind: 'function'; name: string; arity: number }
  | { kind: 'series'; product: boolean }
  | { kind: 'integral'; bounded: boolean };

export function sameKey(a: Key, b: Key): boolean {
  return JSON.stringify(a) === JSON.stringify(b);
}

/** True when the key opens an empty slot for what is typed next. */
export function opensSlot(key: Key): boolean {
  return ![
    'symbol',
    'square',
    'cube',
    'inverse',
    'close',
    'left',
    'right',
    'up',
    'down',
    'delete',
    'clear',
  ].includes(key.kind);
}

const times = '×';
const minus = '−';
const operators = new Set(['+', minus, times, '=', ',']);

const numeral = /^[\p{N}.]*$/u;
function isOperator(item: Item) {
  return item.kind === 'symbol' && operators.has(item.symbol);
}
function isNumeral(item: Item) {
  return item.kind === 'symbol' && numeral.test(item.symbol);
}
function isName(symbol: string) {
  return ['π', '∞'].includes(symbol) || isLetter([...symbol][0]);
}
function endsOperand(item: Item) {
  if (item.kind === 'symbol')
    return isNumeral(item) || isName(item.symbol) || item.symbol === '!';
  return true;
}
function startsOperand(item: Item) {
  if (item.kind === 'symbol') return isNumeral(item) || isName(item.symbol);
  return item.kind !== 'power';
}

/**
 * An expression edited in two dimensions, as on a MathPrint calculator: a
 * fraction has numerator and denominator slots, an exponent is raised, a root
 * has a slot under it, brackets grow. It reads and writes the text syntax
 * nerdamer takes.
 */
export class Expression {
  root: Row;
  caret: { row: Row; index: number };
  /** The variable of derivatives, integrals and limits. */
  variable: string;

  constructor(text = '', variable = 'x') {
    this.variable = variable;
    this.root = new Row(items(text));
    this.caret = { row: this.root, index: this.root.items.length };
  }

  get text(): string {
    return rowText(this.root, this.variable);
  }

  apply(key: Key): void {
    const { row, index } = this.caret;
    const empty = () => new Row();
    const symbols = (text: string) =>
      new Row([...text].map((symbol) => ({ kind: 'symbol', symbol })));
    switch (key.kind) {
      case 'symbol':
        row.items.splice(index, 0, { kind: 'symbol', symbol: key.symbol });
        this.caret.index += 1;
        return;
      case 'fraction':
        return this.insert(
          { kind: 'fraction', top: empty(), bottom: empty() },
          0,
        );
      case 'divide': {
        let start = index;
        while (start > 0 && !isOperator(row.items[start - 1]!)) start -= 1;
        const top = new Row(row.items.splice(start, index - start));
        this.caret.index = start;
        return this.insert(
          { kind: 'fraction', top, bottom: empty() },
          top.items.length === 0 ? 0 : 1,
        );
      }
      case 'power':
        return this.insert({ kind: 'power', exponent: empty() }, 0);
      case 'square':
      case 'cube':
      case 'inverse': {
        const exponent =
          key.kind === 'square' ? '2' : key.kind === 'cube' ? '3' : `${minus}1`;
        row.items.splice(index, 0, {
          kind: 'power',
          exponent: symbols(exponent),
        });
        this.caret.index += 1;
        return;
      }
      case 'root':
        return this.insert({ kind: 'root', radicand: empty() }, 0);
      case 'cubeRoot':
        return this.insert(
          { kind: 'nthRoot', index: symbols('3'), radicand: empty() },
          1,
        );
      case 'nthRoot':
        return this.insert(
          { kind: 'nthRoot', index: empty(), radicand: empty() },
          0,
        );
      case 'logBase':
        return this.insert(
          { kind: 'logBase', base: empty(), argument: empty() },
          0,
        );
      case 'exponential':
        for (const c of key.base) this.apply({ kind: 'symbol', symbol: c });
        return this.apply({ kind: 'power' });
      case 'scientific':
        for (const symbol of [times, '1', '0'])
          this.apply({ kind: 'symbol', symbol });
        return this.apply({ kind: 'power' });
      case 'open':
        return this.insert({ kind: 'group', inner: empty() }, 0);
      case 'fence':
        return this.insert(
          { kind: 'fence', fence: key.fence, inner: empty() },
          0,
        );
      case 'function':
        return this.insert(
          {
            kind: 'function',
            name: key.name,
            args: Array.from({ length: Math.max(1, key.arity) }, empty),
          },
          0,
        );
      case 'series':
        return this.insert(
          {
            kind: 'series',
            product: key.product,
            index: symbols('k'),
            from: empty(),
            to: empty(),
            body: empty(),
          },
          1,
        );
      case 'integral':
        return this.insert(
          key.bounded
            ? {
                kind: 'integral',
                lower: empty(),
                upper: empty(),
                body: empty(),
              }
            : { kind: 'integral', body: empty() },
          0,
        );
      case 'derivative':
        return this.insert({ kind: 'derivative', body: empty() }, 0);
      case 'limit':
        return this.insert({ kind: 'limit', to: empty(), body: empty() }, 0);
      case 'binomial':
        return this.insert({ kind: 'binomial', n: empty(), r: empty() }, 0);
      case 'permutation':
        return this.insert({ kind: 'permutation', n: empty(), r: empty() }, 0);
      case 'close': {
        let current = row;
        for (
          let found = this.parent(current);
          found;
          found = this.parent(current)
        ) {
          const kind = found.row.items[found.index]!.kind;
          if (
            ['group', 'function', 'fence', 'logBase', 'derivative'].includes(
              kind,
            )
          ) {
            this.caret = { row: found.row, index: found.index + 1 };
            return;
          }
          current = found.row;
        }
        return;
      }
      case 'left':
        return this.moveLeft();
      case 'right':
        return this.moveRight();
      case 'up':
        return this.moveVertically(true);
      case 'down':
        return this.moveVertically(false);
      case 'delete':
        return this.delete();
      case 'clear':
        this.root.items = [];
        this.caret = { row: this.root, index: 0 };
        return;
    }
  }

  private insert(item: Item, slot: number) {
    this.caret.row.items.splice(this.caret.index, 0, item);
    const target = slots(item)[slot]!;
    this.caret = { row: target, index: target.items.length };
  }

  /** The item holding `row`: the row it is in, its index there, and which of its slots `row` is. */
  parent(row: Row): { row: Row; index: number; slot: number } | undefined {
    const search = (
      current: Row,
    ): { row: Row; index: number; slot: number } | undefined => {
      for (const [index, item] of current.items.entries()) {
        for (const [slot, child] of slots(item).entries()) {
          if (child === row) return { row: current, index, slot };
          const found = search(child);
          if (found) return found;
        }
      }
      return undefined;
    };
    return search(this.root);
  }

  private moveLeft() {
    const { row, index } = this.caret;
    if (index > 0) {
      const last = slots(row.items[index - 1]!).at(-1);
      if (last) this.caret = { row: last, index: last.items.length };
      else this.caret.index -= 1;
      return;
    }
    const found = this.parent(row);
    if (!found) return;
    const all = slots(found.row.items[found.index]!);
    const previous = all[found.slot - 1];
    this.caret = previous
      ? { row: previous, index: previous.items.length }
      : { row: found.row, index: found.index };
  }

  private moveRight() {
    const { row, index } = this.caret;
    if (index < row.items.length) {
      const first = slots(row.items[index]!)[0];
      if (first) this.caret = { row: first, index: 0 };
      else this.caret.index += 1;
      return;
    }
    const found = this.parent(row);
    if (!found) return;
    const next = slots(found.row.items[found.index]!)[found.slot + 1];
    this.caret = next
      ? { row: next, index: 0 }
      : { row: found.row, index: found.index + 1 };
  }

  /** To the slot above or below in the nearest structure that has one; up into a neighbouring exponent, down out of one. */
  private moveVertically(up: boolean) {
    let current = this.caret.row;
    for (
      let found = this.parent(current);
      found;
      found = this.parent(current)
    ) {
      const item = found.row.items[found.index]!;
      const target = slotFrom(item, found.slot, up);
      if (target !== undefined) {
        const row = slots(item)[target]!;
        this.caret = { row, index: row.items.length };
        return;
      }
      if (item.kind === 'power' && !up) {
        this.caret = { row: found.row, index: found.index + 1 };
        return;
      }
      current = found.row;
    }
    if (!up) return;
    const { row, index } = this.caret;
    const before = row.items[index - 1];
    const after = row.items[index];
    if (before?.kind === 'power')
      this.caret = {
        row: before.exponent,
        index: before.exponent.items.length,
      };
    else if (after?.kind === 'power')
      this.caret = { row: after.exponent, index: 0 };
  }

  /**
   * A symbol or an empty structure goes; a filled structure is entered from
   * its end. At the start of a first slot, the structure is taken apart and
   * its contents stay in its place.
   */
  private delete() {
    const { row, index } = this.caret;
    if (index > 0) {
      const item = row.items[index - 1]!;
      const all = slots(item);
      if (all.every((slot) => slot.items.length === 0)) {
        row.items.splice(index - 1, 1);
        this.caret.index -= 1;
      } else {
        const last = all.at(-1)!;
        this.caret = { row: last, index: last.items.length };
      }
      return;
    }
    const found = this.parent(row);
    if (!found) return;
    const all = slots(found.row.items[found.index]!);
    if (found.slot > 0) {
      const previous = all[found.slot - 1]!;
      this.caret = { row: previous, index: previous.items.length };
    } else {
      found.row.items.splice(
        found.index,
        1,
        ...all.flatMap((slot) => slot.items),
      );
      this.caret = { row: found.row, index: found.index };
    }
  }
}

// MARK: text

/** nerdamer's syntax, with `*` wherever two operands meet. */
export function rowText(row: Row, variable: string): string {
  let text = '';
  row.items.forEach((item, index) => {
    const previous = row.items[index - 1];
    if (
      previous &&
      endsOperand(previous) &&
      startsOperand(item) &&
      !(isNumeral(previous) && isNumeral(item))
    )
      text += '*';
    let piece = itemText(item, variable);
    // exponent covers whole fraction
    if (item.kind === 'fraction' && row.items[index + 1]?.kind === 'power')
      piece = `(${piece})`;
    text += piece;
  });
  return text;
}

const symbolText: Record<string, string> = {
  [times]: '*',
  [minus]: '-',
  π: 'pi',
  '∞': 'Infinity',
};

function itemText(item: Item, v: string): string {
  const t = (row: Row) => rowText(row, v);
  switch (item.kind) {
    case 'symbol':
      return symbolText[item.symbol] ?? item.symbol;
    case 'fraction':
      return `(${t(item.top)})/(${t(item.bottom)})`;
    case 'power': {
      const only = item.exponent.items[0];
      const single =
        item.exponent.items.length === 1 &&
        slots(only!).length === 0 &&
        startsOperand(only!);
      return single ? `^${t(item.exponent)}` : `^(${t(item.exponent)})`;
    }
    case 'root':
      return `sqrt(${t(item.radicand)})`;
    case 'nthRoot':
      return `nthroot(${t(item.radicand)},${t(item.index)})`;
    case 'group':
      return `(${t(item.inner)})`;
    case 'fence':
      return `${item.fence}(${t(item.inner)})`;
    case 'function':
      return `${item.name}(${item.args.map(t).join(',')})`;
    case 'logBase':
      return `log(${t(item.argument)},${t(item.base)})`;
    case 'series':
      return `${item.product ? 'product' : 'sum'}(${[item.body, item.index, item.from, item.to].map(t).join(',')})`;
    case 'integral':
      return item.lower && item.upper
        ? `defint(${t(item.body)},${t(item.lower)},${t(item.upper)},${v})`
        : `integrate(${t(item.body)},${v})`;
    case 'derivative':
      return `diff(${t(item.body)},${v})`;
    case 'limit':
      return `limit(${t(item.body)},${v},${t(item.to)})`;
    // ponytail: nerdamer has no nCr or nPr, so they go out as factorials and come back as them
    case 'binomial':
      return `(factorial(${t(item.n)})/(factorial(${t(item.r)})*factorial((${t(item.n)})-(${t(item.r)}))))`;
    case 'permutation':
      return `(factorial(${t(item.n)})/factorial((${t(item.n)})-(${t(item.r)})))`;
  }
}

/** Items for text in nerdamer's syntax; text that does not parse comes in as one symbol per character. */
export function items(text: string): Item[] {
  const node = parse(text);
  if (!node)
    return [...text]
      .filter((c) => !/\s/u.test(c))
      .map((symbol) => ({ kind: 'symbol', symbol }));
  return nodeItems(node);
}

const row = (node: Node) => new Row(nodeItems(node));

function precedence(node: Node): number {
  switch (node.k) {
    case 'relation':
    case 'list':
      return 0;
    case 'sum':
    case 'negate':
      return 1;
    case 'product':
      return 2;
    case 'power':
      return 3;
    case 'quotient':
    case 'factorial':
      return 4;
    default:
      return 5;
  }
}

function operand(node: Node, below: number): Item[] {
  return precedence(node) < below
    ? [{ kind: 'group', inner: row(node) }]
    : nodeItems(node);
}

const sym = (symbol: string): Item => ({ kind: 'symbol', symbol });

function nodeItems(node: Node): Item[] {
  switch (node.k) {
    case 'number':
      return [...node.v].map(sym);
    case 'symbol':
      return [sym({ pi: 'π', Infinity: '∞' }[node.v] ?? node.v)];
    case 'word':
      return [sym(node.v)];
    case 'hole':
      return [];
    case 'negate':
      return [sym(minus), ...operand(node.a, 2)];
    case 'sum':
      return node.items.flatMap((term, index) =>
        term.k === 'negate'
          ? [sym(minus), ...operand(term.a, 2)]
          : [...(index > 0 ? [sym('+')] : []), ...operand(term, 1)],
      );
    case 'product':
      return node.items.flatMap((factor, index) => {
        const set = operand(factor, 2);
        return index > 0 && set[0] && isNumeral(set[0])
          ? [sym(times), ...set]
          : set;
      });
    case 'quotient':
      return [{ kind: 'fraction', top: row(node.a), bottom: row(node.b) }];
    case 'power':
      return [...operand(node.a, 5), { kind: 'power', exponent: row(node.b) }];
    case 'call':
      return call(node.name, node.items);
    case 'factorial':
      return [...operand(node.a, 5), sym('!')];
    case 'relation':
      return [...nodeItems(node.a), sym(node.op), ...nodeItems(node.b)];
    case 'sub':
      return nodeItems(node.a);
    case 'derivative':
      return [{ kind: 'derivative', body: row(node.a) }];
    case 'integral':
      return [{ kind: 'integral', body: row(node.a) }];
    case 'list':
      return node.items.flatMap((entry, index) => [
        ...(index > 0 ? [sym(',')] : []),
        ...nodeItems(entry),
      ]);
    case 'group':
      return [{ kind: 'group', inner: row(node.a) }];
  }
}

function call(name: string, args: Node[]): Item[] {
  const rows = args.map(row);
  const first = rows[0] ?? new Row();
  const n = rows.length;
  if (name === 'sqrt') return [{ kind: 'root', radicand: first }];
  if (name === 'abs' || name === 'floor' || name === 'ceil')
    return [{ kind: 'fence', fence: name, inner: first }];
  if (name === 'nthroot' && n === 2)
    return [{ kind: 'nthRoot', index: rows[1]!, radicand: rows[0]! }];
  if (name === 'cbrt')
    return [{ kind: 'nthRoot', index: new Row([sym('3')]), radicand: first }];
  if (name === 'log' && n === 2)
    return [{ kind: 'logBase', base: rows[1]!, argument: rows[0]! }];
  if (name === 'factorial') return [...operand(args[0] ?? N.hole, 5), sym('!')];
  if ((name === 'sum' || name === 'product') && n === 4)
    return [
      {
        kind: 'series',
        product: name === 'product',
        index: rows[1]!,
        from: rows[2]!,
        to: rows[3]!,
        body: rows[0]!,
      },
    ];
  if (name === 'defint' && n === 4)
    return [
      { kind: 'integral', lower: rows[1]!, upper: rows[2]!, body: rows[0]! },
    ];
  if (name === 'integrate' && n === 2)
    return [{ kind: 'integral', body: rows[0]! }];
  if (name === 'diff' && n === 2)
    return [{ kind: 'derivative', body: rows[0]! }];
  if (name === 'limit' && n === 3)
    return [{ kind: 'limit', to: rows[2]!, body: rows[0]! }];
  return [{ kind: 'function', name, args: n === 0 ? [new Row()] : rows }];
}

// MARK: layout

const spaced = new Set(['+', minus, times]);
const symbolOf = (item: Item | undefined) =>
  item?.kind === 'symbol' ? item.symbol : undefined;
const italicItem = (item: Item | undefined) =>
  item?.kind === 'symbol' && isItalic(shown(item.symbol));

/** Space before `item`: around binary operators and relations, none inside a number, a hair between letters. */
function gap(row: Row, index: number, s: number, level: number): number {
  const previous = row.items[index - 1];
  const item = row.items[index]!;
  if (!previous) return 0;
  const operatorGap = level >= 2 ? s * 0.12 : s * 0.22;
  const before = symbolOf(previous);
  const own = symbolOf(item);
  if (before === '=' || own === '=') return level >= 2 ? s * 0.14 : s * 0.28;
  if (own !== undefined && spaced.has(own)) return operatorGap;
  if (before !== undefined && spaced.has(before)) {
    // sign after sign: unary
    const earlier = index >= 2 ? symbolOf(row.items[index - 2]) : '=';
    return earlier !== undefined &&
      (spaced.has(earlier) || earlier === '=' || earlier === ',')
      ? s * 0.04
      : operatorGap;
  }
  if (item.kind === 'power') return s * 0.03;
  if (before === ',') return s * 0.2;
  // sin(x) x, (a+b)(a−b)
  if (before === undefined) return s * 0.1;
  const digits = (item: Item) =>
    item.kind === 'symbol' && numeral.test(item.symbol);
  return digits(previous) && digits(item) ? 0 : s * 0.05;
}

/**
 * An edited row set with its caret stops. An empty slot shows a dashed box,
 * lit while the caret is in it.
 */
export function layoutRow(
  setter: Typesetter,
  row: Row,
  {
    level = 0,
    caret,
    variable = 'x',
    isSlot = false,
  }: { level?: number; caret?: Row; variable?: string; isSlot?: boolean } = {},
): Box {
  const s = setter.points(level);
  const script = setter.script(level);
  const slot = (r: Row, l: number) =>
    layoutRow(setter, r, { level: l, caret, variable, isSlot: true });
  // multi-term bodies show end
  const bodied = (body: Row) => {
    const terms = body.items
      .slice(1)
      .some((i) => ['+', minus, '='].includes(symbolOf(i) ?? ''));
    return terms ? setter.parens(slot(body, level), level) : slot(body, level);
  };
  const variableBox = (l: number) =>
    setter.text(variable, { italic: isItalic(variable), level: l });

  let box = new Box();
  const stops: number[] = [];
  if (row.items.length === 0) {
    if (isSlot) {
      box = setter.hole(level, caret === row ? 'accent' : undefined);
    } else {
      box.ascent = s * 0.72;
      box.descent = s * 0.2;
      stops.push(0);
    }
  }
  let previousAscent: number | undefined;
  let previousItalic = false;
  row.items.forEach((item, index) => {
    const space = gap(row, index, s, level);
    stops.push(box.width + space / 2);
    let set: Box;
    switch (item.kind) {
      case 'symbol': {
        const text = shown(item.symbol);
        set = setter.text(text, { italic: isItalic(text), level });
        break;
      }
      case 'fraction':
        set = setter.fraction(
          slot(item.top, level + 1),
          slot(item.bottom, level + 1),
          level,
        );
        break;
      case 'power':
        set = setter.raised(
          slot(item.exponent, script),
          previousAscent ?? s * 0.5,
          level,
        );
        break;
      case 'root':
        set = setter.radical(slot(item.radicand, level), level);
        break;
      case 'nthRoot':
        set = setter.indexedRadical(
          slot(item.index, script),
          slot(item.radicand, level),
          level,
        );
        break;
      case 'group':
        set = setter.parens(slot(item.inner, level), level);
        break;
      case 'fence':
        set = setter.fence(item.fence, slot(item.inner, level), level);
        break;
      case 'function': {
        const args = new Box();
        item.args.forEach((argument, i) => {
          if (i > 0) args.append(setter.text(',', { level }), s * 0.02);
          args.append(slot(argument, level), i > 0 ? s * 0.2 : 0);
        });
        set = setter
          .functionName(item.name, level)
          .append(setter.parens(args, level), s * 0.03);
        break;
      }
      case 'logBase':
        set = setter
          .logBase(slot(item.base, script), level)
          .append(setter.parens(slot(item.argument, level), level), s * 0.03);
        break;
      case 'series': {
        const below = slot(item.index, script)
          .append(setter.text('=', { level: script }), s * 0.04)
          .append(slot(item.from, script), s * 0.04);
        set = setter
          .series(item.product ? 'Π' : 'Σ', below, slot(item.to, script), level)
          .append(bodied(item.body), s * 0.1);
        break;
      }
      case 'integral':
        set = setter
          .integralSign(
            item.lower && slot(item.lower, script),
            item.upper && slot(item.upper, script),
            level,
          )
          .append(bodied(item.body), s * 0.1)
          .append(setter.differential(variableBox(level), level), s * 0.17);
        break;
      case 'derivative':
        set = setter
          .derivativeOperator(variableBox(level + 1), level)
          .append(setter.parens(slot(item.body, level), level), s * 0.1);
        break;
      case 'limit':
        set = setter
          .limitOperator(variableBox(script), slot(item.to, script), level)
          .append(bodied(item.body), s * 0.17);
        break;
      case 'binomial':
        set = setter.parens(
          setter.stacked(
            slot(item.n, level + 1),
            slot(item.r, level + 1),
            level,
          ),
          level,
        );
        break;
      case 'permutation':
        set = setter.permutation(
          slot(item.n, script),
          slot(item.r, script),
          level,
        );
        break;
    }
    const italicGap = item.kind === 'power' && previousItalic ? s * 0.04 : 0;
    box.append(set, space + italicGap);
    if (item.kind !== 'power') {
      previousAscent = set.ascent;
      previousItalic = italicItem(item);
    }
  });
  // extra gap after italics
  if (row.items.length > 0)
    stops.push(box.width + (italicItem(row.items.at(-1)) ? s * 0.1 : s * 0.04));
  const hole = box.atoms[0];
  if (row.items.length === 0 && isSlot && hole) {
    // empty slot is caret
    box.carets.push({ row, index: 0, rect: hole.frame });
  } else {
    box.carets.push(
      ...stops.map((x, index): Caret => ({
        row,
        index,
        rect: { x, y: -s * 0.78, width: 0, height: s },
      })),
    );
  }
  return box;
}
