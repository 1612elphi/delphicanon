import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, triggerEvent, triggerKeyEvent } from '@ember/test-helpers';
import CanonTooltip from '#src/components/canon-tooltip.gts';

module('Component | canon-tooltip', function (hooks) {
  setupRenderingTest(hooks);

  test('describes its trigger and shows on hover', async function (assert) {
    await render(
      <template>
        <CanonTooltip @text="Copy" as |tip|>
          <button type="button" class="target" {{tip.trigger}}>C</button>
        </CanonTooltip>
      </template>,
    );
    const tip = document.querySelector<HTMLElement>('[role=tooltip]')!;
    assert.dom('.target').hasAttribute('aria-describedby', tip.id);
    assert.dom(tip).hasText('Copy');
    assert.false(tip.matches(':popover-open'));

    await triggerEvent('.target', 'pointerenter');
    assert.true(tip.matches(':popover-open'));
    await triggerKeyEvent(document, 'keydown', 'Escape');
    assert.false(tip.matches(':popover-open'), 'Escape hides it');

    await triggerEvent('.target', 'pointerenter');
    await triggerEvent('.target', 'pointerdown');
    assert.false(tip.matches(':popover-open'), 'a press hides it');
  });
  test('keeps its look when the popover sheet loads later', async function (assert) {
    const later = document.createElement('style');
    later.textContent = [...document.styleSheets]
      .flatMap((sheet) => [...sheet.cssRules])
      .filter(
        (rule) =>
          rule instanceof CSSStyleRule &&
          rule.selectorText === '.canon-popover',
      )
      .map((rule) => rule.cssText)
      .join('\n');
    document.head.append(later);
    try {
      await render(
        <template>
          <CanonTooltip @text="Copy" as |tip|>
            <button type="button" {{tip.trigger}}>C</button>
          </CanonTooltip>
        </template>,
      );
      assert.notStrictEqual(later.textContent, '', 'the popover rule exists');
      const style = getComputedStyle(document.querySelector('[role=tooltip]')!);
      assert.strictEqual(style.paddingTop, '6px');
      assert.strictEqual(style.borderTopStyle, 'none');
    } finally {
      later.remove();
    }
  });
});
