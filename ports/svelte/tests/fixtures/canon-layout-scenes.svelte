<script lang="ts">
	import CanonCanvas from '../../src/components/canon-canvas.svelte';
	import CanonPage from '../../src/components/canon-page.svelte';
	import CanonRows from '../../src/components/canon-rows.svelte';
	import CanonRule from '../../src/components/canon-rule.svelte';

	let {
		scene,
	}: { scene: 'rows' | 'rule' | 'page' | 'page-uncapped' | 'canvas' } =
		$props();
</script>

{#if scene === 'rows'}
	<CanonRows framed>
		<div class="a">A</div>
		<div class="b">B</div>
	</CanonRows>
{:else if scene === 'rule'}
	<div style="display: flex; height: 40px"><CanonRule vertical /></div>
	<CanonRule />
{:else if scene === 'page'}
	<div style="width: 1000px; height: 400px">
		<CanonPage>
			<div class="section">Section</div>
			<CanonCanvas height={50} />
		</CanonPage>
	</div>
{:else if scene === 'page-uncapped'}
	<div style="width: 1000px">
		<CanonPage maxWidth={null}
			><div class="section">S</div></CanonPage
		>
	</div>
{:else}
	<div style="width: 400px">
		<CanonCanvas class="fixed" height={120}
			><span>Art</span></CanonCanvas
		>
		<CanonCanvas class="aspect" aspect={4} />
		<CanonCanvas class="capped" aspect={4} maxHeight={60} />
	</div>
{/if}
