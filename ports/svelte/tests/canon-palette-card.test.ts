import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import type { Rgb } from '@canon/lib/colour.ts';
import { canonToast } from '../src/lib/toast-store.svelte.ts';
import Blocks from './fixtures/canon-palette-card-blocks.svelte';
import { click, fakeClipboard, find } from './helpers.ts';

const colours: Rgb[] = [
  [1, 0, 0],
  [0, 0.5, 0],
  [0, 0, 1],
];

test('a tap widens a swatch, a second tap copies its hex', async () => {
  const written = fakeClipboard(canonToast);
  const picks: (number | undefined)[] = [];
  await render(Blocks, { colours, onSelect: (index) => picks.push(index) });
  expect(find('.canon-heading').textContent).toBe('Harmony');
  expect(document.querySelector('.picker')).not.toBeNull();
  expect(document.querySelector('.canon-grid button')).not.toBeNull();
  const second = '.canon-palette-card-swatch:nth-child(2)';
  await click(second);
  expect(picks).toEqual([1]);
  expect(find(second).getAttribute('aria-pressed')).toBe('true');
  expect(find(second).style.flexGrow).toBe('3');
  await click(second);
  expect(written).toEqual(['#008000']);
  // the wide swatch does not select again
  expect(picks).toEqual([1]);
});
