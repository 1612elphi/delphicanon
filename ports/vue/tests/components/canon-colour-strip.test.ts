import { expect, test } from 'vitest';
import CanonColourStrip from '../../src/components/canon-colour-strip.vue';
import type { Rgb } from '@canon/lib/colour.ts';
import { fakeClipboard } from '../helpers/fake-clipboard.ts';
import { click, find, findAll, render } from '../helpers/render.ts';

const red: Rgb = [1, 0, 0];
const palette: Rgb[] = [red, [0, 1, 0], [0, 0, 1]];
const nameOf = () => 'Red';

test('shows name and value and copies the value', async () => {
	const written = fakeClipboard();
	await render(
		`<CanonColourStrip :colour="red" :name-of="nameOf" format="rgb" />`,
		{ CanonColourStrip, red, nameOf },
	);
	expect(find('.canon-colour-strip-name').textContent?.trim()).toBe(
		'Red',
	);
	expect(find('.canon-colour-strip-value').textContent?.trim()).toBe(
		'rgb(255, 0, 0)',
	);
	await click('.canon-colour-strip-single');
	expect(written).toEqual(['rgb(255, 0, 0)']);
});

test('a palette shows swatches instead', async () => {
	await render(`<CanonColourStrip :colour="red" :palette="palette" />`, {
		CanonColourStrip,
		red,
		palette,
	});
	expect(findAll('.canon-swatch')).toHaveLength(3);
	expect(document.querySelector('.canon-colour-strip-single')).toBeNull();
});
