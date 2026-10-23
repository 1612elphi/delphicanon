<script lang="ts">
	import CanonDimensionLine from '../../src/components/canon-dimension-line.svelte';
</script>

<div style="position: relative; width: 400px; height: 300px">
	<CanonDimensionLine
		class="across"
		pixels={1600}
		style="inset-inline-start: 44px; inset-block-start: 0; inline-size: 200px"
	/>
	<CanonDimensionLine class="down" pixels={1200} down />
	<CanonDimensionLine class="blank" pixels={1600} blank />
</div>
