import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonBar from '../src/components/canon-bar.svelte';
import { find } from './helpers.ts';

test('fills its share of the width, clamped', async () => {
	const quarter = await render(CanonBar, {
		class: 'quarter',
		share: 0.25,
	});
	const over = await render(CanonBar, { class: 'over', share: 2 });
	quarter.container.style.width = '200px';
	over.container.style.width = '200px';
	const fill = (selector: string) =>
		find(`${selector} .canon-bar-fill`).offsetWidth;
	expect(fill('.quarter')).toBe(50);
	expect(fill('.over')).toBe(200);
});
