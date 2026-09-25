import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import CanonLoader from '#src/components/canon-loader.gts';

module('Component | canon-loader', function (hooks) {
  setupRenderingTest(hooks);

  test('nine cells sized by cell and gap', async function (assert) {
    await render(
      <template>
        <CanonLoader class="big" />
        <CanonLoader class="small" @mode="thinking" @cell={{4}} @gap={{1}} />
      </template>,
    );
    assert.dom('.big > *').exists({ count: 9 });
    assert
      .dom('.big')
      .hasAttribute('role', 'status')
      .hasAttribute('aria-label', 'Loading');
    assert.dom('.small').hasClass('canon-loader--thinking');
    const width = (s: string) =>
      document.querySelector<HTMLElement>(s)!.offsetWidth;
    assert.strictEqual(width('.big'), 28);
    assert.strictEqual(width('.small'), 14);
  });
});
