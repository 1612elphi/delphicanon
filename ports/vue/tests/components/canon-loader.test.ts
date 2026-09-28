import { expect, test } from 'vitest';
import CanonLoader from '../../src/components/canon-loader.vue';
import { find, findAll, render } from '../helpers/render.ts';

test('nine cells sized by cell and gap', async () => {
  await render(
    `<CanonLoader class="big" />
    <CanonLoader class="small" mode="thinking" :cell="4" :gap="1" />`,
    { CanonLoader },
  );
  expect(findAll('.big > *')).toHaveLength(9);
  expect(find('.big')).toHaveAttribute('role', 'status');
  expect(find('.big')).toHaveAttribute('aria-label', 'Loading');
  expect(find('.small')).toHaveClass('canon-loader--thinking');
  const width = (s: string) => find(s).offsetWidth;
  expect(width('.big')).toBe(28);
  expect(width('.small')).toBe(14);
});
