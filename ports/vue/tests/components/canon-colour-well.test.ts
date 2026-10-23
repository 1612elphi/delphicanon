import { expect, test } from 'vitest';
import CanonColourWell from '../../src/components/canon-colour-well.vue';
import type { Rgb } from '@canon/lib/colour.ts';
import { fillIn, find, render } from '../helpers/render.ts';

const green: Rgb = [0, 0.5, 0];

test('a typed hex changes the colour; anything else puts it back', async () => {
	const changes: Rgb[] = [];
	const change = (colour: Rgb) => changes.push(colour);
	await render(
		`<CanonColourWell label="Foreground" :colour="green" format="rgb" :on-change="change" />`,
		{ CanonColourWell, green, change },
	);
	expect(find('.canon-colour-well-label').textContent?.trim()).toBe(
		'Foreground',
	);
	expect(find('input[type=text]')).toHaveValue('008000');
	expect(find('input[type=color]')).toHaveValue('#008000');
	expect(find('.canon-colour-well-echo').textContent?.trim()).toBe(
		'rgb(0, 128, 0)',
	);
	await fillIn('input[type=text]', '#ff0000');
	expect(changes).toEqual([[1, 0, 0]]);
	await fillIn('input[type=text]', 'nope');
	expect(changes).toHaveLength(1);
	expect(find('input[type=text]')).toHaveValue('008000');
});
