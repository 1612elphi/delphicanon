import { expect, test } from 'vitest';
import CanonColourCard from '../../src/components/canon-colour-card.vue';
import type { Rgb } from '@canon/lib/colour.ts';
import { find, findAll, render } from '../helpers/render.ts';

const grey: Rgb = [0.4667, 0.4667, 0.4667];

test('a chip shows inks with their ratios and three values', async () => {
  await render(
    `<CanonColourCard :colour="grey" name="Mid grey" primary-format="hsl" />`,
    { CanonColourCard, grey },
  );
  expect(find('.canon-colour-card-name').textContent?.trim()).toBe('Mid grey');
  expect(findAll('.canon-value-line-label').map((e) => e.textContent)).toEqual([
    'HEX',
    'HSL',
    'RGB',
  ]);
  expect(findAll('.canon-colour-card-ratio')).toHaveLength(2);
  expect(
    find(
      '.canon-colour-card-ink:first-child .canon-colour-card-ratio',
    ).textContent?.trim(),
  ).toBe('4.47');
  expect(
    find('.canon-colour-card-ink').style.opacity,
    'white fails AA on this grey',
  ).toBe('0.45');
});

test('a row shows the name and the hex', async () => {
  await render(`<CanonColourCard :colour="grey" layout="row" />`, {
    CanonColourCard,
    grey,
  });
  expect(findAll('.canon-value-line')).toHaveLength(1);
  expect(find('.canon-colour-card-name').textContent?.trim()).toBe('#777777');
  expect(document.querySelector('.canon-colour-card-ink')).toBeNull();
});
