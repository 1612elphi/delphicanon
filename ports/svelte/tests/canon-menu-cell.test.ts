import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonMenuCell from '../src/components/canon-menu-cell.svelte';
import { find, select } from './helpers.ts';

const items = ['One', 'Two', 'Three'];

test('shows the choice and reports a new one', async () => {
  const picks: number[] = [];
  await render(CanonMenuCell, {
    items,
    selected: 0,
    label: 'Count',
    onChange: (index) => picks.push(index),
  });
  expect(find('.canon-menu-cell-title').textContent).toBe('One');
  expect(find('select').getAttribute('aria-label')).toBe('Count');
  await select('select', '2');
  expect(picks).toEqual([2]);
  expect(find('.canon-menu-cell-title').textContent).toBe('Three');
  expect(find('.canon-menu-cell').offsetHeight).toBe(44);
});

test('no selection shows the placeholder', async () => {
  await render(CanonMenuCell, { items, label: 'Count' });
  expect(find('.canon-menu-cell-title').textContent).toBe('—');
  expect(document.querySelector('option[hidden]')).not.toBeNull();
});
