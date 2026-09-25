import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, waitUntil } from '@ember/test-helpers';
import CanonTiles from '#src/components/canon-tiles.gts';
import { css } from '../helpers/css.ts';

const items = [
  { label: 'Codec', value: 'AAC' },
  { label: 'Peak', value: '-4.3 dBFS', level: 0.93 },
  { label: 'RMS', value: '-13.6 dBFS', level: 0.77 },
];

module('Component | canon-tiles', function (hooks) {
  setupRenderingTest(hooks);

  test('as many columns as fit, at least two, with level bars', async function (assert) {
    await render(
      <template>
        <div class="wide" style={{css "width: 600px"}}><CanonTiles
            @items={{items}}
          /></div>
        <div class="narrow" style={{css "width: 200px"}}><CanonTiles
            @items={{items}}
          /></div>
      </template>,
    );
    const columns = (selector: string) =>
      document
        .querySelector<HTMLElement>(`${selector} .canon-grid`)!
        .style.getPropertyValue('--canon-grid-columns');
    await waitUntil(() => columns('.wide') === '3');
    assert.strictEqual(columns('.wide'), '3');
    assert.strictEqual(columns('.narrow'), '2');
    assert.dom('.wide .canon-tiles-level').exists({ count: 2 });
    assert.dom('.wide .canon-tiles-tile').hasText('Codec AAC');
  });
});
