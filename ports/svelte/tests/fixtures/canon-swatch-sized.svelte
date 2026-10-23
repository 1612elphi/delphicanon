<script lang="ts">
	import type { ComponentProps } from 'svelte';
	import CanonSwatch from '../../src/components/canon-swatch.svelte';

	let {
		width,
		...props
	}: { width: number } & ComponentProps<typeof CanonSwatch> = $props();
</script>

<div style="display: grid; width: {width}px; height: 52px">
	<CanonSwatch {...props} />
</div>
