import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, triggerEvent } from '@ember/test-helpers';
import CanonMathRail from '#src/components/canon-math-rail.gts';
import { type Key } from '#src/lib/math/expression.ts';
import { css } from '../helpers/css.ts';

module('Component | canon-math-rail', function (hooks) {
  setupRenderingTest(hooks);

  test('the rail steps the caret with its arrows and its ribs', async function (assert) {
    const steps: string[] = [];
    const step = (key: Key) => (steps.push(key.kind), true);
    await render(
      <template>
        <div style={{css "width: 400px"}}><CanonMathRail
            @onStep={{step}}
          /></div>
      </template>,
    );
    await click('[aria-label="Left"]');
    await click('[aria-label="Up"]');
    const ribs = '.canon-math-rail-ribs';
    await triggerEvent(ribs, 'pointerdown', {
      button: 0,
      clientX: 100,
      pointerId: 1,
    });
    await triggerEvent(ribs, 'pointermove', { clientX: 140, pointerId: 1 });
    await triggerEvent(ribs, 'pointerup', { clientX: 140, pointerId: 1 });
    assert.deepEqual(
      steps,
      ['left', 'up', 'right', 'right'],
      'one place per 16 px',
    );
  });
});
