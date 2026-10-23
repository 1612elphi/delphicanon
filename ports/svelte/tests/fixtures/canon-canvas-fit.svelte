<script lang="ts">
	import CanonCanvas from '../../src/components/canon-canvas.svelte';

	let { width, shows }: { width: number; shows: boolean } = $props();
</script>

<div style:width="{width}px">
	<CanonCanvas class="fits" fitting>
		{#if shows}
			<div style="aspect-ratio: 2"></div>
		{/if}
	</CanonCanvas>
</div>
