import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import type { Rgb } from '@canon/lib/colour.ts';
import CanonColourWell from '../src/components/canon-colour-well.svelte';
import { fillIn, find } from './helpers.ts';

const green: Rgb = [0, 0.5, 0];
const value = (selector: string) => find<HTMLInputElement>(selector).value;

test('a typed hex changes the colour; anything else puts it back', async () => {
	const changes: Rgb[] = [];
	await render(CanonColourWell, {
		label: 'Foreground',
		colour: green,
		format: 'rgb',
		onChange: (colour) => changes.push(colour),
	});
	expect(find('.canon-colour-well-label').textContent).toBe('Foreground');
	expect(value('input[type=text]')).toBe('008000');
	expect(value('input[type=color]')).toBe('#008000');
	expect(find('.canon-colour-well-echo').textContent).toBe(
		'rgb(0, 128, 0)',
	);
	await fillIn('input[type=text]', '#ff0000');
	expect(changes).toEqual([[1, 0, 0]]);
	await fillIn('input[type=text]', 'nope');
	expect(changes.length).toBe(1);
	expect(value('input[type=text]')).toBe('008000');
});
