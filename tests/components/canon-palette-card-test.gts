import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import CanonPaletteCard from '#src/components/canon-palette-card.gts';
import type { Rgb } from '#src/lib/colour.ts';
import { css } from '../helpers/css.ts';
import { fakeClipboard } from '../helpers/clipboard.ts';

const colours: Rgb[] = [
  [1, 0, 0],
  [0, 0.5, 0],
  [0, 0, 1],
];

module('Component | canon-palette-card', function (hooks) {
  setupRenderingTest(hooks);

  test('a tap widens a swatch, a second tap copies its hex', async function (assert) {
    const written = fakeClipboard(this.owner.lookup('service:canon-toast'));
    const picks: (number | undefined)[] = [];
    const select = (index: number | undefined) => picks.push(index);
    await render(
      <template>
        <div style={{css "width: 400px"}}>
          <CanonPaletteCard
            @title="Harmony"
            @colours={{colours}}
            @onSelect={{select}}
          >
            <:picker><p class="picker">picker</p></:picker>
            <:actions><button type="button">Copy</button></:actions>
          </CanonPaletteCard>
        </div>
      </template>,
    );
    assert.dom('.canon-heading').hasText('Harmony');
    assert.dom('.picker').exists();
    assert.dom('.canon-grid button').exists();
    const second = '.canon-palette-card-swatch:nth-child(2)';
    await click(second);
    assert.deepEqual(picks, [1]);
    assert.dom(second).hasAttribute('aria-pressed', 'true');
    assert.strictEqual(
      document.querySelector<HTMLElement>(second)!.style.flexGrow,
      '3',
    );
    await click(second);
    assert.deepEqual(written, ['#008000']);
    assert.deepEqual(picks, [1], 'the wide swatch does not select again');
  });
});
