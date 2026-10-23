import { describe, expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import type { CanonMenuBarMenu } from '../src/components/canon-menu-bar.svelte';
import type { CanonMenuItem } from '../src/components/canon-menu.svelte';
import Sized from './fixtures/canon-menu-bar-sized.svelte';
import { click, find, findAll, triggerKeyEvent, waitUntil } from './helpers.ts';

const menus: CanonMenuBarMenu[] = [
	{ title: 'File', items: [{ title: 'New' }, { title: 'Open' }] },
	{ title: 'Edit', items: [{ title: 'Undo' }, { title: 'Redo' }] },
];

const focused = () => document.activeElement as HTMLElement;
const cell = (index: number) => find(`[data-menu-cell="${index}"]`);

describe('canon-menu-bar', () => {
	test('moves between menus while one is open', async () => {
		const chosen: string[] = [];
		const onSelect = (item: CanonMenuItem, menu: number) =>
			chosen.push(`${menu} ${item.title}`);
		await render(Sized, { menus, onSelect });
		expect(find('[role=menubar]').getAttribute('aria-label')).toBe(
			'App',
		);
		expect(
			findAll(
				'[role=menubar] [role=menuitem][aria-haspopup=menu]',
			),
		).toHaveLength(2);
		expect(cell(0).tabIndex).toBe(0);
		expect(cell(1).tabIndex).toBe(-1);
		expect(cell(0).offsetWidth).toBe(cell(1).offsetWidth);

		await click(cell(0));
		await waitUntil(() => focused().textContent?.trim() === 'New');
		expect(cell(0).getAttribute('aria-expanded')).toBe('true');

		await triggerKeyEvent(focused(), 'keydown', 'ArrowRight');
		expect(focused(), 'focus on the next cell').toBe(cell(1));
		expect(findAll(':popover-open')).toHaveLength(1);
		expect(
			document
				.getElementById(
					cell(1).getAttribute('aria-controls')!,
				)!
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
		expect(focused(), 'no menu open: focus moves alone').toBe(
			cell(0),
		);
		expect(findAll(':popover-open')).toHaveLength(0);
	});
});
