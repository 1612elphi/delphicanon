<script lang="ts">
	import CanonColourSolid from '../../src/components/canon-colour-solid.svelte';
	import type { Rgb } from '@canon/lib/colour.ts';
	import type { SolidSpace } from '@canon/lib/colour-space.ts';
	import type { Vec4 } from '@canon/lib/colour-solid/vec.ts';

	interface Props {
		size: number;
		space: SolidSpace;
		point: Vec4;
		sliceAxis?: number | null;
		onChange: (point: Vec4, colour: Rgb) => void;
	}

	let {
		size,
		space,
		point,
		sliceAxis = null,
		onChange,
	}: Props = $props();

	// the model's onChange writes the pick back, as the Ember test's Model does
	let current = $derived(point);

	function change(next: Vec4, colour: Rgb) {
		onChange(next, colour);
		current = next;
	}
</script>

<div style="width: {size}px; height: {size}px">
	<CanonColourSolid
		{space}
		point={current}
		{sliceAxis}
		onChange={change}
	/>
</div>
