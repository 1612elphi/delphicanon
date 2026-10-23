import { describe, expect, test } from 'vitest';
import CanonHeading from '../../src/components/canon-heading.tsx';
import { find, render } from '../helpers/render.tsx';

describe('canon-heading', () => {
	test('is a heading with its text', async () => {
		await render(<CanonHeading text="Rows" />);
		expect(find('h3.canon-heading').textContent).toBe('Rows');
	});
});
