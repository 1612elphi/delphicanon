import { module, test } from 'qunit';
import { isSeparator, menuRole, typeAhead, wrap } from '#src/lib/menu.ts';

module('Unit | lib/menu', function () {
  test('wrap steps round the ring and in from outside', function (assert) {
    assert.strictEqual(wrap(2, 1, 3), 0);
    assert.strictEqual(wrap(0, -1, 3), 2);
    assert.strictEqual(wrap(-1, 1, 3), 0);
    assert.strictEqual(wrap(-1, -1, 3), 2);
    assert.strictEqual(wrap(0, 1, 0), -1);
  });

  test('type-ahead finds the next title and cycles on one letter', function (assert) {
    const titles = ['Save', 'Save as', '', 'Share', 'Open'];
    assert.strictEqual(typeAhead(titles, 's', 0), 1, 'after the current');
    assert.strictEqual(typeAhead(titles, 'ss', 1), 3, 'again steps on');
    assert.strictEqual(typeAhead(titles, 's', 3), 0, 'wraps');
    assert.strictEqual(typeAhead(titles, 'sa', 0), 0, 'a string may stay');
    assert.strictEqual(typeAhead(titles, 'SH', 0), 3, 'ignores case');
    assert.strictEqual(typeAhead(titles, 'x', 0), -1);
    assert.strictEqual(typeAhead(titles, 'o', -1), 4, 'from outside');
  });

  test('roles follow the kind', function (assert) {
    assert.strictEqual(menuRole({ title: 'A' }), 'menuitem');
    assert.strictEqual(
      menuRole({ title: 'A', kind: 'checkbox' }),
      'menuitemcheckbox',
    );
    assert.strictEqual(
      menuRole({ title: 'A', kind: 'radio' }),
      'menuitemradio',
    );
    assert.true(isSeparator({ kind: 'separator' }));
    assert.false(isSeparator({ title: 'A' }));
  });
});
