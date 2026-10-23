import { module, test } from 'qunit';
import {
	barLabel,
	compressionScale,
	formatBytes,
	savingsFigure,
	savingsPercent,
} from '#src/lib/compression.ts';

module('Unit | compression', function () {
	test('savings carry the sign of the change', function (assert) {
		assert.strictEqual(savingsPercent(1000, 400), -60);
		assert.strictEqual(savingsPercent(1000, 1500), 50);
		assert.strictEqual(savingsPercent(0, 100), 0);
		assert.strictEqual(savingsFigure(1000, 1000), '±0');
		assert.strictEqual(savingsFigure(1000, 400), '−60');
		assert.strictEqual(savingsFigure(1000, 1500), '+50');
	});

	test('bytes', function (assert) {
		assert.strictEqual(formatBytes(512), '512 B');
		assert.strictEqual(formatBytes(1536), '1.5 KB');
		assert.strictEqual(formatBytes(3 * 1024 * 1024), '3.0 MB');
		assert.strictEqual(barLabel('PNG', 0), 'PNG');
		assert.strictEqual(barLabel('PNG', 1536), 'PNG  1.5 KB');
	});

	test('the scale before and after a result', function (assert) {
		assert.deepEqual(compressionScale(1000, 0), {
			known: false,
			grew: false,
			share: 0,
			figure: '—',
			unit: undefined,
		});
		assert.deepEqual(compressionScale(1000, 400), {
			known: true,
			grew: false,
			share: 0.4,
			figure: '−60',
			unit: '%',
		});
		const grew = compressionScale(1000, 1500);
		assert.true(grew.grew);
		assert.strictEqual(
			grew.share,
			1,
			'the result bar never passes the original',
		);
	});
});
