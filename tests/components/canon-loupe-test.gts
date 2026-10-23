import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import CanonLoupe from '#src/components/canon-loupe.gts';

module('Component | canon-loupe', function (hooks) {
	setupRenderingTest(hooks);

	test('draws the pixels unsmoothed in a frame of the colour', async function (assert) {
		const pixels = new ImageData(3, 3);
		pixels.data.set([255, 0, 0, 255], 4 * 4);
		await render(
			<template>
				<CanonLoupe
					@pixels={{pixels}}
					@colour={{array 1 0 0}}
				/>
			</template>,
		);
		const canvas =
			document.querySelector<HTMLCanvasElement>('canvas')!;
		assert.deepEqual([canvas.width, canvas.height], [3, 3]);
		assert.deepEqual(
			[
				...canvas
					.getContext('2d')!
					.getImageData(1, 1, 1, 1).data,
			],
			[255, 0, 0, 255],
		);
		assert.strictEqual(
			getComputedStyle(canvas).imageRendering,
			'pixelated',
		);
		const loupe =
			document.querySelector<HTMLElement>('.canon-loupe')!;
		assert.strictEqual(
			getComputedStyle(loupe).borderTopColor,
			'rgb(255, 0, 0)',
		);
		assert.strictEqual(
			getComputedStyle(loupe).borderTopWidth,
			'6px',
		);
	});
});

function array(...values: number[]) {
	return values as [number, number, number];
}
