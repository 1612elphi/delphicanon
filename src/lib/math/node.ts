/** Expressions in nerdamer's syntax as a tree (CanonMath.Node). */
export type Node =
  | { k: 'number'; v: string }
  /** Italic when it is a letter; `pi` and `Infinity` show as signs. */
  | { k: 'symbol'; v: string }
  /** Upright text: an operator's `d`, a relation's empty side. */
  | { k: 'word'; v: string }
  /** A missing operand in unfinished input. */
  | { k: 'hole' }
  | { k: 'negate'; a: Node }
  /** Terms; a subtracted term is a `negate`. */
  | { k: 'sum'; items: Node[] }
  | { k: 'product'; items: Node[] }
  | { k: 'quotient'; a: Node; b: Node }
  | { k: 'power'; a: Node; b: Node }
  | { k: 'call'; name: string; items: Node[] }
  | { k: 'factorial'; a: Node }
  | { k: 'relation'; op: string; a: Node; b: Node }
  | { k: 'sub'; a: Node; v: string }
  | { k: 'list'; items: Node[] }
  /** Always in parentheses. */
  | { k: 'group'; a: Node }
  | { k: 'derivative'; a: Node; v: string }
  | { k: 'integral'; a: Node; v: string };

export type Fence = 'abs' | 'floor' | 'ceil';

export const N = {
  number: (v: string): Node => ({ k: 'number', v }),
  symbol: (v: string): Node => ({ k: 'symbol', v }),
  word: (v: string): Node => ({ k: 'word', v }),
  hole: { k: 'hole' } as Node,
  negate: (a: Node): Node => ({ k: 'negate', a }),
  sum: (items: Node[]): Node => ({ k: 'sum', items }),
  product: (items: Node[]): Node => ({ k: 'product', items }),
  quotient: (a: Node, b: Node): Node => ({ k: 'quotient', a, b }),
  power: (a: Node, b: Node): Node => ({ k: 'power', a, b }),
  call: (name: string, items: Node[]): Node => ({ k: 'call', name, items }),
  factorial: (a: Node): Node => ({ k: 'factorial', a }),
  relation: (op: string, a: Node, b: Node): Node => ({
    k: 'relation',
    op,
    a,
    b,
  }),
  sub: (a: Node, v: string): Node => ({ k: 'sub', a, v }),
  list: (items: Node[]): Node => ({ k: 'list', items }),
  group: (a: Node): Node => ({ k: 'group', a }),
  derivative: (a: Node, v: string): Node => ({ k: 'derivative', a, v }),
  integral: (a: Node, v: string): Node => ({ k: 'integral', a, v }),
};

export function same(a: Node, b: Node): boolean {
  return JSON.stringify(a) === JSON.stringify(b);
}

export const functions = new Set([
  'sin',
  'cos',
  'tan',
  'sec',
  'csc',
  'cot',
  'asin',
  'acos',
  'atan',
  'sinh',
  'cosh',
  'tanh',
  'log',
  'ln',
  'log10',
  'exp',
  'sqrt',
  'abs',
]);

/** Calls set as their own notation, with no function spacing. */
export const structural = new Set([
  'sqrt',
  'abs',
  'floor',
  'ceil',
  'nthroot',
  'cbrt',
  'factorial',
  'sum',
  'product',
  'defint',
  'integrate',
  'diff',
  'limit',
]);

/** Inverse functions, set as the function with a raised −1. */
export const inverses = new Set([
  'asin',
  'acos',
  'atan',
  'asec',
  'acsc',
  'acot',
  'asinh',
  'acosh',
  'atanh',
]);

const signs: Record<string, string> = {
  pi: 'π',
  Infinity: '∞',
  alpha: 'α',
  beta: 'β',
  gamma: 'γ',
  delta: 'δ',
  epsilon: 'ε',
  theta: 'θ',
  lambda: 'λ',
  mu: 'μ',
  sigma: 'σ',
  tau: 'τ',
  phi: 'φ',
  omega: 'ω',
};

export function shown(symbol: string): string {
  return signs[symbol] ?? symbol;
}

const letter = /^\p{L}$/u;
export const isLetter = (c: string | undefined) =>
  c !== undefined && letter.test(c);

/** Letters are italic; constants shown as signs (π, ∞, ∅) are upright. */
export function isItalic(text: string): boolean {
  return (
    !['π', '∞', '∅'].includes(text) &&
    [...text].every((c) => isLetter(c))
  );
}

// MARK: parsing

type Token =
  | { t: 'number'; v: string }
  | { t: 'name'; v: string }
  | { t: 'op'; v: string };

const digit = (c: string) => (c >= '0' && c <= '9') || c === '.';
const nameChar = (c: string) => isLetter(c) || c === '_' || (c >= '0' && c <= '9');

