import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, triggerEvent } from '@ember/test-helpers';
import sidewaysPan from '#src/modifiers/canon-sideways-pan.ts';
import grabPan from '#src/modifiers/canon-grab-pan.ts';
import { css } from '../helpers/css.ts';

const point = (x: number, y: number) => ({
	pointerId: 1,
	button: 0,
	clientX: x,
	clientY: y,
});

module('Modifier | canon pans', function (hooks) {
	setupRenderingTest(hooks);

	test('a sideways pan begins only on a clearly sideways drag', async function (assert) {
		const moves: number[] = [];
		const onMove = (event: PointerEvent) =>
			moves.push(event.clientX);
		await render(
			<template>
				<div
					class="pad"
					style={{css
						"width: 200px; height: 100px"
					}}
					{{sidewaysPan onMove=onMove}}
				></div>
			</template>,
		);
		assert.dom('.pad').hasStyle({ touchAction: 'pan-y' });
		await triggerEvent('.pad', 'pointerdown', point(10, 10));
		await triggerEvent('.pad', 'pointermove', point(12, 20));
		await triggerEvent('.pad', 'pointermove', point(40, 20));
		await triggerEvent('.pad', 'pointerup', point(40, 20));
		assert.deepEqual(moves, [], 'a downward start never begins');
		await triggerEvent('.pad', 'pointerdown', point(10, 10));
		await triggerEvent('.pad', 'pointermove', point(13, 10));
		await triggerEvent('.pad', 'pointermove', point(30, 12));
		await triggerEvent('.pad', 'pointermove', point(50, 12));
		assert.deepEqual(moves, [30, 50]);
	});

	test('a grab pan begins only where grabs says', async function (assert) {
		const begun: number[] = [];
		const grabs = ({ x }: { x: number }) => x < 50;
		const onBegin = (event: PointerEvent) =>
			begun.push(event.clientX);
		await render(
			<template>
				<div
					class="pad"
					style={{css
						"width: 200px; height: 100px"
					}}
					{{grabPan grabs=grabs onBegin=onBegin}}
				></div>
			</template>,
		);
		const box = document
			.querySelector('.pad')!
			.getBoundingClientRect();
		await triggerEvent(
			'.pad',
			'pointerdown',
			point(box.left + 150, box.top + 5),
		);
		await triggerEvent(
			'.pad',
			'pointerup',
			point(box.left + 150, box.top + 5),
		);
		await triggerEvent(
			'.pad',
			'pointerdown',
			point(box.left + 10, box.top + 5),
		);
		assert.deepEqual(begun, [box.left + 10]);
	});
});
