import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import CanonColourStrip from '#src/components/canon-colour-strip.gts';
import type { Rgb } from '#src/lib/colour.ts';
import { fakeClipboard } from '../helpers/clipboard.ts';

const red: Rgb = [1, 0, 0];
const palette: Rgb[] = [red, [0, 1, 0], [0, 0, 1]];
const nameOf = () => 'Red';

module('Component | canon-colour-strip', function (hooks) {
	setupRenderingTest(hooks);

	test('shows name and value and copies the value', async function (assert) {
		const written = fakeClipboard(
			this.owner.lookup('service:canon-toast'),
		);
		await render(
			<template>
				<CanonColourStrip
					@colour={{red}}
					@nameOf={{nameOf}}
					@format="rgb"
				/>
			</template>,
		);
		assert.dom('.canon-colour-strip-name').hasText('Red');
		assert.dom('.canon-colour-strip-value').hasText(
			'rgb(255, 0, 0)',
		);
		await click('.canon-colour-strip-single');
		assert.deepEqual(written, ['rgb(255, 0, 0)']);
	});

	test('a palette shows swatches instead', async function (assert) {
		await render(
			<template>
				<CanonColourStrip
					@colour={{red}}
					@palette={{palette}}
				/>
			</template>,
		);
		assert.dom('.canon-swatch').exists({ count: 3 });
		assert.dom('.canon-colour-strip-single').doesNotExist();
	});
});
