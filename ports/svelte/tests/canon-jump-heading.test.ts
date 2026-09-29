import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import List from './fixtures/canon-jump-heading-list.svelte';
import { click, find, findAll, settled, waitUntil } from './helpers.ts';

const groups = ['Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon'];

test('opens a grid of its scrolling box’s groups lit at the one in view; a pick scrolls there and focuses it', async () => {
  await render(List, { groups });
  const list = find('.list');
  const headings = findAll('.canon-jump-heading');
  expect(headings[0]!.tagName, 'a heading').toBe('H3');
  const buttons = findAll('.canon-jump-heading-button');
  expect(buttons).toHaveLength(5);
  expect(buttons[0]!.getAttribute('aria-haspopup')).toBe('dialog');

  list.scrollTop = headings[2]!.offsetTop - list.offsetTop;
  // the helper focuses first, which would scroll an off-screen heading in
  await click(headings[2]!.querySelector('button')!);
  expect(findAll('.canon-jump-grid-tile')).toHaveLength(5);
  expect(
    find('.canon-jump-grid-tile--lit').textContent?.replace(/\s+/g, ' ').trim(),
  ).toBe('Gamma 3');

  await click('.canon-jump-grid-tile:nth-child(4)');
  const target = headings[3]!;
  await waitUntil(
    () =>
      !document.querySelector('dialog') &&
      Math.abs(
        target.getBoundingClientRect().top - list.getBoundingClientRect().top,
      ) < 2,
    3000,
  );
  await settled();
  expect(document.activeElement).toBe(target.querySelector('button'));
});
