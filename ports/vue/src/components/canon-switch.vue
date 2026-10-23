<script setup lang="ts">
import { computed, ref } from 'vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-switch.css';

const props = withDefaults(
	defineProps<{
		on?: boolean;
		disabled?: boolean;
		onChange?: (on: boolean) => void;
	}>(),
	{ on: undefined },
);

// a flip holds until the on prop changes
const flipped = ref<{ on: boolean; over: boolean | undefined }>();

const on = computed(() =>
	flipped.value && flipped.value.over === props.on
		? flipped.value.on
		: (props.on ?? false),
);

function change(event: Event) {
	const next = (event.target as HTMLInputElement).checked;
	flipped.value = { on: next, over: props.on };
	props.onChange?.(next);
}
</script>

<!-- An on/off switch: a native checkbox with the switch role. -->
<template>
	<input
		type="checkbox"
		role="switch"
		class="canon-switch"
		:checked="on"
		:aria-checked="on ? 'true' : 'false'"
		:disabled="disabled"
		@change="change"
	/>
</template>
