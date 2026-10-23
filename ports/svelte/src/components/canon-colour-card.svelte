<script lang="ts">
	import type { HTMLAttributes } from 'svelte/elements';
	import {
		contrastFigure,
		contrastLevels,
		contrastRatio,
		formatColour,
		formatLabel,
		hex as hexOf,
		type ColourFormat,
		type Rgb,
	} from '@canon/lib/colour.ts';
	import CanonValueLine from './canon-value-line.svelte';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-colour-card.css';

	interface Props extends HTMLAttributes<HTMLDivElement> {
		colour: Rgb;
		/**
		 * chip: swatch above, name and three values below. row: swatch at the
		 * leading edge, name and one value beside it, for lists.
		 */
		layout?: 'chip' | 'row';
		/** Shown instead of the nearest named colour. */
		name?: string;
		/** Nearest colour name for a hex. */
		nameOf?: (hex: string) => string;
		/** The app's colour format settings; default hex and rgb. */
		primaryFormat?: ColourFormat;
		secondaryFormat?: ColourFormat;
	}

	let {
		colour,
		layout = 'chip',
		name: givenName,
		nameOf,
		primaryFormat,
		secondaryFormat,
		class: className,
		...rest
	}: Props = $props();

	const hex = $derived(hexOf(colour));
	const name = $derived(givenName ?? nameOf?.(hex) ?? hex);

	const lines = $derived.by(() => {
		const shown: ColourFormat[] = ['hex'];
		for (const format of [
			primaryFormat ?? 'hex',
			secondaryFormat ?? 'rgb',
			'oklch',
			'rgb',
		] as const) {
			if (!shown.includes(format)) shown.push(format);
		}
		return shown
			.slice(0, layout === 'chip' ? 3 : 1)
			.map((format) => ({
				label: formatLabel(format),
				value: formatColour(colour, format),
			}));
	});

	const inks = $derived(
		[1, 0].map((level) => {
			const ratio = contrastRatio(colour, [
				level,
				level,
				level,
			]);
			const faint = ratio < contrastLevels.aa;
			return {
				figure: contrastFigure(ratio),
				style: `color: ${level ? 'white' : 'black'}; opacity: ${faint ? 0.45 : 1}`,
			};
		}),
	);
</script>

<!--
  @component
  A paint chip: the colour over its name and values. The swatch carries
  white and black type with their contrast ratios; each value line copies
  itself on a tap.
-->
<div
	class={['canon-colour-card', `canon-colour-card--${layout}`, className]}
	{...rest}
>
	<div class="canon-colour-card-swatch" style="background: {hex}">
		{#if layout === 'chip'}
			{#each inks as ink, i (i)}
				<span
					class="canon-colour-card-ink"
					style={ink.style}
					aria-hidden="true"
				>
					<span class="canon-colour-card-specimen"
						>Aa</span
					>
					<span class="canon-colour-card-ratio"
						>{ink.figure}</span
					>
				</span>
			{/each}
		{/if}
	</div>
	<div class="canon-colour-card-info">
		<div class="canon-colour-card-name">{name}</div>
		{#each lines as line (line.label)}
			<CanonValueLine label={line.label} value={line.value} />
		{/each}
	</div>
</div>
