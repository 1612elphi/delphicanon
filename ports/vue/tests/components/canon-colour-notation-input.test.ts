import { afterEach, beforeEach, expect, test } from 'vitest';
import CanonColourNotationInput from '../../src/components/canon-colour-notation-input.vue';
import type { Rgb } from '@canon/lib/colour.ts';
import { blur, click, fillIn, find, focus, render } from '../helpers/render.ts';

type EyeDropperWindow = { EyeDropper?: unknown };

const green: Rgb = [0, 1, 0];

let saved: unknown;
beforeEach(() => {
	saved = (window as EyeDropperWindow).EyeDropper;
});
afterEach(() => {
	(window as EyeDropperWindow).EyeDropper = saved;
});

test('shows the colour, reads typed notation and marks what does not read', async () => {
	const colours: Rgb[] = [];
	const use = (colour: Rgb) => colours.push(colour);
	await render(
		`<CanonColourNotationInput :colour="green" :on-colour="use" label="Any notation" />`,
		{ CanonColourNotationInput, green, use },
	);
	expect(find('input')).toHaveValue('#00FF00');
	await focus('input');
	await fillIn('input', 'rgb(255 0 0)');
	await blur('input');
	expect(colours).toEqual([[1, 0, 0]]);
	await focus('input');
	await fillIn('input', 'not a colour');
	await blur('input');
	expect(find('input')).toHaveValue('not a colour');
	expect(find('input')).toHaveAttribute('aria-invalid');
	expect(find('input')).toHaveClass('canon-colour-notation-input--fails');
});

test('a parse function swaps in its own notation', async () => {
	const read: string[] = [];
	const parse = (text: string) => {
		read.push(text);
		return text === 'ok';
	};
	await render(
		`<CanonColourNotationInput text="12 34 56" :parse="parse" />`,
		{
			CanonColourNotationInput,
			parse,
		},
	);
	expect(find('input')).toHaveValue('12 34 56');
	await fillIn('input', 'ok');
	await blur('input');
	expect(find('input')).not.toHaveAttribute('aria-invalid');
	await fillIn('input', 'nope');
	await blur('input');
	expect(find('input')).toHaveAttribute('aria-invalid', 'true');
	expect(read).toEqual(['ok', 'nope']);
});

test('the eyedropper picks through the EyeDropper API, and is absent without it', async () => {
	(window as EyeDropperWindow).EyeDropper = class {
		open() {
			return Promise.resolve({ sRGBHex: '#0000ff' });
		}
	};
	const colours: Rgb[] = [];
	const use = (colour: Rgb) => colours.push(colour);
	await render(`<CanonColourNotationInput :on-colour="use" />`, {
		CanonColourNotationInput,
		use,
	});
	await click('.canon-button');
	expect(colours).toEqual([[0, 0, 1]]);

	delete (window as EyeDropperWindow).EyeDropper;
	const host = await render(`<CanonColourNotationInput />`, {
		CanonColourNotationInput,
	});
	expect(host.querySelector('.canon-button')).toBeNull();
});
