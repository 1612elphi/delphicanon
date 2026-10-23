import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonSegmented from '../src/components/canon-segmented.svelte';
import { click, dot, find, findAll } from './helpers.ts';

const modes = ['Region', 'Window', 'Screen'];

test('picks one and reports it', async () => {
	const picks: number[] = [];
	await render(CanonSegmented, {
		items: modes,
		selected: 0,
		onChange: (index) => picks.push(index),
	});
	expect(findAll('[role=radio]').length).toBe(3);
	await click('[role=radio]:nth-child(2)');
	expect(picks).toEqual([1]);
	expect(
		find('[role=radio]:nth-child(2)').getAttribute('aria-checked'),
	).toBe('true');
	expect(
		find('[role=radio]:nth-child(1)').getAttribute('aria-checked'),
	).toBe('false');
	await click('[role=radio]:nth-child(2)');
	expect(picks, 'the selected choice sends nothing').toEqual([1]);
});

test('greys single choices and shows symbols', async () => {
	await render(CanonSegmented, {
		items: modes,
		icons: [dot, dot, dot],
		disabledIndices: [2],
	});
	expect(
		find<HTMLButtonElement>('[role=radio]:nth-child(3)').disabled,
	).toBe(true);
	expect(
		find<HTMLButtonElement>('[role=radio]:nth-child(1)').disabled,
	).toBe(false);
	expect(
		find('[role=radio]:nth-child(1)').getAttribute('aria-label'),
	).toBe('Region');
});
