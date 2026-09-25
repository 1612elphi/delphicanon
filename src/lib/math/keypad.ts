import {
  Expression,
  layoutRow,
  Row,
  type Item,
  type Key,
} from './expression.ts';
import { isItalic } from './node.ts';
import { Box, Typesetter, type Metrics } from './typeset.ts';

/**
 * Key colours by family, from the Braun ET66: cream digit keys, dark umber
 * operator keys and one yellow key, Done. The tinted families keep their
 * colour on every page.
 */
export type Family =
  | 'digit'
  | 'operation'
  | 'structure'
  | 'calculus'
  | 'letter'
  | 'clear'
  | 'done';

const operationSigns = ['+', '−', '×', '=', ','];

/** The family a key belongs to wherever it appears, for keys placed outside the keypad. */
export function familyOf(key: Key): Family {
  switch (key.kind) {
    case 'symbol':
      if (/^[\p{N}.]*$/u.test(key.symbol)) return 'digit';
      if (operationSigns.includes(key.symbol)) return 'operation';
      return key.symbol === '!' ? 'calculus' : 'letter';
    case 'series':
    case 'integral':
    case 'derivative':
    case 'limit':
    case 'binomial':
    case 'permutation':
      return 'calculus';
    case 'divide':
    case 'delete':
      return 'operation';
    case 'clear':
      return 'clear';
    default:
      return 'structure';
  }
}

export interface Spec {
  key: Key;
  family: Family;
  /** Column, row, and width and height in cells. */
  x: number;
  y: number;
  w: number;
  h: number;
  scale: number;
  /** A submenu key: its label, and the keys it offers. */
  menu?: { title: string; keys: Key[] };
}

export const columns = 6;
export const rows = 4;
/** Key height, and the height on a short screen. */
export const keyHeights = { regular: 54, short: 44 };
export const tabHeights = { regular: 40, short: 34 };
/** Label size as a share of the key height. */
export const labelShare = 0.44;
/** Label scale for names and function keys, so a row of names shares one size. */
export const nameScale = 0.82;
/** Label scale for a submenu key's title. */
export const menuScale = 0.72;
/** Width of the spine column (delete, clear, Done), in page columns. */
export const spineWeight = 1.15;
/** Page spring: seconds per swing and damping ratio. */
export const glideSpring = { response: 0.46, damping: 0.84 };
/** Seconds before a slot key typed on a later page returns to the numbers. */
export const returnDelay = 0.22;

export function keypadHeight(short: boolean): number {
  const key = short ? keyHeights.short : keyHeights.regular;
  return (short ? tabHeights.short : tabHeights.regular) + rows + key * rows;
}

/** Letters offered, the variable first. */
export function letters(variable: string): string[] {
  return [
    variable,
    ...['x', 'y', 'z', 't', 'n', 'k', 'a', 'b', 'c', 'm', 'p', 'r', 's'].filter(
      (l) => l !== variable,
    ),
  ].slice(0, 12);
}

const pi = 'π';
const infinity = '∞';

