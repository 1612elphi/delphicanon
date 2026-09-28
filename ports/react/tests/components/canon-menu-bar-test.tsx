import { describe, expect, test } from 'vitest';
import CanonMenuBar, {
  type CanonMenuBarMenu,
} from '../../src/components/canon-menu-bar.tsx';
import type { CanonMenuItem } from '../../src/components/canon-menu.tsx';
import {
  click,
  find,
  findAll,
  key,
  render,
  waitUntil,
} from '../helpers/render.tsx';

const menus: CanonMenuBarMenu[] = [
  { title: 'File', items: [{ title: 'New' }, { title: 'Open' }] },
  { title: 'Edit', items: [{ title: 'Undo' }, { title: 'Redo' }] },
];

const focused = () => document.activeElement as HTMLElement;
const cell = (index: number) => find(`[data-menu-cell="${index}"]`);
const open = () => findAll(':popover-open').length;

describe('canon-menu-bar', () => {
  test('moves between menus while one is open', async () => {
    const chosen: string[] = [];
    const choose = (item: CanonMenuItem, menu: number) =>
      chosen.push(`${menu} ${item.title}`);
    await render(
      <div style={{ width: 400 }}>
        <CanonMenuBar aria-label="App" menus={menus} onSelect={choose} />
      </div>,
    );
    expect(find('[role=menubar]').getAttribute('aria-label')).toBe('App');
    expect(
      findAll('[role=menubar] [role=menuitem][aria-haspopup=menu]'),
    ).toHaveLength(2);
    expect(cell(0).tabIndex).toBe(0);
    expect(cell(1).tabIndex).toBe(-1);
    expect(cell(0).offsetWidth).toBe(cell(1).offsetWidth);

    await click(cell(0));
    await waitUntil(() => focused().textContent?.trim() === 'New');
    expect(cell(0).getAttribute('aria-expanded')).toBe('true');

    await key(focused(), 'ArrowRight');
    expect(focused(), 'focus on the next cell').toBe(cell(1));
    expect(open()).toBe(1);
    expect(
      document
        .getElementById(cell(1).getAttribute('aria-controls')!)!
        .matches(':popover-open'),
      'with its menu open',
    ).toBe(true);
    await waitUntil(() => cell(1).tabIndex === 0);

    await key(cell(1), 'ArrowDown');
    expect(focused().textContent?.trim()).toBe('Undo');
    await click(focused());
    expect(chosen).toEqual(['1 Undo']);
    expect(open()).toBe(0);

    await key(cell(1), 'ArrowLeft');
    expect(focused(), 'no menu open: focus moves alone').toBe(cell(0));
    expect(open()).toBe(0);
  });

  test('keeps its cells wired when the menus are replaced', async () => {
    const view = await render(
      <div style={{ width: 400 }}>
        <CanonMenuBar aria-label="App" menus={menus} />
      </div>,
    );
    await view.rerender(
      <div style={{ width: 400 }}>
        <CanonMenuBar
          aria-label="App"
          menus={menus.map((menu) => ({ ...menu }))}
        />
      </div>,
    );
    expect(
      findAll('[role=menubar] [role=menuitem][aria-haspopup=menu]'),
    ).toHaveLength(2);
    const panel = document.getElementById(
      cell(0).getAttribute('aria-controls')!,
    );
    expect(panel, 'the cell controls a rendered menu').toBeTruthy();
    expect((cell(0) as HTMLButtonElement).popoverTargetElement).toBe(panel);
    await click(cell(0));
    await waitUntil(() => focused().textContent?.trim() === 'New');
    expect(panel!.matches(':popover-open')).toBe(true);
  });
});
