<script lang="ts">
	import CanonMenuBar, {
		type CanonMenuBarMenu,
	} from '../../src/components/canon-menu-bar.svelte';
	import type { CanonMenuItem } from '../../src/components/canon-menu.svelte';

	let {
		menus,
		onSelect,
	}: {
		menus: CanonMenuBarMenu[];
		onSelect?: (item: CanonMenuItem, menu: number) => void;
	} = $props();
</script>

<div style="width: 400px">
	<CanonMenuBar aria-label="App" {menus} {onSelect} />
</div>
