<script lang="ts">
/** Typing commits after this pause, or when the field loses focus. */
export const typingPauseMs = 600;
</script>

<script setup lang="ts">
import { computed, onBeforeUnmount, ref } from 'vue';
import CanonStepper from './canon-stepper.vue';
import {
	formatDecimal,
	parseDecimal,
	roundDecimal,
} from '@canon/lib/number.ts';
import '@canon/styles/tokens.css';

const props = defineProps<{
	value: number;
	/** Default 0, or no lower bound when `signed`. */
	min?: number;
	max?: number;
	/** Default "s". */
	unit?: string;
	/** Default 0.1. */
	step?: number;
	/** Places kept; default 3. */
	decimals?: number;
	/** Gives a touch keyboard a minus key; the decimal pad has none. */
	signed?: boolean;
	labelledBy?: string;
	label?: string;
	disabled?: boolean;
	onChange?: (value: number) => void;
}>();

const held = ref<{ value: number; over: number }>();
const draft = ref<string>();
let typing: number | undefined;

const decimals = computed(() => props.decimals ?? 3);
const unit = computed(() => props.unit ?? 's');
const min = computed(() => props.min ?? (props.signed ? -Infinity : 0));
const max = computed(() => props.max ?? Infinity);
const value = computed(() =>
	held.value && held.value.over === props.value
		? held.value.value
		: props.value,
);
const text = computed(
	() => draft.value ?? formatDecimal(value.value, decimals.value),
);

function apply(raw: number) {
	const next = roundDecimal(raw, decimals.value, min.value, max.value);
	if (next === value.value) return;
	held.value = { value: next, over: props.value };
	props.onChange?.(next);
}

function nudge(direction: -1 | 1) {
	draft.value = undefined;
	apply(value.value + direction * (props.step ?? 0.1));
}

function commit() {
	window.clearTimeout(typing);
	const typed =
		draft.value === undefined
			? undefined
			: parseDecimal(draft.value);
	if (typed !== undefined) apply(typed);
}

function typed(event: Event) {
	draft.value = (event.target as HTMLInputElement).value;
	window.clearTimeout(typing);
	typing = window.setTimeout(commit, typingPauseMs);
}

function key(event: KeyboardEvent) {
	if (event.key === 'Enter') (event.target as HTMLInputElement).blur();
	if (event.key !== 'ArrowUp' && event.key !== 'ArrowDown') return;
	event.preventDefault();
	commit();
	nudge(event.key === 'ArrowUp' ? 1 : -1);
}

function leave() {
	commit();
	draft.value = undefined;
}

onBeforeUnmount(() => window.clearTimeout(typing));
</script>

<!-- A decimal number with step buttons and a unit; seconds by default. -->
<template>
	<CanonStepper
		class="canon-decimal-field"
		:on-step="nudge"
		:disabled="disabled"
	>
		<span class="canon-stepper-value">
			<input
				type="text"
				class="canon-stepper-field canon-decimal-field-input"
				role="spinbutton"
				:aria-valuenow="value"
				:aria-valuetext="`${text} ${unit}`"
				:inputmode="signed ? 'text' : 'decimal'"
				enterkeyhint="done"
				:aria-labelledby="labelledBy"
				:aria-label="label"
				:value="text"
				:disabled="disabled"
				@input="typed"
				@keydown="key"
				@blur="leave"
			/>
			<span class="canon-stepper-unit">{{ unit }}</span>
		</span>
	</CanonStepper>
</template>
