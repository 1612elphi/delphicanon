import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Widths from './fixtures/canon-tiles-widths.svelte';
import { find, findAll, waitUntil } from './helpers.ts';

const items = [
	{ label: 'Codec', value: 'AAC' },
	{ label: 'Peak', value: '-4.3 dBFS', level: 0.93 },
	{ label: 'RMS', value: '-13.6 dBFS', level: 0.77 },
];

describe('canon-tiles', () => {
	test('as many columns as fit, at least two, with level bars', async () => {
		await render(Widths, { items });
		const columns = (selector: string) =>
			find(`${selector} .canon-grid`).style.getPropertyValue(
				'--canon-grid-columns',
			);
		await waitUntil(() => columns('.wide') === '3');
		expect(columns('.wide')).toBe('3');
		expect(columns('.narrow')).toBe('2');
		expect(findAll('.wide .canon-tiles-level')).toHaveLength(2);
		expect(
			find('.wide .canon-tiles-tile')
				.textContent.replace(/\s+/g, ' ')
				.trim(),
		).toBe('Codec AAC');
	});
});
