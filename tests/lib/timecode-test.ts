import { module, test } from 'qunit';
import { hasDigits, hundredths, timecodeRuns } from '#src/lib/timecode.ts';

const text = (runs: ReturnType<typeof timecodeRuns>) =>
  runs.map((run) => run.text).join('');
const dimmed = (runs: ReturnType<typeof timecodeRuns>) =>
  runs
    .filter((run) => run.dim)
    .map((run) => run.text)
    .join('');

module('Unit | lib/timecode', function () {
  test('hundredths formats minutes, seconds and hundredths', function (assert) {
    assert.strictEqual(hundredths(83.4), '01:23.40');
    assert.strictEqual(hundredths(0), '00:00.00');
    assert.strictEqual(hundredths(-3), '00:00.00');
    assert.strictEqual(hundredths(100 * 60), '99:00.00', 'minutes cap at 99');
  });

  test('leading zeros dim, the last four never', function (assert) {
    assert.strictEqual(dimmed(timecodeRuns('01:23.40', false)), '0');
    assert.strictEqual(dimmed(timecodeRuns('00:04.20', false)), '00:0');
    assert.strictEqual(dimmed(timecodeRuns('00:00.00', false)), '00:0');
  });

  test('a blank counter shows hyphens in the same shape', function (assert) {
    const runs = timecodeRuns('01:02:03:04', true);
    assert.strictEqual(text(runs), '--:--:--:--');
    assert.strictEqual(dimmed(runs), '');
  });

  test('SMPTE drop frame shows its semicolon as a kerned stop', function (assert) {
    const runs = timecodeRuns('01:02:03;04', false);
    assert.strictEqual(text(runs), '01:02:03.04');
    assert.deepEqual(
      runs.filter((run) => run.stop).map((run) => run.text),
      ['.'],
    );
  });

  test('hasDigits', function (assert) {
    assert.true(hasDigits('1:00'));
    assert.false(hasDigits('--:--'));
    assert.false(hasDigits(null));
  });
});
