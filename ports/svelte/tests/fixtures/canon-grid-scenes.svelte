<script lang="ts">
	import CanonButton from '../../src/components/canon-button.svelte';
	import CanonGrid from '../../src/components/canon-grid.svelte';
	import { dot } from '../helpers.ts';

	let { scene }: { scene: 'four' | 'five' | 'titles' } = $props();
</script>

{#if scene === 'four'}
	<div style="width: 300px">
		<CanonGrid columns={3}>
			<div>1</div>
			<div>2</div>
			<div>3</div>
			<div>4</div>
		</CanonGrid>
	</div>
{:else if scene === 'five'}
	<div style="width: 302px">
		<CanonGrid columns={3}>
			<div>1</div>
			<div>2</div>
			<div>3</div>
			<div>4</div>
			<div>5</div>
		</CanonGrid>
	</div>
{:else}
	<div class="narrow" style="width: 240px">
		<CanonGrid>
			<CanonButton text="Loop" icon={dot} />
			<CanonButton text="Shuffle" icon={dot} />
			<CanonButton text="Export" icon={dot} />
		</CanonGrid>
	</div>
	<div class="wide" style="width: 900px">
		<CanonGrid>
			<CanonButton text="Loop" icon={dot} />
			<CanonButton text="Shuffle" icon={dot} />
			<CanonButton text="Export" icon={dot} />
		</CanonGrid>
	</div>
{/if}
