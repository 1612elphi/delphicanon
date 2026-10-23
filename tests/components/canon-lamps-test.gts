import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, rerender } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import CanonLamps from '#src/components/canon-lamps.gts';

class State {
	@tracked loops = 0;
}

module('Component | canon-lamps', function (hooks) {
	setupRenderingTest(hooks);

	test('every lamp present, lit ones lit, a flash blinks', async function (assert) {
		const state = new State();
		const lit = ['play', 'loop'] as const;
		await render(
			<template>
				<CanonLamps
					@lit={{lit}}
					@flashes={{hash loop=state.loops}}
				/>
				<CanonLamps
					class="rec"
					@lamps={{recording}}
					@lit={{recording}}
				/>
			</template>,
		);
		assert.dom('.canon-lamps-lamp').exists({ count: 5 });
		assert.dom('.canon-lamps-lamp--play').hasClass(
			'canon-lamps-lamp--lit',
		);
		assert.dom('.canon-lamps-lamp--pause').doesNotHaveClass(
			'canon-lamps-lamp--lit',
		);
		assert.dom('.canon-lamps-lamp--blink').doesNotExist();
		state.loops = 1;
		await rerender();
		assert.dom('.canon-lamps-lamp--loop').hasClass(
			'canon-lamps-lamp--blink',
		);
		assert.dom('.rec .canon-lamps-lamp--record').hasClass(
			'canon-lamps-lamp--lit',
		);
	});
});

const recording = ['record' as const, 'pause' as const];
