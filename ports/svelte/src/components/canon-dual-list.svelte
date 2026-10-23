<script lang="ts" module>
	export interface CanonDualItem {
		id: string;
		name: string;
		caption?: string;
	}
</script>

<script lang="ts">
	import type { HTMLAttributes } from 'svelte/elements';
	import CanonButton from './canon-button.svelte';
	import CanonGrid from './canon-grid.svelte';
	import CanonHeading from './canon-heading.svelte';
	import { press } from '../lib/press.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-dual-list.css';

	type Side = 'left' | 'right';

	interface Props extends Omit<
		HTMLAttributes<HTMLDivElement>,
		'children'
	> {
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
	}

	let {
		left,
		right,
		leftTitle,
		rightTitle,
		listHeight = 240,
		onMoveRight,
		onMoveLeft,
		onReorder,
		class: className,
		...rest
	}: Props = $props();

	const id = $props.id();
	let picked = $state<{ side: Side; id: string }>();

	/** The pick, while its item is still on that side. */
	const selection = $derived.by(() => {
		if (!picked) return undefined;
		const { side, id } = picked;
		const items = side === 'left' ? left : right;
		return items.some((item) => item.id === id)
			? picked
			: undefined;
	});
	const rightIndex = $derived(
		selection?.side === 'right'
			? right.findIndex((item) => item.id === selection.id)
			: -1,
	);
	const columns = $derived(
		(['left', 'right'] as const).map((side) => ({
			side,
			title: side === 'left' ? leftTitle : rightTitle,
			rows: (side === 'left' ? left : right).map((item) => ({
				item,
				selected:
					selection?.side === side &&
					selection.id === item.id,
			})),
		})),
	);

	function move(side: Side) {
		if (selection?.side !== side) return;
		const moved = selection.id;
		picked = {
			side: side === 'left' ? 'right' : 'left',
			id: moved,
		};
		(side === 'left' ? onMoveRight : onMoveLeft)?.(moved);
	}

	function reorder(delta: -1 | 1) {
		if (selection?.side === 'right')
			onReorder?.(selection.id, delta);
	}
</script>

<!-- @component Two columns with one selection between them; the right column can be reordered. -->
<div
	class={['canon-dual-list', className]}
	style="--canon-dual-list-height: {listHeight}px"
	{...rest}
>
	<div class="canon-dual-list-columns">
		{#each columns as column, index (column.side)}
			<div class="canon-dual-list-column">
				<CanonHeading
					id="{id}-{index}"
					text={column.title}
				/>
				<div
					class="canon-dual-list-items"
					role="group"
					aria-labelledby="{id}-{index}"
				>
					{#each column.rows as row (row.item.id)}
						<button
							type="button"
							class={[
								'canon-dual-list-item',
								row.selected &&
									'canon-dual-list-item--selected',
							]}
							aria-pressed={row.selected
								? 'true'
								: 'false'}
							{@attach press}
							onclick={() =>
								(picked = {
									side: column.side,
									id: row
										.item
										.id,
								})}
						>
							<span
								class="canon-dual-list-name"
								>{row.item
									.name}</span
							>
							{#if row.item.caption}
								<span
									class="canon-dual-list-caption"
									>{row
										.item
										.caption}</span
								>
							{/if}
						</button>
					{/each}
				</div>
			</div>
		{/each}
	</div>
	<CanonGrid>
		<CanonButton
			kind="cell"
			text="Show"
			disabled={selection?.side !== 'left'}
			onClick={() => move('left')}
		/>
		<CanonButton
			kind="cell"
			text="Hide"
			disabled={selection?.side !== 'right'}
			onClick={() => move('right')}
		/>
		<CanonButton
			kind="cell"
			text="Up"
			disabled={rightIndex < 1}
			onClick={() => reorder(-1)}
		/>
		<CanonButton
			kind="cell"
			text="Down"
			disabled={rightIndex < 0 ||
				rightIndex >= right.length - 1}
			onClick={() => reorder(1)}
		/>
	</CanonGrid>
</div>
