import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
	click,
	render,
	rerender,
	triggerKeyEvent,
	waitUntil,
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import CanonMenuBar, {
	type CanonMenuBarMenu,
} from '#src/components/canon-menu-bar.gts';
import type { CanonMenuItem } from '#src/components/canon-menu.gts';
import { css } from '../helpers/css.ts';

const menus: CanonMenuBarMenu[] = [
	{ title: 'File', items: [{ title: 'New' }, { title: 'Open' }] },
	{ title: 'Edit', items: [{ title: 'Undo' }, { title: 'Redo' }] },
];

const focused = () => document.activeElement as HTMLElement;
const cell = (index: number) =>
	document.querySelector<HTMLElement>(`[data-menu-cell="${index}"]`)!;

module('Component | canon-menu-bar', function (hooks) {
	setupRenderingTest(hooks);

	test('moves between menus while one is open', async function (assert) {
		const chosen: string[] = [];
		const choose = (item: CanonMenuItem, menu: number) =>
			chosen.push(`${menu} ${item.title}`);
		await render(
			<template>
				<div style={{css "width: 400px"}}>
					<CanonMenuBar
						aria-label="App"
						@menus={{menus}}
						@onSelect={{choose}}
					/>
				</div>
			</template>,
		);
		assert.dom('[role=menubar]').hasAttribute('aria-label', 'App');
		assert.dom(
			'[role=menubar] [role=menuitem][aria-haspopup=menu]',
		).exists({
			count: 2,
		});
		assert.strictEqual(cell(0).tabIndex, 0);
		assert.strictEqual(cell(1).tabIndex, -1);
		assert.strictEqual(cell(0).offsetWidth, cell(1).offsetWidth);

		await click(cell(0));
		await waitUntil(() => focused().textContent?.trim() === 'New');
		assert.dom(cell(0)).hasAttribute('aria-expanded', 'true');

		await triggerKeyEvent(focused(), 'keydown', 'ArrowRight');
		assert.strictEqual(
			focused(),
			cell(1),
			'focus on the next cell',
		);
		assert.dom(':popover-open').exists({ count: 1 });
		assert.true(
			document
				.getElementById(
					cell(1).getAttribute('aria-controls')!,
				)!
				.matches(':popover-open'),
			'with its menu open',
		);
		await waitUntil(() => cell(1).tabIndex === 0);

		await triggerKeyEvent(cell(1), 'keydown', 'ArrowDown');
		assert.strictEqual(focused().textContent?.trim(), 'Undo');
		await click(focused());
		assert.deepEqual(chosen, ['1 Undo']);
		assert.dom(':popover-open').doesNotExist();

		await triggerKeyEvent(cell(1), 'keydown', 'ArrowLeft');
		assert.strictEqual(
			focused(),
			cell(0),
			'no menu open: focus moves alone',
		);
		assert.dom(':popover-open').doesNotExist();
	});

	test('keeps its cells wired when the menus are replaced', async function (assert) {
		class State {
			@tracked menus = menus;
		}
		const state = new State();
		await render(
			<template>
				<div style={{css "width: 400px"}}>
					<CanonMenuBar
						aria-label="App"
						@menus={{state.menus}}
					/>
				</div>
			</template>,
		);
		state.menus = menus.map((menu) => ({ ...menu }));
		await rerender();
		assert.dom(
			'[role=menubar] [role=menuitem][aria-haspopup=menu]',
		).exists({
			count: 2,
		});
		const panel = document.getElementById(
			cell(0).getAttribute('aria-controls')!,
		);
		assert.ok(panel, 'the cell controls a rendered menu');
		assert.strictEqual(
			(cell(0) as HTMLButtonElement).popoverTargetElement,
			panel,
		);
		await click(cell(0));
		await waitUntil(() => focused().textContent?.trim() === 'New');
		assert.true(panel!.matches(':popover-open'));
	});
});
