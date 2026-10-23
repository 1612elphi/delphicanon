import { module, test } from 'qunit';
import {
	clamp,
	dragSpeed,
	formatDecimal,
	parseDecimal,
	parseInteger,
	roundDecimal,
	snap,
} from '#src/lib/number.ts';

module('Unit | lib/number', function () {
	test('parseInteger takes whole numbers only', function (assert) {
		assert.strictEqual(parseInteger(' 42 '), 42);
		assert.strictEqual(parseInteger('-7'), -7);
		assert.strictEqual(parseInteger('4.2'), undefined);
		assert.strictEqual(parseInteger(''), undefined);
		assert.strictEqual(parseInteger('-'), undefined);
		assert.strictEqual(
			parseInteger('99999999999999999999'),
			undefined,
		);
	});

	test('parseDecimal reads a comma as the decimal point', function (assert) {
		assert.strictEqual(parseDecimal('1,25'), 1.25);
		assert.strictEqual(parseDecimal('.5'), 0.5);
		assert.strictEqual(parseDecimal('-0.001'), -0.001);
		assert.strictEqual(parseDecimal('3.'), 3);
		assert.strictEqual(parseDecimal('1.2.3'), undefined);
		assert.strictEqual(parseDecimal('abc'), undefined);
	});

	test('roundDecimal rounds to places, then clamps', function (assert) {
		assert.strictEqual(roundDecimal(1.23456, 3, 0, 10), 1.235);
		assert.strictEqual(roundDecimal(0.1 + 0.2, 3, 0, 10), 0.3);
		assert.strictEqual(roundDecimal(-1, 3, 0, 10), 0);
		assert.strictEqual(roundDecimal(12, 3, 0, 10), 10);
	});

	test('formatDecimal drops trailing zeros and grouping', function (assert) {
		assert.strictEqual(formatDecimal(1.5, 3), '1.5');
		assert.strictEqual(formatDecimal(2, 3), '2');
		assert.strictEqual(formatDecimal(1234.5678, 3), '1234.568');
		assert.strictEqual(formatDecimal(-0.000001, 6), '-0.000001');
	});

	test('snap clamps and steps from the lower bound', function (assert) {
		assert.strictEqual(snap(99.4 + 1, 1, 100, 1), 100);
		assert.strictEqual(snap(101, 1, 100, 1), 100);
		assert.strictEqual(snap(7.4, 2, 20, 5), 7);
		assert.strictEqual(snap(0.33, 0, 1), 0.33);
		assert.strictEqual(clamp(8, 0, 5), 5);
	});

	test('dragging slows with distance from the track', function (assert) {
		assert.strictEqual(dragSpeed(0), 1);
		assert.strictEqual(dragSpeed(59), 1);
		assert.strictEqual(dragSpeed(60), 0.5);
		assert.strictEqual(dragSpeed(150), 0.25);
		assert.strictEqual(dragSpeed(500), 0.1);
	});
});
