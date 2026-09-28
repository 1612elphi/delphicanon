import { expect, test } from 'vitest';
import CanonDualList from '../../src/components/canon-dual-list.vue';
import { click, find, findAll, render } from '../helpers/render.ts';

const hidden = [{ id: 'b', name: 'Beta', caption: 'two' }];
const shown = [
  { id: 'a', name: 'Alpha' },
  { id: 'c', name: 'Gamma' },
];

test('one selection between two lists drives the actions', async () => {
  const calls: string[] = [];
  const right = (id: string) => calls.push(`right ${id}`);
  const reorder = (id: string, delta: number) =>
    calls.push(`reorder ${id} ${delta}`);
  await render(
    `<CanonDualList
      :left="hidden"
      :right="shown"
      left-title="Hidden"
      right-title="Shown"
      :list-height="140"
      :on-move-right="right"
      :on-reorder="reorder"
    />`,
    { CanonDualList, hidden, shown, right, reorder },
  );
  const button = (text: string) =>
    findAll('.canon-grid button').find((b) => b.textContent?.trim() === text)!;
  expect(findAll('.canon-dual-list-items')).toHaveLength(2);
  expect(find('.canon-dual-list-items').offsetHeight).toBe(140);
  expect(button('Show')).toBeDisabled();

  await click('.canon-dual-list-item');
  expect(find('.canon-dual-list-item')).toHaveAttribute('aria-pressed', 'true');
  expect(button('Show')).not.toBeDisabled();
  expect(button('Up')).toBeDisabled();
  await click(button('Show'));

  const gamma = findAll('.canon-dual-list-item')[2]!;
  await click(gamma);
  expect(button('Up')).not.toBeDisabled();
  expect(button('Down')).toBeDisabled();
  await click(button('Up'));
  expect(calls).toEqual(['right b', 'reorder c -1']);
});
