import { expect, test } from 'vitest';
import CanonSwitch from '../../src/components/canon-switch.vue';
import { click, find, render } from '../helpers/render.ts';

test('a native switch that reports each flip', async () => {
	const flips: boolean[] = [];
	const record = (on: boolean) => flips.push(on);
	await render(
		`<CanonSwitch :on="true" aria-label="Sound" :on-change="record" />`,
		{ CanonSwitch, record },
	);
	expect(find('input')).toHaveAttribute('role', 'switch');
	expect(find('input')).toBeChecked();
	expect(find('input')).toHaveAttribute('aria-checked', 'true');
	await click('input');
	await click('input');
	expect(flips).toEqual([false, true]);
	expect(find('input')).toHaveAttribute('aria-checked', 'true');
});
