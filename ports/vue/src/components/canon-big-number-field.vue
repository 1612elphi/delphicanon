<script setup lang="ts">
import CanonStepper from './canon-stepper.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-big-number-field.css';

const props = defineProps<{
	/** The field's text; the tool parses it and sets it. */
	value?: string;
	placeholder?: string;
	/** Centred under the number. */
	unit?: string;
	/** Called with -1 or 1 by the step buttons (repeating while held) and the arrow keys. */
	onStep: (direction: -1 | 1) => void;
	/** Called on every edit with the typed text. */
	onInput?: (text: string) => void;
	/** Typing ended: the field lost focus or Return was pressed. */
	onEndEditing?: () => void;
	labelledBy?: string;
	label?: string;
	disabled?: boolean;
}>();

function typed(event: Event) {
	props.onInput?.((event.target as HTMLInputElement).value);
}

function keys(event: KeyboardEvent) {
	if (event.key === 'Enter') (event.target as HTMLInputElement).blur();
	if (event.key !== 'ArrowUp' && event.key !== 'ArrowDown') return;
	event.preventDefault();
	props.onStep(event.key === 'ArrowUp' ? 1 : -1);
}

function ended() {
	props.onEndEditing?.();
}
</script>

<!-- A tool's main number, large and centred over its unit, between step buttons. -->
<template>
	<CanonStepper
		class="canon-big-number-field"
		:on-step="onStep"
		:disabled="disabled"
	>
		<span class="canon-big-number-field-stack">
			<input
				type="text"
				class="canon-big-number-field-input"
				inputmode="decimal"
				enterkeyhint="done"
				autocomplete="off"
				spellcheck="false"
				:value="value"
				:placeholder="placeholder"
				:aria-labelledby="labelledBy"
				:aria-label="label"
				:disabled="disabled"
				@input="typed"
				@keydown="keys"
				@blur="ended"
			/>
			<span v-if="unit" class="canon-big-number-field-unit">{{
				unit
			}}</span>
		</span>
	</CanonStepper>
</template>
