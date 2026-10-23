import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';
import { htmlSafe } from '@ember/template';
import CanonButton from './canon-button.gts';
import CanonGrid from './canon-grid.gts';
import CanonHeading from './canon-heading.gts';
import press from '../modifiers/canon-press.ts';
import '../styles/tokens.css';
import './canon-dual-list.css';

export interface CanonDualItem {
	id: string;
	name: string;
	caption?: string;
}

type Side = 'left' | 'right';

export interface CanonDualListSignature {
	Args: {
		left: CanonDualItem[];
		right: CanonDualItem[];
		leftTitle: string;
		rightTitle: string;
		/** Height of each list in px; default 240. */
		listHeight?: number;
		onMoveRight?: (id: string) => void;
		onMoveLeft?: (id: string) => void;
		/** Item id and a delta of -1 or 1. */
		onReorder?: (id: string, delta: -1 | 1) => void;
	};
	Element: HTMLDivElement;
}

/** Two columns with one selection between them; the right column can be reordered. */
export default class CanonDualList extends Component<CanonDualListSignature> {
	@tracked picked?: { side: Side; id: string };
	id = guidFor(this);

	/** The pick, while its item is still on that side. */
	get selection() {
		const { picked } = this;
		if (!picked) return undefined;
		const items =
			picked.side === 'left'
				? this.args.left
				: this.args.right;
		return items.some((item) => item.id === picked.id)
			? picked
			: undefined;
	}

	get selectedSide() {
		return this.selection?.side;
	}

	get rightIndex() {
		const { selection } = this;
		return selection?.side === 'right'
			? this.args.right.findIndex(
					(item) => item.id === selection.id,
				)
			: -1;
	}

	get style() {
		return htmlSafe(
			`--canon-dual-list-height: ${this.args.listHeight ?? 240}px`,
		);
	}

	rows(side: Side) {
		const items =
			side === 'left' ? this.args.left : this.args.right;
		return items.map((item) => ({
			item,
			side,
			selected:
				this.selection?.side === side &&
				this.selection.id === item.id,
		}));
	}

	get leftRows() {
		return this.rows('left');
	}

	get rightRows() {
		return this.rows('right');
	}

	select = (side: Side, id: string) => {
		this.picked = { side, id };
	};

	move = (side: Side) => {
		const { selection } = this;
		if (selection?.side !== side) return;
		this.picked = {
			side: side === 'left' ? 'right' : 'left',
			id: selection.id,
		};
		(side === 'left'
			? this.args.onMoveRight
			: this.args.onMoveLeft)?.(selection.id);
	};

	reorder = (delta: -1 | 1) => {
		const { selection } = this;
		if (selection?.side === 'right')
			this.args.onReorder?.(selection.id, delta);
	};

	<template>
		<div class="canon-dual-list" style={{this.style}} ...attributes>
			<div class="canon-dual-list-columns">
				{{#each
					(array this.leftRows this.rightRows)
					as |rows index|
				}}
					<div class="canon-dual-list-column">
						<CanonHeading
							id="{{this.id}}-{{index}}"
							@text={{if
								index
								@rightTitle
								@leftTitle
							}}
						/>
						<div
							class="canon-dual-list-items"
							role="group"
							aria-labelledby="{{this.id}}-{{index}}"
						>
							{{#each rows as |row|}}
								<button
									type="button"
									class="canon-dual-list-item
										{{if
											row.selected
											'canon-dual-list-item--selected'
										}}"
									aria-pressed={{if
										row.selected
										"true"
										"false"
									}}
									{{press}}
									{{on
										"click"
										(fn
											this.select
											row.side
											row.item.id
										)
									}}
								>
									<span
										class="canon-dual-list-name"
									>{{row.item.name}}</span>
									{{#if
										row.item.caption
									}}
										<span
											class="canon-dual-list-caption"
										>{{row.item.caption}}</span>
									{{/if}}
								</button>
							{{/each}}
						</div>
					</div>
				{{/each}}
			</div>
			<CanonGrid>
				<CanonButton
					@kind="cell"
					@text="Show"
					@disabled={{notEq
						this.selectedSide
						"left"
					}}
					@onClick={{fn this.move "left"}}
				/>
				<CanonButton
					@kind="cell"
					@text="Hide"
					@disabled={{notEq
						this.selectedSide
						"right"
					}}
					@onClick={{fn this.move "right"}}
				/>
				<CanonButton
					@kind="cell"
					@text="Up"
					@disabled={{lessThan this.rightIndex 1}}
					@onClick={{fn this.reorder -1}}
				/>
				<CanonButton
					@kind="cell"
					@text="Down"
					@disabled={{isLast
						this.rightIndex
						@right.length
					}}
					@onClick={{fn this.reorder 1}}
				/>
			</CanonGrid>
		</div>
	</template>
}

function array<T>(...items: T[]) {
	return items;
}

function notEq(a: unknown, b: unknown) {
	return a !== b;
}

function lessThan(a: number, b: number) {
	return a < b;
}

function isLast(index: number, count: number) {
	return index < 0 || index >= count - 1;
}
