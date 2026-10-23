import { module, test } from 'qunit';
import { frame } from '#src/lib/loupe.ts';

const size = { width: 400, height: 300 };

module('Unit | lib/loupe', function () {
	test('up and to the left of the point', function (assert) {
		assert.deepEqual(frame({ x: 200, y: 200 }, 100, 20, size, 0), {
			x: 80,
			y: 80,
			width: 100,
			height: 100,
		});
	});

	test('turns back inside near an edge and below the top', function (assert) {
		const near = frame({ x: 50, y: 60 }, 100, 20, size, 40);
		assert.strictEqual(near.x, 70, 'right of the point');
		assert.strictEqual(near.y, 80, 'below the point');
		const corner = frame({ x: 390, y: 290 }, 100, 20, size, 0);
		assert.deepEqual([corner.x, corner.y], [270, 170]);
		const kept = frame({ x: 395, y: 295 }, 100, 20, size, 0, {
			left: false,
			above: false,
		});
		assert.deepEqual(
			[kept.x, kept.y],
			[292, 192],
			'held side, kept inside',
		);
	});
});
