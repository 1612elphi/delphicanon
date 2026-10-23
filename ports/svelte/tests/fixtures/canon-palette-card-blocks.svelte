<script lang="ts">
	import type { Rgb } from '@canon/lib/colour.ts';
	import CanonPaletteCard from '../../src/components/canon-palette-card.svelte';

	let {
		colours,
		onSelect,
	}: { colours: Rgb[]; onSelect: (index: number | undefined) => void } =
		$props();
</script>

<div style="width: 400px">
	<CanonPaletteCard title="Harmony" {colours} {onSelect}>
		{#snippet picker()}<p class="picker">picker</p>{/snippet}
		{#snippet actions()}<button type="button">Copy</button
			>{/snippet}
	</CanonPaletteCard>
</div>
