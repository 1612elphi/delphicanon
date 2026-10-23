import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import CanonMathKeypad from '#src/components/canon-math-keypad.gts';
import { type Key } from '#src/lib/math/expression.ts';
import { css } from '../helpers/css.ts';

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
const all = (selector: string) => [
	...document.querySelectorAll<HTMLElement>(selector),
];

module('Component | canon-math-keypad', function (hooks) {
	setupRenderingTest(hooks);

	test('the keypad types keys, pages and opens submenus', async function (assert) {
		const typed: Key[] = [];
		let done = 0;
		const onKey = (key: Key) => typed.push(key);
		const onDone = () => (done += 1);
		await render(
			<template>
				<div style={{css "width: 420px"}}>
					<CanonMathKeypad
						@variable="t"
						@onKey={{onKey}}
						@onDone={{onDone}}
					/>
				</div>
			</template>,
		);
		assert.strictEqual(all('.canon-math-keypad-page').length, 4);
		const firstPage = all('.canon-math-keypad-page')[0];
		assert.strictEqual(
			all('.canon-math-keypad-page')[0]!.children.length,
			23,
			'the numbers page, with a wide 0',
		);
		await click('[aria-label="7"]');
		await click('[aria-label="Delete"]');
		await click('[aria-label="Done"]');
		assert.deepEqual(typed, [
			{ kind: 'symbol', symbol: '7' },
			{ kind: 'delete' },
		]);
		assert.strictEqual(done, 1);
		assert.dom(
			'.canon-math-keypad-page:first-child .canon-math-key--letter',
		).hasAttribute('aria-label', 't');

		await click('.canon-math-tab:nth-child(2)');
		await wait(900);
		const pager = document.querySelector<HTMLElement>(
			'.canon-math-keypad-pager',
		)!;
		assert.strictEqual(
			Math.round(pager.scrollLeft / pager.clientWidth),
			1,
		);
		assert.dom('.canon-math-tab:nth-child(2)').hasAttribute(
			'aria-current',
			'true',
		);
		assert.strictEqual(
			all('.canon-math-keypad-page')[0],
			firstPage,
			'scrolling keeps the page elements, whose replacement resets the scroll in WebKit',
		);

		await click('[data-canon-math-key="1-0-3"]');
		assert.dom('.canon-math-submenu .canon-math-key').exists({
			count: 6,
		});
		await click('.canon-math-submenu [aria-label="cosh"]');
		assert.dom('.canon-math-submenu').doesNotExist(
			'typing closes it',
		);
		assert.deepEqual(typed.at(-1), {
			kind: 'function',
			name: 'cosh',
			arity: 1,
		});
		await wait(1100);
		assert.strictEqual(
			Math.round(pager.scrollLeft / pager.clientWidth),
			0,
			'a slot key on a later page returns to 123',
		);
	});
});
