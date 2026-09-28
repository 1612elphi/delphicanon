import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonFigure from '../src/components/canon-figure.svelte';
import { find, findAll, settled } from './helpers.ts';

test('rolls the changed characters only', async () => {
  const { rerender } = await render(CanonFigure, {
    text: '200',
    unit: 'px',
    size: 28,
  });
  expect(find('.canon-figure-said').textContent).toBe('200px');
  expect(findAll('.canon-figure-char').length).toBe(3);
  expect(find('.canon-figure-unit').textContent).toBe('px');
  await rerender({ text: '250' });
  await settled();
  expect(find('.canon-figure-said').textContent).toBe('250px');
  expect(find('.canon-figure-text').textContent).toMatch(/^250/);
  const rolling = findAll('.canon-figure-char').map(
    (c) => c.getAnimations().length > 0,
  );
  const still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  expect(rolling).toEqual(still ? [false, false, false] : [false, true, false]);
});

test('a halo draws an outline shadow', async () => {
  await render(CanonFigure, { text: '1', halo: 'black' });
  expect(getComputedStyle(find('.canon-figure')).textShadow).toContain(
    '0px 3px 5px',
  );
});
