import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import CanonPreviewPanel from '#src/components/canon-preview-panel.gts';

module('Component | canon-preview-panel', function (hooks) {
  setupRenderingTest(hooks);

  test('caption and detail over the content', async function (assert) {
    await render(
      <template>
        <CanonPreviewPanel @caption="Preview" @detail="1600 x 900"><span
            class="art"
          >Art</span></CanonPreviewPanel>
      </template>,
    );
    assert.dom('figcaption').hasText('Preview 1600 x 900');
    assert.dom('.canon-preview-panel-content .art').exists();
    const header = document.querySelector('figcaption')!;
    const content = document.querySelector('.canon-preview-panel-content')!;
    assert.true(
      header.getBoundingClientRect().bottom <=
        content.getBoundingClientRect().top,
      'the caption sits above the content',
    );
  });
});
