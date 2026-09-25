import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import CanonTextOutput from '#src/components/canon-text-output.gts';

module('Component | canon-text-output', function (hooks) {
  setupRenderingTest(hooks);

  test('heading, text, Share beside Copy; blank shows None', async function (assert) {
    const toast = this.owner.lookup('service:canon-toast');
    const written: string[] = [];
    toast.write = (text) => {
      written.push(text);
      return Promise.resolve();
    };
    await render(
      <template>
        <CanonTextOutput
          class="full"
          @text="GLYPH"
          @heading="Output"
          @fileName="a.txt"
        />
        <CanonTextOutput
          class="blank"
          @text=" "
          @heading="Output"
          @fileName="a.txt"
        />
      </template>,
    );
    assert.dom('.full .canon-heading').hasText('Output');
    assert.dom('.full .canon-text-output-text').hasText('GLYPH');
    assert.dom('.full .canon-grid .canon-button').exists({ count: 2 });
    assert.dom('.full .canon-button--primary').hasText('Copy');
    await click('.full .canon-button--primary');
    assert.deepEqual(written, ['GLYPH']);
    assert.dom('.blank .canon-empty-row').hasText('None');
    assert.dom('.blank .canon-button--primary').isDisabled();
  });
});
