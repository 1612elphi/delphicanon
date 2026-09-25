import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, select } from '@ember/test-helpers';
import CanonFromTo from '#src/components/canon-from-to.gts';

const rates = ['23.976', '24', '25'];

module('Component | canon-from-to', function (hooks) {
  setupRenderingTest(hooks);

  test('two named menus with an arrow between', async function (assert) {
    const tos: number[] = [];
    const record = (index: number) => tos.push(index);
    await render(
      <template>
        <CanonFromTo
          @items={{rates}}
          @from={{0}}
          @to={{2}}
          @onToChange={{record}}
        />
      </template>,
    );
    assert.dom('select').exists({ count: 2 });
    assert.dom('.canon-from-to-arrow').exists();
    assert
      .dom('.canon-menu-cell:first-child select')
      .hasAttribute('aria-label', 'From');
    await select('.canon-menu-cell:last-child select', '1');
    assert.deepEqual(tos, [1]);
    const [from, to] = [
      ...document.querySelectorAll<HTMLElement>('.canon-menu-cell'),
    ];
    assert.strictEqual(from!.offsetWidth, to!.offsetWidth);
  });
});
