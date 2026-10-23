import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Fit from './fixtures/canon-canvas-fit.svelte';
import Scenes from './fixtures/canon-layout-scenes.svelte';
import { find, waitUntil } from './helpers.ts';

describe('canon-canvas', () => {
	test('sizes fixed, by aspect, and capped', async () => {
		await render(Scenes, { scene: 'canvas' });
		const height = (selector: string) =>
			find(selector).offsetHeight;
		expect(height('.fixed')).toBe(120);
		// content 400 / 4 plus two rules
		expect(height('.aspect')).toBe(104);
		expect(height('.capped')).toBe(60);
		expect(
			find(
				'.fixed .canon-canvas-content',
			).textContent?.trim(),
		).toBe('Art');
	});

	test('fitting takes its height from the content', async () => {
		const { rerender } = await render(Fit, {
			width: 400,
			shows: true,
		});
		const height = () => find('.fits').offsetHeight;
		await waitUntil(() => height() === 204);
		expect(height()).toBe(204);
		await rerender({ width: 300 });
		await waitUntil(() => height() === 154);
		expect(height()).toBe(154);
		await rerender({ shows: false });
		await waitUntil(() => height() === 0);
		expect(height()).toBe(0);
	});
});
