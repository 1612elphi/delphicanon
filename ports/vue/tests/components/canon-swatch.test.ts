import { expect, test } from 'vitest';
import CanonSwatch from '../../src/components/canon-swatch.vue';
import type { Rgb } from '@canon/lib/colour.ts';
import { fakeClipboard } from '../helpers/fake-clipboard.ts';
import { click, find, render } from '../helpers/render.ts';

const yellow: Rgb = [1, 0.9, 0];
const nameOf = () => 'Yellow';

test('shows its hex in the ink that reads and copies it', async () => {
  const written = fakeClipboard();
  await render(
    `<div style="display: grid; width: 120px; height: 52px">
      <CanonSwatch :colour="yellow" :name-of="nameOf" />
    </div>`,
    { CanonSwatch, yellow, nameOf },
  );
  expect(find('.canon-swatch-hex').textContent?.trim()).toBe('#FFE600');
  expect(find('.canon-swatch-hex')).toBeVisible();
  expect(find('.canon-swatch')).toHaveAttribute('aria-label', 'Yellow #FFE600');
  expect(find('.canon-swatch').style.color).toBe('black');
  await click('.canon-swatch');
  expect(written).toEqual(['#FFE600']);
});

test('drops the hex when narrow', async () => {
  await render(
    `<div style="display: grid; width: 30px; height: 52px">
      <CanonSwatch :colour="yellow" />
    </div>`,
    { CanonSwatch, yellow },
  );
  expect(find('.canon-swatch-hex')).not.toBeVisible();
});
