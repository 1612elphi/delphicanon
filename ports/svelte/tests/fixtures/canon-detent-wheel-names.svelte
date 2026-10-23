<script lang="ts">
	import CanonDetentWheel from '../../src/components/canon-detent-wheel.svelte';
	import CanonDetentWheelRow from '../../src/components/canon-detent-wheel-row.svelte';

	interface Props {
		names: string[];
		selected: number;
		onSelect: (index: number) => void;
	}

	let { names, selected, onSelect }: Props = $props();

	const name = (index: number) => names[index]!;

	// the test's onSelect writes the selection back, as the Ember test's State does
	let current = $derived(selected);

	function select(index: number) {
		onSelect(index);
		current = index;
	}
</script>

<div style="height: 200px; width: 240px">
	<CanonDetentWheel
		count={names.length}
		selected={current}
		onSelect={select}
		text={name}
		label="Colour"
	>
		{#snippet children(index, focus)}
			<CanonDetentWheelRow {focus}
				>{name(index)}</CanonDetentWheelRow
			>
		{/snippet}
	</CanonDetentWheel>
</div>
