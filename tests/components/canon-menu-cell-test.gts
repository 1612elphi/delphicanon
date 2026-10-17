import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, rerender, select } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import CanonMenuCell from '#src/components/canon-menu-cell.gts';

const items = ['One', 'Two', 'Three'];

class State {
  @tracked selected = 0;
  picks: number[] = [];
  pick = (index: number) => {
    this.picks.push(index);
    this.selected = index;
  };
}

module('Component | canon-menu-cell', function (hooks) {
  setupRenderingTest(hooks);

  test('shows the choice and reports a new one', async function (assert) {
    const picks: number[] = [];
    const record = (index: number) => picks.push(index);
    await render(
      <template>
        <CanonMenuCell
          @items={{items}}
          @selected={{0}}
          @label="Count"
          @onChange={{record}}
        />
      </template>,
    );
    assert.dom('.canon-menu-cell-title').hasText('One');
    assert.dom('select').hasAttribute('aria-label', 'Count');
    await select('select', '2');
    assert.deepEqual(picks, [2]);
    assert.dom('.canon-menu-cell-title').hasText('Three');
    assert.strictEqual(
      document.querySelector<HTMLElement>('.canon-menu-cell')!.offsetHeight,
      44,
    );
  });

  test('follows a value set elsewhere after a pick', async function (assert) {
    const state = new State();
    await render(
      <template>
        <CanonMenuCell
          @items={{items}}
          @selected={{state.selected}}
          @label="Count"
          @onChange={{state.pick}}
        />
      </template>,
    );
    await select('select', '2');
    state.selected = 0;
    await rerender();
    assert
      .dom('.canon-menu-cell-title')
      .hasText('One', 'an undo shows the old choice');
    assert.dom('select').hasValue('0');
    await select('select', '2');
    assert.deepEqual(state.picks, [2, 2], 'the same pick is sent again');
    assert.dom('.canon-menu-cell-title').hasText('Three');
  });

  test('no selection shows the placeholder', async function (assert) {
    await render(
      <template><CanonMenuCell @items={{items}} @label="Count" /></template>,
    );
    assert.dom('.canon-menu-cell-title').hasText('—');
    assert.dom('option[hidden]').exists();
  });
});
