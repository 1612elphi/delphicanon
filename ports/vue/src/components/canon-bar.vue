<script setup lang="ts">
import { computed } from 'vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-bar.css';

const props = defineProps<{
	/** Filled share of the width, 0 to 1. */
	share: number;
	/** CSS colour of the fill; default the primary colour. */
	fill?: string;
	/** CSS colour of the track; default the muted colour. */
	track?: string;
}>();

const style = computed(() => ({
	'--canon-bar-share': Math.min(Math.max(props.share, 0), 1),
	'--canon-bar-fill': props.fill,
	'--canon-bar-track': props.track,
}));
</script>

<!-- A bar filled from the leading edge. -->
<template>
	<div class="canon-bar" :style="style">
		<div class="canon-bar-fill" />
	</div>
</template>
