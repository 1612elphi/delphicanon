<script lang="ts">
	import CanonTooltip from '../../src/components/canon-tooltip.svelte';
</script>

<CanonTooltip text="Copy">
	{#snippet children(tip)}
		<button type="button" class="target" {@attach tip.trigger}
			>C</button
		>
	{/snippet}
</CanonTooltip>
