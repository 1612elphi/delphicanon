import { describe, expect, test } from 'vitest';
import type { GlyphKind } from '@canon/lib/glyph-rows.ts';
import CanonGlyphFlow from '../../src/components/canon-glyph-flow.tsx';
import { find, findAll, render, wait } from '../helpers/render.tsx';

const metrics = { height: 36, rowGap: 8, gap: 4 };
const measure = () => 28;
const kind = (c: string): GlyphKind =>
	c === '\n' ? 'newline' : c === ' ' ? 'space' : 'glyph';

describe('canon-glyph-flow', () => {
	test('glyphs paint through the block, one row centred, wrapping when long', async () => {
		const ui = (glyphs: string[]) => (
			<div style={{ width: 300, height: 120 }}>
				<CanonGlyphFlow
					glyphs={glyphs}
					metrics={metrics}
					measure={measure}
					kind={kind}
					label="ab"
				>
					{(glyph, index) => (
						<span
							className="g"
							data-index={
								index ??
								undefined
							}
						>
							{glyph}
						</span>
					)}
				</CanonGlyphFlow>
			</div>
		);
		const { rerender } = await render(ui([...'ab']));
		for (let i = 0; i < 50 && findAll('.g').length !== 2; i++)
			await wait(20);
		expect(
			find('.canon-glyph-flow').getAttribute('aria-label'),
		).toBe('ab');
		const boxes = findAll('.canon-glyph-flow-glyph');
		const left = parseFloat(boxes[0]!.style.left);
		const right = parseFloat(boxes[1]!.style.left) + 28;
		expect(left + right).toBe(300);

		await rerender(ui([...'abcdefghijklmnopqrstuvwxyz']));
		const tops = new Set(
			findAll('.canon-glyph-flow-glyph').map(
				(g) => g.style.top,
			),
		);
		expect(tops.size).toBeGreaterThan(1);
	});

	test('no glyphs shows the empty block', async () => {
		await render(
			<div style={{ width: 300, height: 120 }}>
				<CanonGlyphFlow
					glyphs={[] as string[]}
					metrics={metrics}
					measure={measure}
					kind={kind}
					empty={
						<span className="nothing">
							Empty
						</span>
					}
				/>
			</div>,
		);
		expect(document.querySelector('.nothing')).not.toBeNull();
	});
});
