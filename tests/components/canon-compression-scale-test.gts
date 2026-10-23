import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, rerender } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import CanonCompressionScale from '#src/components/canon-compression-scale.gts';
import { css } from '../helpers/css.ts';

class Sizes {
	@tracked before = 0;
	@tracked after = 0;
	@tracked working = false;
}

const said = () => document.querySelector('.canon-figure-said')!.textContent;
const bars = () => [
	...document.querySelectorAll<HTMLElement>(
		'.canon-compression-scale-bar',
	),
];

module('Component | canon-compression-scale', function (hooks) {
	setupRenderingTest(hooks);

	test('the original over the result, the saving as a figure', async function (assert) {
		const state = new Sizes();
		await render(
			<template>
				<div
					style={{css
						"width: 600px; height: 176px"
					}}
				>
					<CanonCompressionScale
						@before={{state.before}}
						@after={{state.after}}
						@format="JPEG"
						@working={{state.working}}
					/>
				</div>
			</template>,
		);
		assert.strictEqual(said(), '—', 'a dash before a result');
		assert.dom('.canon-compression-scale-label').hasText(
			'Original',
		);
		assert.dom('.canon-loader').doesNotExist();

		state.before = 2_400_000;
		state.working = true;
		await rerender();
		assert.dom('.canon-loader').exists();
		assert.dom(bars()[0]).hasText('Original 2.3 MB');
		assert.dom(bars()[1]).hasText('JPEG');

		state.after = 1_200_000;
		state.working = false;
		await rerender();
		assert.strictEqual(said(), '−50%');
		assert.dom(bars()[1]).hasText('JPEG 1.1 MB');
		assert.dom(bars()[1]).hasAttribute('data-inside');
		assert.strictEqual(
			bars()[1]!.style.getPropertyValue(
				'--canon-compression-scale-share',
			),
			'0.5',
		);

		state.after = 3_600_000;
		await rerender();
		assert.strictEqual(said(), '+50%');
		assert.strictEqual(
			bars()[1]!
				.querySelector<HTMLElement>('.canon-bar')!
				.style.getPropertyValue('--canon-bar-fill'),
			'var(--canon-destructive)',
			'red when the result grew',
		);

		state.after = 24_000;
		await rerender();
		assert.dom(bars()[1]).doesNotHaveAttribute(
			'data-inside',
			'a sliver puts the label after the fill',
		);
	});
});
