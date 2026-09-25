import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, rerender } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import CanonFigure from '#src/components/canon-figure.gts';

class Model {
  @tracked text = '200';
}

module('Component | canon-figure', function (hooks) {
  setupRenderingTest(hooks);

  test('rolls the changed characters only', async function (assert) {
    const model = new Model();
    await render(
      <template>
        <CanonFigure @text={{model.text}} @unit="px" @size={{28}} />
      </template>,
    );
    assert.dom('.canon-figure-said').hasText('200px');
    assert.dom('.canon-figure-char').exists({ count: 3 });
    assert.dom('.canon-figure-unit').hasText('px');
    model.text = '250';
    await rerender();
    assert.dom('.canon-figure-said').hasText('250px');
    assert.dom('.canon-figure-text').hasText(/^250/);
    const chars = [...document.querySelectorAll('.canon-figure-char')];
    const rolling = chars.map((c) => c.getAnimations().length > 0);
    const still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    assert.deepEqual(
      rolling,
      still ? [false, false, false] : [false, true, false],
    );
  });

  test('a halo draws an outline shadow', async function (assert) {
    await render(<template><CanonFigure @text="1" @halo="black" /></template>);
    assert.true(
      getComputedStyle(
        document.querySelector('.canon-figure')!,
      ).textShadow.includes('0px 3px 5px'),
    );
  });
});
