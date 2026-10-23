<script setup lang="ts">
import { computed, ref } from 'vue';
import CanonStepper from './canon-stepper.vue';
import { clamp, parseInteger } from '@canon/lib/number.ts';
import '@canon/styles/tokens.css';

const props = defineProps<{
	value: number;
	min?: number;
	max?: number;
	step?: number;
	/** Muted, after the number. */
	unit?: string;
	/** Id of the element that names the field, such as a row title. */
	labelledBy?: string;
	label?: string;
	disabled?: boolean;
	onChange?: (value: number) => void;
}>();

// a change holds until the value prop changes
const held = ref<{ value: number; over: number }>();
const draft = ref<string>();

const min = computed(() => props.min ?? 0);
const max = computed(() => props.max ?? Number.MAX_SAFE_INTEGER);
const value = computed(() => {
	const raw =
		held.value && held.value.over === props.value
			? held.value.value
			: props.value;
	return clamp(raw, min.value, max.value);
});
const text = computed(() => draft.value ?? String(value.value));

function commit(next: number) {
	if (next === value.value) return;
	held.value = { value: next, over: props.value };
	props.onChange?.(next);
}

function nudge(direction: -1 | 1) {
	draft.value = undefined;
	commit(
		clamp(
			value.value + direction * (props.step ?? 1),
			min.value,
			max.value,
		),
	);
}

function typed(event: Event) {
	draft.value = (event.target as HTMLInputElement).value;
	const next = parseInteger(draft.value);
	if (next !== undefined && next >= min.value && next <= max.value)
		commit(next);
}

function key(event: KeyboardEvent) {
	if (event.key === 'Enter') (event.target as HTMLInputElement).blur();
	if (event.key !== 'ArrowUp' && event.key !== 'ArrowDown') return;
	event.preventDefault();
	nudge(event.key === 'ArrowUp' ? 1 : -1);
}

function leave() {
	draft.value = undefined;
}
</script>

<!-- Integer with step buttons either side. Arrow keys step too. -->
<template>
	<CanonStepper
		class="canon-number-field"
		:on-step="nudge"
		:disabled="disabled"
	>
		<span class="canon-stepper-value">
			<input
				type="text"
				class="canon-stepper-field"
				role="spinbutton"
				:aria-valuenow="value"
				:aria-valuemin="min"
				:aria-valuemax="max"
				:inputmode="min < 0 ? 'text' : 'numeric'"
				enterkeyhint="done"
				:aria-labelledby="labelledBy"
				:aria-label="label"
				:value="text"
				:disabled="disabled"
				@input="typed"
				@keydown="key"
				@blur="leave"
			/>
			<span v-if="unit" class="canon-stepper-unit">{{
				unit
			}}</span>
		</span>
	</CanonStepper>
</template>
