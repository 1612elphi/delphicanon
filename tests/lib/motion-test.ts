import { module, test } from 'qunit';
import { capture, pressedTransform, springEasing } from '#src/lib/motion.ts';

const angle = (transform: string, axis: 'X' | 'Y') =>
	Number(
		new RegExp(`rotate${axis}\\((-?[\\d.]+)rad\\)`).exec(
			transform,
		)?.[1],
	);

module('Unit | lib/motion', function () {
	test('no point presses the centre with no lean', function (assert) {
		assert.strictEqual(
			pressedTransform(100, 44),
			'perspective(600px) scale(0.97)',
		);
	});

	test('the edge under the pointer sinks, within 22 degrees', function (assert) {
		const right = pressedTransform(100, 44, { x: 100, y: 22 });
		const bottom = pressedTransform(100, 44, { x: 50, y: 44 });
		assert.true(
			angle(right, 'Y') > 0,
			'rotateY positive sinks the right edge',
		);
		assert.true(
			angle(bottom, 'X') < 0,
			'rotateX negative sinks the bottom edge',
		);
		const small = pressedTransform(10, 10, { x: 10, y: 5 });
		assert.true(angle(small, 'Y') <= (22 * Math.PI) / 180 + 1e-4);
	});

	test('the spring starts at rest and ends settled', function (assert) {
		const easing = springEasing(0.45);
		const points = easing.slice(7, -1).split(', ').map(Number);
		assert.strictEqual(points[0], 0);
		assert.strictEqual(points.at(-1), 1);
		assert.true(
			Math.max(...points) > 1,
			'underdamped: it overshoots',
		);
	});

	test('a capture blocks text selection until its pointer is released', function (assert) {
		const selects = () =>
			document.dispatchEvent(
				new Event('selectstart', { cancelable: true }),
			);
		const element = document.createElement('div');
		document.body.append(element);
		capture(element, 7);
		assert.false(
			selects(),
			'blocked while held, a synthetic pointer too',
		);
		window.dispatchEvent(
			new PointerEvent('pointerup', { pointerId: 8 }),
		);
		assert.false(selects(), 'another pointer does not release it');
		window.dispatchEvent(
			new PointerEvent('pointerup', { pointerId: 7 }),
		);
		assert.true(selects());
		element.remove();
	});
});
