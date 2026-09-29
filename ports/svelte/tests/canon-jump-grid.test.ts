import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Owner from './fixtures/canon-jump-grid-owner.svelte';
import { JumpState } from './fixtures/jump-state.svelte.ts';
import { click, find, findAll, settled, waitUntil } from './helpers.ts';

const sections = [
  { title: 'ISO A', detail: '16' },
  { title: 'ISO B', detail: '11' },
  { title: 'ISO C', detail: '9' },
  { title: 'RA' },
];

const closed = () =>
  waitUntil(() => !find<HTMLDialogElement>('dialog').open).then(settled);

test('lights and focuses the current group, reports a pick after closing, closes on a click beside the tiles', async () => {
  const state = new JumpState();
  await render(Owner, { state, sections });
  await settled();
  const dialog = find<HTMLDialogElement>('dialog');
  expect(dialog.matches(':modal')).toBe(true);
  expect(dialog.getAttribute('aria-label')).toBe('Sections');
  expect(findAll('.canon-jump-grid-tile')).toHaveLength(4);
  const lit = find('.canon-jump-grid-tile--lit');
  expect(lit.textContent?.replace(/\s+/g, ' ').trim()).toBe('ISO C 9');
  expect(lit.getAttribute('aria-current')).toBe('true');
  expect(document.activeElement).toBe(lit);
  expect(
    findAll('.canon-jump-grid-tile:nth-child(4) .canon-jump-grid-detail'),
  ).toHaveLength(0);

  await click('.canon-jump-grid-tile:nth-child(2)');
  await closed();
  expect(state.picks).toEqual([1]);
  expect(state.closes).toBe(1);

  state.open = true;
  await settled();
  await click('.canon-jump-grid-holder');
  await closed();
  expect(state.picks, 'a click beside the tiles picks nothing').toEqual([1]);
  expect(state.closes).toBe(2);
});
