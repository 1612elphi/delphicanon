<script setup lang="ts">
import { computed, type Directive } from 'vue';
import {
	barLabel,
	compressionScale,
	labelSpare,
} from '@canon/lib/compression.ts';
import { springEasing } from '@canon/lib/motion.ts';
import CanonBar from './canon-bar.vue';
import CanonFigure from './canon-figure.vue';
import CanonLoader from './canon-loader.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-compression-scale.css';

const props = defineProps<{
	/** The original's size in bytes; 0 before a file. */
	before: number;
	/** The result's size in bytes; 0 before a result. */
	after: number;
	/** The result bar's label. */
	format: string;
	/** Shows the loader beside the figure. */
	working?: boolean;
}>();

// the iOS bar spring: 0.6 s, damping 0.7
const style = { '--canon-compression-scale-easing': springEasing(0.7) };

const shares = new WeakMap<HTMLElement, number>();
const observers = new WeakMap<HTMLElement, ResizeObserver>();

function place(bar: HTMLElement) {
	const label = bar.querySelector<HTMLElement>(
		'.canon-compression-scale-label',
	)!;
	bar.toggleAttribute(
		'data-inside',
		bar.clientWidth * (shares.get(bar) ?? 0) >=
			label.offsetWidth + labelSpare,
	);
}

/** The label sits inside the fill when it fits with 20 px to spare, else after it. */
const vPlace: Directive<HTMLElement, number> = {
	mounted(bar, { value }) {
		shares.set(bar, value);
		place(bar);
		const observer = new ResizeObserver(() => place(bar));
		observer.observe(bar);
		observers.set(bar, observer);
	},
	updated(bar, { value }) {
		shares.set(bar, value);
		place(bar);
	},
	beforeUnmount(bar) {
		observers.get(bar)?.disconnect();
	},
};

const scale = computed(() => compressionScale(props.before, props.after));
const colour = computed(() =>
	scale.value.grew ? 'var(--canon-destructive)' : 'var(--canon-primary)',
);
const bars = computed(() => [
	{
		label: barLabel('Original', props.before),
		share: 1,
		fill: 'var(--canon-muted)',
		ink: 'var(--canon-foreground)',
	},
	{
		label: barLabel(
			props.format,
			scale.value.known ? props.after : 0,
		),
		share: scale.value.share,
		fill: colour.value,
		ink: 'var(--canon-primary-foreground)',
	},
]);
</script>

<!-- Two bars to one scale, the original's bytes over the result's, with the saving as a figure. -->
<template>
	<div class="canon-compression-scale" :style="style">
		<div class="canon-compression-scale-top">
			<CanonLoader
				v-if="working"
				class="canon-compression-scale-loader"
				:cell="5"
				:gap="1"
			/>
			<CanonFigure
				:text="scale.figure"
				:unit="scale.unit"
				:colour="colour"
			/>
		</div>
		<div
			v-for="(bar, index) in bars"
			:key="index"
			v-place="bar.share"
			class="canon-compression-scale-bar"
			:style="{
				'--canon-compression-scale-share': Math.min(
					Math.max(bar.share, 0),
					1,
				),
				'--canon-compression-scale-ink': bar.ink,
			}"
		>
			<CanonBar
				:share="bar.share"
				:fill="bar.fill"
				track="transparent"
			/>
			<span class="canon-compression-scale-label">{{
				bar.label
			}}</span>
		</div>
	</div>
</template>