function tokenise(text: string): Token[] {
  const chars = [...text];
  const tokens: Token[] = [];
  let i = 0;
  const scan = (test: (c: string) => boolean) => {
    const start = i;
    while (i < chars.length && test(chars[i]!)) i += 1;
    return chars.slice(start, i).join('');
  };
  while (i < chars.length) {
    const c = chars[i]!;
    if (/\s/u.test(c)) {
      i += 1;
    } else if (digit(c)) {
      tokens.push({ t: 'number', v: scan(digit) });
    } else if (isLetter(c) || c === '_') {
      tokens.push({ t: 'name', v: scan(nameChar) });
    } else {
      i += 1;
      if (c === '−') tokens.push({ t: 'op', v: '-' });
      else if (['×', '·', '⋅'].includes(c))
        tokens.push({ t: 'op', v: '*' });
      else if (c === '÷') tokens.push({ t: 'op', v: '/' });
      else if (c === '√') tokens.push({ t: 'name', v: 'sqrt' });
      else tokens.push({ t: 'op', v: c });
    }
  }
  return tokens;
}

class Parser {
  at = 0;
  constructor(private tokens: Token[]) {}

  private get peek(): Token | undefined {
    return this.tokens[this.at];
  }

  private take(op: string): boolean {
    const p = this.peek;
    if (p?.t !== 'op' || p.v !== op) return false;
    this.at += 1;
    return true;
  }

  /** Starts an operand that may follow another with no sign between: `2x`, `2(x+1)`. */
  private get startsImplicitFactor(): boolean {
    const p = this.peek;
    if (!p) return false;
    return p.t !== 'op' || p.v === '(' || p.v === '[';
  }

  statement(): Node {
    const left = this.expression();
    return this.take('=') ? N.relation('=', left, this.expression()) : left;
  }

  private expression(): Node {
    const terms = [this.term()];
    for (;;) {
      if (this.take('+')) terms.push(this.term());
      else if (this.take('-')) terms.push(N.negate(this.term()));
      else break;
    }
    return terms.length === 1 ? terms[0]! : N.sum(terms);
  }

  private term(): Node {
    let node = this.unary();
    for (;;) {
      if (this.take('*')) node = multiply(node, this.unary());
      else if (this.take('/')) node = N.quotient(node, this.unary());
      else if (this.startsImplicitFactor) node = multiply(node, this.power());
      else return node;
    }
  }

  private unary(): Node {
    if (this.take('-')) return N.negate(this.unary());
    if (this.take('+')) return this.unary();
    return this.power();
  }

  // right associative
  private power(): Node {
    const base = this.postfix();
    return this.take('^') ? N.power(base, this.unary()) : base;
  }

  private postfix(): Node {
    let node = this.primary();
    while (this.take('!')) node = N.factorial(node);
    return node;
  }

  private primary(): Node {
    const p = this.peek;
    if (p?.t === 'number') {
      this.at += 1;
      return N.number(p.v);
    }
    if (p?.t === 'name') {
      this.at += 1;
      if (this.take('(')) return N.call(p.v, this.arguments(')'));
      if (functions.has(p.v) && this.startsImplicitFactor)
        return N.call(p.v, [this.power()]);
      return N.symbol(p.v);
    }
    if (this.take('(')) {
      const inner = this.statement();
      this.take(')');
      return inner;
    }
    if (this.take('[')) return N.list(this.arguments(']'));
    if (this.take('|')) {
      const inner = this.expression();
      this.take('|');
      return N.call('abs', [inner]);
    }
    return N.hole;
  }

  private arguments(closing: string): Node[] {
    if (this.take(closing)) return [];
    const items = [this.statement()];
    while (this.take(',')) items.push(this.statement());
    this.take(closing);
    return items;
  }
}

function multiply(left: Node, right: Node): Node {
  return left.k === 'product'
    ? N.product([...left.items, right])
    : N.product([left, right]);
}

/**
 * The tree of `text`; undefined when there is nothing, or when input is left
 * over that does not parse, such as an unopened bracket. An operand still to
 * be typed is a hole, a bracket still open is closed.
 */
export function parse(text: string): Node | undefined {
  const tokens = tokenise(text);
  if (tokens.length === 0) return undefined;
  const parser = new Parser(tokens);
  const node = parser.statement();
  return parser.at === tokens.length ? node : undefined;
}

// MARK: presentation

const constants = new Set(['e', 'pi', 'i', 'Infinity']);
const half = N.quotient(N.number('1'), N.number('2'));
const one = N.number('1');

/**
 * A result as it is written by hand: powers of the variable falling, a
 * positive term first, negative powers and rational coefficients as
 * fractions, a power of a half as a root. Typed input is set as typed instead.
 */
