import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { guidFor } from '@ember/object/internals';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import CanonButton from './canon-button.gts';
import CanonGrid from './canon-grid.gts';
import {
	CanonMenuList,
	showMenu,
	type CanonMenuEntry,
	type CanonMenuItem,
} from './canon-menu.gts';
import { wrap } from '../lib/menu.ts';
import { attach, hide } from '../lib/popover.ts';
import '../styles/tokens.css';
import './canon-menu-bar.css';

export interface CanonMenuBarMenu {
	title: string;
	items: CanonMenuEntry[];
}

export interface CanonMenuBarSignature {
	Args: {
		menus: CanonMenuBarMenu[];
		/** The item, and the index of the menu it is in. */
		onSelect?: (item: CanonMenuItem, menu: number) => void;
	};
	Element: HTMLDivElement;
}

/**
 * A row of flush cells, each opening a menu. While one is open, the
 * pointer over another cell or the inline arrow keys move to its menu, as
 * in the macOS menu bar. Give it an `aria-label`.
 */
export default class CanonMenuBar extends Component<CanonMenuBarSignature> {
	id = `${guidFor(this)}-bar`;
	/** The cell in the tab order. */
	@tracked current = 0;
	@tracked opened?: number;
	#root?: HTMLElement;

	get cells() {
		return this.args.menus.map((menu, index) => ({
			index,
			title: menu.title,
			current: index === this.current,
			open: index === this.opened,
		}));
	}

	cell(index: number) {
		return this.#root?.querySelector<HTMLElement>(
			`[data-menu-cell="${index}"]`,
		);
	}

	panel(index: number) {
		return this.#root?.querySelector<HTMLElement>(
			`#${this.id}-${index}`,
		);
	}

	openPanel() {
		return this.#root?.querySelector<HTMLElement>(
			':scope > .canon-menu:popover-open',
		);
	}

	setup = modifier((root: HTMLElement) => {
		this.#root = root;
		// Tab out of the bar closes its menu
		const focusout = (event: FocusEvent) => {
			const next = event.relatedTarget;
			const open = this.openPanel();
			if (
				open &&
				next instanceof Node &&
				!root.contains(next)
			)
				hide(open);
		};
		root.addEventListener('focusout', focusout);
		return () => root.removeEventListener('focusout', focusout);
	});

	anchor = modifier((panel: HTMLElement, [index]: [number]) => {
		const cell = panel.parentElement?.querySelector<HTMLElement>(
			`[data-menu-cell="${index}"]`,
		);
		if (!cell) return;
		const detach = attach(panel, cell, {
			placement: 'bottom-start',
			invokes: true,
			haspopup: 'menu',
		});
		const toggle = (event: ToggleEvent) => {
			if (event.newState === 'open') this.opened = index;
			else if (this.opened === index) this.opened = undefined;
		};
		panel.addEventListener('toggle', toggle);
		return () => {
			panel.removeEventListener('toggle', toggle);
			detach();
		};
	});

	/** Focus a cell; if a menu is open, the cell's menu replaces it with focus left on the cell. */
	move(to: number) {
		const panel = this.panel(to);
		if (panel && this.openPanel()) showMenu(panel, 'none');
		this.cell(to)?.focus({ preventScroll: true });
	}

	cellKey = (index: number, event: KeyboardEvent) => {
		const count = this.args.menus.length;
		const rtl = (event.currentTarget as Element).matches(
			':dir(rtl)',
		);
		const panel = this.panel(index);
		switch (event.key) {
			case rtl ? 'ArrowLeft' : 'ArrowRight':
				this.move(wrap(index, 1, count));
				break;
			case rtl ? 'ArrowRight' : 'ArrowLeft':
				this.move(wrap(index, -1, count));
				break;
			case 'Home':
				this.move(0);
				break;
			case 'End':
				this.move(count - 1);
				break;
			// Enter and Space would toggle through popovertarget and close an open menu
			case 'ArrowDown':
			case 'Enter':
			case ' ':
				if (panel) showMenu(panel, 'first');
				break;
			case 'ArrowUp':
				if (panel) showMenu(panel, 'last');
				break;
			default:
				return;
		}
		event.preventDefault();
	};

	hover = (index: number, event: PointerEvent) => {
		if (event.pointerType === 'touch') return;
		const open = this.openPanel();
		if (open && open !== this.panel(index)) this.move(index);
	};

	focused = (index: number) => {
		this.current = index;
	};

	edge = (index: number, step: 1 | -1) => {
		const to = wrap(index, step, this.args.menus.length);
		const panel = this.panel(to);
		if (panel) showMenu(panel, 'none');
		this.cell(to)?.focus({ preventScroll: true });
	};

	select = (index: number, item: CanonMenuItem) =>
		this.args.onSelect?.(item, index);

	<template>
		<div
			class="canon-menu-bar"
			role="menubar"
			{{this.setup}}
			...attributes
		>
			<CanonGrid class="canon-menu-bar-cells">
				{{#each this.cells key="index" as |cell|}}
					{{! the menubar parent is the root, through CanonGrid }}
					{{! template-lint-disable require-context-role }}
					<CanonButton
						class="canon-menu-bar-cell
							{{if
								cell.open
								'canon-menu-bar-cell--open'
							}}"
						role="menuitem"
						tabindex={{if
							cell.current
							"0"
							"-1"
						}}
						data-menu-cell={{cell.index}}
						@kind="cell"
						@text={{cell.title}}
						{{on
							"keydown"
							(fn
								this.cellKey
								cell.index
							)
						}}
						{{on
							"pointerenter"
							(fn
								this.hover
								cell.index
							)
						}}
						{{on
							"focus"
							(fn
								this.focused
								cell.index
							)
						}}
					/>
				{{/each}}
			</CanonGrid>
			{{#each @menus key="@index" as |menu index|}}
				<CanonMenuList
					id="{{this.id}}-{{index}}"
					@items={{menu.items}}
					@onSelect={{fn this.select index}}
					@onEdge={{fn this.edge index}}
					{{this.anchor index}}
				/>
			{{/each}}
		</div>
	</template>
}
