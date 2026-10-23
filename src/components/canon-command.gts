import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';
import type { ComponentLike } from '@glint/template';
import CanonEmptyRow from './canon-empty-row.gts';
import CanonHeading from './canon-heading.gts';
import CanonIcon from './canon-icon.gts';
import CanonRows from './canon-rows.gts';
import { rank, step, type CommandEntry } from '../lib/command.ts';
import '../styles/tokens.css';
import './canon-command.css';
import { Search as search } from 'lucide-static';

export interface CanonCommandItem extends CommandEntry {
	/** Rendered before the title; the consumer supplies it. */
	icon?: ComponentLike;
	/** Keys drawn as key caps at the end of the row, `['⌘', 'K']`. */
	shortcut?: string[];
	/** A second line: where it lives, or the query an answer answers. */
	detail?: string;
}

export interface CanonCommandSignature {
	Args: {
		items: CanonCommandItem[];
		placeholder?: string;
		/** Accessible name of the field and the list; default Search. */
		label?: string;
		/** Shown when nothing matches; default No results. */
		empty?: string;
		/** Draws the 2 px tool frame; leave off inside a CanonDialog. */
		framed?: boolean;
		/** A click, or Enter on the active row. */
		onSelect?: (item: CanonCommandItem) => void;
		/** Every edit of the query, so the owner can add answer items for it. */
		onQuery?: (query: string) => void;
	};
	Element: HTMLDivElement;
}

interface Row {
	item: CanonCommandItem;
	index: number;
	id: string;
}

const SearchIcon = <template><CanonIcon @svg={{search}} /></template>;

/**
 * The search and command palette (the macOS Omnibox): a combobox field over
 * a listbox of grouped rows. Focus stays in the field; the arrow keys move
 * the active row, wrapping, Enter selects it, Escape clears the query.
 */
export default class CanonCommand extends Component<CanonCommandSignature> {
	@tracked query = '';
	/** Row index the keys or the pointer moved to; -1 is the first enabled row. */
	@tracked chosen = -1;
	listId = `${guidFor(this)}-list`;

	get label() {
		return this.args.label ?? 'Search';
	}

	@cached
	get groups() {
		let index = 0;
		return rank(this.args.items, this.query).map(
			(group, number) => ({
				name: group.name,
				headingId: `${this.listId}-group-${number}`,
				rows: group.items.map((item): Row => ({
					item,
					index,
					id: `${this.listId}-${index++}`,
				})),
			}),
		);
	}

	get rows(): Row[] {
		return this.groups.flatMap((group) => group.rows);
	}

	get activeIndex(): number {
		const rows = this.rows;
		if (rows[this.chosen] && !rows[this.chosen]!.item.disabled)
			return this.chosen;
		return rows.findIndex((row) => !row.item.disabled);
	}

	get activeId(): string | undefined {
		return this.rows[this.activeIndex]?.id;
	}

	isActive = (row: Row) => row.index === this.activeIndex;

	input = (event: Event) => {
		this.setQuery((event.target as HTMLInputElement).value);
	};

	setQuery(query: string) {
		this.query = query;
		this.chosen = -1;
		this.args.onQuery?.(query);
	}

	pick = (item: CanonCommandItem) => {
		if (!item.disabled) this.args.onSelect?.(item);
	};

	hover = (index: number) => {
		if (index !== this.chosen && !this.rows[index]?.item.disabled)
			this.chosen = index;
	};

	keydown = (event: KeyboardEvent) => {
		if (event.isComposing) return;
		const delta =
			event.key === 'ArrowDown'
				? 1
				: event.key === 'ArrowUp'
					? -1
					: 0;
		if (delta) {
			event.preventDefault();
			const enabled = this.rows.filter(
				(row) => !row.item.disabled,
			);
			const at = enabled.findIndex(
				(row) => row.index === this.activeIndex,
			);
			const next = enabled[step(at, delta, enabled.length)];
			if (!next) return;
			this.chosen = next.index;
			document.getElementById(next.id)?.scrollIntoView({
				block: 'nearest',
			});
		} else if (event.key === 'Enter') {
			const row = this.rows[this.activeIndex];
			if (!row) return;
			event.preventDefault();
			this.pick(row.item);
		} else if (event.key === 'Escape' && this.query) {
			// precedes dialog close request
			event.preventDefault();
			this.setQuery('');
		}
	};

	<template>
		<CanonRows
			@framed={{@framed}}
			class="canon-command"
			...attributes
		>
			<div class="canon-command-bar">
				<span
					class="canon-command-search"
					aria-hidden="true"
				><SearchIcon /></span>
				<input
					class="canon-command-input"
					type="text"
					role="combobox"
					aria-label={{this.label}}
					aria-expanded="true"
					aria-controls={{this.listId}}
					aria-autocomplete="list"
					aria-activedescendant={{this.activeId}}
					autocomplete="off"
					spellcheck="false"
					placeholder={{@placeholder}}
					value={{this.query}}
					{{on "input" this.input}}
					{{on "keydown" this.keydown}}
				/>
			</div>
			<div
				class="canon-command-list"
				role="listbox"
				id={{this.listId}}
				aria-label={{this.label}}
				hidden={{unless this.rows.length true}}
			>
				{{#each this.groups as |group|}}
					<div
						class="canon-command-group"
						role="group"
						aria-labelledby={{if
							group.name
							group.headingId
						}}
					>
						{{#if group.name}}
							<CanonHeading
								@text={{group.name}}
								id={{group.headingId}}
								role="presentation"
							/>
						{{/if}}
						{{#each group.rows as |row|}}
							{{! template-lint-disable no-invalid-interactive require-context-role require-presentational-children }}
							<div
								class="canon-command-item
									{{if
										row.item.answer
										'canon-command-item--answer'
									}}"
								role="option"
								id={{row.id}}
								aria-selected={{if
									(this.isActive
										row
									)
									"true"
									"false"
								}}
								aria-disabled={{if
									row.item.disabled
									"true"
								}}
								data-active={{if
									(this.isActive
										row
									)
									""
								}}
								{{on
									"click"
									(fn
										this.pick
										row.item
									)
								}}
								{{on
									"pointermove"
									(fn
										this.hover
										row.index
									)
								}}
							>
								{{#let
									row.item.icon
									as |Icon|
								}}
									{{#if
										Icon
									}}
										<span
											class="canon-command-icon"
											aria-hidden="true"
										><Icon
											/></span>
									{{/if}}
								{{/let}}
								<span
									class="canon-command-text"
								>
									<span
										class="canon-command-title"
									>{{row.item.title}}</span>
									{{#if
										row.item.detail
									}}
										<span
											class="canon-command-detail"
										>{{row.item.detail}}</span>
									{{/if}}
								</span>
								{{#if
									row.item.shortcut
								}}
									<span
										class="canon-command-keys"
									>
										{{#each
											row.item.shortcut
											as |key|
										}}
											<span
												class="canon-command-key"
											>{{key}}</span>
										{{/each}}
									</span>
								{{else if
									(this.isActive
										row
									)
								}}
									<span
										class="canon-command-enter"
										aria-hidden="true"
									>↵</span>
								{{/if}}
							</div>
						{{/each}}
					</div>
				{{/each}}
			</div>
			{{#unless this.rows.length}}
				<CanonEmptyRow
					@text={{if @empty @empty "No results"}}
					class="canon-command-empty"
					role="status"
				/>
			{{/unless}}
		</CanonRows>
	</template>
}
