import { module, test } from 'qunit';
import { changedFromEnd, leadingNumber } from '#src/lib/figure.ts';

module('Unit | lib/figure', function () {
	test('leadingNumber reads the number a text starts with', function (assert) {
		assert.strictEqual(leadingNumber('250'), 250);
		assert.strictEqual(leadingNumber('-1.5 dB'), -1.5);
		assert.strictEqual(leadingNumber('px'), 0);
	});

	test('changedFromEnd lines up the units digits', function (assert) {
		assert.deepEqual(changedFromEnd('200', '250'), [
			{ index: 1, old: '0' },
		]);
		assert.deepEqual(changedFromEnd('950', '1000'), [
			{ index: 0, old: undefined },
			{ index: 1, old: '9' },
			{ index: 2, old: '5' },
		]);
		assert.deepEqual(changedFromEnd('1000', '999'), [
			{ index: 0, old: '0' },
			{ index: 1, old: '0' },
			{ index: 2, old: '0' },
		]);
	});
});
