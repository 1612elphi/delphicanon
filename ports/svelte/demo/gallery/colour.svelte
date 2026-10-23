<script lang="ts" module>
	export const pane = 'main';
	export const order = 40;
</script>

<script lang="ts">
	import CanonColourWell from '../../src/components/canon-colour-well.svelte';
	import CanonHeading from '../../src/components/canon-heading.svelte';
	import CanonRows from '../../src/components/canon-rows.svelte';
	import type { Rgb } from '@canon/lib/colour.ts';

	let foreground = $state<Rgb>([0.118, 0.4, 0.149]);
	let orange = $state<Rgb>([1, 0.584, 0]);
</script>

<CanonRows framed>
	<CanonHeading text="Wells" />
	<CanonColourWell
		label="Foreground"
		colour={foreground}
		format="oklch"
		onChange={(colour) => (foreground = colour)}
	/>
	<CanonColourWell
		colour={orange}
		onChange={(colour) => (orange = colour)}
	/>
</CanonRows>
