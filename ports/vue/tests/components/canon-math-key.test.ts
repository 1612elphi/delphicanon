import { expect, test } from 'vitest';
import CanonMathKey from '../../src/components/canon-math-key.vue';
import type { Key } from '@canon/lib/math/expression.ts';
import { click, find, render, triggerEvent } from '../helpers/render.ts';

test('a key takes its family, label and one tap', async () => {
  let taps = 0;
  const tap = () => (taps += 1);
  const root: Key = { kind: 'root' };
  const times: Key = { kind: 'symbol', symbol: '×' };
  await render(
    `<CanonMathKey class="root" :math-key="root" :on-click="tap" />
    <CanonMathKey class="times" :math-key="times" />`,
    { CanonMathKey, root, times, tap },
  );
  expect(find('.root')).toHaveClass('canon-math-key--structure');
  expect(find('.root')).toHaveAttribute('aria-label', 'Square root');
  expect(find('.times')).toHaveClass('canon-math-key--operation');
  await click('.root');
  expect(taps).toBe(1);
  await triggerEvent('.root', 'pointerdown', { clientX: 10, clientY: 10 });
  await triggerEvent('.root', 'pointermove', { clientX: 40, clientY: 10 });
  await click('.root');
  expect(taps, 'a drag past the slop does not type').toBe(1);
});
