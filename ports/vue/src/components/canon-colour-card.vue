<script setup lang="ts">
import { computed } from 'vue';
import {
	contrastFigure,
	contrastLevels,
	contrastRatio,
	formatColour,
	formatLabel,
	hex,
	type ColourFormat,
	type Rgb,
} from '@canon/lib/colour.ts';
import CanonValueLine from './canon-value-line.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-colour-card.css';

const props = defineProps<{
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
}>();

const layout = computed(() => props.layout ?? 'chip');
const code = computed(() => hex(props.colour));
const name = computed(
	() => props.name ?? props.nameOf?.(code.value) ?? code.value,
);

const lines = computed(() => {
	const shown: ColourFormat[] = ['hex'];
	for (const format of [
		props.primaryFormat ?? 'hex',
		props.secondaryFormat ?? 'rgb',
		'oklch',
		'rgb',
	] as const) {
		if (!shown.includes(format)) shown.push(format);
	}
	return shown
		.slice(0, layout.value === 'chip' ? 3 : 1)
		.map((format) => ({
			label: formatLabel(format),
			value: formatColour(props.colour, format),
		}));
});

const inks = computed(() =>
	[1, 0].map((level) => {
		const ratio = contrastRatio(props.colour, [
			level,
			level,
			level,
		]);
		const faint = ratio < contrastLevels.aa;
		return {
			figure: contrastFigure(ratio),
			style: {
				color: level ? 'white' : 'black',
				opacity: faint ? 0.45 : 1,
			},
		};
	}),
);
</script>

<!--
  A paint chip: the colour over its name and values. The swatch carries
  white and black type with their contrast ratios; each value line copies
  itself on a tap.
-->
<template>
	<div class="canon-colour-card" :class="`canon-colour-card--${layout}`">
		<div
			class="canon-colour-card-swatch"
			:style="{ background: code }"
		>
			<template v-if="layout === 'chip'">
				<span
					v-for="(ink, i) in inks"
					:key="i"
					class="canon-colour-card-ink"
					:style="ink.style"
					aria-hidden="true"
				>
					<span class="canon-colour-card-specimen"
						>Aa</span
					>
					<span class="canon-colour-card-ratio">{{
						ink.figure
					}}</span>
				</span>
			</template>
		</div>
		<div class="canon-colour-card-info">
			<div class="canon-colour-card-name">{{ name }}</div>
			<CanonValueLine
				v-for="line in lines"
				:key="line.label"
				:label="line.label"
				:value="line.value"
			/>
		</div>
	</div>
</template>
