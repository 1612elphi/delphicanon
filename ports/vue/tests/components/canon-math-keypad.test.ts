import { expect, test } from 'vitest';
import CanonMathKeypad from '../../src/components/canon-math-keypad.vue';
import type { Key } from '@canon/lib/math/expression.ts';
import { click, find, findAll, render, wait } from '../helpers/render.ts';

test('the keypad types keys, pages and opens submenus', async () => {
  const typed: Key[] = [];
  let done = 0;
  const onKey = (key: Key) => typed.push(key);
  const onDone = () => (done += 1);
  await render(
    `<div style="width: 420px">
      <CanonMathKeypad variable="t" :on-key="onKey" :on-done="onDone" />
    </div>`,
    { CanonMathKeypad, onKey, onDone },
  );
  expect(findAll('.canon-math-keypad-page').length).toBe(4);
  expect(
    findAll('.canon-math-keypad-page')[0]!.children.length,
    'the numbers page, with a wide 0',
  ).toBe(23);
  await click('[aria-label="7"]');
  await click('[aria-label="Delete"]');
  await click('[aria-label="Done"]');
  expect(typed).toEqual([{ kind: 'symbol', symbol: '7' }, { kind: 'delete' }]);
  expect(done).toBe(1);
  expect(
    find('.canon-math-keypad-page:first-child .canon-math-key--letter'),
  ).toHaveAttribute('aria-label', 't');

  await click('.canon-math-tab:nth-child(2)');
  await wait(900);
  const pager = find('.canon-math-keypad-pager');
  expect(Math.round(pager.scrollLeft / pager.clientWidth)).toBe(1);
  expect(find('.canon-math-tab:nth-child(2)')).toHaveAttribute(
    'aria-current',
    'true',
  );

  await click('[data-canon-math-key="1-0-3"]');
  expect(findAll('.canon-math-submenu .canon-math-key').length).toBe(6);
  await click('.canon-math-submenu [aria-label="cosh"]');
  expect(
    document.querySelector('.canon-math-submenu'),
    'typing closes it',
  ).toBeNull();
  expect(typed.at(-1)).toEqual({ kind: 'function', name: 'cosh', arity: 1 });
  await wait(1100);
  expect(
    Math.round(pager.scrollLeft / pager.clientWidth),
    'a slot key on a later page returns to 123',
  ).toBe(0);
});
