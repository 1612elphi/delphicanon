import { module, test } from 'qunit';
import { accepts, splitForMiddle, stem } from '#src/lib/files.ts';

const png = { name: 'Photo.PNG', type: 'image/png' };
const wav = { name: 'take.wav', type: 'audio/wav' };

module('Unit | lib/files', function () {
  test('accepts reads an accept list', function (assert) {
    assert.true(accepts(png, 'image/*'));
    assert.false(accepts(wav, 'image/*'));
    assert.true(accepts(wav, 'image/*, .wav'));
    assert.true(accepts(png, '.png'));
    assert.true(accepts(wav, 'audio/wav'));
    assert.true(accepts(wav, ''), 'an empty list takes any file');
  });

  test('stem drops the extension only', function (assert) {
    assert.strictEqual(stem('scan.final.jpg'), 'scan.final');
    assert.strictEqual(stem('.env'), '.env');
    assert.strictEqual(stem('README'), 'README');
  });

  test('splitForMiddle keeps the tail whole', function (assert) {
    assert.deepEqual(splitForMiddle('short.txt', 9), ['', 'short.txt']);
    assert.deepEqual(splitForMiddle('a-long-name.wav', 8), [
      'a-long-',
      'name.wav',
    ]);
  });
});
