import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import CanonCanvas from '#src/components/canon-canvas.gts';
import CanonPage from '#src/components/canon-page.gts';
import { css } from '../helpers/css.ts';

module('Component | canon-page', function (hooks) {
  setupRenderingTest(hooks);

  test('caps and centres sections; a canvas spans the width', async function (assert) {
    await render(
      <template>
        <div style={{css "width: 1000px; height: 400px"}}>
          <CanonPage>
            <div class="section">Section</div>
            <CanonCanvas @height={{50}} />
          </CanonPage>
        </div>
      </template>,
    );
    const section = document.querySelector<HTMLElement>('.section')!;
    assert.strictEqual(section.offsetWidth, 720);
    assert.strictEqual(section.offsetLeft, 140);
    assert.strictEqual(
      document.querySelector<HTMLElement>('.canon-canvas')!.offsetWidth,
      1000,
    );
  });

  test('null maxWidth leaves only the padding', async function (assert) {
    await render(
      <template>
        <div style={{css "width: 1000px"}}>
          <CanonPage @maxWidth={{null}}><div class="section">S</div></CanonPage>
        </div>
      </template>,
    );
    assert.strictEqual(
      document.querySelector<HTMLElement>('.section')!.offsetWidth,
      968,
    );
  });
});
