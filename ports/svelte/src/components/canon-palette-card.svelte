<script lang="ts" module>
	import { springEasing } from '@canon/lib/motion.ts';

	/** Width of the widened swatch against the others. */
	export const widened = 3;
	const spring = springEasing(0.82);
</script>

<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { HTMLAttributes } from 'svelte/elements';
	import {
		formatColour,
		hex,
		takesBlackInk,
		type ColourFormat,
		type Rgb,
	} from '@canon/lib/colour.ts';
	import { canonToast } from '../lib/toast-store.svelte.ts';
	import CanonGrid from './canon-grid.svelte';
	import CanonHeading from './canon-heading.svelte';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-palette-card.css';

	interface Props extends Omit<HTMLAttributes<HTMLDivElement>, 'title'> {
		title: string;
		colours: Rgb[];
		/** Height of the swatches in px. */
		height?: number;
		selected?: number;
		onSelect?: (index: number | undefined) => void;
		/** Nearest colour name for a hex, shown on the widened swatch. */
		nameOf?: (hex: string) => string;
		/** The app's colour format settings; the widened swatch shows the first that is not hex. */
		primaryFormat?: ColourFormat;
		secondaryFormat?: ColourFormat;
		/** A choice between palettes, under the heading: a CanonSegmented. */
		picker?: Snippet;
		/** Flush cells in a bar under the swatches: CanonButtons of kind cell. */
		actions?: Snippet;
	}

	let {
		title,
		colours,
		height,
		selected: selectedIndex,
		onSelect,
		nameOf,
		primaryFormat,
		secondaryFormat,
		picker,
		actions,
		class: className,
		...rest
	}: Props = $props();

	// a pick holds until the selected prop changes
	let picked = $state<{ index: number; over: number | undefined }>();

	const selected = $derived.by(() => {
		const index =
			picked && picked.over === selectedIndex
				? picked.index
				: selectedIndex;
		return index !== undefined && index < colours.length
			? index
			: undefined;
	});

	const detailFormat = $derived<ColourFormat>(
		[primaryFormat ?? 'hex', secondaryFormat ?? 'rgb'].find(
			(format) => format !== 'hex',
		) ?? 'oklch',
	);

	const swatches = $derived(
		colours.map((colour, index) => {
			const code = hex(colour);
			const wide = index === selected;
			return {
				index,
				hex: code,
				wide,
				name: wide ? nameOf?.(code) : undefined,
				label: nameOf?.(code) ?? code,
				details: formatColour(colour, detailFormat),
				style: `background: ${code}; color: ${takesBlackInk(colour) ? 'black' : 'white'}; flex-grow: ${wide ? widened : 1}`,
			};
		}),
	);

	function tap(index: number) {
		if (index === selected) {
			void canonToast.copy(hex(colours[index]!));
			return;
		}
		picked = { index, over: selectedIndex };
		onSelect?.(index);
	}
</script>

<!--
  @component
  A palette as swatches meeting at hairlines, under a heading. A tap widens
  a swatch to show its name and values; a tap on the widened swatch copies
  its hex.
-->
<div class={['canon-palette-card', className]} {...rest}>
	<CanonHeading text={title} />
	{@render picker?.()}
	<div
		class="canon-palette-card-strip"
		style="block-size: {height ??
			156}px; --canon-palette-spring: {spring}"
	>
		{#each swatches as swatch (swatch.index)}
			<button
				type="button"
				class={[
					'canon-palette-card-swatch',
					swatch.wide &&
						'canon-palette-card-swatch--wide',
				]}
				style={swatch.style}
				aria-label={swatch.label}
				aria-pressed={swatch.wide ? 'true' : 'false'}
				onclick={() => tap(swatch.index)}
			>
				<span class="canon-palette-card-name"
					>{swatch.name}</span
				>
				<span class="canon-palette-card-details"
					>{swatch.details}</span
				>
				<span class="canon-palette-card-hex"
					>{swatch.hex}</span
				>
			</button>
		{/each}
	</div>
	{#if actions}
		<CanonGrid>{@render actions()}</CanonGrid>
	{/if}
</div>
