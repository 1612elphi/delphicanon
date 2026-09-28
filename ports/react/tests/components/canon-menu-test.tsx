import { describe, expect, test } from 'vitest';
import CanonMenu, {
  type CanonMenuEntry,
  type CanonMenuItem,
} from '../../src/components/canon-menu.tsx';
import {
  click,
  find,
  findAll,
  key,
  render,
  waitUntil,
} from '../helpers/render.tsx';

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
const open = () => findAll(':popover-open').length;

describe('canon-menu', () => {
  test('opens at the first item, moves by keyboard and reports a choice', async () => {
    const chosen: string[] = [];
    const choose = (item: CanonMenuItem) => chosen.push(item.title);
    await render(
      <CanonMenu items={items} onSelect={choose}>
        {(menu) => (
          <button type="button" className="opener" ref={menu.trigger}>
            Menu
          </button>
        )}
      </CanonMenu>,
    );
    const trigger = find('.opener');
    expect(trigger.getAttribute('aria-haspopup')).toBe('menu');
    expect(findAll('[role=menu]')).toHaveLength(2);
    expect(find('[role=menuitemcheckbox]').getAttribute('aria-checked')).toBe(
      'true',
    );
    expect(find('[role=menuitemradio]').getAttribute('aria-checked')).toBe(
      'false',
    );
    expect(findAll('[role=separator]')).toHaveLength(1);
    expect(find('.canon-menu-item-shortcut').textContent).toBe('⌘D');

    await click(trigger);
    await waitUntil(() => text() === 'Duplicate');
    await key(focused(), 'ArrowDown');
    expect(text()).toBe('Share');
    await key(focused(), 'ArrowRight');
    expect(text(), 'the submenu opens at its first item').toBe('Email');
    expect(open()).toBe(2);
    await key(focused(), 'ArrowLeft');
    await waitUntil(() => text() === 'Share');
    expect(open()).toBe(1);

    await key(focused(), 'R');
    expect(text(), 'type-ahead').toBe('Rasterise');
    await click(focused());
    expect(chosen, 'a disabled item does nothing').toEqual([]);
    await key(focused(), 'ArrowUp');
    await key(focused(), 'End');
    expect(text()).toBe('Delete');
    await key(focused(), 'Home');
    expect(text()).toBe('Duplicate');
    await key(focused(), 'ArrowUp');
    expect(text(), 'wraps').toBe('Delete');

    await click(focused());
    expect(chosen).toEqual(['Delete']);
    expect(open()).toBe(0);
    await waitUntil(() => focused() === trigger);
  });

  test('the up arrow on the trigger opens at the last item', async () => {
    await render(
      <CanonMenu items={items}>
        {(menu) => (
          <button type="button" className="opener" ref={menu.trigger}>
            Menu
          </button>
        )}
      </CanonMenu>,
    );
    await key('.opener', 'ArrowUp');
    expect(text()).toBe('Delete');
    expect(focused().offsetHeight).toBe(44);
  });
});