/** The four pages. `x`, `y`, `w` and `h` place a key on the page's six by four grid. */
export function pages(variable: string): Spec[][] {
  const ls = letters(variable);
  const key = (
    key: Key,
    family: Family,
    x: number,
    y: number,
    { w = 1, h = 1, scale = 1 } = {},
  ): Spec => ({ key, family, x, y, w, h, scale });
  const symbol = (s: string): Key => ({ kind: 'symbol', symbol: s });
  const digit = (d: number, x: number, y: number, w = 1) =>
    key(symbol(String(d)), 'digit', x, y, { w, scale: 1.1 });
  const sign = (s: string, x: number, y: number, w = 1) =>
    key(symbol(s), 'operation', x, y, { w, scale: 1.2 });
  const name = (k: Key, family: Family, x: number, y: number) =>
    key(k, family, x, y, { scale: nameScale });
  const fn = (
    n: string,
    x: number,
    y: number,
    {
      arity = 1,
      family = 'structure',
      w = 1,
    }: { arity?: number; family?: Family; w?: number } = {},
  ) =>
    key({ kind: 'function', name: n, arity }, family, x, y, {
      w,
      scale: nameScale,
    });
  const menu = (title: string, names: string[], x: number, y: number): Spec => {
    const keys = names.map((n): Key => ({
      kind: 'function',
      name: n,
      arity: 1,
    }));
    return {
      ...key(keys[0]!, 'structure', x, y, { w: 3 }),
      menu: { title, keys },
    };
  };
  const numbers = [
    key({ kind: 'fraction' }, 'structure', 0, 0),
    digit(7, 1, 0),
    digit(8, 2, 0),
    digit(9, 3, 0),
    key({ kind: 'divide' }, 'operation', 4, 0, { scale: 1.2 }),
    key({ kind: 'open' }, 'structure', 5, 0),
    key({ kind: 'square' }, 'structure', 0, 1),
    digit(4, 1, 1),
    digit(5, 2, 1),
    digit(6, 3, 1),
    sign('×', 4, 1),
    key(symbol(ls[0]!), 'letter', 5, 1, { scale: 1.1 }),
    key({ kind: 'root' }, 'structure', 0, 2),
    digit(1, 1, 2),
    digit(2, 2, 2),
    digit(3, 3, 2),
    sign('−', 4, 2),
    key(symbol(pi), 'letter', 5, 2, { scale: 1.1 }),
    key({ kind: 'power' }, 'structure', 0, 3),
    digit(0, 1, 3, 2),
    key(symbol('.'), 'digit', 3, 3, { scale: 1.1 }),
    sign('+', 4, 3),
    sign('=', 5, 3),
  ];
  const functions = [
    fn('sin', 0, 0),
    fn('cos', 1, 0),
    fn('tan', 2, 0),
    fn('log', 3, 0),
    fn('log10', 4, 0),
    name({ kind: 'logBase' }, 'structure', 5, 0),
    fn('asin', 0, 1),
    fn('acos', 1, 1),
    fn('atan', 2, 1),
    name({ kind: 'exponential', base: 'e' }, 'structure', 3, 1),
    name({ kind: 'exponential', base: '10' }, 'structure', 4, 1),
    name({ kind: 'inverse' }, 'structure', 5, 1),
    name({ kind: 'cube' }, 'structure', 0, 2),
    name({ kind: 'cubeRoot' }, 'structure', 1, 2),
    name({ kind: 'nthRoot' }, 'structure', 2, 2),
    name({ kind: 'fence', fence: 'abs' }, 'structure', 3, 2),
    name({ kind: 'fence', fence: 'floor' }, 'structure', 4, 2),
    name({ kind: 'fence', fence: 'ceil' }, 'structure', 5, 2),
    menu(
      'sinh cosh tanh',
      ['sinh', 'cosh', 'tanh', 'asinh', 'acosh', 'atanh'],
      0,
      3,
    ),
    menu('sec csc cot', ['sec', 'csc', 'cot', 'asec', 'acsc', 'acot'], 3, 3),
  ];
  const tall = { h: 2, scale: 1.3 };
  const calculus = [
    key({ kind: 'derivative' }, 'calculus', 0, 0, tall),
    key({ kind: 'integral', bounded: false }, 'calculus', 1, 0, tall),
    key({ kind: 'integral', bounded: true }, 'calculus', 2, 0, tall),
    key({ kind: 'limit' }, 'calculus', 3, 0, tall),
    key({ kind: 'series', product: false }, 'calculus', 4, 0, tall),
    key({ kind: 'series', product: true }, 'calculus', 5, 0, tall),
    name(symbol('!'), 'calculus', 0, 2),
    name({ kind: 'binomial' }, 'calculus', 1, 2),
    name({ kind: 'permutation' }, 'calculus', 2, 2),
    fn('mod', 3, 2, { arity: 2, family: 'calculus' }),
    fn('gcd', 4, 2, { arity: 2, family: 'calculus' }),
    fn('lcm', 5, 2, { arity: 2, family: 'calculus' }),
    fn('min', 0, 3, { arity: 2, family: 'calculus' }),
    fn('max', 1, 3, { arity: 2, family: 'calculus' }),
    fn('round', 2, 3, { family: 'calculus', w: 2 }),
    key(symbol(infinity), 'calculus', 4, 3, { w: 2, scale: 1.2 }),
  ];
  const greek = ['theta', 'alpha', 'beta', 'lambda', 'mu', 'omega'];
  const variables = [
    ...ls.map((l, i) =>
      key(symbol(l), 'letter', i % 6, Math.floor(i / 6), { scale: 1.1 }),
    ),
    ...greek.map((g, i) => key(symbol(g), 'letter', i, 2, { scale: 1.1 })),
    key(symbol(pi), 'letter', 0, 3, { scale: 1.1 }),
    key(symbol('e'), 'letter', 1, 3, { scale: 1.1 }),
    key(symbol('i'), 'letter', 2, 3, { scale: 1.1 }),
    key(symbol(infinity), 'letter', 3, 3, { scale: 1.1 }),
    sign('=', 4, 3, 2),
  ];
  return [numbers, functions, calculus, variables];
}

