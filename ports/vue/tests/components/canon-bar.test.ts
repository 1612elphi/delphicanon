import { expect, test } from 'vitest';
import CanonBar from '../../src/components/canon-bar.vue';
import { find, render } from '../helpers/render.ts';

test('fills its share of the width, clamped', async () => {
	await render(
		`<div style="width: 200px">
      <CanonBar class="quarter" :share="0.25" />
      <CanonBar class="over" :share="2" />
    </div>`,
		{ CanonBar },
	);
	const fill = (selector: string) =>
		find(`${selector} .canon-bar-fill`).offsetWidth;
	expect(fill('.quarter')).toBe(50);
	expect(fill('.over')).toBe(200);
});
