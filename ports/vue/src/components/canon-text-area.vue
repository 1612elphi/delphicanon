<script setup lang="ts">
import { computed, useTemplateRef, watch } from 'vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-text-area.css';

const props = defineProps<{
	value?: string;
	placeholder?: string;
	/** Fixed height in px; default 200. The text scrolls inside it. */
	height?: number;
	/** Called for typed edits, not for a new `value`. */
	onChange?: (value: string) => void;
}>();

const style = computed(() =>
	props.height === undefined
		? undefined
		: { blockSize: `${props.height}px` },
);

const area = useTemplateRef<HTMLTextAreaElement>('area');
// a model echo must not replace the text being typed
watch(
	[area, () => props.value || ''],
	([element, value]) => {
		if (
			element &&
			document.activeElement !== element &&
			element.value !== value
		)
			element.value = value;
	},
	{ flush: 'post' },
);

function edited(event: Event) {
	props.onChange?.((event.target as HTMLTextAreaElement).value);
}
</script>

<!-- Multi-line monospaced input, wrapping, with its own scrolling. -->
<template>
	<textarea
		ref="area"
		class="canon-text-area"
		:placeholder="placeholder"
		autocomplete="off"
		autocapitalize="off"
		spellcheck="false"
		:style="style"
		@input="edited"
	></textarea>
</template>
