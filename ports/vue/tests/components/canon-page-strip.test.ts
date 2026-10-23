import { reactive } from 'vue';
import { expect, test } from 'vitest';
import CanonPageStrip, {
	type CanonPage,
} from '../../src/components/canon-page-strip.vue';
import {
	click,
	find,
	findAll,
	render,
	settled,
	triggerKeyEvent,
} from '../helpers/render.ts';

function makeState() {
	const state = reactive({
		pages: [
			{ size: { width: 595, height: 842 }, name: 'A' },
			{ size: { width: 842, height: 595 }, name: 'B' },
			{
				size: { width: 595, height: 842 },
				name: 'C',
				depth: 2,
			},
		] as CanonPage[],
		selected: 1,
		moves: [] as [number, number][],
		move: (from: number, to: number) => {
			state.moves.push([from, to]);
			const pages = [...state.pages];
			pages.splice(to, 0, ...pages.splice(from, 1));
			state.pages = pages;
		},
		select: (index: number) => {
			state.selected = index;
		},
	});
	return state;
}

// Vue drops whitespace between elements; the parts are flex items, so compare the rendered text
const shown = (selector: string) =>
	find(selector).innerText.replace(/\s+/g, ' ').trim();

test('pages to scale, lit, stacked, reordered by keyboard', async () => {
	const state = makeState();
	await render(
		`<div style="width: 600px; height: 192px">
      <CanonPageStrip
        :pages="state.pages"
        :selected="state.selected"
        :on-select="state.select"
        :reorders="true"
        :on-move="state.move"
      />
    </div>`,
		{ CanonPageStrip, state },
	);
	const papers = findAll('.canon-page-strip-stack');
	expect(papers).toHaveLength(3);
	const [portrait, landscape] = papers.map((p) =>
		p.getBoundingClientRect(),
	);
	expect(portrait!.height > portrait!.width, 'portrait is tall').toBe(
		true,
	);
	expect(landscape!.width > landscape!.height, 'landscape is wide').toBe(
		true,
	);
	expect(shown('.canon-page-strip-cell--lit')).toBe('2 B');
	expect(findAll('.canon-page-strip-sheet')).toHaveLength(2);

	await click('[data-page-index="0"] .canon-page-strip-page');
	expect(state.selected).toBe(0);
	expect(find('[data-page-index="0"] button')).toHaveAttribute(
		'aria-current',
		'true',
	);

	await triggerKeyEvent(
		'[data-page-index="0"] button',
		'keydown',
		'ArrowRight',
		{ altKey: true },
	);
	await settled();
	expect(state.moves).toEqual([[0, 1]]);
	expect(
		find(
			'[data-page-index="1"] .canon-page-strip-name',
		).textContent.trim(),
	).toBe('A');
});

test('no pages shows the empty text', async () => {
	await render(`<CanonPageStrip :pages="[]" />`, { CanonPageStrip });
	expect(find('.canon-page-strip-empty').textContent.trim()).toBe(
		'Pages',
	);
});
