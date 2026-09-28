import { module, test } from 'qunit';
import { placementStyle } from '#src/lib/popover.ts';

module('Unit | lib/popover', function () {
  test('placements become position areas with a gap towards the anchor', function (assert) {
    assert.deepEqual(placementStyle('bottom-start'), {
      area: 'block-end span-inline-end',
      fallbacks: 'flip-block, flip-inline, flip-block flip-inline',
      gap: 'margin-block-start',
    });
    assert.strictEqual(
      placementStyle('top-end').area,
      'block-start span-inline-start',
    );
    assert.strictEqual(placementStyle('top').area, 'block-start');
    assert.deepEqual(placementStyle('right-start'), {
      area: 'inline-end span-block-end',
      fallbacks: 'flip-inline, flip-block, flip-inline flip-block',
      gap: 'margin-inline-start',
    });
    assert.strictEqual(placementStyle('left').gap, 'margin-inline-end');
  });
});
