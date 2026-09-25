import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, select } from '@ember/test-helpers';
import CanonMenuCell from '#src/components/canon-menu-cell.gts';

const items = ['One', 'Two', 'Three'];

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

  test('no selection shows the placeholder', async function (assert) {
    await render(
      <template><CanonMenuCell @items={{items}} @label="Count" /></template>,
    );
    assert.dom('.canon-menu-cell-title').hasText('—');
    assert.dom('option[hidden]').exists();
  });
});
