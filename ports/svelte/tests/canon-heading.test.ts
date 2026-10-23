import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonHeading from '../src/components/canon-heading.svelte';
import { find } from './helpers.ts';

describe('canon-heading', () => {
	test('is a heading with its text', async () => {
		await render(CanonHeading, { text: 'Rows' });
		expect(find('h3.canon-heading').textContent).toBe('Rows');
	});
});
