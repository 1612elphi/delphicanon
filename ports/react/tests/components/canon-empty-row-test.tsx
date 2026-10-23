import { describe, expect, test } from 'vitest';
import CanonEmptyRow from '../../src/components/canon-empty-row.tsx';
import { find, render } from '../helpers/render.tsx';

describe('canon-empty-row', () => {
	test('shows its text in a tall row', async () => {
		await render(<CanonEmptyRow text="Nothing here" />);
		expect(find('.canon-empty-row').textContent).toBe(
			'Nothing here',
		);
		expect(find('.canon-empty-row').offsetHeight).toBe(96);
	});
});
