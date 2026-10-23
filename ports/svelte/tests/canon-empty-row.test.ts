import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonEmptyRow from '../src/components/canon-empty-row.svelte';
import { find } from './helpers.ts';

test('shows its text in a tall row', async () => {
	await render(CanonEmptyRow, { text: 'Nothing here' });
	expect(find('.canon-empty-row').textContent).toBe('Nothing here');
	expect(find('.canon-empty-row').offsetHeight).toBe(96);
});
