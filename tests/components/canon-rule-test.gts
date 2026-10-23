import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import { css } from '../helpers/css.ts';
import CanonRule from '#src/components/canon-rule.gts';

module('Component | canon-rule', function (hooks) {
	setupRenderingTest(hooks);

	test('draws a hairline either way', async function (assert) {
		await render(
			<template>
				<div
					style={{css
						"display: flex; height: 40px"
					}}
				><CanonRule @vertical={{true}} /></div>
				<CanonRule />
			</template>,
		);
		const [vertical, horizontal] = [
			...document.querySelectorAll<HTMLElement>(
				'.canon-rule',
			),
		];
		assert.strictEqual(vertical?.offsetWidth, 1);
		assert.strictEqual(vertical?.offsetHeight, 40);
		assert.strictEqual(horizontal?.offsetHeight, 1);
		assert.dom(vertical).hasAttribute(
			'aria-orientation',
			'vertical',
		);
	});
});
