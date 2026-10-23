import { expect, test } from 'vitest';
import CanonHeading from '../../src/components/canon-heading.vue';
import { find, render } from '../helpers/render.ts';

test('is a heading with its text', async () => {
	await render(`<CanonHeading text="Rows" />`, { CanonHeading });
	expect(find('h3.canon-heading')).toHaveTextContent('Rows');
});
