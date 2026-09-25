import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, triggerEvent } from '@ember/test-helpers';
import CanonStepper from '#src/components/canon-stepper.gts';
import { repeatTiming } from '#src/components/canon-button.gts';

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

module('Component | canon-stepper', function (hooks) {
  setupRenderingTest(hooks);

  test('minus and plus step once per tap', async function (assert) {
    const steps: number[] = [];
    const step = (direction: number) => steps.push(direction);
    await render(
      <template>
        <CanonStepper @onStep={{step}}><input aria-label="n" /></CanonStepper>
      </template>,
    );
    assert.dom('.canon-stepper-minus').hasAttribute('aria-label', 'Decrease');
    await click('.canon-stepper-minus');
    await click('.canon-stepper-plus');
    assert.deepEqual(steps, [-1, 1]);
  });

  test('a held button repeats after the delay, then every interval', async function (assert) {
    let steps = 0;
    const step = () => (steps += 1);
    await render(
      <template>
        <CanonStepper @onStep={{step}}><input aria-label="n" /></CanonStepper>
      </template>,
    );
    await triggerEvent('.canon-stepper-plus', 'pointerdown', { button: 0 });
    await wait(repeatTiming.delay * 1000 - 100);
    assert.strictEqual(steps, 0, 'nothing before the delay');
    await wait(100 + repeatTiming.interval * 1000 * 3);
    await triggerEvent('.canon-stepper-plus', 'pointerup', { button: 0 });
    // timers run late under load, never early
    assert.true(steps >= 2 && steps <= 4, `${steps} steps`);
  });

  test('a click in the middle cell focuses the field', async function (assert) {
    const step = () => undefined;
    await render(
      <template>
        <CanonStepper @onStep={{step}}><input aria-label="n" /></CanonStepper>
      </template>,
    );
    await click('.canon-stepper-centre');
    assert.dom('input').isFocused();
  });
});
