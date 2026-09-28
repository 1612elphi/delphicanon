import { expect, test } from 'vitest';
import CanonTiles from '../../src/components/canon-tiles.vue';
import { find, findAll, render, waitUntil } from '../helpers/render.ts';

// Vue drops whitespace between elements; the parts are flex items, so compare the rendered text
const shown = (selector: string) =>
  find(selector).innerText.replace(/\s+/g, ' ').trim();

const items = [
  { label: 'Codec', value: 'AAC' },
  { label: 'Peak', value: '-4.3 dBFS', level: 0.93 },
  { label: 'RMS', value: '-13.6 dBFS', level: 0.77 },
];

test('as many columns as fit, at least two, with level bars', async () => {
  await render(
    `<div class="wide" style="width: 600px"><CanonTiles :items="items" /></div>
    <div class="narrow" style="width: 200px"><CanonTiles :items="items" /></div>`,
    { CanonTiles, items },
  );
  const columns = (selector: string) =>
    find(`${selector} .canon-grid`).style.getPropertyValue(
      '--canon-grid-columns',
    );
  await waitUntil(() => columns('.wide') === '3');
  expect(columns('.wide')).toBe('3');
  expect(columns('.narrow')).toBe('2');
  expect(findAll('.wide .canon-tiles-level')).toHaveLength(2);
  expect(shown('.wide .canon-tiles-tile')).toBe('Codec AAC');
});
