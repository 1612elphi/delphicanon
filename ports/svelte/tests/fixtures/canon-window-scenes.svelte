<script lang="ts">
	import CanonSidebar from '../../src/components/canon-sidebar.svelte';
	import CanonSidebarRow from '../../src/components/canon-sidebar-row.svelte';
	import CanonWindow from '../../src/components/canon-window.svelte';

	let {
		scene,
		onClose,
		onZoom,
	}: {
		scene: 'bar' | 'bare' | 'widths';
		onClose?: () => void;
		onZoom?: () => void;
	} = $props();
</script>

{#if scene === 'bar'}
	<div style="width: 900px; height: 500px">
		<CanonWindow title="Delphi" {onClose} {onZoom}>
			{#snippet toolbar()}<button type="button" class="tool"
					>T</button
				>{/snippet}
			{#snippet menubar()}<span class="menu">M</span
				>{/snippet}
			{#snippet main()}<p class="detail">D</p>{/snippet}
		</CanonWindow>
	</div>
{:else if scene === 'bare'}
	<CanonWindow />
{:else}
	<div style="display: flex; gap: 8px; height: 400px">
		<div style="flex: none; width: 900px">
			<CanonWindow class="wide">
				{#snippet sidebar()}<CanonSidebar
						><CanonSidebarRow
							title="A"
						/></CanonSidebar
					>{/snippet}
			</CanonWindow>
		</div>
		<div style="flex: none; width: 400px">
			<CanonWindow class="narrow">
				{#snippet sidebar()}<CanonSidebar
						><CanonSidebarRow
							title="A"
						/></CanonSidebar
					>{/snippet}
			</CanonWindow>
		</div>
		<div style="flex: none; width: 400px">
			<CanonWindow class="kept">
				{#snippet sidebar()}<CanonSidebar
						collapsed={false}
						><CanonSidebarRow
							title="A"
						/></CanonSidebar
					>{/snippet}
			</CanonWindow>
		</div>
	</div>
{/if}
