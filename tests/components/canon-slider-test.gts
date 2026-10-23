import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
	render,
	rerender,
	triggerEvent,
	triggerKeyEvent,
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import CanonSlider from '#src/components/canon-slider.gts';
import { css } from '../helpers/css.ts';

const whole = (value: number) => String(Math.round(value));

class State {
	@tracked value = 50;
	values: number[] = [];
	set = (value: number) => {
		this.values.push(value);
		this.value = value;
	};
}

module('Component | canon-slider', function (hooks) {
	setupRenderingTest(hooks);

	test('shows the readout and steps from the keyboard', async function (assert) {
		const values: number[] = [];
		const record = (value: number) => values.push(value);
		await render(
			<template>
				<CanonSlider
					@value={{99.4}}
					@min={{1}}
					@max={{100}}
					@step={{1}}
					@readout={{whole}}
					@label="Level"
					@onChange={{record}}
				/>
			</template>,
		);
		assert.dom('.canon-slider').hasAttribute('role', 'slider');
		assert.dom('.canon-slider-readout').hasText('99');
		await triggerKeyEvent('.canon-slider', 'keydown', 'ArrowRight');
		await triggerKeyEvent('.canon-slider', 'keydown', 'ArrowRight');
		assert.deepEqual(values, [100], 'stops at the top');
		await triggerKeyEvent('.canon-slider', 'keydown', 'Home');
		assert.dom('.canon-slider').hasAttribute('aria-valuenow', '1');
	});

	test('a tap on the track sets the value', async function (assert) {
		await render(
			<template>
				<div style={{css "width: 300px"}}><CanonSlider
						@value={{0.2}}
						@label="Mix"
					/></div>
			</template>,
		);
		const track = document
			.querySelector('.canon-slider-track')!
			.getBoundingClientRect();
		const at = {
			button: 0,
			pointerId: 1,
			clientX: track.left + track.width * 0.75,
			clientY: track.top + track.height / 2,
		};
		await triggerEvent('.canon-slider', 'pointerdown', at);
		await triggerEvent('.canon-slider', 'pointerup', at);
		assert.dom('.canon-slider-readout').hasText('75%');
	});

	test('follows a value set elsewhere after a change', async function (assert) {
		const state = new State();
		await render(
			<template>
				<CanonSlider
					@value={{state.value}}
					@min={{0}}
					@max={{100}}
					@step={{10}}
					@readout={{whole}}
					@label="Level"
					@onChange={{state.set}}
				/>
			</template>,
		);
		await triggerKeyEvent('.canon-slider', 'keydown', 'ArrowRight');
		state.value = 50;
		await rerender();
		assert.dom('.canon-slider-readout').hasText(
			'50',
			'an undo shows the old value',
		);
		await triggerKeyEvent('.canon-slider', 'keydown', 'ArrowRight');
		assert.deepEqual(
			state.values,
			[60, 60],
			'the same step is sent again',
		);
		assert.dom('.canon-slider').hasAttribute('aria-valuenow', '60');
	});

	test('a new range clamps the value', async function (assert) {
		await render(
			<template>
				<CanonSlider
					@value={{8}}
					@max={{5}}
					@label="Gain"
				/>
			</template>,
		);
		assert.dom('.canon-slider').hasAttribute('aria-valuenow', '5');
	});
});
