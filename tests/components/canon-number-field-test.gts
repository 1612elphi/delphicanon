import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
	blur,
	click,
	fillIn,
	render,
	triggerKeyEvent,
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import CanonNumberField from '#src/components/canon-number-field.gts';

class State {
	@tracked value: number;
	values: number[] = [];
	constructor(
		value: number,
		readonly limit = Infinity,
	) {
		this.value = value;
	}
	set = (value: number) => {
		this.values.push(value);
		this.value = Math.min(value, this.limit);
	};
}

module('Component | canon-number-field', function (hooks) {
	setupRenderingTest(hooks);

	test('clamps, steps and takes typed integers in range', async function (assert) {
		const state = new State(9000);
		await render(
			<template>
				<CanonNumberField
					@value={{state.value}}
					@max={{5000}}
					@step={{50}}
					@unit="items"
					@label="Count"
					@onChange={{state.set}}
				/>
			</template>,
		);
		assert.dom('input')
			.hasValue('5000')
			.hasAttribute('role', 'spinbutton');
		assert.dom('.canon-stepper-unit').hasText('items');
		await click('.canon-stepper-plus');
		assert.deepEqual(
			state.values,
			[],
			'at the top, plus does nothing',
		);
		await click('.canon-stepper-minus');
		assert.dom('input').hasValue('4950');
		await fillIn('input', '12');
		await fillIn('input', '9999');
		await triggerKeyEvent('input', 'keydown', 'ArrowUp');
		await blur('input');
		assert.deepEqual(state.values, [4950, 12, 62]);
		assert.dom('input').hasValue('62');
	});

	test('shows the value the consumer keeps', async function (assert) {
		const state = new State(12, 12);
		await render(
			<template>
				<CanonNumberField
					@value={{state.value}}
					@label="From"
					@onChange={{state.set}}
				/>
			</template>,
		);
		await fillIn('input', '50');
		await blur('input');
		assert.deepEqual(state.values, [50]);
		assert.dom('input').hasValue(
			'12',
			'a refused value reverts on blur',
		);
		await click('.canon-stepper-plus');
		assert.deepEqual(state.values, [50, 13]);
		assert.dom('input').hasValue(
			'12',
			'a refused step shows the kept value',
		);
	});

	test('without onChange, keeps its own value', async function (assert) {
		await render(
			<template>
				<CanonNumberField
					@value={{3}}
					@label="Copies"
				/>
			</template>,
		);
		await click('.canon-stepper-plus');
		assert.dom('input').hasValue('4');
	});
});
