import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Sized from './fixtures/canon-compression-scale-sized.svelte';
import { find, findAll } from './helpers.ts';

const said = () => find('.canon-figure-said').textContent;
const bars = () => findAll('.canon-compression-scale-bar');
const text = (element: Element | undefined) =>
	element?.textContent?.replace(/\s+/g, ' ').trim();

describe('canon-compression-scale', () => {
	test('the original over the result, the saving as a figure', async () => {
		const { rerender } = await render(Sized, {
			before: 0,
			after: 0,
		});
		expect(said(), 'a dash before a result').toBe('—');
		expect(text(bars()[0])).toBe('Original');
		expect(document.querySelector('.canon-loader')).toBeNull();

		await rerender({ before: 2_400_000, working: true });
		expect(document.querySelector('.canon-loader')).not.toBeNull();
		expect(text(bars()[0])).toBe('Original 2.3 MB');
		expect(text(bars()[1])).toBe('JPEG');

		await rerender({ after: 1_200_000, working: false });
		expect(said()).toBe('−50%');
		expect(text(bars()[1])).toBe('JPEG 1.1 MB');
		expect(bars()[1]!.hasAttribute('data-inside')).toBe(true);
		expect(
			bars()[1]!.style.getPropertyValue(
				'--canon-compression-scale-share',
			),
		).toBe('0.5');

		await rerender({ after: 3_600_000 });
		expect(said()).toBe('+50%');
		expect(
			find(
				bars()[1]!.querySelector('.canon-bar')!,
			).style.getPropertyValue('--canon-bar-fill'),
			'red when the result grew',
		).toBe('var(--canon-destructive)');

		await rerender({ after: 24_000 });
		expect(
			bars()[1]!.hasAttribute('data-inside'),
			'a sliver puts the label after the fill',
		).toBe(false);
	});
});
