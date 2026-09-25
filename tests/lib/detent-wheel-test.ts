import { module, test } from 'qunit';
import {
  advance,
  drum,
  goal,
  isSettled,
  placement,
  tappedRows,
  wrapped,
  type DetentMotion,
  type DetentRange,
} from '#src/lib/detent-wheel.ts';

function settle(start: DetentMotion, range: DetentRange) {
  let motion = start;
  let time = 0;
  while (!isSettled(motion) && time < 10) {
    motion = advance(motion, 1 / 60, range);
    time += 1 / 60;
  }
  return { motion, time };
}

module('Unit | lib/detent-wheel', function () {
  test('a fling coasts and settles on a row', function (assert) {
    const { motion, time } = settle({ position: 0.3, velocity: 30 }, undefined);
    assert.true(isSettled(motion));
    assert.strictEqual(motion.position, Math.round(motion.position));
    assert.true(motion.position > 4);
    assert.true(time < 3);
  });

  test('the ends pull back', function (assert) {
    assert.strictEqual(
      settle({ position: 4.6, velocity: 12 }, [0, 4]).motion.position,
      4,
    );
    assert.strictEqual(
      settle({ position: -0.8, velocity: -5 }, [0, 4]).motion.position,
      0,
    );
  });

  test('a slow wheel is caught by the row ahead', function (assert) {
    assert.strictEqual(
      settle({ position: 2.45, velocity: 2 }, undefined).motion.position,
      3,
    );
  });

  test('indices wrap and select the shorter way round', function (assert) {
    assert.strictEqual(wrapped(-1, 5), 4);
    assert.strictEqual(wrapped(7, 5), 2);
    assert.strictEqual(goal(0, 4, 5, true), -1);
    assert.strictEqual(goal(10, 1, 5, true), 11);
    assert.strictEqual(goal(0, 4, 5, false), 4);
  });

  test('drum geometry and row placement', function (assert) {
    const { radius, step, fitting } = drum(200, 40);
    assert.strictEqual(radius, 100);
    assert.strictEqual(step, 0.4);
    assert.strictEqual(fitting, 7);
    const centre = placement(0, step, radius);
    assert.deepEqual(centre, { y: 0, scaleY: 1, opacity: 1, focus: 1 });
    const below = placement(1, step, radius);
    assert.true(below.y > 0 && below.scaleY < 1 && below.focus === 0);
    assert.strictEqual(tappedRows(radius * Math.sin(step), radius, step), 1);
    assert.strictEqual(tappedRows(-5, radius, step), 0);
  });
});
