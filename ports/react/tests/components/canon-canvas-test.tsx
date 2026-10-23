import { describe, expect, test } from 'vitest';
import CanonCanvas from '../../src/components/canon-canvas.tsx';
import { find, render, waitUntil } from '../helpers/render.tsx';

describe('canon-canvas', () => {
	test('sizes fixed, by aspect, and capped', async () => {
		await render(
			<div style={{ width: 400 }}>
				<CanonCanvas className="fixed" height={120}>
					<span>Art</span>
				</CanonCanvas>
				<CanonCanvas className="aspect" aspect={4} />
				<CanonCanvas
					className="capped"
					aspect={4}
					maxHeight={60}
				/>
			</div>,
		);
		const height = (selector: string) =>
			find(selector).offsetHeight;
		expect(height('.fixed')).toBe(120);
		// content 400 / 4 plus two rules
		expect(height('.aspect')).toBe(104);
		expect(height('.capped')).toBe(60);
		expect(find('.fixed .canon-canvas-content').textContent).toBe(
			'Art',
		);
	});

	test('fitting takes its height from the content', async () => {
		const fit = (width: number, shows: boolean) => (
			<div style={{ width }}>
				<CanonCanvas className="fits" fitting>
					{shows && (
						<div
							style={{
								aspectRatio: 2,
							}}
						/>
					)}
				</CanonCanvas>
			</div>
		);
		const { rerender } = await render(fit(400, true));
		const height = () => find('.fits').offsetHeight;
		await waitUntil(() => height() === 204);
		expect(height()).toBe(204);
		await rerender(fit(300, true));
		await waitUntil(() => height() === 154);
		expect(height()).toBe(154);
		await rerender(fit(300, false));
		await waitUntil(() => height() === 0);
		expect(height()).toBe(0);
	});
});
