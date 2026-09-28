import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  render,
  triggerEvent,
  triggerKeyEvent,
  waitUntil,
} from '@ember/test-helpers';
import CanonContextMenu from '#src/components/canon-context-menu.gts';
import type {
  CanonMenuEntry,
  CanonMenuItem,
} from '#src/components/canon-menu.gts';

const items: CanonMenuEntry[] = [{ title: 'Paste' }, { title: 'Select all' }];

module('Component | canon-context-menu', function (hooks) {
  setupRenderingTest(hooks);

  test('opens at the pointer and by keyboard, and reports a choice', async function (assert) {
    const chosen: string[] = [];
    const choose = (item: CanonMenuItem) => chosen.push(item.title);
    await render(
      <template>
        <CanonContextMenu @items={{items}} @onSelect={{choose}}>
          <div class="area" tabindex="0">Area</div>
        </CanonContextMenu>
      </template>,
    );
    const menu = document.querySelector<HTMLElement>('[role=menu]')!;
    const point = document.querySelector<HTMLElement>(
      '.canon-context-menu-point',
    )!;

    await triggerEvent('.area', 'contextmenu', { clientX: 40, clientY: 30 });
    assert.true(menu.matches(':popover-open'));
    assert.strictEqual(point.style.left, '40px');
    assert.strictEqual(point.style.top, '30px');
    assert.dom(document.activeElement).hasText('Paste');

    await click('[role=menuitem]:nth-child(2)');
    assert.deepEqual(chosen, ['Select all']);
    assert.false(menu.matches(':popover-open'));

    document.querySelector<HTMLElement>('.area')!.focus();
    await triggerKeyEvent('.area', 'keydown', 'F10', { shiftKey: true });
    assert.true(menu.matches(':popover-open'), 'Shift+F10');
    menu.hidePopover();
    await waitUntil(() => document.activeElement?.matches('.area'));
    assert.dom('.area').isFocused('focus goes back');
  });
});
