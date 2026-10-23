import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import CanonSwitch from '#src/components/canon-switch.gts';

module('Component | canon-switch', function (hooks) {
	setupRenderingTest(hooks);

	test('a native switch that reports each flip', async function (assert) {
		const flips: boolean[] = [];
		const record = (on: boolean) => flips.push(on);
		await render(
			<template>
				<CanonSwitch
					@on={{true}}
					aria-label="Sound"
					@onChange={{record}}
				/>
			</template>,
		);
		assert.dom('input').hasAttribute('role', 'switch').isChecked();
		assert.dom('input').hasAttribute('aria-checked', 'true');
		await click('input');
		await click('input');
		assert.deepEqual(flips, [false, true]);
		assert.dom('input').hasAttribute('aria-checked', 'true');
	});
});
