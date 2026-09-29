import { module, test } from 'qunit';
import { appearDelay, jumpColumns, litIndex } from '#src/lib/jump.ts';

module('Unit | lib/jump', function () {
  test('the lit group is the last heading at or above the top', function (assert) {
    assert.strictEqual(litIndex([0, 300, 600], 0), 0);
    assert.strictEqual(litIndex([-400, -100, 200], 0), 1);
    assert.strictEqual(litIndex([0.5, 300], 0), 0, 'within a pixel');
    assert.strictEqual(litIndex([50, 300], 0), 0, 'none above: the first');
  });

  test('columns and stagger', function (assert) {
    assert.strictEqual(jumpColumns(390), 2);
    assert.strictEqual(jumpColumns(560), 3);
    assert.strictEqual(appearDelay(3, 13, 8), 90, 'short lists start at 0');
    assert.strictEqual(appearDelay(38, 40, 40), 60, 'long lists at the lit');
    assert.strictEqual(appearDelay(0, 13, 0), 0);
    assert.strictEqual(appearDelay(40, 41, 0), 720, 'capped at 24 steps');
  });
});
