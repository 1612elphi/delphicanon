import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  fillIn,
  render,
  triggerEvent,
  waitUntil,
} from '@ember/test-helpers';
import CanonColourControls, {
  CanonColourSolidState,
} from '#src/components/canon-colour-controls.gts';
import CanonRows from '#src/components/canon-rows.gts';
import { hex } from '#src/lib/colour.ts';
import { css } from '../helpers/css.ts';

module('Component | canon-colour-controls', function (hooks) {
  setupRenderingTest(hooks);

  test('one slider per channel, the active one the slice', async function (assert) {
    const state = new CanonColourSolidState({
      colour: [1, 0, 0],
      activeRow: 2,
    });
    await render(
      <template>
        <div style={{css "width: 400px"}}>
          <CanonRows><CanonColourControls @state={{state}} /></CanonRows>
        </div>
      </template>,
    );
    assert.dom('input[type=range]').exists({ count: 3 });
    assert
      .dom('.canon-colour-controls-lit .canon-row-title')
      .hasText('Lightness');
    assert.strictEqual(state.sliceAxis, 1, 'hsl lightness is axis 1');
    assert.dom('.canon-colour-controls-notation-field').hasValue('#FF0000');

    await fillIn('input[type=range]', '120');
    assert.strictEqual(hex(state.colour), '#00FF00');
    assert.strictEqual(state.activeRow, 0);
    assert.true(state.animated, 'a change without a drag eases');

    await click('[role=radio]:nth-child(8)');
    assert.strictEqual(state.space, 'cmyk');
    assert.dom('input[type=range]').exists({ count: 4 });
    assert.strictEqual(hex(state.colour), '#00FF00', 'the colour survives');

    await triggerEvent('input[role=switch]', 'click');
    assert.true(state.isOrtho);
  });

  test('reads any notation after a pause', async function (assert) {
    const state = new CanonColourSolidState();
    await render(
      <template>
        <CanonRows><CanonColourControls @state={{state}} /></CanonRows>
      </template>,
    );
    await fillIn('.canon-colour-controls-notation-field', 'rgb(59, 130, 246)');
    await waitUntil(() => hex(state.colour) === '#3B82F6', { timeout: 2000 });
    assert.strictEqual(hex(state.colour), '#3B82F6');
    await fillIn('.canon-colour-controls-notation-field', 'nope');
    assert
      .dom('.canon-colour-controls-notation-field')
      .hasAttribute('aria-invalid', 'true');
  });
});
