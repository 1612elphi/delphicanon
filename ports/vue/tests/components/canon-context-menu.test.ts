import { expect, test } from 'vitest';
import CanonContextMenu from '../../src/components/canon-context-menu.vue';
import type {
	CanonMenuEntry,
	CanonMenuItem,
} from '../../src/components/canon-menu.vue';
import {
	click,
	find,
	render,
	triggerEvent,
	triggerKeyEvent,
	waitUntil,
} from '../helpers/render.ts';

const items: CanonMenuEntry[] = [{ title: 'Paste' }, { title: 'Select all' }];

test('opens at the pointer and by keyboard, and reports a choice', async () => {
	const chosen: string[] = [];
	const choose = (item: CanonMenuItem) => chosen.push(item.title);
	await render(
		`<CanonContextMenu :items="items" :on-select="choose">
      <div class="area" tabindex="0">Area</div>
    </CanonContextMenu>`,
		{ CanonContextMenu, items, choose },
	);
	const menu = find('[role=menu]');
	const point = find('.canon-context-menu-point');

	await triggerEvent('.area', 'contextmenu', {
		clientX: 40,
		clientY: 30,
	});
	expect(menu.matches(':popover-open')).toBe(true);
	expect(point.style.left).toBe('40px');
	expect(point.style.top).toBe('30px');
	expect(document.activeElement).toHaveTextContent('Paste');

	await click('[role=menuitem]:nth-child(2)');
	expect(chosen).toEqual(['Select all']);
	expect(menu.matches(':popover-open')).toBe(false);

	find('.area').focus();
	await triggerKeyEvent('.area', 'keydown', 'F10', { shiftKey: true });
	expect(menu.matches(':popover-open'), 'Shift+F10').toBe(true);
	menu.hidePopover();
	await waitUntil(() => document.activeElement?.matches('.area'));
	expect(find('.area'), 'focus goes back').toHaveFocus();
});
