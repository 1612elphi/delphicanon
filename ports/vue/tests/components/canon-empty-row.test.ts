import { expect, test } from 'vitest';
import CanonEmptyRow from '../../src/components/canon-empty-row.vue';
import { find, render } from '../helpers/render.ts';

test('shows its text in a tall row', async () => {
	await render(`<CanonEmptyRow text="Nothing here" />`, {
		CanonEmptyRow,
	});
	expect(find('.canon-empty-row')).toHaveTextContent('Nothing here');
	expect(find('.canon-empty-row').offsetHeight).toBe(96);
});
