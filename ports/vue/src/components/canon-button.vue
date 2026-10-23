<script lang="ts">
export type CanonButtonKind = 'primary' | 'secondary' | 'cell' | 'segment';

/** Seconds before a held button repeats, between repeats, and between repeats after ten. */
export const repeatTiming = { delay: 0.4, interval: 0.09, fast: 0.04 } as const;
export const flashSeconds = 1.5;
</script>

<script setup lang="ts">
import {
	computed,
	h,
	onBeforeUnmount,
	ref,
	type Component,
	type FunctionalComponent,
} from 'vue';
import { vPress } from '../lib/press.ts';
import { check } from '../lib/lucide.ts';
import CanonIcon from './canon-icon.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-button.css';

const props = defineProps<{
	/** The title. Empty shows the icon alone. */
	text?: string;
	/** Rendered as the symbol; the consumer supplies it (lucide in the web app). */
	icon?: Component;
	/**
	 * inline: small, beside the title. oversized: large and faint behind the
	 * title, turned, cut off by the trailing and bottom edges. Keep it rare.
	 */
	iconStyle?: 'inline' | 'oversized';
	/**
	 * primary: the tool's main verb, fills its container. secondary: fills
	 * its container. cell: content width, the enclosing grid or flush row
	 * draws the lines. segment: a cell that shows `selected`.
	 */
	kind?: CanonButtonKind;
	selected?: boolean;
	disabled?: boolean;
	/** Accessible name when the title is empty or dropped. */
	label?: string;
	onClick?: () => void;
	/** Holding the button runs onClick again and again; a tap runs it once. */
	repeats?: boolean;
	/** Shows Copied with a check for 1.5 s after each click. */
	flashesCopied?: boolean;
}>();

const Check: FunctionalComponent = () => h(CanonIcon, { svg: check });

const flashing = ref(false);
let flashTimer: number | undefined;
let holdTimer: number | undefined;
let held = false;
let didRepeat = false;

const kind = computed(() => props.kind ?? 'secondary');
const text = computed(() => (flashing.value ? 'Copied' : (props.text ?? '')));
const icon = computed(() => (flashing.value ? Check : props.icon));
const oversized = computed(
	() => props.iconStyle === 'oversized' && icon.value !== undefined,
);
const filled = computed(
	() =>
		kind.value === 'primary' ||
		(props.selected &&
			(kind.value === 'segment' ||
				kind.value === 'secondary')),
);
/** A grid drops the title of a filling button with a symbol when it does not fit. */
const fits = computed(
	() =>
		(kind.value === 'primary' || kind.value === 'secondary') &&
		text.value !== '' &&
		icon.value !== undefined &&
		!oversized.value,
);
const label = computed(() => {
	if (icon.value === undefined) return undefined;
	return props.label ?? (text.value || undefined);
});

function click() {
	if (didRepeat) {
		didRepeat = false;
		return;
	}
	props.onClick?.();
	if (props.flashesCopied) flash();
}

function flash() {
	flashing.value = true;
	window.clearTimeout(flashTimer);
	flashTimer = window.setTimeout(() => {
		flashing.value = false;
	}, flashSeconds * 1000);
}

function hold(event: PointerEvent) {
	if (!props.repeats || event.button !== 0) return;
	held = true;
	didRepeat = false;
	schedule(repeatTiming.delay, 0);
}

function letGo() {
	held = false;
	window.clearTimeout(holdTimer);
}

function schedule(seconds: number, count: number) {
	window.clearTimeout(holdTimer);
	holdTimer = window.setTimeout(() => {
		if (!held || props.disabled) return;
		didRepeat = true;
		props.onClick?.();
		schedule(
			count < 10 ? repeatTiming.interval : repeatTiming.fast,
			count + 1,
		);
	}, seconds * 1000);
}

onBeforeUnmount(() => {
	window.clearTimeout(flashTimer);
	letGo();
});
</script>

<template>
	<button
		v-press
		type="button"
		class="canon-button"
		:class="[
			`canon-button--${kind}`,
			{
				'canon-button--filled': filled,
				'canon-button--has-icon': icon,
				'canon-button--oversized': oversized,
				'canon-button--symbol': !text,
			},
		]"
		:data-canon-fit="fits ? '' : undefined"
		:disabled="disabled"
		:aria-label="label"
		@click="click"
		@pointerdown="hold"
		@pointerup="letGo"
		@pointerleave="letGo"
		@pointercancel="letGo"
	>
		<span
			v-if="icon"
			:class="
				oversized
					? 'canon-button-watermark'
					: 'canon-button-icon'
			"
			aria-hidden="true"
			><component :is="icon"
		/></span>
		<span v-if="text" class="canon-button-title">{{ text }}</span>
	</button>
</template>
