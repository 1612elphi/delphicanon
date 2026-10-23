<script setup lang="ts">
import { computed, onBeforeUnmount, ref } from 'vue';
import { vPress } from '../lib/press.ts';
import { toast } from '../lib/toast-store.ts';
import { check, copy as copyIcon } from '../lib/lucide.ts';
import { flashSeconds } from './canon-button.vue';
import CanonIcon from './canon-icon.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-code-block.css';

const props = defineProps<{
	code: string;
	/** Shown uppercased in a heading bar above the code; without it the copy button sits below. */
	language?: string;
	/** Taller code scrolls inside the block. */
	maxHeight?: number;
}>();

const copied = ref(false);
let timer: number | undefined;
let gone = false;

const style = computed(() =>
	props.maxHeight === undefined
		? undefined
		: { maxBlockSize: `${props.maxHeight}px` },
);

async function copy() {
	try {
		await toast.write(props.code);
	} catch {
		return;
	}
	if (gone) return;
	copied.value = true;
	window.clearTimeout(timer);
	timer = window.setTimeout(() => {
		copied.value = false;
	}, flashSeconds * 1000);
}

onBeforeUnmount(() => {
	gone = true;
	window.clearTimeout(timer);
});
</script>

<!--
  Monospaced, selectable code with a copy button. Lines do not wrap; the
  block scrolls sideways.
-->
<template>
	<div
		class="canon-code-block"
		:class="{ 'canon-code-block--titled': language }"
	>
		<div class="canon-code-block-bar">
			<span
				v-if="language"
				class="canon-code-block-language"
				>{{ language }}</span
			>
			<button
				v-press
				type="button"
				class="canon-code-block-copy"
				:class="{
					'canon-code-block-copy--copied': copied,
				}"
				aria-label="Copy code"
				@click="copy"
			>
				<CanonIcon :svg="copied ? check : copyIcon" />
			</button>
		</div>
		<pre
			class="canon-code-block-code"
			tabindex="0"
			:style="style"
			>{{ code }}</pre>
	</div>
</template>
