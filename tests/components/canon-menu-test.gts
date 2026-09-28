import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, triggerKeyEvent, waitUntil } from '@ember/test-helpers';
import CanonMenu, {
  type CanonMenuEntry,
  type CanonMenuItem,
} from '#src/components/canon-menu.gts';

const items: CanonMenuEntry[] = [
  { title: 'Duplicate', shortcut: '⌘D' },
  { title: 'Share', items: [{ title: 'Email' }, { title: 'Messages' }] },
  { kind: 'separator' },
  { title: 'Grid', kind: 'checkbox', checked: true },
  { title: 'Small', kind: 'radio', checked: false },
  { title: 'Rasterise', disabled: true },
  { title: 'Delete', destructive: true },
];

const focused = () => document.activeElement as HTMLElement;
const text = () =>
  focused().querySelector('.canon-menu-item-title')?.textContent ?? '';

module('Component | canon-menu', function (hooks) {
  setupRenderingTest(hooks);

  test('opens at the first item, moves by keyboard and reports a choice', async function (assert) {
    const chosen: string[] = [];
    const choose = (item: CanonMenuItem) => chosen.push(item.title);
    await render(
      <template>
        <CanonMenu @items={{items}} @onSelect={{choose}} as |menu|>
          <button type="button" class="opener" {{menu.trigger}}>Menu</button>
        </CanonMenu>
      </template>,
    );
    const trigger = document.querySelector<HTMLElement>('.opener')!;
    assert.dom(trigger).hasAttribute('aria-haspopup', 'menu');
    assert.dom('[role=menu]').exists({ count: 2 });
    assert.dom('[role=menuitemcheckbox]').hasAttribute('aria-checked', 'true');
    assert.dom('[role=menuitemradio]').hasAttribute('aria-checked', 'false');
    assert.dom('[role=separator]').exists({ count: 1 });
    assert.dom('.canon-menu-item-shortcut').hasText('⌘D');

    await click(trigger);
    await waitUntil(() => text() === 'Duplicate');
    await triggerKeyEvent(focused(), 'keydown', 'ArrowDown');
    assert.strictEqual(text(), 'Share');
    await triggerKeyEvent(focused(), 'keydown', 'ArrowRight');
    assert.strictEqual(text(), 'Email', 'the submenu opens at its first item');
    assert.dom(':popover-open').exists({ count: 2 });
    await triggerKeyEvent(focused(), 'keydown', 'ArrowLeft');
    await waitUntil(() => text() === 'Share');
    assert.dom(':popover-open').exists({ count: 1 });

    await triggerKeyEvent(focused(), 'keydown', 'R');
    assert.strictEqual(text(), 'Rasterise', 'type-ahead');
    await click(focused());
    assert.deepEqual(chosen, [], 'a disabled item does nothing');
    await triggerKeyEvent(focused(), 'keydown', 'ArrowUp');
    await triggerKeyEvent(focused(), 'keydown', 'End');
    assert.strictEqual(text(), 'Delete');
    await triggerKeyEvent(focused(), 'keydown', 'Home');
    assert.strictEqual(text(), 'Duplicate');
    await triggerKeyEvent(focused(), 'keydown', 'ArrowUp');
    assert.strictEqual(text(), 'Delete', 'wraps');

    await click(focused());
    assert.deepEqual(chosen, ['Delete']);
    assert.dom(':popover-open').doesNotExist();
    await waitUntil(() => focused() === trigger);
  });

  test('the up arrow on the trigger opens at the last item', async function (assert) {
    await render(
      <template>
        <CanonMenu @items={{items}} as |menu|>
          <button type="button" class="opener" {{menu.trigger}}>Menu</button>
        </CanonMenu>
      </template>,
    );
    await triggerKeyEvent('.opener', 'keydown', 'ArrowUp');
    assert.strictEqual(text(), 'Delete');
    const item = focused();
    assert.strictEqual(item.offsetHeight, 44);
  });
});
