<script setup lang="ts">
import { computed } from 'vue';
import { hex, takesBlackInk, type Rgb } from '@canon/lib/colour.ts';
import { vPress } from '../lib/press.ts';
import { toast } from '../lib/toast-store.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-swatch.css';

const props = defineProps<{
	colour: Rgb;
	/** Nearest colour name for a hex, read by assistive technology. */
	nameOf?: (hex: string) => string;
}>();

const code = computed(() => hex(props.colour));
const label = computed(() => {
	const name = props.nameOf?.(code.value);
	return name ? `${name} ${code.value}` : code.value;
});
const style = computed(() => ({
	background: code.value,
	color: takesBlackInk(props.colour) ? 'black' : 'white',
}));

const copy = () => void toast.copy(code.value);
</script>

<!--
  One colour, its hex where it fits; a tap copies the hex. The swatch of a
  CanonColourStrip palette. Its width comes from the parent (a grid cell or
  a flex item that grows): it measures itself for the hex.
-->
<template>
	<button
		v-press
		type="button"
		class="canon-swatch"
		:style="style"
		:aria-label="label"
		@click="copy"
	>
		<span class="canon-swatch-hex" aria-hidden="true">{{
			code
		}}</span>
	</button>
</template>
