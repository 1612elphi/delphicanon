import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, waitUntil } from '@ember/test-helpers';
import { on } from '@ember/modifier';
import CanonPopover from '#src/components/canon-popover.gts';

module('Component | canon-popover', function (hooks) {
  setupRenderingTest(hooks);

  test('the trigger toggles the anchored panel and gets focus back', async function (assert) {
    await render(
      <template>
        <CanonPopover role="dialog" aria-label="Panel" @placement="top-end">
          <:trigger as |popover|>
            <button
              type="button"
              class="opener"
              {{popover.trigger}}
            >Open</button>
          </:trigger>
          <:content as |popover|>
            <button
              type="button"
              class="inside"
              {{on "click" popover.close}}
            >Close</button>
          </:content>
        </CanonPopover>
      </template>,
    );
    const trigger = document.querySelector<HTMLButtonElement>('.opener')!;
    const panel = document.querySelector<HTMLElement>('.canon-popover')!;
    assert.strictEqual(trigger.popoverTargetElement, panel);
    assert.dom(trigger).hasAttribute('aria-expanded', 'false');
    assert.dom(trigger).hasAttribute('aria-controls', panel.id);
    assert.strictEqual(
      panel.style.getPropertyValue('position-anchor'),
      trigger.style.getPropertyValue('anchor-name'),
    );
    assert.strictEqual(
      panel.style.getPropertyValue('position-area'),
      'block-start span-inline-start',
    );

    await click(trigger);
    assert.true(panel.matches(':popover-open'));
    await waitUntil(() => trigger.getAttribute('aria-expanded') === 'true');

    document.querySelector<HTMLElement>('.inside')!.focus();
    await click('.inside');
    assert.false(panel.matches(':popover-open'));
    await waitUntil(() => document.activeElement === trigger);
    assert.dom(trigger).hasAttribute('aria-expanded', 'false');

    panel.showPopover();
    assert.dom(trigger).hasAttribute('aria-expanded', 'true', 'as it opens');
    panel.hidePopover();
    assert.dom(trigger).hasAttribute('aria-expanded', 'false', 'as it closes');
  });
});
