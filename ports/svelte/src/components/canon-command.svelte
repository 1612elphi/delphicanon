<script lang="ts" module>
	import type { Snippet } from 'svelte';
	import type { CommandEntry } from '@canon/lib/command.ts';

	export interface CanonCommandItem extends CommandEntry {
		/** Rendered before the title; the consumer supplies it. */
		icon?: Snippet;
		/** Keys drawn as key caps at the end of the row, `['⌘', 'K']`. */
		shortcut?: string[];
		/** A second line: where it lives, or the query an answer answers. */
		detail?: string;
	}
</script>

<script lang="ts">
	import type { HTMLAttributes } from 'svelte/elements';
	import CanonEmptyRow from './canon-empty-row.svelte';
	import CanonHeading from './canon-heading.svelte';
	import CanonRows from './canon-rows.svelte';
	import { iconSnippet, search } from '../lib/control-icons.ts';
	import { rank, step } from '@canon/lib/command.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-command.css';

	interface Props extends Omit<
		HTMLAttributes<HTMLDivElement>,
		'children' | 'onselect'
	> {
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
	}

	interface Row {
		item: CanonCommandItem;
		index: number;
		id: string;
	}

	let {
		items,
		placeholder,
		label = 'Search',
		empty,
		framed,
		onSelect,
		onQuery,
		class: className,
		...rest
	}: Props = $props();

	const SearchIcon = iconSnippet(search);
	const uid = $props.id();
	const listId = `${uid}-list`;

	let query = $state('');
	/** Row index the keys or the pointer moved to; -1 is the first enabled row. */
	let chosen = $state(-1);

	const groups = $derived.by(() => {
		let index = 0;
		return rank(items, query).map((group, number) => ({
			name: group.name,
			headingId: `${listId}-group-${number}`,
			rows: group.items.map((item): Row => ({
				item,
				index,
				id: `${listId}-${index++}`,
			})),
		}));
	});
	const rows = $derived(groups.flatMap((group) => group.rows));
	const activeIndex = $derived.by(() => {
		if (rows[chosen] && !rows[chosen]!.item.disabled) return chosen;
		return rows.findIndex((row) => !row.item.disabled);
	});
	const activeId = $derived(rows[activeIndex]?.id);

	function setQuery(text: string) {
		query = text;
		chosen = -1;
		onQuery?.(text);
	}

	function pick(item: CanonCommandItem) {
		if (!item.disabled) onSelect?.(item);
	}

	function hover(index: number) {
		if (index !== chosen && !rows[index]?.item.disabled)
			chosen = index;
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
			const enabled = rows.filter(
				(row) => !row.item.disabled,
			);
			const at = enabled.findIndex(
				(row) => row.index === activeIndex,
			);
			const next = enabled[step(at, delta, enabled.length)];
			if (!next) return;
			chosen = next.index;
			document.getElementById(next.id)?.scrollIntoView({
				block: 'nearest',
			});
		} else if (event.key === 'Enter') {
			const row = rows[activeIndex];
			if (!row) return;
			event.preventDefault();
			pick(row.item);
		} else if (event.key === 'Escape' && query) {
			// precedes dialog close request
			event.preventDefault();
			setQuery('');
		}
	}
</script>

<!--
  @component
  The search and command palette (the macOS Omnibox): a combobox field over
  a listbox of grouped rows. Focus stays in the field; the arrow keys move
  the active row, wrapping, Enter selects it, Escape clears the query.
-->
<CanonRows {framed} class={['canon-command', className]} {...rest}>
	<div class="canon-command-bar">
		<span class="canon-command-search" aria-hidden="true"
			>{@render SearchIcon()}</span
		>
		<input
			class="canon-command-input"
			type="text"
			role="combobox"
			aria-label={label}
			aria-expanded="true"
			aria-controls={listId}
			aria-autocomplete="list"
			aria-activedescendant={activeId}
			autocomplete="off"
			spellcheck="false"
			{placeholder}
			value={query}
			oninput={(event) => setQuery(event.currentTarget.value)}
			onkeydown={keydown}
		/>
	</div>
	<div
		class="canon-command-list"
		role="listbox"
		id={listId}
		aria-label={label}
		hidden={rows.length ? undefined : true}
	>
		{#each groups as group (group.headingId)}
			<div
				class="canon-command-group"
				role="group"
				aria-labelledby={group.name
					? group.headingId
					: undefined}
			>
				{#if group.name}
					<CanonHeading
						text={group.name}
						id={group.headingId}
						role="presentation"
					/>
				{/if}
				{#each group.rows as row (row.id)}
					<!-- svelte-ignore a11y_click_events_have_key_events, a11y_interactive_supports_focus -->
					<div
						class={[
							'canon-command-item',
							row.item.answer &&
								'canon-command-item--answer',
						]}
						role="option"
						id={row.id}
						aria-selected={row.index ===
						activeIndex
							? 'true'
							: 'false'}
						aria-disabled={row.item.disabled
							? 'true'
							: undefined}
						data-active={row.index ===
						activeIndex
							? ''
							: undefined}
						onclick={() => pick(row.item)}
						onpointermove={() =>
							hover(row.index)}
					>
						{#if row.item.icon}
							<span
								class="canon-command-icon"
								aria-hidden="true"
								>{@render row.item.icon()}</span
							>
						{/if}
						<span
							class="canon-command-text"
						>
							<span
								class="canon-command-title"
								>{row.item
									.title}</span
							>
							{#if row.item.detail}
								<span
									class="canon-command-detail"
									>{row
										.item
										.detail}</span
								>
							{/if}
						</span>
						{#if row.item.shortcut}
							<span
								class="canon-command-keys"
							>
								{#each row.item.shortcut as key, i (i)}
									<span
										class="canon-command-key"
										>{key}</span
									>
								{/each}
							</span>
						{:else if row.index === activeIndex}
							<span
								class="canon-command-enter"
								aria-hidden="true"
								>↵</span
							>
						{/if}
					</div>
				{/each}
			</div>
		{/each}
	</div>
	{#if !rows.length}
		<CanonEmptyRow
			text={empty ? empty : 'No results'}
			class="canon-command-empty"
			role="status"
		/>
	{/if}
</CanonRows>
