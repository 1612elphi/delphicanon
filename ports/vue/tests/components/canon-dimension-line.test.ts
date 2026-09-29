import { expect, test } from 'vitest';
import CanonDimensionLine from '../../src/components/canon-dimension-line.vue';
import { find, render } from '../helpers/render.ts';

test('a rule with ticks and the figure, turned or blank', async () => {
  await render(
    `<div style="position: relative; width: 400px; height: 300px">
      <CanonDimensionLine
        class="across"
        :pixels="1600"
        style="inset-inline-start: 44px; inset-block-start: 0; inline-size: 200px"
      />
      <CanonDimensionLine class="down" :pixels="1200" down />
      <CanonDimensionLine class="blank" :pixels="1600" blank />
    </div>`,
    { CanonDimensionLine },
  );
  expect(find('.across')).toHaveAttribute('aria-hidden', 'true');
  expect(find('.across .canon-figure-said')).toHaveTextContent('1600px');
  expect(find('.across').offsetWidth).toBe(200);
  expect(find('.across').offsetHeight).toBe(32);
  expect(getComputedStyle(find('.down')).rotate).toBe('-90deg');
  expect(document.querySelector('.blank .canon-figure')).toBeNull();
  const ink = (selector: string) =>
    getComputedStyle(find(selector), '::before').backgroundColor;
  expect(ink('.blank'), 'blank ticks are muted').not.toBe(ink('.across'));
});
