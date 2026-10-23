<script lang="ts" module>
	export const pane = 'sidebar';
	export const order = 40;
</script>

<script lang="ts">
	import CanonHeading from '../../src/components/canon-heading.svelte';
	import CanonRows from '../../src/components/canon-rows.svelte';
	import CanonTiles from '../../src/components/canon-tiles.svelte';

	const items = [
		{ label: 'Codec', value: 'AAC' },
		{ label: 'Sample rate', value: '44100 Hz' },
		{ label: 'Peak', value: '-4.3 dBFS', level: 0.93 },
		{ label: 'RMS', value: '-13.6 dBFS', level: 0.77 },
		{ label: 'Encoded with', value: 'Lavf62.12.101' },
	];
</script>

<CanonRows framed>
	<CanonHeading text="Tiles" />
	<CanonTiles {items} />
</CanonRows>
