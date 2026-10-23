<script lang="ts">
import { compareSpring, springEasing } from '@canon/lib/motion.ts';

const tapEasing = springEasing(compareSpring.damping);
const nudge = 0.1;
</script>

<script setup lang="ts">
import { computed, ref } from 'vue';
import { vSidewaysPan } from '../lib/sideways-pan.ts';
import { arrowLeftRight } from '../lib/lucide.ts';
import CanonIcon from './canon-icon.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-image-compare.css';

const props = defineProps<{
	/** URL of the original. */
	before?: string;
	/** URL of the result. */
	after?: string;
	/** The result could not be made: the original dims and `failure` shows. */
	failed?: boolean;
	/** Shown over the original when `failed`. */
	failure?: string;
	beforeTitle?: string;
	afterTitle?: string;
}>();

/** Share of the width that shows the original. */
const split = ref(0.5);
const springs = ref(false);
let dragged = false;

const comparing = computed(() => Boolean(props.before && props.after));
const beforeTitle = computed(() => props.beforeTitle ?? 'Before');
const afterTitle = computed(() => props.afterTitle ?? 'After');
const percent = computed(() => Math.round(split.value * 100));

const style = computed(() => ({
	'--canon-compare-split': split.value,
	'--canon-compare-transition': springs.value
		? `${compareSpring.ms}ms ${tapEasing}`
		: undefined,
}));

function move(element: HTMLElement, clientX: number, spring: boolean) {
	const box = element.getBoundingClientRect();
	if (box.width <= 0 || !comparing.value) return;
	let share = (clientX - box.left) / box.width;
	if (getComputedStyle(element).direction === 'rtl') share = 1 - share;
	springs.value =
		spring &&
		!window.matchMedia('(prefers-reduced-motion: reduce)').matches;
	split.value = Math.min(Math.max(share, 0), 1);
}

const pan = {
	onBegin: () => {
		dragged = true;
	},
	onMove: (event: PointerEvent) => {
		move(event.currentTarget as HTMLElement, event.clientX, false);
	},
};

function onClick(event: MouseEvent) {
	if (dragged) {
		dragged = false;
		return;
	}
	move(event.currentTarget as HTMLElement, event.clientX, true);
}

function onKey(event: KeyboardEvent) {
	if (!comparing.value) return;
	const element = event.currentTarget as HTMLElement;
	const sign = getComputedStyle(element).direction === 'rtl' ? -1 : 1;
	const steps: Record<string, number> = {
		ArrowRight: nudge * sign,
		ArrowLeft: -nudge * sign,
		ArrowUp: nudge,
		ArrowDown: -nudge,
		Home: -1,
		End: 1,
	};
	const step = steps[event.key];
	if (step === undefined) return;
	event.preventDefault();
	springs.value = false;
	split.value = Math.min(Math.max(split.value + step, 0), 1);
}
</script>

<!--
  One picture, the original on the leading side of a draggable divider and
  the result on the other; a tap moves the divider. To assistive technology
  it is a slider.
-->
<template>
	<div
		v-sideways-pan="pan"
		class="canon-image-compare"
		:class="{
			'canon-image-compare--comparing': comparing,
			'canon-image-compare--failed': failed,
		}"
		:style="style"
		:role="comparing ? 'slider' : undefined"
		:tabindex="comparing ? 0 : undefined"
		:aria-label="`${beforeTitle}, ${afterTitle}`"
		:aria-valuemin="comparing ? 0 : undefined"
		:aria-valuemax="comparing ? 100 : undefined"
		:aria-valuenow="comparing ? percent : undefined"
		:aria-valuetext="comparing ? `${percent}%` : undefined"
		@click="onClick"
		@keydown="onKey"
	>
		<img
			v-if="before"
			class="canon-image-compare-before"
			:src="before"
			alt=""
			draggable="false"
		/>
		<template v-if="comparing">
			<div class="canon-image-compare-after">
				<img :src="after" alt="" draggable="false" />
			</div>
			<div class="canon-image-compare-divider"></div>
			<div class="canon-image-compare-grip">
				<CanonIcon :svg="arrowLeftRight" />
			</div>
			<span
				class="canon-image-compare-tag canon-image-compare-tag--before"
				>{{ beforeTitle }}</span
			>
			<span
				class="canon-image-compare-tag canon-image-compare-tag--after"
				>{{ afterTitle }}</span
			>
		</template>
		<p
			v-if="failed"
			class="canon-image-compare-failure"
			role="status"
		>
			{{ failure }}
		</p>
	</div>
</template>
