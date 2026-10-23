import { useState } from 'react';
import { describe, expect, test } from 'vitest';
import CanonPageStrip, {
	type CanonPage,
} from '../../src/components/canon-page-strip.tsx';
import { click, find, findAll, key, render, wait } from '../helpers/render.tsx';

const start: CanonPage[] = [
	{ size: { width: 595, height: 842 }, name: 'A' },
	{ size: { width: 842, height: 595 }, name: 'B' },
	{ size: { width: 595, height: 842 }, name: 'C', depth: 2 },
];

describe('canon-page-strip', () => {
	test('pages to scale, lit, stacked, reordered by keyboard', async () => {
		const moves: [number, number][] = [];
		let selected = 1;
		function Strip() {
			const [pages, setPages] = useState(start);
			const [lit, setLit] = useState(1);
			return (
				<div style={{ width: 600, height: 192 }}>
					<CanonPageStrip
						pages={pages}
						selected={lit}
						onSelect={(index) => {
							selected = index;
							setLit(index);
						}}
						reorders
						onMove={(from, to) => {
							moves.push([from, to]);
							const next = [...pages];
							next.splice(
								to,
								0,
								...next.splice(
									from,
									1,
								),
							);
							setPages(next);
						}}
					/>
				</div>
			);
		}
		await render(<Strip />);
		const papers = findAll('.canon-page-strip-stack');
		expect(papers).toHaveLength(3);
		const [portrait, landscape] = papers.map((p) =>
			p.getBoundingClientRect(),
		);
		expect(portrait!.height).toBeGreaterThan(portrait!.width);
		expect(landscape!.width).toBeGreaterThan(landscape!.height);
		expect(
			find('.canon-page-strip-cell--lit').innerText.replace(
				/\s+/g,
				' ',
			),
		).toBe('2 B');
		expect(findAll('.canon-page-strip-sheet')).toHaveLength(2);

		await click('[data-page-index="0"] .canon-page-strip-page');
		expect(selected).toBe(0);
		expect(
			find('[data-page-index="0"] button').getAttribute(
				'aria-current',
			),
		).toBe('true');

		await key('[data-page-index="0"] button', 'ArrowRight', {
			altKey: true,
		});
		await wait(20);
		expect(moves).toEqual([[0, 1]]);
		expect(
			find('[data-page-index="1"] .canon-page-strip-name')
				.textContent,
		).toBe('A');
	});

	test('no pages shows the empty text', async () => {
		await render(<CanonPageStrip pages={[]} />);
		expect(find('.canon-page-strip-empty').textContent).toBe(
			'Pages',
		);
	});
});
