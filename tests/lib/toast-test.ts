import { module, test } from 'qunit';
import { placeToast, toastDetail } from '#src/lib/toast.ts';

const column = { left: 100, top: 0, right: 500, bottom: 800 };

module('Unit | lib/toast', function () {
	test('centred at the bottom of the column', function (assert) {
		assert.deepEqual(placeToast(column, 40), {
			x: 300,
			bottom: 800,
		});
	});

	test('stays above a pointer near that bottom', function (assert) {
		assert.deepEqual(placeToast(column, 40, { x: 200, y: 780 }), {
			x: 300,
			bottom: 744,
		});
		assert.deepEqual(
			placeToast(column, 40, { x: 200, y: 400 }).bottom,
			800,
			'a pointer higher up is left alone',
		);
		assert.deepEqual(
			placeToast(column, 40, { x: 50, y: 780 }).bottom,
			800,
			'a pointer in another column is left alone',
		);
	});

	test('the detail is one short line or nothing', function (assert) {
		assert.strictEqual(toastDetail('#3B82F6'), '#3B82F6');
		assert.strictEqual(toastDetail('a\nb'), undefined);
		assert.strictEqual(toastDetail('x'.repeat(49)), undefined);
		assert.strictEqual(toastDetail(), undefined);
	});
});
