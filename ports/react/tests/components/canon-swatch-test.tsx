import { describe, expect, test } from 'vitest';
import type { Rgb } from '@canon/lib/colour.ts';
import CanonSwatch from '../../src/components/canon-swatch.tsx';
import { fakeClipboard } from '../helpers/clipboard.ts';
import { click, find, render } from '../helpers/render.tsx';

const yellow: Rgb = [1, 0.9, 0];
const nameOf = () => 'Yellow';
const visible = (selector: string) =>
	find(selector).checkVisibility({ visibilityProperty: true });

describe('canon-swatch', () => {
	test('shows its hex in the ink that reads and copies it', async () => {
		const written = fakeClipboard();
		await render(
			<div
				style={{
					display: 'grid',
					width: 120,
					height: 52,
				}}
			>
				<CanonSwatch colour={yellow} nameOf={nameOf} />
			</div>,
		);
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
		await render(
			<div style={{ display: 'grid', width: 30, height: 52 }}>
				<CanonSwatch colour={yellow} />
			</div>,
		);
		expect(visible('.canon-swatch-hex')).toBe(false);
	});
});
