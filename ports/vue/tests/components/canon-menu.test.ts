import { expect, test } from 'vitest';
import CanonMenu, {
	type CanonMenuEntry,
	type CanonMenuItem,
} from '../../src/components/canon-menu.vue';
import {
	click,
	find,
	findAll,
	render,
	triggerKeyEvent,
	waitUntil,
} from '../helpers/render.ts';

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

test('opens at the first item, moves by keyboard and reports a choice', async () => {
	const chosen: string[] = [];
	const choose = (item: CanonMenuItem) => chosen.push(item.title);
	await render(
		`<CanonMenu :items="items" :on-select="choose" v-slot="{ trigger }">
      <button type="button" class="opener" :ref="trigger">Menu</button>
    </CanonMenu>`,
		{ CanonMenu, items, choose },
	);
	const trigger = find('.opener');
	expect(trigger).toHaveAttribute('aria-haspopup', 'menu');
	expect(findAll('[role=menu]')).toHaveLength(2);
	expect(find('[role=menuitemcheckbox]')).toHaveAttribute(
		'aria-checked',
		'true',
	);
	expect(find('[role=menuitemradio]')).toHaveAttribute(
		'aria-checked',
		'false',
	);
	expect(findAll('[role=separator]')).toHaveLength(1);
	expect(find('.canon-menu-item-shortcut')).toHaveTextContent('⌘D');

	await click(trigger);
	await waitUntil(() => text() === 'Duplicate');
	await triggerKeyEvent(focused(), 'keydown', 'ArrowDown');
	expect(text()).toBe('Share');
	await triggerKeyEvent(focused(), 'keydown', 'ArrowRight');
	expect(text(), 'the submenu opens at its first item').toBe('Email');
	expect(findAll(':popover-open')).toHaveLength(2);
	await triggerKeyEvent(focused(), 'keydown', 'ArrowLeft');
	await waitUntil(() => text() === 'Share');
	expect(findAll(':popover-open')).toHaveLength(1);

	await triggerKeyEvent(focused(), 'keydown', 'R');
	expect(text(), 'type-ahead').toBe('Rasterise');
	await click(focused());
	expect(chosen, 'a disabled item does nothing').toEqual([]);
	await triggerKeyEvent(focused(), 'keydown', 'ArrowUp');
	await triggerKeyEvent(focused(), 'keydown', 'End');
	expect(text()).toBe('Delete');
	await triggerKeyEvent(focused(), 'keydown', 'Home');
	expect(text()).toBe('Duplicate');
	await triggerKeyEvent(focused(), 'keydown', 'ArrowUp');
	expect(text(), 'wraps').toBe('Delete');

	await click(focused());
	expect(chosen).toEqual(['Delete']);
	expect(findAll(':popover-open')).toHaveLength(0);
	await waitUntil(() => focused() === trigger);
});

test('the up arrow on the trigger opens at the last item', async () => {
	await render(
		`<CanonMenu :items="items" v-slot="{ trigger }">
      <button type="button" class="opener" :ref="trigger">Menu</button>
    </CanonMenu>`,
		{ CanonMenu, items },
	);
	await triggerKeyEvent('.opener', 'keydown', 'ArrowUp');
	expect(text()).toBe('Delete');
	expect(focused().offsetHeight).toBe(44);
});
