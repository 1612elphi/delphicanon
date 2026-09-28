import { expect, test } from 'vitest';
import CanonPaletteCard from '../../src/components/canon-palette-card.vue';
import type { Rgb } from '@canon/lib/colour.ts';
import { fakeClipboard } from '../helpers/fake-clipboard.ts';
import { click, find, render } from '../helpers/render.ts';

const colours: Rgb[] = [
  [1, 0, 0],
  [0, 0.5, 0],
  [0, 0, 1],
];

test('a tap widens a swatch, a second tap copies its hex', async () => {
  const written = fakeClipboard();
  const picks: (number | undefined)[] = [];
  const select = (index: number | undefined) => picks.push(index);
  await render(
    `<div style="width: 400px">
      <CanonPaletteCard title="Harmony" :colours="colours" :on-select="select">
        <template #picker><p class="picker">picker</p></template>
        <template #actions><button type="button">Copy</button></template>
      </CanonPaletteCard>
    </div>`,
    { CanonPaletteCard, colours, select },
  );
  expect(find('.canon-heading').textContent?.trim()).toBe('Harmony');
  expect(document.querySelector('.picker')).not.toBeNull();
  expect(document.querySelector('.canon-grid button')).not.toBeNull();
  const second = '.canon-palette-card-swatch:nth-child(2)';
  await click(second);
  expect(picks).toEqual([1]);
  expect(find(second)).toHaveAttribute('aria-pressed', 'true');
  expect(find(second).style.flexGrow).toBe('3');
  await click(second);
  expect(written).toEqual(['#008000']);
  expect(picks, 'the wide swatch does not select again').toEqual([1]);
});
