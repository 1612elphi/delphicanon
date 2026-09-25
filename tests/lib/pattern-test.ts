import { module, test } from 'qunit';
import { canonPatternTile } from '#src/lib/pattern.ts';

module('Unit | lib/pattern', function () {
  test('wraps the symbol twice in a 92 px tile', function (assert) {
    const url = canonPatternTile('<svg/>');
    assert.true(url.startsWith('url("data:image/svg+xml,'));
    const tile = decodeURIComponent(url.slice(24, -2));
    assert.true(tile.includes('width="92"'));
    assert.strictEqual(tile.match(/<image /g)?.length, 2);
  });
});
