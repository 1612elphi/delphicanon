import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import type { Rgb } from '@canon/lib/colour.ts';
import { canonToast } from '../src/lib/toast-store.svelte.ts';
import Sized from './fixtures/canon-swatch-sized.svelte';
import { click, fakeClipboard, find } from './helpers.ts';

const yellow: Rgb = [1, 0.9, 0];
const nameOf = () => 'Yellow';
const visible = (selector: string) => find(selector).checkVisibility();

test('shows its hex in the ink that reads and copies it', async () => {
	const written = fakeClipboard(canonToast);
	await render(Sized, { width: 120, colour: yellow, nameOf });
	expect(find('.canon-swatch-hex').textContent).toBe('#FFE600');
	expect(visible('.canon-swatch-hex')).toBe(true);
	expect(find('.canon-swatch').getAttribute('aria-label')).toBe(
		'Yellow #FFE600',
	);
	expect(find('.canon-swatch').style.color).toBe('black');
	await click('.canon-swatch');
	expect(written).toEqual(['#FFE600']);
});

test('drops the hex when narrow', async () => {
	await render(Sized, { width: 30, colour: yellow });
	expect(visible('.canon-swatch-hex')).toBe(false);
});
