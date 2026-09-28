import { expect, test } from 'vitest';
import CanonMenuCell from '../../src/components/canon-menu-cell.vue';
import { find, render, select } from '../helpers/render.ts';

const items = ['One', 'Two', 'Three'];

test('shows the choice and reports a new one', async () => {
  const picks: number[] = [];
  const record = (index: number) => picks.push(index);
  await render(
    `<CanonMenuCell :items="items" :selected="0" label="Count" :on-change="record" />`,
    { CanonMenuCell, items, record },
  );
  expect(find('.canon-menu-cell-title').textContent?.trim()).toBe('One');
  expect(find('select')).toHaveAttribute('aria-label', 'Count');
  await select('select', '2');
  expect(picks).toEqual([2]);
  expect(find('.canon-menu-cell-title').textContent?.trim()).toBe('Three');
  expect(find('.canon-menu-cell').offsetHeight).toBe(44);
});

test('no selection shows the placeholder', async () => {
  await render(`<CanonMenuCell :items="items" label="Count" />`, {
    CanonMenuCell,
    items,
  });
  expect(find('.canon-menu-cell-title').textContent?.trim()).toBe('—');
  expect(document.querySelector('option[hidden]')).not.toBeNull();
});
