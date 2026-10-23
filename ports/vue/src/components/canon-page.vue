<script setup lang="ts">
import { computed } from 'vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-page.css';

const props = defineProps<{
	/** Widest a section gets, in px; null for no cap. Default 720. */
	maxWidth?: number | null;
}>();

const style = computed(() =>
	props.maxWidth === null
		? undefined
		: { '--canon-page-max-width': `${props.maxWidth ?? 720}px` },
);
</script>

<!--
  Scrolling tool body. Sections are centred, capped at maxWidth and inset by
  the panel padding; a CanonCanvas section spans the full width instead
  (CanonPage and CanonPaddedSection).
-->
<template>
	<div class="canon-page" :style="style"><slot /></div>
</template>