/** A key's one label at `size`: its symbol or its name, with letters where the key opens slots. */
export function label(
  key: Key,
  variable: string,
  size: number,
  metrics: Metrics,
): Box {
  const setter = new Typesetter(metrics, size, 'result');
  const row = (items: Item[]) =>
    layoutRow(setter, new Row(items), { variable });
  const sym = (symbol: string): Item => ({ kind: 'symbol', symbol });
  const letters = (text: string) => new Row([...text].map(sym));
  const italic = (text: string) => setter.text(text, { italic: true });
  switch (key.kind) {
    case 'symbol':
      return key.symbol === '!'
        ? row([sym('n'), sym('!')])
        : row([sym(key.symbol)]);
    case 'fraction':
      return row([
        { kind: 'fraction', top: letters('a'), bottom: letters('b') },
      ]);
    case 'divide':
      return setter.text('÷');
    case 'power':
      return row([sym('x'), { kind: 'power', exponent: letters('y') }]);
    case 'square':
      return row([sym('x'), { kind: 'power', exponent: letters('2') }]);
    case 'cube':
      return row([sym('x'), { kind: 'power', exponent: letters('3') }]);
    case 'inverse':
      return row([
        sym('x'),
        { kind: 'power', exponent: new Row([sym('−'), sym('1')]) },
      ]);
    case 'root':
      return row([{ kind: 'root', radicand: letters('x') }]);
    case 'cubeRoot':
      return row([
        { kind: 'nthRoot', index: letters('3'), radicand: letters('x') },
      ]);
    case 'nthRoot':
      return row([
        { kind: 'nthRoot', index: letters('n'), radicand: letters('x') },
      ]);
    case 'logBase':
      return setter.logBase(setter.text('b', { italic: true, level: 2 }), 0);
    case 'exponential':
      return row([
        ...[...key.base].map(sym),
        { kind: 'power', exponent: letters('x') },
      ]);
    case 'scientific': {
      const box = setter.text('×10');
      return box.append(
        setter.raised(
          setter.text('n', { italic: true, level: 2 }),
          box.ascent,
          0,
        ),
        size * 0.04,
      );
    }
    case 'open':
      return setter.text('( )');
    case 'close':
      return setter.text(')');
    case 'fence':
      return row([{ kind: 'fence', fence: key.fence, inner: letters('x') }]);
    case 'function':
      return setter.functionName(key.name, 0);
    case 'series':
      return setter.text(key.product ? 'Π' : 'Σ', { scale: 1.1 });
    case 'integral': {
      const bound = (l: string) =>
        key.bounded ? setter.text(l, { italic: true, level: 2 }) : undefined;
      return setter.integralSign(bound('a'), bound('b'), 0);
    }
    case 'derivative':
      return setter.derivativeOperator(
        setter.text(variable, { italic: isItalic(variable), level: 1 }),
        0,
      );
    case 'limit':
      return setter.text('lim');
    case 'binomial':
    case 'permutation':
      return italic('n')
        .append(setter.text(key.kind === 'binomial' ? 'C' : 'P'), size * 0.03)
        .append(italic('r'), size * 0.03);
    case 'clear':
      return setter.text('AC');
    default:
      return new Box();
  }
}

const spokenNames: Partial<Record<string, string>> = {
  'symbol:×': 'Multiply',
  divide: 'Divide',
  'symbol:!': 'Factorial',
  'symbol:π': 'Pi',
  fraction: 'Fraction',
  power: 'Power',
  square: 'Square',
  root: 'Square root',
  'fence:abs': 'Absolute value',
  clear: 'Clear',
};

/** What a screen reader reads for a key. */
export function spoken(key: Key, variable: string): string {
  const id =
    key.kind === 'symbol'
      ? `symbol:${key.symbol}`
      : key.kind === 'fence'
        ? `fence:${key.fence}`
        : key.kind;
  const named = spokenNames[id];
  if (named) return named;
  const typed = new Expression('', variable);
  typed.apply(key);
  return typed.text.replaceAll('()', '').replaceAll('(,)', '');
}

const typedSigns: Record<string, Key> = {
  '+': { kind: 'symbol', symbol: '+' },
  '-': { kind: 'symbol', symbol: '−' },
  '*': { kind: 'symbol', symbol: '×' },
  '=': { kind: 'symbol', symbol: '=' },
  ',': { kind: 'symbol', symbol: ',' },
  '!': { kind: 'symbol', symbol: '!' },
  '.': { kind: 'symbol', symbol: '.' },
  '/': { kind: 'divide' },
  '^': { kind: 'power' },
  '(': { kind: 'open' },
  ')': { kind: 'close' },
  '|': { kind: 'fence', fence: 'abs' },
  ArrowLeft: { kind: 'left' },
  ArrowRight: { kind: 'right' },
  ArrowUp: { kind: 'up' },
  ArrowDown: { kind: 'down' },
  Backspace: { kind: 'delete' },
};

/** The key a physical keyboard's `KeyboardEvent.key` types: digits, signs, letters, arrows and Backspace. */
export function keyForKeyboard(name: string): Key | undefined {
  if (typedSigns[name]) return typedSigns[name];
  if (/^[0-9a-zA-Z]$/.test(name)) return { kind: 'symbol', symbol: name };
  return undefined;
}
