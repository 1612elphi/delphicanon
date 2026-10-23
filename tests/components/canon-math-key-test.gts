import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, triggerEvent } from '@ember/test-helpers';
import CanonMathKey from '#src/components/canon-math-key.gts';
import { type Key } from '#src/lib/math/expression.ts';

module('Component | canon-math-key', function (hooks) {
	setupRenderingTest(hooks);

	test('a key takes its family, label and one tap', async function (assert) {
		let taps = 0;
		const tap = () => (taps += 1);
		const root: Key = { kind: 'root' };
		const times: Key = { kind: 'symbol', symbol: '×' };
		await render(
			<template>
				<CanonMathKey
					class="root"
					@key={{root}}
					@onClick={{tap}}
				/>
				<CanonMathKey class="times" @key={{times}} />
			</template>,
		);
		assert.dom('.root').hasClass('canon-math-key--structure');
		assert.dom('.root').hasAttribute('aria-label', 'Square root');
		assert.dom('.times').hasClass('canon-math-key--operation');
		await click('.root');
		assert.strictEqual(taps, 1);
		await triggerEvent('.root', 'pointerdown', {
			clientX: 10,
			clientY: 10,
		});
		await triggerEvent('.root', 'pointermove', {
			clientX: 40,
			clientY: 10,
		});
		await click('.root');
		assert.strictEqual(
			taps,
			1,
			'a drag past the slop does not type',
		);
	});
});
