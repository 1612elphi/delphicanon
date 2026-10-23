import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Art from './fixtures/canon-preview-panel-art.svelte';
import { find } from './helpers.ts';

describe('canon-preview-panel', () => {
	test('caption and detail over the content', async () => {
		await render(Art);
		expect(
			find('figcaption')
				.textContent.replace(/\s+/g, ' ')
				.trim(),
		).toBe('Preview 1600 x 900');
		expect(
			document.querySelector(
				'.canon-preview-panel-content .art',
			),
		).not.toBeNull();
		const header = find('figcaption');
		const content = find('.canon-preview-panel-content');
		// the caption sits above the content
		expect(
			header.getBoundingClientRect().bottom,
		).toBeLessThanOrEqual(content.getBoundingClientRect().top);
	});
});
