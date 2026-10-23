import { describe, expect, test } from 'vitest';
import CanonContextMenu from '../../src/components/canon-context-menu.tsx';
import type {
	CanonMenuEntry,
	CanonMenuItem,
} from '../../src/components/canon-menu.tsx';
import {
	click,
	find,
	key,
	render,
	trigger,
	waitUntil,
} from '../helpers/render.tsx';

const items: CanonMenuEntry[] = [{ title: 'Paste' }, { title: 'Select all' }];

describe('canon-context-menu', () => {
	test('opens at the pointer and by keyboard, and reports a choice', async () => {
		const chosen: string[] = [];
		const choose = (item: CanonMenuItem) => chosen.push(item.title);
		await render(
			<CanonContextMenu items={items} onSelect={choose}>
				<div className="area" tabIndex={0}>
					Area
				</div>
			</CanonContextMenu>,
		);
		const menu = find('[role=menu]');
		const point = find('.canon-context-menu-point');

		await trigger('.area', 'contextmenu', {
			clientX: 40,
			clientY: 30,
		});
		expect(menu.matches(':popover-open')).toBe(true);
		expect(point.style.left).toBe('40px');
		expect(point.style.top).toBe('30px');
		expect(document.activeElement?.textContent).toBe('Paste');

		await click('[role=menuitem]:nth-child(2)');
		expect(chosen).toEqual(['Select all']);
		expect(menu.matches(':popover-open')).toBe(false);

		find('.area').focus();
		await key('.area', 'F10', { shiftKey: true });
		expect(menu.matches(':popover-open'), 'Shift+F10').toBe(true);
		menu.hidePopover();
		await waitUntil(
			() => document.activeElement?.matches('.area') ?? false,
		);
		expect(document.activeElement, 'focus goes back').toBe(
			find('.area'),
		);
	});
});
