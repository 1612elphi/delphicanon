<script lang="ts">
	import CanonContextMenu from '../../src/components/canon-context-menu.svelte';
	import type {
		CanonMenuEntry,
		CanonMenuItem,
	} from '../../src/components/canon-menu.svelte';

	let {
		items,
		onSelect,
	}: {
		items: CanonMenuEntry[];
		onSelect?: (item: CanonMenuItem) => void;
	} = $props();
</script>

<CanonContextMenu {items} {onSelect}>
	<!-- svelte-ignore a11y_no_noninteractive_tabindex -->
	<div class="area" tabindex="0">Area</div>
</CanonContextMenu>
