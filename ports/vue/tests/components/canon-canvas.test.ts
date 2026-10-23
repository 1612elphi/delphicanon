import { reactive } from 'vue';
import { expect, test } from 'vitest';
import CanonCanvas from '../../src/components/canon-canvas.vue';
import { find, render, settled, waitUntil } from '../helpers/render.ts';

test('sizes fixed, by aspect, and capped', async () => {
	await render(
		`<div style="width: 400px">
      <CanonCanvas class="fixed" :height="120"><span>Art</span></CanonCanvas>
      <CanonCanvas class="aspect" :aspect="4" />
      <CanonCanvas class="capped" :aspect="4" :max-height="60" />
    </div>`,
		{ CanonCanvas },
	);
	const height = (selector: string) => find(selector).offsetHeight;
	expect(height('.fixed')).toBe(120);
	expect(height('.aspect'), 'content 400 / 4 plus two rules').toBe(104);
	expect(height('.capped')).toBe(60);
	expect(find('.fixed .canon-canvas-content')).toHaveTextContent('Art');
});

test('fitting takes its height from the content', async () => {
	const fit = reactive({ width: 400, shows: true });
	await render(
		`<div :style="{ width: fit.width + 'px' }">
      <CanonCanvas class="fits" :fitting="true">
        <div v-if="fit.shows" style="aspect-ratio: 2"></div>
      </CanonCanvas>
    </div>`,
		{ CanonCanvas, fit },
	);
	const height = () => find('.fits').offsetHeight;
	await waitUntil(() => height() === 204);
	expect(height(), 'half the width plus two rules').toBe(204);
	fit.width = 300;
	await settled();
	await waitUntil(() => height() === 154);
	expect(height(), 'refits on a width change').toBe(154);
	fit.shows = false;
	await settled();
	await waitUntil(() => height() === 0);
	expect(height(), 'no content, no band').toBe(0);
});
