import { describe, expect, test } from 'vitest';
import CanonSwitch from '../../src/components/canon-switch.tsx';
import { click, find, render } from '../helpers/render.tsx';

describe('canon-switch', () => {
	test('a native switch that reports each flip', async () => {
		const flips: boolean[] = [];
		const record = (on: boolean) => flips.push(on);
		await render(
			<CanonSwitch on aria-label="Sound" onChange={record} />,
		);
		const input = find<HTMLInputElement>('input');
		expect(input.getAttribute('role')).toBe('switch');
		expect(input.checked).toBe(true);
		expect(input.getAttribute('aria-checked')).toBe('true');
		await click('input');
		await click('input');
		expect(flips).toEqual([false, true]);
		expect(input.getAttribute('aria-checked')).toBe('true');
	});
});
