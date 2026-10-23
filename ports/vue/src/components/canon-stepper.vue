<script setup lang="ts">
import CanonButton from './canon-button.vue';
import { Minus, Plus } from '../lib/control-icons.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-stepper.css';

defineProps<{
	/** Called with -1 or 1; repeats while a button is held. */
	onStep: (direction: -1 | 1) => void;
	disabled?: boolean;
}>();

defineSlots<{
	/** The middle cell, usually a field and its unit. A click anywhere in it focuses the field. */
	default?: () => unknown;
}>();
</script>

<!-- Minus and plus cells either side of a field's cell, divided by hairlines. -->
<template>
	<div class="canon-stepper">
		<CanonButton
			class="canon-stepper-minus"
			kind="cell"
			:icon="Minus"
			label="Decrease"
			:repeats="true"
			:disabled="disabled"
			:on-click="() => onStep(-1)"
		/>
		<label class="canon-stepper-centre"><slot /></label>
		<CanonButton
			class="canon-stepper-plus"
			kind="cell"
			:icon="Plus"
			label="Increase"
			:repeats="true"
			:disabled="disabled"
			:on-click="() => onStep(1)"
		/>
	</div>
</template>
