import { expect, test } from 'vitest';
import CanonRule from '../../src/components/canon-rule.vue';
import { findAll, render } from '../helpers/render.ts';

test('draws a hairline either way', async () => {
	await render(
		`<div style="display: flex; height: 40px"><CanonRule :vertical="true" /></div>
    <CanonRule />`,
		{ CanonRule },
	);
	const [vertical, horizontal] = findAll('.canon-rule');
	expect(vertical?.offsetWidth).toBe(1);
	expect(vertical?.offsetHeight).toBe(40);
	expect(horizontal?.offsetHeight).toBe(1);
	expect(vertical).toHaveAttribute('aria-orientation', 'vertical');
});
