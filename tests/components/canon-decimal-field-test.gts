import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { blur, click, fillIn, render } from '@ember/test-helpers';
import CanonDecimalField from '#src/components/canon-decimal-field.gts';

module('Component | canon-decimal-field', function (hooks) {
	setupRenderingTest(hooks);

	test('steps in tenths and commits typing on blur', async function (assert) {
		const values: number[] = [];
		const record = (value: number) => values.push(value);
		await render(
			<template>
				<CanonDecimalField
					@value={{1.5}}
					@label="Start"
					@onChange={{record}}
				/>
			</template>,
		);
		assert.dom('input').hasValue('1.5');
		assert.dom('.canon-stepper-unit').hasText('s');
		await click('.canon-stepper-plus');
		assert.dom('input').hasValue('1.6');
		await fillIn('input', '2,34567');
		await blur('input');
		assert.deepEqual(values, [1.6, 2.346]);
		assert.dom('input').hasValue('2.346');
		await click('.canon-stepper-minus');
		await fillIn('input', '-3');
		await blur('input');
		assert.strictEqual(values.at(-1), 0, 'unsigned stops at 0');
	});
});
