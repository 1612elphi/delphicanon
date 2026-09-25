import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  fillIn,
  find,
  render,
  triggerEvent,
  waitUntil,
} from '@ember/test-helpers';
import CanonColourControls, {
  CanonColourSolidState,
} from '#src/components/canon-colour-controls.gts';
import CanonColourSolid from '#src/components/canon-colour-solid.gts';
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
          <div style={{css "height: 200px"}}>
            <CanonColourSolid
              @space={{state.space}}
              @point={{state.point}}
              @animated={{state.animated}}
              @sliceAxis={{state.sliceAxis}}
              @isOrtho={{state.isOrtho}}
              @showsWhole={{state.showsWhole}}
              @onChange={{state.pick}}
            />
          </div>
          <CanonRows><CanonColourControls @state={{state}} /></CanonRows>
        </div>
      </template>,
    );
    assert.dom('.canon-slider').exists({ count: 3 });
    assert
      .dom('.canon-colour-controls-lit .canon-row-title')
      .hasText('Lightness');
    assert.strictEqual(state.sliceAxis, 1, 'hsl lightness is axis 1');
    assert.dom('.canon-colour-controls-notation-field').hasValue('#FF0000');

    const track = document
      .querySelector('.canon-slider-track')!
      .getBoundingClientRect();
    const at = {
      button: 0,
      pointerId: 1,
      clientX: track.left + track.width / 3,
      clientY: track.top + track.height / 2,
    };
    await triggerEvent('.canon-slider', 'pointerdown', at);
    await triggerEvent('.canon-slider', 'pointerup', at);
    assert.strictEqual(hex(state.colour), '#00FF00');
    assert.strictEqual(state.activeRow, 0);
    assert.true(state.animated, 'a tap eases');
    // the solid paints on the next animation frame, which test waiters do not track
    await waitUntil(
      () => find('.canon-colour-solid output')?.textContent === '#00FF00',
    );

    await click('[role=radio]:nth-child(8)');
    assert.strictEqual(state.space, 'cmyk');
    await waitUntil(() => hex(state.colour) === '#00FF00');
    assert.dom('.canon-slider').exists({ count: 4 });
    assert.deepEqual(
      state.point.map((v) => Math.round(v * 100)),
      [100, 0, 100, 0],
      'the solid converts the pick, the colour survives',
    );

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
