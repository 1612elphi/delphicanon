import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, triggerKeyEvent } from '@ember/test-helpers';
import CanonImageCompare from '#src/components/canon-image-compare.gts';
import { css } from '../helpers/css.ts';

const pixel =
  'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="2" height="1"/%3E';

module('Component | canon-image-compare', function (hooks) {
  setupRenderingTest(hooks);

  test('a slider with titles; keys move the divider', async function (assert) {
    await render(
      <template>
        <div style={{css "width: 400px; height: 200px"}}>
          <CanonImageCompare
            @before={{pixel}}
            @after={{pixel}}
            @afterTitle="Grey"
          />
        </div>
      </template>,
    );
    assert.dom('[role=slider]').hasAttribute('aria-valuenow', '50');
    assert.dom('[role=slider]').hasAria('label', 'Before, Grey');
    assert.dom('.canon-image-compare-tag--after').hasText('Grey');
    await triggerKeyEvent('[role=slider]', 'keydown', 'ArrowRight');
    assert.dom('[role=slider]').hasAttribute('aria-valuenow', '60');
    await triggerKeyEvent('[role=slider]', 'keydown', 'Home');
    assert.dom('[role=slider]').hasAttribute('aria-valuetext', '0%');
  });

  test('a failure dims the original and hides the divider', async function (assert) {
    await render(
      <template>
        <CanonImageCompare @before={{pixel}} @failed={{true}} @failure="No" />
      </template>,
    );
    assert.dom('[role=slider]').doesNotExist();
    assert.dom('.canon-image-compare-divider').doesNotExist();
    assert.dom('.canon-image-compare-failure').hasText('No');
  });
});
