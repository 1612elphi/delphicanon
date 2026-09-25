import { module, test } from 'qunit';
import { N, parse, present, same } from '#src/lib/math/node.ts';
import {
  Expression,
  layoutRow,
  opensSlot,
  type Key,
} from '#src/lib/math/expression.ts';
import { Typesetter, type Metrics } from '#src/lib/math/typeset.ts';
import {
  columns,
  familyOf,
  label,
  letters,
  pages,
  rows,
  spoken,
} from '#src/lib/math/keypad.ts';
import { eased, grown, keyed } from '#src/lib/math/morph.ts';

/** Every glyph half an em wide, 0.7 em tall, nothing below the baseline. */
const metrics: Metrics = {
  measure: (text, _italic, size) => ({
    width: [...text].length * size * 0.5,
    ascent: size * 0.7,
    descent: 0,
  }),
  xHeight: (size) => size * 0.45,
};

const x = N.symbol('x');
const close = (a: number, b: number) => Math.abs(a - b) < 1e-9;

function typed(keys: Key[], variable = 'x'): Expression {
  const expression = new Expression('', variable);
  keys.forEach((key) => expression.apply(key));
  return expression;
}
const s = (symbol: string): Key => ({ kind: 'symbol', symbol });

module('Unit | lib/math', function () {
  test('parses nerdamer syntax', function (assert) {
    assert.deepEqual(
      parse('x^2 - 4 = 0'),
      N.relation(
        '=',
        N.sum([N.power(x, N.number('2')), N.negate(N.number('4'))]),
        N.number('0'),
      ),
    );
    assert.deepEqual(parse('2x'), N.product([N.number('2'), x]));
    assert.deepEqual(parse('sin x'), N.call('sin', [x]));
    assert.deepEqual(parse('(x+1'), N.sum([x, N.number('1')]));
    assert.deepEqual(parse('x^'), N.power(x, N.hole));
    assert.strictEqual(parse('x)'), undefined);
    assert.strictEqual(parse('  '), undefined);
  });

  test('presents results as written by hand', function (assert) {
    const p = (text: string) => present(parse(text)!);
    assert.deepEqual(p('b*c^(-1)'), N.quotient(N.symbol('b'), N.symbol('c')));
    assert.deepEqual(
      p('(1/2)*x^(-1/2)'),
      N.quotient(N.number('1'), N.product([N.number('2'), N.call('sqrt', [x])])),
    );
    assert.deepEqual(
      p('-x^(-2)'),
      N.negate(N.quotient(N.number('1'), N.power(x, N.number('2')))),
    );
    assert.deepEqual(
      p('1+3*x+x^2'),
      N.sum([
        N.power(x, N.number('2')),
        N.product([N.number('3'), x]),
        N.number('1'),
      ]),
    );
    assert.deepEqual(
      p('-b^2+a^2'),
      N.sum([
        N.power(N.symbol('a'), N.number('2')),
        N.negate(N.power(N.symbol('b'), N.number('2'))),
      ]),
    );
    assert.deepEqual(
      p('2*e^x*x'),
      N.product([N.number('2'), x, N.power(N.symbol('e'), x)]),
    );
  });

  test('every slot kind round trips through nerdamer syntax', function (assert) {
    for (const text of [
      '(x+1)^2 - x^2',
      'sin(x)^2 + cos(x)^2',
      '(a*b)/(a*c)',
      'x^2 + 5*x + 6',
      '2*x + 3 = 7',
      'e^x * x^2',
      '1/x',
      'sqrt(x)+abs(x-1)',
      'x^(-1/2)',
      '-x^2',
      '2*3',
      'nthroot(x,3)+log(8,2)+floor(x)+ceil(x/2)',
      'sum(k^2,k,1,n)',
      'product(k,k,1,5)',
      'defint(x^2,0,3,x)',
      'integrate(sin(x),x)',
      'diff(sin(x),x)',
      'limit(1/x,x,Infinity)',
      'asin(x)+log10(x)+log(x)',
      'gcd(12,18)',
      '(x+1)*(x-1)',
      'x!+3',
    ]) {
      const round = new Expression(text).text;
      assert.true(
        same(parse(round)!, parse(text)!),
        `${text} came back as ${round}`,
      );
    }
  });

  test('keys type the slot kinds', function (assert) {
    const cases: [Key[], string][] = [
      [[{ kind: 'fraction' }, s('1'), { kind: 'down' }, s('2')], '(1)/(2)'],
      [[s('x'), { kind: 'power' }, s('2')], 'x^2'],
      [[s('x'), { kind: 'square' }], 'x^2'],
      [[s('x'), { kind: 'inverse' }], 'x^(-1)'],
      [[{ kind: 'root' }, s('2')], 'sqrt(2)'],
      [[{ kind: 'cubeRoot' }, s('8')], 'nthroot(8,3)'],
      [[{ kind: 'nthRoot' }, s('4'), { kind: 'right' }, s('x')], 'nthroot(x,4)'],
      [[{ kind: 'logBase' }, s('2'), { kind: 'right' }, s('8')], 'log(8,2)'],
      [[{ kind: 'exponential', base: 'e' }, s('x')], 'e^x'],
      [[s('2'), { kind: 'scientific' }, s('3')], '2*10^3'],
      [[{ kind: 'series', product: false }, s('1'), { kind: 'up' }, s('n'), { kind: 'right' }, s('k')], 'sum(k,k,1,n)'],
      [[{ kind: 'series', product: true }, s('1'), { kind: 'up' }, s('5'), { kind: 'right' }, s('k')], 'product(k,k,1,5)'],
      [[{ kind: 'integral', bounded: false }, s('x')], 'integrate(x,x)'],
      [[{ kind: 'integral', bounded: true }, s('0'), { kind: 'up' }, s('1'), { kind: 'right' }, s('x')], 'defint(x,0,1,x)'],
      [[{ kind: 'derivative' }, s('x')], 'diff(x,x)'],
      [[{ kind: 'limit' }, s('0'), { kind: 'right' }, s('x')], 'limit(x,x,0)'],
      [[{ kind: 'fence', fence: 'abs' }, s('x')], 'abs(x)'],
      [[{ kind: 'fence', fence: 'floor' }, s('x')], 'floor(x)'],
      [[{ kind: 'fence', fence: 'ceil' }, s('x')], 'ceil(x)'],
      [[{ kind: 'open' }, s('x'), { kind: 'close' }, s('2')], '(x)*2'],
      [[{ kind: 'function', name: 'gcd', arity: 2 }, s('4'), { kind: 'right' }, s('6')], 'gcd(4,6)'],
      [[{ kind: 'binomial' }, s('5'), { kind: 'right' }, s('2')], '(factorial(5)/(factorial(2)*factorial((5)-(2))))'],
      [[{ kind: 'permutation' }, s('5'), { kind: 'right' }, s('2')], '(factorial(5)/factorial((5)-(2)))'],
    ];
    for (const [keys, text] of cases) assert.strictEqual(typed(keys).text, text);
  });

  test('nCr and nPr come back as factorials that keep their value', function (assert) {
    for (const keys of [
      [{ kind: 'binomial' }, s('n'), { kind: 'right' }, s('r')],
      [{ kind: 'permutation' }, s('n'), { kind: 'right' }, s('r')],
    ] as Key[][]) {
      const once = new Expression(typed(keys).text).text;
      assert.strictEqual(new Expression(once).text, once, once);
      assert.true(once.includes('!'), once);
    }
  });

  test('edits and caret moves as on iOS', function (assert) {
    const e = typed([
      s('x'),
      { kind: 'power' },
      s('2'),
      { kind: 'right' },
      s('+'),
      s('1'),
      { kind: 'divide' },
      s('2'),
    ]);
    assert.strictEqual(e.text, 'x^2+(1)/(2)');
    e.apply({ kind: 'delete' });
    assert.strictEqual(e.text, 'x^2+(1)/()');
    for (let i = 0; i < 3; i += 1) e.apply({ kind: 'delete' });
    assert.strictEqual(e.text, 'x^2+');
    e.apply({ kind: 'left' });
    e.apply({ kind: 'left' });
    e.apply(s('3'));
    assert.strictEqual(e.text, 'x^(23)+');
    assert.strictEqual(
      typed([s('2'), { kind: 'open' }, s('x'), { kind: 'close' }, { kind: 'square' }]).text,
      '2*(x)^2',
    );
    const calculus = typed(
      [
        { kind: 'series', product: false },
        s('1'),
        { kind: 'up' },
        s('5'),
        { kind: 'right' },
        s('k'),
        { kind: 'right' },
        s('+'),
        { kind: 'integral', bounded: true },
        s('0'),
        { kind: 'up' },
        s('1'),
        { kind: 'right' },
        s('t'),
      ],
      't',
    );
    assert.strictEqual(calculus.text, 'sum(k,k,1,5)+defint(t,0,1,t)');
    assert.true(opensSlot({ kind: 'fraction' }));
    assert.false(opensSlot({ kind: 'square' }));
    assert.false(opensSlot(s('x')));
  });

  test('caret walks into and out of slots', function (assert) {
    const e = new Expression('(1)/(2)+x');
    assert.strictEqual(e.caret.index, 3);
    e.apply({ kind: 'left' });
    e.apply({ kind: 'left' });
    e.apply({ kind: 'left' });
    assert.strictEqual(e.caret.row.items.length, 1, 'inside the denominator');
    e.apply({ kind: 'up' });
    e.apply(s('0'));
    assert.strictEqual(e.text, '(10)/(2)+x');
    e.apply({ kind: 'down' });
    e.apply({ kind: 'right' });
    assert.strictEqual(e.caret.row, e.root);
    assert.strictEqual(e.caret.index, 1);
    e.apply({ kind: 'delete' });
    assert.strictEqual(e.text, '(10)/(2)+x', 'delete enters a filled fraction');
    e.apply({ kind: 'clear' });
    assert.strictEqual(e.text, '');
    assert.strictEqual(e.caret.index, 0);
  });

  test('box metrics follow the iOS typesetter', function (assert) {
    const setter = new Typesetter(metrics, 20);
    const one = setter.layout(N.number('1'));
    assert.true(close(one.width, 10));
    assert.true(close(one.ascent, 14));
    const fraction = setter.layout(N.quotient(N.number('1'), N.number('2')));
    // bar is the wider part plus 0.16 em, with 0.08 em margins
    assert.true(close(fraction.width, 10 + 3.2 + 3.2));
    assert.true(fraction.ascent > one.ascent && fraction.descent > 0);
    const rule = fraction.atoms.find((a) => a.mark.m === 'rule')!;
    assert.true(close(rule.frame.y, -20 * 0.26 - 0.5));
    const root = setter.layout(N.call('sqrt', [x]));
    assert.deepEqual(
      root.atoms.map((a) => a.mark.m),
      ['radical', 'rule', 'glyphs'],
    );
    assert.true(close(root.width, 0.8 + 10 + 1.2 + 10 + 1.2 + 0.8));
    const power = setter.layout(N.power(x, N.number('2')));
    const exponent = power.atoms[1]!;
    assert.true(close(exponent.frame.height, 14), 'script at 0.7');
    assert.true(exponent.frame.y < 0, 'raised');
    const tall = setter.layout(
      N.group(N.quotient(N.number('1'), N.number('2'))),
    );
    assert.deepEqual(
      tall.atoms.map((a) => a.mark.m),
      ['paren', 'glyphs', 'glyphs', 'rule', 'paren'],
      'drawn brackets around a fraction',
    );
    assert.strictEqual(
      setter.layout(N.relation('=', x, N.number('1'))).atoms[1]!.ink,
      'accent',
    );
  });

  test('edited rows show holes and caret stops', function (assert) {
    const setter = new Typesetter(metrics, 30);
    const e = new Expression('');
    e.apply({ kind: 'fraction' });
    const box = layoutRow(setter, e.root, { caret: e.caret.row });
    const holes = box.atoms.filter((a) => a.mark.m === 'hole');
    assert.strictEqual(holes.length, 2);
    assert.deepEqual(
      holes.map((h) => h.ink),
      ['accent', 'result'],
      'the slot with the caret is lit',
    );
    const stop = box.carets.find(
      (c) => c.row === e.caret.row && c.index === e.caret.index,
    )!;
    assert.true(stop.rect.width > 0, 'an empty slot is its own caret');
    const flat = new Expression('12+x');
    const stops = layoutRow(setter, flat.root).carets;
    assert.strictEqual(stops.length, 5);
    assert.true(stops.every((c, i) => i === 0 || c.rect.x > stops[i - 1]!.rect.x));
  });

  test('keypad pages cover their grids once', function (assert) {
    for (const [index, specs] of pages('t').entries()) {
      const covered = new Set<number>();
      for (const spec of specs) {
        for (let cx = spec.x; cx < spec.x + spec.w; cx += 1)
          for (let cy = spec.y; cy < spec.y + spec.h; cy += 1) {
            assert.true(cx < columns && cy < rows, `page ${index} on the grid`);
            assert.false(covered.has(cy * columns + cx), `page ${index} ${cx},${cy} once`);
            covered.add(cy * columns + cx);
          }
        for (const key of spec.menu?.keys ?? [spec.key]) {
          assert.true(label(key, 't', 20, metrics).width > 0, 'labelled');
          assert.notStrictEqual(typed([key], 't').text, '', 'types something');
        }
      }
      assert.strictEqual(covered.size, columns * rows, `page ${index} full`);
    }
    assert.strictEqual(letters('t')[0], 't');
    assert.strictEqual(letters('t').length, 12);
    assert.strictEqual(familyOf(s('7')), 'digit');
    assert.strictEqual(familyOf({ kind: 'integral', bounded: true }), 'calculus');
    assert.strictEqual(familyOf(s('×')), 'operation');
    assert.strictEqual(familyOf(s('y')), 'letter');
    assert.strictEqual(spoken({ kind: 'root' }, 'x'), 'Square root');
    assert.strictEqual(spoken({ kind: 'function', name: 'gcd', arity: 2 }, 'x'), 'gcd');
  });

  test('morph keys stay with their glyphs', function (assert) {
    const setter = new Typesetter(metrics, 20);
    const a = keyed(setter.layout(parse('x+x')!).atoms, 'p').map((k) => k.key);
    assert.deepEqual(a, ['p|gix#0', 'p|gu+#0', 'p|gix#1']);
    assert.strictEqual(eased(0), 0);
    assert.true(Math.abs(eased(1) - 1) < 0.001);
    assert.true(Math.max(...[0.3, 0.35, 0.4].map(eased)) > 1, 'overshoots');
    const placed = {
      atom: setter.layout(x).atoms[0]!,
      frame: { x: 0, y: 0, width: 10, height: 20 },
      alpha: 1,
    };
    assert.deepEqual(grown(placed, 0.5), { x: 2.5, y: 0, width: 5, height: 10 });
  });
});
