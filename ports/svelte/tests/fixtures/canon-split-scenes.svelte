<script lang="ts">
	import CanonCanvas from '../../src/components/canon-canvas.svelte';
	import CanonSplit from '../../src/components/canon-split.svelte';

	let {
		scene,
		aspect = 1,
	}: {
		scene:
			| 'wide'
			| 'narrow'
			| 'one-column'
			| 'leads-halves'
			| 'collapsing'
			| 'footer-hidden';
		aspect?: number;
	} = $props();
</script>

{#snippet side()}<div class="side">Side</div>{/snippet}
{#snippet main()}<div class="main">Main</div>{/snippet}
{#snippet strip()}<div class="strip">Strip</div>{/snippet}

{#if scene === 'wide'}
	<div style="width: 1000px; height: 600px">
		<CanonSplit sidebar={side} {main} footer={strip}>
			{#snippet banner()}<CanonCanvas
					height={100}
				/>{/snippet}
		</CanonSplit>
	</div>
{:else if scene === 'narrow'}
	<div style="width: 500px; height: 800px">
		<CanonSplit sidebar={side} {main} />
	</div>
{:else if scene === 'one-column'}
	<div style="width: 1000px; height: 600px">
		<CanonSplit oneColumn sidebar={side} {main} />
	</div>
{:else if scene === 'leads-halves'}
	<div class="stacked" style="width: 500px; height: 800px">
		<CanonSplit mainLeadsStacked sidebar={side} {main} />
	</div>
	<div class="halves" style="width: 1001px; height: 600px">
		<CanonSplit halves {main}>
			{#snippet sidebar()}<CanonCanvas aspect={1} />{/snippet}
		</CanonSplit>
	</div>
{:else if scene === 'collapsing'}
	<div style="width: 500px; height: 800px">
		<CanonSplit halves collapsesTo={100} {main}>
			{#snippet sidebar()}<CanonCanvas {aspect} />{/snippet}
		</CanonSplit>
	</div>
{:else}
	<div style="width: 1000px; height: 600px">
		<CanonSplit footerHidden {main} footer={strip} />
	</div>
{/if}
