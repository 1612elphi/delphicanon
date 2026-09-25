import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { fillIn, render, triggerKeyEvent } from '@ember/test-helpers';
import CanonTextCell from '#src/components/canon-text-cell.gts';

module('Component | canon-text-cell', function (hooks) {
  setupRenderingTest(hooks);

  test('reports every edit; Enter leaves the field', async function (assert) {
    const edits: string[] = [];
    const record = (value: string) => edits.push(value);
    await render(
      <template>
        <CanonTextCell
          @placeholder="Trigger"
          aria-label="Trigger"
          @onChange={{record}}
        />
      </template>,
    );
    assert.dom('input').hasAttribute('placeholder', 'Trigger');
    assert.strictEqual(
      document.querySelector<HTMLElement>('.canon-text-cell')!.offsetHeight,
      44,
    );
    await fillIn('input', 'go');
    assert.deepEqual(edits, ['go']);
    await triggerKeyEvent('input', 'keydown', 'Enter');
    assert.dom('input').isNotFocused();
  });
});
