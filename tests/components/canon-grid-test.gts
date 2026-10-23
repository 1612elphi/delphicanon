import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled } from '@ember/test-helpers';
import CanonButton from '#src/components/canon-button.gts';
import CanonGrid from '#src/components/canon-grid.gts';
import Dot from '../helpers/dot.gts';
import { css } from '../helpers/css.ts';

const nextFrame = () =>
	new Promise((resolve) =>
		requestAnimationFrame(() => resolve(undefined)),
	);

module('Component | canon-grid', function (hooks) {
	setupRenderingTest(hooks);

	test('balances rows: four cells at three columns are two rows of two', async function (assert) {
		await render(
			<template>
				<div style={{css "width: 300px"}}>
					<CanonGrid @columns={{3}}>
						<div>1</div><div>2</div><div
						>3</div><div>4</div>
					</CanonGrid>
				</div>
			</template>,
		);
		const cells = [
			...document.querySelectorAll<HTMLElement>(
				'.canon-grid > div',
			),
		];
		assert.deepEqual(
			cells.map((c) => c.offsetTop > cells[0]!.offsetTop),
			[false, false, true, true],
		);
		assert.strictEqual(
			cells[0]!.offsetWidth,
			cells[3]!.offsetWidth,
		);
	});

	test('the last cell of a short row spans the rest', async function (assert) {
		await render(
			<template>
				<div style={{css "width: 302px"}}>
					<CanonGrid @columns={{3}}>
						<div>1</div><div>2</div><div
						>3</div><div>4</div><div>5</div>
					</CanonGrid>
				</div>
			</template>,
		);
		const cells = [
			...document.querySelectorAll<HTMLElement>(
				'.canon-grid > div',
			),
		];
		assert.strictEqual(
			cells[3]!.offsetWidth,
			cells[0]!.offsetWidth,
		);
		assert.strictEqual(
			cells[4]!.offsetWidth,
			cells[1]!.offsetWidth * 2 + 1,
		);
	});

	test('filling buttons drop their titles together when one does not fit', async function (assert) {
		await render(
			<template>
				<div
					class="narrow"
					style={{css "width: 240px"}}
				>
					<CanonGrid>
						<CanonButton
							@text="Loop"
							@icon={{Dot}}
						/>
						<CanonButton
							@text="Shuffle"
							@icon={{Dot}}
						/>
						<CanonButton
							@text="Export"
							@icon={{Dot}}
						/>
					</CanonGrid>
				</div>
				<div class="wide" style={{css "width: 900px"}}>
					<CanonGrid>
						<CanonButton
							@text="Loop"
							@icon={{Dot}}
						/>
						<CanonButton
							@text="Shuffle"
							@icon={{Dot}}
						/>
						<CanonButton
							@text="Export"
							@icon={{Dot}}
						/>
					</CanonGrid>
				</div>
			</template>,
		);
		await nextFrame();
		await settled();
		assert.dom('.narrow .canon-grid').hasAttribute(
			'data-symbol-only',
		);
		assert.dom('.narrow .canon-button-title').isNotVisible();
		assert.dom('.narrow .canon-button').hasAttribute(
			'aria-label',
			'Loop',
		);
		assert.dom('.wide .canon-grid').doesNotHaveAttribute(
			'data-symbol-only',
		);
	});
});
