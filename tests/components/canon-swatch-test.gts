import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import CanonSwatch from '#src/components/canon-swatch.gts';
import type { Rgb } from '#src/lib/colour.ts';
import { css } from '../helpers/css.ts';
import { fakeClipboard } from '../helpers/clipboard.ts';

const yellow: Rgb = [1, 0.9, 0];
const nameOf = () => 'Yellow';

module('Component | canon-swatch', function (hooks) {
	setupRenderingTest(hooks);

	test('shows its hex in the ink that reads and copies it', async function (assert) {
		const written = fakeClipboard(
			this.owner.lookup('service:canon-toast'),
		);
		await render(
			<template>
				<div
					style={{css
						"display: grid; width: 120px; height: 52px"
					}}
				>
					<CanonSwatch
						@colour={{yellow}}
						@nameOf={{nameOf}}
					/>
				</div>
			</template>,
		);
		assert.dom('.canon-swatch-hex').hasText('#FFE600').isVisible();
		assert.dom('.canon-swatch').hasAttribute(
			'aria-label',
			'Yellow #FFE600',
		);
		assert.strictEqual(
			document.querySelector<HTMLElement>('.canon-swatch')!
				.style.color,
			'black',
		);
		await click('.canon-swatch');
		assert.deepEqual(written, ['#FFE600']);
	});

	test('drops the hex when narrow', async function (assert) {
		await render(
			<template>
				<div
					style={{css
						"display: grid; width: 30px; height: 52px"
					}}
				>
					<CanonSwatch @colour={{yellow}} />
				</div>
			</template>,
		);
		assert.dom('.canon-swatch-hex').isNotVisible();
	});
});
