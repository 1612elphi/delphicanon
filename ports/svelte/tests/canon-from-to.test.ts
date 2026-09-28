import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonFromTo from '../src/components/canon-from-to.svelte';
import { find, findAll, select } from './helpers.ts';

const rates = ['23.976', '24', '25'];

test('two named menus with an arrow between', async () => {
  const tos: number[] = [];
  await render(CanonFromTo, {
    items: rates,
    from: 0,
    to: 2,
    onToChange: (index) => tos.push(index),
  });
  expect(findAll('select').length).toBe(2);
  expect(document.querySelector('.canon-from-to-arrow')).not.toBeNull();
  expect(
    find('.canon-menu-cell:first-child select').getAttribute('aria-label'),
  ).toBe('From');
  await select('.canon-menu-cell:last-child select', '1');
  expect(tos).toEqual([1]);
  const [from, to] = findAll('.canon-menu-cell');
  expect(from!.offsetWidth).toBe(to!.offsetWidth);
});
