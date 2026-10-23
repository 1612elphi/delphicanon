import { describe, expect, test } from 'vitest';
import CanonMathKeypad from '../../src/components/canon-math-keypad.tsx';
import type { Key } from '@canon/lib/math/expression.ts';
import { click, find, findAll, render, wait } from '../helpers/render.tsx';

describe('canon-math-keypad', () => {
	test('the keypad types keys, pages and opens submenus', async () => {
		const typed: Key[] = [];
		let done = 0;
		const onKey = (key: Key) => typed.push(key);
		const onDone = () => (done += 1);
		await render(
			<div style={{ width: 420 }}>
				<CanonMathKeypad
					variable="t"
					onKey={onKey}
					onDone={onDone}
				/>
			</div>,
		);
		expect(findAll('.canon-math-keypad-page').length).toBe(4);
		expect(
			findAll('.canon-math-keypad-page')[0]!.children.length,
		).toBe(23);
		await click('[aria-label="7"]');
		await click('[aria-label="Delete"]');
		await click('[aria-label="Done"]');
		expect(typed).toEqual([
			{ kind: 'symbol', symbol: '7' },
			{ kind: 'delete' },
		]);
		expect(done).toBe(1);
		expect(
			find(
				'.canon-math-keypad-page:first-child .canon-math-key--letter',
			).getAttribute('aria-label'),
		).toBe('t');

		await click('.canon-math-tab:nth-child(2)');
		await wait(900);
		const pager = find('.canon-math-keypad-pager');
		expect(Math.round(pager.scrollLeft / pager.clientWidth)).toBe(
			1,
		);
		expect(
			find('.canon-math-tab:nth-child(2)').getAttribute(
				'aria-current',
			),
		).toBe('true');

		await click('[data-canon-math-key="1-0-3"]');
		expect(
			findAll('.canon-math-submenu .canon-math-key').length,
		).toBe(6);
		await click('.canon-math-submenu [aria-label="cosh"]');
		expect(
			document.querySelector('.canon-math-submenu'),
		).toBeNull();
		expect(typed.at(-1)).toEqual({
			kind: 'function',
			name: 'cosh',
			arity: 1,
		});
		await wait(1100);
		expect(Math.round(pager.scrollLeft / pager.clientWidth)).toBe(
			0,
		);
	});
});
