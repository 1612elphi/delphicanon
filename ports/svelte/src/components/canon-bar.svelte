<script lang="ts">
	import type { HTMLAttributes } from 'svelte/elements';
	import { clamp } from '@canon/lib/number.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-bar.css';

	interface Props extends Omit<
		HTMLAttributes<HTMLDivElement>,
		'children'
	> {
		/** Filled share of the width, 0 to 1. */
		share: number;
		/** CSS colour of the fill; default the primary colour. */
		fill?: string;
		/** CSS colour of the track; default the muted colour. */
		track?: string;
	}

	let { share, fill, track, class: className, ...rest }: Props = $props();

	const style = $derived(
		[
			`--canon-bar-share: ${clamp(share, 0, 1)}`,
			fill && `--canon-bar-fill: ${fill}`,
			track && `--canon-bar-track: ${track}`,
		]
			.filter(Boolean)
			.join('; '),
	);
</script>

<!-- @component A bar filled from the leading edge. -->
<div class={['canon-bar', className]} {style} {...rest}>
	<div class="canon-bar-fill"></div>
</div>
