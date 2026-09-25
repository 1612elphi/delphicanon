import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import CanonColourCard from '#src/components/canon-colour-card.gts';
import type { Rgb } from '#src/lib/colour.ts';

const grey: Rgb = [0.4667, 0.4667, 0.4667];

module('Component | canon-colour-card', function (hooks) {
  setupRenderingTest(hooks);

  test('a chip shows inks with their ratios and three values', async function (assert) {
    await render(
      <template>
        <CanonColourCard
          @colour={{grey}}
          @name="Mid grey"
          @primaryFormat="hsl"
        />
      </template>,
    );
    assert.dom('.canon-colour-card-name').hasText('Mid grey');
    assert.deepEqual(
      [...document.querySelectorAll('.canon-value-line-label')].map(
        (e) => e.textContent,
      ),
      ['HEX', 'HSL', 'RGB'],
    );
    assert.dom('.canon-colour-card-ratio').exists({ count: 2 });
    assert
      .dom('.canon-colour-card-ink:first-child .canon-colour-card-ratio')
      .hasText('4.47');
    assert.strictEqual(
      document.querySelector<HTMLElement>('.canon-colour-card-ink')!.style
        .opacity,
      '0.45',
      'white fails AA on this grey',
    );
  });

  test('a row shows the name and the hex', async function (assert) {
    await render(
      <template><CanonColourCard @colour={{grey}} @layout="row" /></template>,
    );
    assert.dom('.canon-value-line').exists({ count: 1 });
    assert.dom('.canon-colour-card-name').hasText('#777777');
    assert.dom('.canon-colour-card-ink').doesNotExist();
  });
});
