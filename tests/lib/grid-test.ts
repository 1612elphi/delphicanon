import { module, test } from 'qunit';
import { balanced, spans } from '#src/lib/grid.ts';

module('Unit | lib/grid', function () {
  test('balanced rows differ by at most one, larger first', function (assert) {
    assert.deepEqual(balanced(5, 3), [3, 2]);
    assert.deepEqual(balanced(7, 3), [3, 2, 2]);
    assert.deepEqual(balanced(4, 3), [2, 2]);
    assert.deepEqual(balanced(4, 9), [4]);
    assert.deepEqual(balanced(0, 3), []);
  });

  test('the last cell of a short row spans the rest', function (assert) {
    assert.deepEqual(spans(5, 3), [1, 1, 1, 1, 2]);
    assert.deepEqual(spans(7, 3), [1, 1, 1, 1, 2, 1, 2]);
    assert.deepEqual(spans(4, 3), [1, 1, 1, 1]);
  });
});
