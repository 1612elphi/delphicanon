import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import CanonStatus from '#src/components/canon-status.gts';

module('Component | canon-status', function (hooks) {
  setupRenderingTest(hooks);

  test('tone sets the colour; row pads it', async function (assert) {
    await render(
      <template>
        <CanonStatus class="ok" @text="Granted" @tone="ok" />
        <CanonStatus class="row" @text="Stopped" @tone="warn" @row={{true}} />
      </template>,
    );
    assert.dom('.ok').hasText('Granted').hasClass('canon-status--ok');
    assert.dom('.row').hasClass('canon-status--row');
    const ok = getComputedStyle(document.querySelector('.ok')!);
    const warn = getComputedStyle(document.querySelector('.row')!);
    assert.notStrictEqual(ok.color, warn.color);
    assert.strictEqual(warn.paddingTop, '10px');
  });
});
