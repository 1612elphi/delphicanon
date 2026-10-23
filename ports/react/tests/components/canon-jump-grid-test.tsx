import { useState } from 'react';
import { describe, expect, test } from 'vitest';
import CanonJumpGrid from '../../src/components/canon-jump-grid.tsx';
import {
	click,
	find,
	findAll,
	render,
	settle,
	waitUntil,
} from '../helpers/render.tsx';

const sections = [
	{ title: 'ISO A', detail: '16' },
	{ title: 'ISO B', detail: '11' },
	{ title: 'ISO C', detail: '9' },
	{ title: 'RA' },
];

const closed = () =>
	waitUntil(() => !find<HTMLDialogElement>('dialog').open).then(() =>
		settle(),
	);

describe('canon-jump-grid', () => {
	test('lights and focuses the current group, reports a pick after closing, closes on a click beside the tiles', async () => {
		const picks: number[] = [];
		let closes = 0;
		let reopen = () => {};
		function Owner() {
			const [open, setOpen] = useState(true);
			reopen = () => setOpen(true);
			return (
				<CanonJumpGrid
					open={open}
					sections={sections}
					current={2}
					onPick={(index) => picks.push(index)}
					onClose={() => {
						setOpen(false);
						closes += 1;
					}}
				/>
			);
		}
		await render(<Owner />);
		const dialog = find<HTMLDialogElement>('dialog');
		expect(dialog.matches(':modal')).toBe(true);
		expect(dialog.getAttribute('aria-label')).toBe('Sections');
		expect(findAll('.canon-jump-grid-tile')).toHaveLength(4);
		const lit = find('.canon-jump-grid-tile--lit');
		expect(lit.textContent).toBe('ISO C9');
		expect(lit.getAttribute('aria-current')).toBe('true');
		expect(document.activeElement).toBe(lit);
		expect(
			findAll(
				'.canon-jump-grid-tile:nth-child(4) .canon-jump-grid-detail',
			),
		).toHaveLength(0);

		await click('.canon-jump-grid-tile:nth-child(2)');
		await closed();
		expect(picks).toEqual([1]);
		expect(closes).toBe(1);

		await settle(reopen);
		await click('.canon-jump-grid-holder');
		await closed();
		expect(picks, 'a click beside the tiles picks nothing').toEqual(
			[1],
		);
		expect(closes).toBe(2);
	});
});
