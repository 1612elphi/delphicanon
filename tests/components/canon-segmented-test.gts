import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, rerender } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import CanonSegmented from '#src/components/canon-segmented.gts';
import Dot from '../helpers/dot.gts';

const modes = ['Region', 'Window', 'Screen'];

class State {
  @tracked selected = 0;
  picks: number[] = [];
  pick = (index: number) => {
    this.picks.push(index);
    this.selected = index;
  };
}

class Choices {
  @tracked items = modes;
}

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

  test('follows a value set elsewhere after a pick', async function (assert) {
    const state = new State();
    await render(
      <template>
        <CanonSegmented
          @items={{modes}}
          @selected={{state.selected}}
          @onChange={{state.pick}}
        />
      </template>,
    );
    await click('[role=radio]:nth-child(2)');
    state.selected = 0;
    await rerender();
    assert
      .dom('[role=radio]:nth-child(1)')
      .hasAttribute('aria-checked', 'true', 'an undo shows the old choice');
    await click('[role=radio]:nth-child(2)');
    assert.deepEqual(state.picks, [1, 1], 'the same pick is sent again');
    assert
      .dom('[role=radio]:nth-child(2)')
      .hasAttribute('aria-checked', 'true');
  });

  test('new items drop a pick', async function (assert) {
    const state = new Choices();
    await render(
      <template><CanonSegmented @items={{state.items}} /></template>,
    );
    await click('[role=radio]:nth-child(3)');
    state.items = ['Square', 'Portrait', 'Story'];
    await rerender();
    assert
      .dom('[role=radio]:nth-child(1)')
      .hasAttribute('aria-checked', 'true');
    assert
      .dom('[role=radio]:nth-child(3)')
      .hasAttribute('aria-checked', 'false');
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
