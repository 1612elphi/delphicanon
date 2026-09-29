import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import CanonDimensionLine from '#src/components/canon-dimension-line.gts';
import { css } from '../helpers/css.ts';

module('Component | canon-dimension-line', function (hooks) {
  setupRenderingTest(hooks);

  test('a rule with ticks and the figure, turned or blank', async function (assert) {
    await render(
      <template>
        <div style={{css "position: relative; width: 400px; height: 300px"}}>
          <CanonDimensionLine
            class="across"
            @pixels={{1600}}
            style={{css
              "inset-inline-start: 44px; inset-block-start: 0; inline-size: 200px"
            }}
          />
          <CanonDimensionLine class="down" @pixels={{1200}} @down={{true}} />
          <CanonDimensionLine class="blank" @pixels={{1600}} @blank={{true}} />
        </div>
      </template>,
    );
    assert.dom('.across').hasAttribute('aria-hidden', 'true');
    assert.dom('.across .canon-figure-said').hasText('1600px');
    const across = document.querySelector<HTMLElement>('.across')!;
    assert.strictEqual(across.offsetWidth, 200);
    assert.strictEqual(across.offsetHeight, 32);
    assert.strictEqual(
      getComputedStyle(document.querySelector('.down')!).rotate,
      '-90deg',
    );
    assert.dom('.blank .canon-figure').doesNotExist();
    const ink = (selector: string) =>
      getComputedStyle(document.querySelector(selector)!, '::before')
        .backgroundColor;
    assert.notStrictEqual(
      ink('.blank'),
      ink('.across'),
      'blank ticks are muted',
    );
  });
});
