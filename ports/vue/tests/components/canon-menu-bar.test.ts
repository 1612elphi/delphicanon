import { expect, test } from 'vitest';
import CanonMenuBar, {
  type CanonMenuBarMenu,
} from '../../src/components/canon-menu-bar.vue';
import type { CanonMenuItem } from '../../src/components/canon-menu.vue';
import {
  click,
  find,
  findAll,
  render,
  triggerKeyEvent,
  waitUntil,
} from '../helpers/render.ts';

const menus: CanonMenuBarMenu[] = [
  { title: 'File', items: [{ title: 'New' }, { title: 'Open' }] },
  { title: 'Edit', items: [{ title: 'Undo' }, { title: 'Redo' }] },
];

const focused = () => document.activeElement as HTMLElement;
const cell = (index: number) => find(`[data-menu-cell="${index}"]`);

test('moves between menus while one is open', async () => {
  const chosen: string[] = [];
  const choose = (item: CanonMenuItem, menu: number) =>
    chosen.push(`${menu} ${item.title}`);
  await render(
    `<div style="width: 400px">
      <CanonMenuBar aria-label="App" :menus="menus" :on-select="choose" />
    </div>`,
    { CanonMenuBar, menus, choose },
  );
  expect(find('[role=menubar]')).toHaveAttribute('aria-label', 'App');
  expect(
    findAll('[role=menubar] [role=menuitem][aria-haspopup=menu]'),
  ).toHaveLength(2);
  expect(cell(0).tabIndex).toBe(0);
  expect(cell(1).tabIndex).toBe(-1);
  expect(cell(0).offsetWidth).toBe(cell(1).offsetWidth);

  await click(cell(0));
  await waitUntil(() => focused().textContent?.trim() === 'New');
  expect(cell(0)).toHaveAttribute('aria-expanded', 'true');

  await triggerKeyEvent(focused(), 'keydown', 'ArrowRight');
  expect(focused(), 'focus on the next cell').toBe(cell(1));
  expect(findAll(':popover-open')).toHaveLength(1);
  expect(
    document
      .getElementById(cell(1).getAttribute('aria-controls')!)!
      .matches(':popover-open'),
    'with its menu open',
  ).toBe(true);
  await waitUntil(() => cell(1).tabIndex === 0);

  await triggerKeyEvent(cell(1), 'keydown', 'ArrowDown');
  expect(focused().textContent?.trim()).toBe('Undo');
  await click(focused());
  expect(chosen).toEqual(['1 Undo']);
  expect(findAll(':popover-open')).toHaveLength(0);

  await triggerKeyEvent(cell(1), 'keydown', 'ArrowLeft');
  expect(focused(), 'no menu open: focus moves alone').toBe(cell(0));
  expect(findAll(':popover-open')).toHaveLength(0);
});
