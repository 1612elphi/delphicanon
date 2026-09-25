import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import { css } from '../helpers/css.ts';
import CanonBar from '#src/components/canon-bar.gts';

module('Component | canon-bar', function (hooks) {
  setupRenderingTest(hooks);

  test('fills its share of the width, clamped', async function (assert) {
    await render(
      <template>
        <div style={{css "width: 200px"}}>
          <CanonBar class="quarter" @share={{0.25}} />
          <CanonBar class="over" @share={{2}} />
        </div>
      </template>,
    );
    const fill = (selector: string) =>
      document.querySelector<HTMLElement>(`${selector} .canon-bar-fill`)!
        .offsetWidth;
    assert.strictEqual(fill('.quarter'), 50);
    assert.strictEqual(fill('.over'), 200);
  });
});
