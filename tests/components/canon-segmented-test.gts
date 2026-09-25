import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import CanonSegmented from '#src/components/canon-segmented.gts';
import Dot from '../helpers/dot.gts';

const modes = ['Region', 'Window', 'Screen'];

module('Component | canon-segmented', function (hooks) {
  setupRenderingTest(hooks);

  test('picks one and reports it', async function (assert) {
    const picks: number[] = [];
    const pick = (index: number) => picks.push(index);
    await render(
      <template>
        <CanonSegmented @items={{modes}} @selected={{0}} @onChange={{pick}} />
      </template>,
    );
    assert.dom('[role=radio]').exists({ count: 3 });
    await click('[role=radio]:nth-child(2)');
    assert.deepEqual(picks, [1]);
    assert
      .dom('[role=radio]:nth-child(2)')
      .hasAttribute('aria-checked', 'true');
    assert
      .dom('[role=radio]:nth-child(1)')
      .hasAttribute('aria-checked', 'false');
    await click('[role=radio]:nth-child(2)');
    assert.deepEqual(picks, [1], 'the selected choice sends nothing');
  });

  test('greys single choices and shows symbols', async function (assert) {
    const icons = [Dot, Dot, Dot];
    const off = [2];
    await render(
      <template>
        <CanonSegmented
          @items={{modes}}
          @icons={{icons}}
          @disabledIndices={{off}}
        />
      </template>,
    );
    assert.dom('[role=radio]:nth-child(3)').isDisabled();
    assert.dom('[role=radio]:nth-child(1)').isNotDisabled();
    assert
      .dom('[role=radio]:nth-child(1)')
      .hasAttribute('aria-label', 'Region');
  });
});
