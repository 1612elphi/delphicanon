import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import Scenes from './fixtures/canon-layout-scenes.svelte';
import { findAll } from './helpers.ts';

describe('canon-rule', () => {
	test('draws a hairline either way', async () => {
		await render(Scenes, { scene: 'rule' });
		const [vertical, horizontal] = findAll('.canon-rule');
		expect(vertical?.offsetWidth).toBe(1);
		expect(vertical?.offsetHeight).toBe(40);
		expect(horizontal?.offsetHeight).toBe(1);
		expect(vertical?.getAttribute('aria-orientation')).toBe(
			'vertical',
		);
	});
});
