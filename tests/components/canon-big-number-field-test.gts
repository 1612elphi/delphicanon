import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  blur,
  click,
  fillIn,
  render,
  triggerKeyEvent,
} from '@ember/test-helpers';
import CanonBigNumberField from '#src/components/canon-big-number-field.gts';

module('Component | canon-big-number-field', function (hooks) {
  setupRenderingTest(hooks);

  test('steps, reports typing and the end of typing', async function (assert) {
    const steps: number[] = [];
    const typed: string[] = [];
    let ended = 0;
    const step = (direction: -1 | 1) => steps.push(direction);
    const typing = (text: string) => typed.push(text);
    const end = () => ended++;
    await render(
      <template>
        <CanonBigNumberField
          @value="16"
          @placeholder="0"
          @unit="PX"
          @label="Size"
          @onStep={{step}}
          @onInput={{typing}}
          @onEndEditing={{end}}
        />
      </template>,
    );
    assert.dom('input').hasValue('16').hasAttribute('inputmode', 'decimal');
    assert.dom('.canon-big-number-field-unit').hasText('PX');
    await click('.canon-stepper-plus');
    await click('.canon-stepper-minus');
    await triggerKeyEvent('input', 'keydown', 'ArrowUp');
    assert.deepEqual(steps, [1, -1, 1]);
    await fillIn('input', '24');
    await blur('input');
    assert.deepEqual(typed, ['24']);
    assert.strictEqual(ended, 1);
  });
});
