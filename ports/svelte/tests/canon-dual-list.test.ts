import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonDualList from '../src/components/canon-dual-list.svelte';
import { click, find, findAll } from './helpers.ts';

const hidden = [{ id: 'b', name: 'Beta', caption: 'two' }];
const shown = [
	{ id: 'a', name: 'Alpha' },
	{ id: 'c', name: 'Gamma' },
];

test('one selection between two lists drives the actions', async () => {
	const calls: string[] = [];
	await render(CanonDualList, {
		left: hidden,
		right: shown,
		leftTitle: 'Hidden',
		rightTitle: 'Shown',
		listHeight: 140,
		onMoveRight: (id) => calls.push(`right ${id}`),
		onReorder: (id, delta) => calls.push(`reorder ${id} ${delta}`),
	});
	const button = (text: string) =>
		findAll<HTMLButtonElement>('.canon-grid button').find(
			(b) => b.textContent?.trim() === text,
		)!;
	expect(findAll('.canon-dual-list-items').length).toBe(2);
	expect(find('.canon-dual-list-items').offsetHeight).toBe(140);
	expect(button('Show').disabled).toBe(true);

	await click('.canon-dual-list-item');
	expect(find('.canon-dual-list-item').getAttribute('aria-pressed')).toBe(
		'true',
	);
	expect(button('Show').disabled).toBe(false);
	expect(button('Up').disabled).toBe(true);
	await click(button('Show'));

	const gamma = findAll('.canon-dual-list-item')[2]!;
	await click(gamma);
	expect(button('Up').disabled).toBe(false);
	expect(button('Down').disabled).toBe(true);
	await click(button('Up'));
	expect(calls).toEqual(['right b', 'reorder c -1']);
});
