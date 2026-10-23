import { reactive } from 'vue';
import { expect, test } from 'vitest';
import CanonJumpGrid from '../../src/components/canon-jump-grid.vue';
import {
	click,
	find,
	findAll,
	render,
	settled,
	waitUntil,
} from '../helpers/render.ts';

const sections = [
	{ title: 'ISO A', detail: '16' },
	{ title: 'ISO B', detail: '11' },
	{ title: 'ISO C', detail: '9' },
	{ title: 'RA' },
];

const closed = () =>
	waitUntil(() => !find<HTMLDialogElement>('dialog').open).then(settled);

test('lights and focuses the current group, reports a pick after closing, closes on a click beside the tiles', async () => {
	const s = reactive({
		open: true,
		picks: [] as number[],
		closes: 0,
		pick: (index: number) => s.picks.push(index),
		close: () => {
			s.open = false;
			s.closes += 1;
		},
	});
	await render(
		`<CanonJumpGrid :open="s.open" :sections="sections" :current="2" :on-pick="s.pick" :on-close="s.close" />`,
		{ CanonJumpGrid, s, sections },
	);
	const dialog = find<HTMLDialogElement>('dialog');
	expect(dialog.matches(':modal')).toBe(true);
	expect(dialog).toHaveAttribute('aria-label', 'Sections');
	expect(findAll('.canon-jump-grid-tile')).toHaveLength(4);
	const lit = find('.canon-jump-grid-tile--lit');
	expect(lit.innerText.replace(/\s+/g, ' ')).toBe('ISO C 9');
	expect(lit).toHaveAttribute('aria-current', 'true');
	expect(lit).toHaveFocus();
	expect(
		findAll(
			'.canon-jump-grid-tile:nth-child(4) .canon-jump-grid-detail',
		),
	).toHaveLength(0);

	await click('.canon-jump-grid-tile:nth-child(2)');
	await closed();
	expect(s.picks).toEqual([1]);
	expect(s.closes).toBe(1);

	s.open = true;
	await settled();
	await click('.canon-jump-grid-holder');
	await closed();
	expect(s.picks, 'a click beside the tiles picks nothing').toEqual([1]);
	expect(s.closes).toBe(2);
});
