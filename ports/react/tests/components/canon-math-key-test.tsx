import { describe, expect, test } from 'vitest';
import CanonMathKey from '../../src/components/canon-math-key.tsx';
import type { Key } from '@canon/lib/math/expression.ts';
import { click, find, render, trigger } from '../helpers/render.tsx';

describe('canon-math-key', () => {
	test('a key takes its family, label and one tap', async () => {
		let taps = 0;
		const tap = () => (taps += 1);
		const root: Key = { kind: 'root' };
		const times: Key = { kind: 'symbol', symbol: '×' };
		await render(
			<>
				<CanonMathKey
					className="root"
					mathKey={root}
					onClick={tap}
				/>
				<CanonMathKey
					className="times"
					mathKey={times}
				/>
			</>,
		);
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
		await trigger('.root', 'pointerdown', {
			clientX: 10,
			clientY: 10,
		});
		await trigger('.root', 'pointermove', {
			clientX: 40,
			clientY: 10,
		});
		// a real drag ends with pointerup then click, and no second pointerdown
		await trigger('.root', 'pointerup', {
			clientX: 40,
			clientY: 10,
		});
		await trigger('.root', 'click');
		expect(taps).toBe(1);
	});
});
