import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import CanonCanvas from '#src/components/canon-canvas.gts';
import { css } from '../helpers/css.ts';

module('Component | canon-canvas', function (hooks) {
  setupRenderingTest(hooks);

  test('sizes fixed, by aspect, and capped', async function (assert) {
    await render(
      <template>
        <div style={{css "width: 400px"}}>
          <CanonCanvas class="fixed" @height={{120}}><span
            >Art</span></CanonCanvas>
          <CanonCanvas class="aspect" @aspect={{4}} />
          <CanonCanvas class="capped" @aspect={{4}} @maxHeight={{60}} />
        </div>
      </template>,
    );
    const height = (selector: string) =>
      document.querySelector<HTMLElement>(selector)!.offsetHeight;
    assert.strictEqual(height('.fixed'), 120);
    assert.strictEqual(
      height('.aspect'),
      104,
      'content 400 / 4 plus two rules',
    );
    assert.strictEqual(height('.capped'), 60);
    assert.dom('.fixed .canon-canvas-content').hasText('Art');
  });
});
