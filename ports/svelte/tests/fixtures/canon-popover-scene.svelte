<script lang="ts">
	import CanonPopover from '../../src/components/canon-popover.svelte';
</script>

<CanonPopover role="dialog" aria-label="Panel" placement="top-end">
	{#snippet trigger(popover)}
		<button type="button" class="opener" {@attach popover.trigger}
			>Open</button
		>
	{/snippet}
	{#snippet content(popover)}
		<button type="button" class="inside" onclick={popover.close}
			>Close</button
		>
	{/snippet}
</CanonPopover>
