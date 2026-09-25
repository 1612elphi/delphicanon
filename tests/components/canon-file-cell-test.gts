import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, triggerEvent } from '@ember/test-helpers';
import CanonFileCell from '#src/components/canon-file-cell.gts';

module('Component | canon-file-cell', function (hooks) {
  setupRenderingTest(hooks);

  test('shows None, then the chosen file name', async function (assert) {
    const picked: string[] = [];
    const record = (file: File) => picked.push(file.name);
    await render(
      <template>
        <CanonFileCell @accept="image/*" @onChange={{record}} />
      </template>,
    );
    assert.dom('.canon-file-cell-name').hasText('None');
    assert.dom('input[type=file]').hasAttribute('accept', 'image/*');
    assert.dom('button').hasText('Choose');
    const file = new File(['x'], 'a-rather-long-name.png', {
      type: 'image/png',
    });
    await triggerEvent('input[type=file]', 'change', { files: [file] });
    assert.deepEqual(picked, ['a-rather-long-name.png']);
    assert.dom('.canon-file-cell-tail').hasText('name.png');
  });
});
