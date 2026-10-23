import { describe, expect, test } from 'vitest';
import type { Rgb } from '@canon/lib/colour.ts';
import CanonPaletteCard from '../../src/components/canon-palette-card.tsx';
import { fakeClipboard } from '../helpers/clipboard.ts';
import { click, find, render } from '../helpers/render.tsx';

const colours: Rgb[] = [
	[1, 0, 0],
	[0, 0.5, 0],
	[0, 0, 1],
];

describe('canon-palette-card', () => {
	test('a tap widens a swatch, a second tap copies its hex', async () => {
		const written = fakeClipboard();
		const picks: (number | undefined)[] = [];
		await render(
			<div style={{ width: 400 }}>
				<CanonPaletteCard
					title="Harmony"
					colours={colours}
					onSelect={(index) => picks.push(index)}
					picker={
						<p className="picker">picker</p>
					}
					actions={
						<button type="button">
							Copy
						</button>
					}
				/>
			</div>,
		);
		expect(find('.canon-heading').textContent).toBe('Harmony');
		expect(document.querySelector('.picker')).not.toBeNull();
		expect(
			document.querySelector('.canon-grid button'),
		).not.toBeNull();
		const second = '.canon-palette-card-swatch:nth-child(2)';
		await click(second);
		expect(picks).toEqual([1]);
		expect(find(second).getAttribute('aria-pressed')).toBe('true');
		expect(find(second).style.flexGrow).toBe('3');
		await click(second);
		expect(written).toEqual(['#008000']);
		// the wide swatch does not select again
		expect(picks).toEqual([1]);
	});
});
