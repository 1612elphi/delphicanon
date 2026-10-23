import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { fillIn, render } from '@ember/test-helpers';
import CanonColourWell from '#src/components/canon-colour-well.gts';
import type { Rgb } from '#src/lib/colour.ts';

const green: Rgb = [0, 0.5, 0];

module('Component | canon-colour-well', function (hooks) {
	setupRenderingTest(hooks);

	test('a typed hex changes the colour; anything else puts it back', async function (assert) {
		const changes: Rgb[] = [];
		const change = (colour: Rgb) => changes.push(colour);
		await render(
			<template>
				<CanonColourWell
					@label="Foreground"
					@colour={{green}}
					@format="rgb"
					@onChange={{change}}
				/>
			</template>,
		);
		assert.dom('.canon-colour-well-label').hasText('Foreground');
		assert.dom('input[type=text]').hasValue('008000');
		assert.dom('input[type=color]').hasValue('#008000');
		assert.dom('.canon-colour-well-echo').hasText('rgb(0, 128, 0)');
		await fillIn('input[type=text]', '#ff0000');
		assert.deepEqual(changes, [[1, 0, 0]]);
		await fillIn('input[type=text]', 'nope');
		assert.strictEqual(changes.length, 1);
		assert.dom('input[type=text]').hasValue('008000');
	});
});
