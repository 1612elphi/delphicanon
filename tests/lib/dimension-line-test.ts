import { module, test } from 'qunit';
import { dimensionLines, sheet } from '#src/lib/dimension-line.ts';

module('Unit | dimension-line', function () {
	test('the sheet leaves room for the lines', function (assert) {
		const area = { x: 16, y: 8, width: 544, height: 544 };
		assert.deepEqual(sheet({ width: 1080, height: 1080 }, area), {
			x: 60,
			y: 52,
			width: 500,
			height: 500,
		});
		assert.strictEqual(
			sheet(
				{ width: 1, height: 1 },
				{ x: 0, y: 0, width: 40, height: 40 },
			).width,
			0,
		);
	});

	test('lines over and beside a span, as the iOS self check', function (assert) {
		const span = { x: 44, y: 44, width: 200, height: 100 };
		const { across, down } = dimensionLines(span);
		assert.deepEqual(across, {
			x: 44,
			y: 0,
			width: 200,
			height: 32,
		});
		// centre (16, 94), 100 by 32 before the turn
		assert.deepEqual(down, {
			x: -34,
			y: 78,
			width: 100,
			height: 32,
		});
		const inner = { x: 94, y: 64, width: 100, height: 60 };
		assert.deepEqual(dimensionLines(inner, span, 8).across, {
			x: 94,
			y: 4,
			width: 100,
			height: 32,
		});
	});
});
