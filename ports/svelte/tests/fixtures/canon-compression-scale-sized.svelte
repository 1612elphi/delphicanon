<script lang="ts">
	import CanonCompressionScale from '../../src/components/canon-compression-scale.svelte';

	let {
		before,
		after,
		working = false,
	}: { before: number; after: number; working?: boolean } = $props();
</script>

<div style="width: 600px; height: 176px">
	<CanonCompressionScale {before} {after} format="JPEG" {working} />
</div>
