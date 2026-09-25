import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import { fakeClipboard } from '../helpers/clipboard.ts';
import CanonValueLine from '#src/components/canon-value-line.gts';

module('Component | canon-value-line', function (hooks) {
  setupRenderingTest(hooks);

  test('shows the label and value and copies the value', async function (assert) {
    const written = fakeClipboard(this.owner.lookup('service:canon-toast'));
    await render(
      <template>
        <CanonValueLine
          @label="OKLCH"
          @value="oklch(0.5 0.1 140)"
          @labelWidth={{60}}
        />
      </template>,
    );
    assert.dom('.canon-value-line-label').hasText('OKLCH');
    assert.dom('.canon-value-line-value').hasText('oklch(0.5 0.1 140)');
    assert.strictEqual(
      document.querySelector<HTMLElement>('.canon-value-line-label')!
        .offsetWidth,
      60,
    );
    await click('.canon-value-line');
    assert.deepEqual(written, ['oklch(0.5 0.1 140)']);
  });
});
