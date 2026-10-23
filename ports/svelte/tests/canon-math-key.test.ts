import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonMathKey from '../src/components/canon-math-key.svelte';
import type { Key } from '@canon/lib/math/expression.ts';
import { click, find, triggerEvent } from './helpers.ts';

describe('canon-math-key', () => {
	test('a key takes its family, label and one tap', async () => {
		let taps = 0;
		const tap = () => (taps += 1);
		const root: Key = { kind: 'root' };
		const times: Key = { kind: 'symbol', symbol: '×' };
		await render(CanonMathKey, {
			class: 'root',
			key: root,
			onClick: tap,
		});
		await render(CanonMathKey, { class: 'times', key: times });
		expect(find('.root').classList).toContain(
			'canon-math-key--structure',
		);
		expect(find('.root').getAttribute('aria-label')).toBe(
			'Square root',
		);
		expect(find('.times').classList).toContain(
			'canon-math-key--operation',
		);
		await click('.root');
		expect(taps).toBe(1);
		await triggerEvent('.root', 'pointerdown', {
			clientX: 10,
			clientY: 10,
		});
		await triggerEvent('.root', 'pointermove', {
			clientX: 40,
			clientY: 10,
		});
		await click('.root');
		expect(taps, 'a drag past the slop does not type').toBe(1);
	});
});