export function present(node: Node): Node {
  switch (node.k) {
    case 'sum': {
      const flat: Node[] = [];
      for (const term of node.items.map(present)) {
        if (term.k === 'sum') flat.push(...term.items);
        else flat.push(term);
      }
      const ordered = flat
        .map((n, i) => ({ n, i, d: degree(n) }))
        .sort((a, b) => (a.d !== b.d ? b.d - a.d : a.i - b.i))
        .map((e) => e.n);
      if (isNegative(ordered[0]!)) {
        const positive = ordered.findIndex((n) => !isNegative(n));
        if (positive >= 0) ordered.unshift(...ordered.splice(positive, 1));
      }
      return N.sum(ordered);
    }
    case 'product':
      return product(node.items.map(present));
    case 'power': {
      const base = present(node.a);
      const exponent = present(node.b);
      if (same(exponent, half)) return N.call('sqrt', [base]);
      if (exponent.k === 'negate') {
        const inner = exponent.a;
        const denominator = same(inner, one)
          ? base
          : same(inner, half)
            ? N.call('sqrt', [base])
            : N.power(base, inner);
        return N.quotient(one, denominator);
      }
      return N.power(base, exponent);
    }
    case 'negate': {
      const inner = present(node.a);
      return inner.k === 'negate' ? inner.a : N.negate(inner);
    }
    case 'quotient':
      return product([N.quotient(present(node.a), present(node.b))]);
    case 'call':
      return N.call(node.name, node.items.map(present));
    case 'factorial':
      return N.factorial(present(node.a));
    case 'relation':
      return N.relation(node.op, present(node.a), present(node.b));
    case 'list':
      return N.list(node.items.map(present));
    default:
      return node;
  }
}

/** Factors split over a fraction bar, with the sign pulled out front and numbers before letters before functions. */
function product(factors: Node[]): Node {
  let negative = false;
  const top: Node[] = [];
  const bottom: Node[] = [];
  const queue = [...factors];
  while (queue.length > 0) {
    let factor = queue.shift()!;
    while (factor.k === 'negate') {
      negative = !negative;
      factor = factor.a;
    }
    if (factor.k === 'product') {
      queue.unshift(...factor.items);
    } else if (factor.k === 'quotient') {
      let above = factor.a;
      while (above.k === 'negate') {
        negative = !negative;
        above = above.a;
      }
      if (above.k === 'product') top.push(...above.items);
      else if (!same(above, one)) top.push(above);
      if (factor.b.k === 'product') bottom.push(...factor.b.items);
      else bottom.push(factor.b);
    } else {
      top.push(factor);
    }
  }
  const joined = (nodes: Node[]): Node => {
    const ordered = nodes
      .map((n, i) => ({ n, i, r: rank(n) }))
      .sort((a, b) => (a.r !== b.r ? a.r - b.r : a.i - b.i))
      .map((e) => e.n);
    if (ordered.length === 0) return one;
    return ordered.length === 1 ? ordered[0]! : N.product(ordered);
  };
  const body =
    bottom.length === 0 ? joined(top) : N.quotient(joined(top), joined(bottom));
  return negative ? N.negate(body) : body;
}

function rank(node: Node): number {
  if (node.k === 'number') return 0;
  if (node.k === 'symbol' && !constants.has(node.v)) return 1;
  if (
    node.k === 'power' &&
    node.a.k === 'symbol' &&
    node.b.k === 'number' &&
    !constants.has(node.a.v)
  )
    return 1;
  if (node.k === 'sum') return 3;
  return 2;
}

function isNegative(node: Node): boolean {
  return node.k === 'negate';
}

function value(node: Node): number | undefined {
  switch (node.k) {
    case 'number':
      return Number(node.v);
    case 'negate': {
      const v = value(node.a);
      return v === undefined ? undefined : -v;
    }
    case 'quotient': {
      const top = value(node.a);
      const bottom = value(node.b);
      return top === undefined || bottom === undefined
        ? undefined
        : top / bottom;
    }
    default:
      return undefined;
  }
}

/** Total power of the letters in a term; constants and functions count nothing. */
export function degree(node: Node): number {
  switch (node.k) {
    case 'symbol':
      return constants.has(node.v) ? 0 : 1;
    case 'negate':
    case 'factorial':
      return degree(node.a);
    case 'product':
      return node.items.reduce((sum, n) => sum + degree(n), 0);
    case 'quotient':
      return degree(node.a) - degree(node.b);
    case 'power': {
      const v = value(node.b);
      return v === undefined ? 0 : degree(node.a) * v;
    }
    case 'call':
      return node.name === 'sqrt' && node.items[0]
        ? degree(node.items[0]) / 2
        : 0;
    case 'sum':
      return node.items.length ? Math.max(...node.items.map(degree)) : 0;
    default:
      return 0;
  }
}
