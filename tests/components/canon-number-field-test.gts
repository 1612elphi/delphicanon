import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  blur,
  click,
  fillIn,
  render,
  triggerKeyEvent,
} from '@ember/test-helpers';
import CanonNumberField from '#src/components/canon-number-field.gts';

module('Component | canon-number-field', function (hooks) {
  setupRenderingTest(hooks);

  test('clamps, steps and takes typed integers in range', async function (assert) {
    const values: number[] = [];
    const record = (value: number) => values.push(value);
    await render(
      <template>
        <CanonNumberField
          @value={{9000}}
          @max={{5000}}
          @step={{50}}
          @unit="items"
          @label="Count"
          @onChange={{record}}
        />
      </template>,
    );
    assert.dom('input').hasValue('5000').hasAttribute('role', 'spinbutton');
    assert.dom('.canon-stepper-unit').hasText('items');
    await click('.canon-stepper-plus');
    assert.deepEqual(values, [], 'at the top, plus does nothing');
    await click('.canon-stepper-minus');
    assert.dom('input').hasValue('4950');
    await fillIn('input', '12');
    await fillIn('input', '9999');
    await triggerKeyEvent('input', 'keydown', 'ArrowUp');
    await blur('input');
    assert.deepEqual(values, [4950, 12, 62]);
    assert.dom('input').hasValue('62');
  });
});
