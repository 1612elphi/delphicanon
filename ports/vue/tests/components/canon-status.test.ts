import { expect, test } from 'vitest';
import CanonStatus from '../../src/components/canon-status.vue';
import { find, render } from '../helpers/render.ts';

test('tone sets the colour; row pads it', async () => {
  await render(
    `<CanonStatus class="ok" text="Granted" tone="ok" />
    <CanonStatus class="row" text="Stopped" tone="warn" :row="true" />`,
    { CanonStatus },
  );
  expect(find('.ok').textContent?.trim()).toBe('Granted');
  expect(find('.ok')).toHaveClass('canon-status--ok');
  expect(find('.row')).toHaveClass('canon-status--row');
  const ok = getComputedStyle(find('.ok'));
  const warn = getComputedStyle(find('.row'));
  expect(ok.color).not.toBe(warn.color);
  expect(warn.paddingTop).toBe('10px');
});
