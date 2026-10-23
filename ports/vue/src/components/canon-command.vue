<script setup lang="ts">
import {
	computed,
	h,
	ref,
	useId,
	type Component,
	type FunctionalComponent,
} from 'vue';
import { rank, step, type CommandEntry } from '@canon/lib/command.ts';
import { search } from '../lib/lucide.ts';
import CanonEmptyRow from './canon-empty-row.vue';
import CanonHeading from './canon-heading.vue';
import CanonIcon from './canon-icon.vue';
import CanonRows from './canon-rows.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-command.css';

export interface CanonCommandItem extends CommandEntry {
	/** Rendered before the title; the consumer supplies it. */
	icon?: Component;
	/** Keys drawn as key caps at the end of the row, `['⌘', 'K']`. */
	shortcut?: string[];
	/** A second line: where it lives, or the query an answer answers. */
	detail?: string;
}

const props = defineProps<{
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
}>();

interface Row {
	item: CanonCommandItem;
	index: number;
	id: string;
}

const SearchIcon: FunctionalComponent = () => h(CanonIcon, { svg: search });

const query = ref('');
/** Row index the keys or the pointer moved to; -1 is the first enabled row. */
const chosen = ref(-1);
const listId = `${useId()}-list`;

const label = computed(() => props.label ?? 'Search');

const groups = computed(() => {
	let index = 0;
	return rank(props.items, query.value).map((group, number) => ({
		name: group.name,
		headingId: `${listId}-group-${number}`,
		rows: group.items.map((item): Row => ({
			item,
			index,
			id: `${listId}-${index++}`,
		})),
	}));
});

const rows = computed(() => groups.value.flatMap((group) => group.rows));

const activeIndex = computed(() => {
	const all = rows.value;
	if (all[chosen.value] && !all[chosen.value]!.item.disabled)
		return chosen.value;
	return all.findIndex((row) => !row.item.disabled);
});

const activeId = computed(() => rows.value[activeIndex.value]?.id);

function input(event: Event) {
	setQuery((event.target as HTMLInputElement).value);
}

function setQuery(text: string) {
	query.value = text;
	chosen.value = -1;
	props.onQuery?.(text);
}

function pick(item: CanonCommandItem) {
	if (!item.disabled) props.onSelect?.(item);
}

function hover(index: number) {
	if (index !== chosen.value && !rows.value[index]?.item.disabled)
		chosen.value = index;
}

function keydown(event: KeyboardEvent) {
	if (event.isComposing) return;
	const delta =
		event.key === 'ArrowDown'
			? 1
			: event.key === 'ArrowUp'
				? -1
				: 0;
	if (delta) {
		event.preventDefault();
		const enabled = rows.value.filter((row) => !row.item.disabled);
		const at = enabled.findIndex(
			(row) => row.index === activeIndex.value,
		);
		const next = enabled[step(at, delta, enabled.length)];
		if (!next) return;
		chosen.value = next.index;
		document.getElementById(next.id)?.scrollIntoView({
			block: 'nearest',
		});
	} else if (event.key === 'Enter') {
		const row = rows.value[activeIndex.value];
		if (!row) return;
		event.preventDefault();
		pick(row.item);
	} else if (event.key === 'Escape' && query.value) {
		// precedes dialog close request
		event.preventDefault();
		setQuery('');
	}
}
</script>

<!--
  The search and command palette (the macOS Omnibox): a combobox field over
  a listbox of grouped rows. Focus stays in the field; the arrow keys move
  the active row, wrapping, Enter selects it, Escape clears the query.
-->
<template>
	<CanonRows :framed="framed" class="canon-command">
		<div class="canon-command-bar">
			<span class="canon-command-search" aria-hidden="true"
				><SearchIcon
			/></span>
			<input
				class="canon-command-input"
				type="text"
				role="combobox"
				:aria-label="label"
				aria-expanded="true"
				:aria-controls="listId"
				aria-autocomplete="list"
				:aria-activedescendant="activeId"
				autocomplete="off"
				spellcheck="false"
				:placeholder="placeholder"
				:value="query"
				@input="input"
				@keydown="keydown"
			/>
		</div>
		<div
			:id="listId"
			class="canon-command-list"
			role="listbox"
			:aria-label="label"
			:hidden="!rows.length"
		>
			<div
				v-for="group in groups"
				:key="group.headingId"
				class="canon-command-group"
				role="group"
				:aria-labelledby="
					group.name ? group.headingId : undefined
				"
			>
				<CanonHeading
					v-if="group.name"
					:id="group.headingId"
					:text="group.name"
					role="presentation"
				/>
				<div
					v-for="row in group.rows"
					:id="row.id"
					:key="row.id"
					class="canon-command-item"
					:class="{
						'canon-command-item--answer':
							row.item.answer,
					}"
					role="option"
					:aria-selected="
						row.index === activeIndex
							? 'true'
							: 'false'
					"
					:aria-disabled="
						row.item.disabled
							? 'true'
							: undefined
					"
					:data-active="
						row.index === activeIndex
							? ''
							: undefined
					"
					@click="pick(row.item)"
					@pointermove="hover(row.index)"
				>
					<span
						v-if="row.item.icon"
						class="canon-command-icon"
						aria-hidden="true"
						><component :is="row.item.icon"
					/></span>
					<span class="canon-command-text">
						<span
							class="canon-command-title"
							>{{
								row.item.title
							}}</span
						>
						<span
							v-if="row.item.detail"
							class="canon-command-detail"
							>{{
								row.item.detail
							}}</span
						>
					</span>
					<span
						v-if="row.item.shortcut"
						class="canon-command-keys"
					>
						<span
							v-for="(key, k) in row
								.item.shortcut"
							:key="k"
							class="canon-command-key"
							>{{ key }}</span
						>
					</span>
					<span
						v-else-if="
							row.index ===
							activeIndex
						"
						class="canon-command-enter"
						aria-hidden="true"
						>↵</span
					>
				</div>
			</div>
		</div>
		<CanonEmptyRow
			v-if="!rows.length"
			:text="empty || 'No results'"
			class="canon-command-empty"
			role="status"
		/>
	</CanonRows>
</template>
